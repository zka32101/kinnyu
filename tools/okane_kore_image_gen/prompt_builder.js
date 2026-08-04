// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// お金コレ！ AI画像プロンプト組み立てモジュール
// leonardo-ai-image-gen スキル（原本: card_crown/tools/seed_card_image_gen/）を流用。
// お金コレはカードゲームと異なり画像点数が固定（11枚）のため、
// Dartファイルからの動的パースではなく、静的リストとして直接定義する。
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━

// アプリ全体で統一する house style（フラットベクター・親しみやすい金融教育アプリ風）
const HOUSE_STYLE =
  'flat vector illustration, cute minimalist character design, soft rounded shapes, ' +
  'warm friendly color palette, clean professional fintech education app illustration style, ' +
  'simple soft gradient background, centered composition';

const NEGATIVE_PROMPT = [
  'text, words, letters, numbers, watermark, signature, logo',
  'photorealistic, 3d render, realistic skin texture',
  'scary, creepy, dark, disturbing',
  'ugly, blurry, low quality, deformed, mutated, malformed',
  'extra limbs, bad anatomy, extra fingers',
  'duplicate, oversaturated, washed out',
].join(', ');

// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
// 画像仕様一覧（id は生成ファイル名 & Flutter 側 asset パスに使う安定キー）
// ━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━━
const IMAGE_SPECS = [
  // --- ① 家計診断 結果タイプ別イラスト（3枚） ---
  // PatternDiagnosisGenerator._spendingTypes と対応
  {
    id: 'diag_chiritsumo',
    category: 'diagnosis',
    label: 'ちりつも支出タイプ',
    prompt:
      'a cheerful young Japanese person happily holding a coffee cup and a convenience store bag, ' +
      'small coins gently scattering around like falling leaves, symbolizing frequent small purchases, ' +
      'light and playful mood',
  },
  {
    id: 'diag_merihari',
    category: 'diagnosis',
    label: 'メリハリ消費タイプ',
    prompt:
      'an excited young Japanese person celebrating with shopping bags and a restaurant receipt, ' +
      'joyful bursty spending energy, small confetti and sparkle effects around, dynamic happy pose',
  },
  {
    id: 'diag_kotei',
    category: 'diagnosis',
    label: '固定費モヤモヤタイプ',
    prompt:
      'a puzzled young Japanese person looking at a small stack of subscription bills and insurance papers, ' +
      'gentle question marks floating around their head, mildly confused but approachable expression',
  },

  // --- ② ロールプレイ シナリオ別キャラクター（3枚） ---
  // RoleplayScenarios（youngFamily / singleProfessional / preRetirement）と対応
  {
    id: 'roleplay_young_family',
    category: 'roleplay',
    label: '若い家族',
    prompt:
      'a warm happy Japanese family of four, two parents and two small children standing together, ' +
      'cozy home living room background, gentle smiles, wholesome family portrait pose',
  },
  {
    id: 'roleplay_single_professional',
    category: 'roleplay',
    label: '独身社会人',
    prompt:
      'a confident young Japanese office worker in smart business casual attire, standing alone with a bag, ' +
      'modern city skyline background, energetic independent pose',
  },
  {
    id: 'roleplay_pre_retirement',
    category: 'roleplay',
    label: '退職前夫婦',
    prompt:
      'a warm mature Japanese couple in their fifties with graying hair, standing together smiling, ' +
      'comfortable cozy home background, calm reassuring pose',
  },

  // --- ③ 貯金箱マスコット 差分（5枚） ---
  // ホーム画面スプラッシュの白い貯金箱シルエットをかわいいキャラクター化
  {
    id: 'mascot_normal',
    category: 'mascot',
    label: 'マスコット・通常',
    prompt:
      'a cute kawaii piggy bank mascot character, simple round chubby body, small stubby legs, ' +
      'gentle friendly smile, standing pose, soft pastel pink and blue color scheme, chibi style',
  },
  {
    id: 'mascot_streak',
    category: 'mascot',
    label: 'マスコット・ストリーク達成',
    prompt:
      'a cute kawaii piggy bank mascot character celebrating with a small orange flame icon glowing above its head, ' +
      'excited jumping pose, sparkles around, soft pastel pink and blue color scheme, chibi style',
  },
  {
    id: 'mascot_correct',
    category: 'mascot',
    label: 'マスコット・正解',
    prompt:
      'a cute kawaii piggy bank mascot character with a big joyful smile, one stubby arm raised in victory, ' +
      'small gold coins happily flying around it, soft pastel pink and blue color scheme, chibi style',
  },
  {
    id: 'mascot_incorrect',
    category: 'mascot',
    label: 'マスコット・不正解',
    prompt:
      'a cute kawaii piggy bank mascot character with a slightly disappointed but still endearing expression, ' +
      'one small teardrop, encouraging not sad, soft pastel pink and blue color scheme, chibi style',
  },
  {
    id: 'mascot_levelup',
    category: 'mascot',
    label: 'マスコット・レベルアップ',
    prompt:
      'a cute kawaii piggy bank mascot character wearing a tiny golden crown, glowing warm golden aura around it, ' +
      'proud confident pose, soft pastel pink and blue color scheme, chibi style',
  },

  // --- ④ アプリアイコン（1枚） ---
  // 小サイズでも視認性が高いよう、背景いっぱいに大きく1体だけを配置するアイコン専用構図。
  // ホーム画面スプラッシュと世界観を統一するため貯金箱マスコットを採用。
  {
    id: 'app_icon',
    category: 'icon',
    label: 'アプリアイコン',
    prompt:
      'app icon design, a cute kawaii piggy bank mascot character filling most of the frame, ' +
      'simple bold shapes, thick clean outlines, high contrast, gentle happy smile, ' +
      'centered composition with small margin, flat solid vivid blue background, ' +
      'soft pastel pink piggy bank body, no small details, easily recognizable at small sizes, ' +
      'square composition, chibi style, mobile app icon',
  },
];

function buildPrompt(spec) {
  const prompt = [spec.prompt, HOUSE_STYLE, 'no text no watermark no border']
    .filter(Boolean)
    .join(', ');
  return { prompt, negativePrompt: NEGATIVE_PROMPT };
}

module.exports = { IMAGE_SPECS, buildPrompt, HOUSE_STYLE, NEGATIVE_PROMPT };
