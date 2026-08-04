#!/usr/bin/env node
// アプリアイコン専用：1024x1024の高解像度で1枚だけ生成する（App Store要件対応）。
// 通常のgenerate_leonardo.jsは512x512固定のため、このアイコンだけ別スクリプトで対応する。
const fs = require('fs');
const path = require('path');
const { buildPrompt, IMAGE_SPECS } = require('./prompt_builder');

const LEONARDO_API_KEY = process.env.LEONARDO_API_KEY;
const LEONARDO_MODEL_ID = process.env.LEONARDO_MODEL_ID || 'de7d3faf-762f-48e0-b3b7-9d0ac3a3fcf3';
const API_BASE = 'https://cloud.leonardo.ai/api/rest/v1';
const OUTPUT_DIR = path.join(__dirname, 'output');

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
      width: 1024,
      height: 1024,
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
  if (!genId) throw new Error(`generationId が取得できませんでした: ${JSON.stringify(created)}`);

  let attempts = 0;
  let images = null;
  while (attempts < 30) {
    await new Promise((r) => setTimeout(r, 2000));
    const poll = await fetch(`${API_BASE}/generations/${genId}`, {
      headers: { Authorization: `Bearer ${LEONARDO_API_KEY}` },
    });
    const data = await poll.json();
    const gen = data.generations_by_pk;
    if (gen?.status === 'COMPLETE') { images = gen.generated_images; break; }
    if (gen?.status === 'FAILED') throw new Error(`generation failed: ${JSON.stringify(gen)}`);
    attempts++;
  }
  if (!images || !images[0]?.url) throw new Error('画像生成がタイムアウトしました');
  return images[0].url;
}

async function downloadTo(url, filePath) {
  const res = await fetch(url);
  const buf = Buffer.from(await res.arrayBuffer());
  fs.writeFileSync(filePath, buf);
}

async function main() {
  if (!LEONARDO_API_KEY) {
    console.error('❌ LEONARDO_API_KEY が設定されていません。');
    process.exit(1);
  }
  const spec = IMAGE_SPECS.find((s) => s.id === 'app_icon');
  const { prompt, negativePrompt } = buildPrompt(spec);
  console.log('🎨 アプリアイコンを1024x1024で生成します...');
  const imageUrl = await generateImage(prompt, negativePrompt);
  const outFile = path.join(OUTPUT_DIR, 'app_icon_1024.png');
  await downloadTo(imageUrl, outFile);
  console.log(`✅ 完了: ${outFile}`);
}

main().catch((e) => {
  console.error(`❌ エラー: ${e.message}`);
  process.exit(1);
});
