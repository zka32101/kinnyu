# お金コレ！— 金融知識学習アプリ

大人が1日2分のスキマ時間で、金融知識（貯蓄・税金・投資・保険）を習い、実行できるDuolingo型学習アプリ。

## Project Status

**Version**: v1.3（革新5アイデア統合）  
**Phase**: 基盤実装中（簡単な実装→複雑な実装はSonnetで）  
**Next**: Firebase設定、Quiz エンジン実装

## Features (v1.3)

### Must機能（7個）
1. **レシート OCR + クイズ化** — レシート撮影→自動抽出→実支出クイズ化
2. **実行ミッション** — ふるさと納税等の行動タスク・完了報告でXP
3. **貯蓄額ストリーク** — 金額で可視化（¥47,000節約など）
4. **世帯リーグ** — 夫婦・家族単位で参加・競争
5. **家計ロールプレイ** — 仮想人生シミュレーター
6. **見える投資ポートフォリオ** — 節約額を仮想投資・実市場データ連動
7. **ベンチマーク + チャレンジイベント** — 同年代比較 + 期間限定全国競争

## Tech Stack

```
言語: Dart 3.x
UI Framework: Flutter (最新安定版)
状態管理: Riverpod
データベース: Firebase Firestore
認証: Firebase Auth
計測: Firebase Analytics + Crashlytics
課金: RevenueCat (後で追加)
アニメーション: Lottie (後で追加)
```

## Project Structure

```
lib/
├── main.dart                          # Entry point + Firebase init
├── firebase_options.dart              # Firebase configuration
├── features/
│   ├── quiz/                          # Quiz engine
│   │   ├── data/                      # Repositories, datasources
│   │   ├── domain/                    # Entities, models
│   │   └── presentation/              # Pages, widgets, notifiers
│   ├── home/                          # Home screen
│   ├── user_profile/                  # User profile & state
│   ├── payment/                       # RevenueCat integration (WIP)
│   └── analytics/                     # Firebase Analytics (WIP)
├── core/
│   ├── firebase/                      # Firebase helpers
│   ├── remote_config/                 # Remote Config for A/B tests
│   ├── analytics/                     # Analytics service
│   └── constants/                     # App-wide constants
└── utils/                             # Utility functions
```

## Getting Started

### Prerequisites
- Flutter 3.12+
- Firebase project setup
- Android Studio / VS Code + Flutter extension

### Setup

1. **Install dependencies**
   ```bash
   cd okane_kore
   flutter pub get
   ```

2. **Configure Firebase**
   - Create Firebase project (Google Cloud Console)
   - Download google-services.json (Android) and GoogleService-Info.plist (iOS)
   - Run: `flutterfire configure`
   - Update `lib/firebase_options.dart` with credentials

3. **Run app**
   ```bash
   flutter run
   ```

## Roadmap

### Week 1-2: 基盤 (基本実装 ✅)
- [x] Flutter project setup
- [x] Firebase configuration template
- [x] Directory structure
- [x] Home screen UI
- [x] User profile state (Riverpod)
- [x] Question model
- [ ] Firebase connection (next)
- [ ] Quiz datasource (next)

### Week 3-4: コア体験（レシート→クイズ→投資）
- [ ] Receipt OCR integration (Google Vision API)
- [ ] Quiz engine with receipt context
- [ ] Investment simulator engine
- [ ] UI for virtual portfolio

### Week 5: 世帯機能・ベンチマーク・チャレンジ
- [ ] Household group management
- [ ] Anonymous benchmark statistics
- [ ] Challenge event system

### Week 6-8: 計測・テスト・ローンチ
- [ ] Firebase Analytics integration
- [ ] Unit / Widget / Integration tests
- [ ] CI/CD (GitHub Actions)
- [ ] App Store & Play Store preparation

## Important Notes

### Compliance
- **Week 0**: 金融庁コンプライアンス確認（1-2ヶ月・必須）
  - 投資シミュレーションの指導範囲確認
  - ベンチマーク統計のプライバシー対応
  - ロールプレイの教育範囲確認

### KPI Targets (OKR)
- **KR1**: Day7 リテンション 24% 以上
- **KR2**: Day30 リテンション 16% 以上
- **KR3**: コンバージョン率 6% 以上
- **KR4**: 世帯チャーン率 10% 未満

### Aha Moment
「節約した金額が、本当に『貯まる』『増える』ことを可視化した瞬間」
- Example: 月3万節約 → 仮想投資開始 → 3ヶ月後¥31,200に増加

## Development Strategy

1. **Simple first** — 複雑な実装はあとでSonnetで
2. **Test-driven** — Unit tests (カバレッジ 50%+) 優先
3. **Analytics first** — KPI イベント仕込み優先
4. **Firebase + RevenueCat** — 双方向テスト

## References

- [Design Doc v1.3](../../docs/okane_kore_design_v1_3.md)
- [Firebase Docs](https://firebase.google.com/docs)
- [Flutter Riverpod](https://riverpod.dev)
- [Financial Literacy Guidelines](https://www.fsa.go.jp) — 金融庁ガイドライン
