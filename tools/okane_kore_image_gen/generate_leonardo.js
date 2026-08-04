#!/usr/bin/env node
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// お金コレ！ イラスト一括生成ツール（Leonardo.ai版）
// leonardo-ai-image-gen スキルのパターンを流用。
// 診断結果イラスト3枚・ロールプレイキャラ3枚・マスコット差分5枚 = 計11枚を生成する。
//
// コスト最小化: alchemy:false, photoReal:false, num_images:1, 512x512
// 既存ファイルは自動スキップ（--allを何度実行しても未生成分だけ課金される）
//
// 使い方（PowerShellでは事前に $env:LEONARDO_API_KEY="xxxx" を実行）:
//   node generate_leonardo.js --count 2
//   node generate_leonardo.js --ids diag_chiritsumo,mascot_normal
//   node generate_leonardo.js --all
//   node generate_leonardo.js --all --force
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

const fs = require('fs');
const path = require('path');
const { IMAGE_SPECS, buildPrompt } = require('./prompt_builder');

const LEONARDO_API_KEY = process.env.LEONARDO_API_KEY;
const LEONARDO_MODEL_ID = process.env.LEONARDO_MODEL_ID || 'de7d3faf-762f-48e0-b3b7-9d0ac3a3fcf3';
const OUTPUT_DIR = path.join(__dirname, 'output');
const API_BASE = 'https://cloud.leonardo.ai/api/rest/v1';

async function generateImage(prompt, negativePrompt) {
  const createRes = await fetch(`${API_BASE}/generations`, {
    method: 'POST',
    headers: {
      Authorization: `Bearer ${LEONARDO_API_KEY}`,
      'Content-Type': 'application/json',
    },
    body: JSON.stringify({
      prompt,
      negative_prompt: negativePrompt,
      modelId: LEONARDO_MODEL_ID,
      width: 512,
      height: 512,
      num_images: 1,
      alchemy: false,
      photoReal: false,
    }),
  });

  if (!createRes.ok) {
    throw new Error(`Leonardo API error (create): ${createRes.status} ${await createRes.text()}`);
  }

  const created = await createRes.json();
  const genId = created?.sdGenerationJob?.generationId;
  if (!genId) {
    throw new Error(`generationId が取得できませんでした: ${JSON.stringify(created)}`);
  }

  let attempts = 0;
  let images = null;
  while (attempts < 30) {
    await new Promise((r) => setTimeout(r, 2000));
    const poll = await fetch(`${API_BASE}/generations/${genId}`, {
      headers: { Authorization: `Bearer ${LEONARDO_API_KEY}` },
    });
    if (!poll.ok) {
      throw new Error(`Leonardo API error (poll): ${poll.status} ${await poll.text()}`);
    }
    const data = await poll.json();
    const gen = data.generations_by_pk;
    if (gen?.status === 'COMPLETE') {
      images = gen.generated_images;
      break;
    }
    if (gen?.status === 'FAILED') {
      throw new Error(`generation failed: ${JSON.stringify(gen)}`);
    }
    attempts++;
  }

  if (!images || !images[0]?.url) {
    throw new Error('画像生成がタイムアウトしました');
  }

  return images[0].url;
}

async function downloadTo(url, filePath) {
  const res = await fetch(url);
  if (!res.ok) throw new Error(`download failed: ${res.status}`);
  const buf = Buffer.from(await res.arrayBuffer());
  fs.writeFileSync(filePath, buf);
}

function parseArgs() {
  const args = process.argv.slice(2);
  const opts = { count: null, ids: null, all: false, force: false };
  for (let i = 0; i < args.length; i++) {
    if (args[i] === '--count') opts.count = parseInt(args[++i], 10);
    else if (args[i] === '--ids') opts.ids = args[++i].split(',').map((s) => s.trim());
    else if (args[i] === '--all') opts.all = true;
    else if (args[i] === '--force') opts.force = true;
  }
  return opts;
}

async function main() {
  if (!LEONARDO_API_KEY) {
    console.error('❌ LEONARDO_API_KEY が設定されていません。');
    console.error('   例: $env:LEONARDO_API_KEY="xxxx"; node generate_leonardo.js --count 2');
    process.exit(1);
  }

  const opts = parseArgs();
  console.log(`📋 画像仕様を ${IMAGE_SPECS.length} 件読み込みました`);

  let target;
  if (opts.ids) {
    target = IMAGE_SPECS.filter((s) => opts.ids.includes(s.id));
  } else if (opts.all) {
    target = IMAGE_SPECS;
  } else {
    const n = opts.count || 2;
    target = IMAGE_SPECS.slice(0, n);
  }

  if (target.length === 0) {
    console.error('❌ 対象画像が見つかりません');
    process.exit(1);
  }

  fs.mkdirSync(OUTPUT_DIR, { recursive: true });
  const manifestPath = path.join(OUTPUT_DIR, 'manifest.json');
  const manifest = fs.existsSync(manifestPath)
    ? JSON.parse(fs.readFileSync(manifestPath, 'utf8'))
    : {};

  let skipped = 0;
  const toGenerate = opts.force
    ? target
    : target.filter((spec) => {
        const exists = fs.existsSync(path.join(OUTPUT_DIR, `${spec.id}.png`));
        if (exists) skipped++;
        return !exists;
      });

  if (skipped > 0) {
    console.log(`⏭️  既存の${skipped}枚をスキップ（再生成するには --force を付けてください）`);
  }
  console.log(`🎨 ${toGenerate.length} 枚を生成します（Leonardo.ai / modelId=${LEONARDO_MODEL_ID} / alchemy=off / 512x512）\n`);

  for (const spec of toGenerate) {
    const { prompt, negativePrompt } = buildPrompt(spec);
    process.stdout.write(`  ${spec.id} (${spec.label} / ${spec.category}) ... `);
    try {
      const imageUrl = await generateImage(prompt, negativePrompt);
      const outFile = path.join(OUTPUT_DIR, `${spec.id}.png`);
      await downloadTo(imageUrl, outFile);
      manifest[spec.id] = {
        label: spec.label,
        category: spec.category,
        file: `${spec.id}.png`,
        prompt,
        provider: 'leonardo',
        modelId: LEONARDO_MODEL_ID,
        generatedAt: new Date().toISOString(),
      };
      fs.writeFileSync(manifestPath, JSON.stringify(manifest, null, 2));
      console.log('✅');
    } catch (e) {
      console.log(`❌ ${e.message}`);
    }
  }

  console.log(`\n完了（生成${toGenerate.length}枚 / スキップ${skipped}枚）。出力先: ${OUTPUT_DIR}`);
}

main().catch((e) => {
  console.error(`❌ 予期しないエラー: ${e.message}`);
  process.exit(1);
});
