# Firestore ルールの配備手順（金融・家計学校 / プロジェクト `okane-bea50`）

最終確認: 2026-10-04。

## 現状（配備前）

- 本番で動いているルール = PR#53 時点の `firestore.rules`（**差分0行**を確認。リリース `projects/okane-bea50/rulesets/a87f1ff7-7535-4867-9a46-8dabe95761f0`、更新 2026-09-30）
- リポジトリの `main` には PR#56 の修正が入っていて、**本番に未配備**

## 今回の変更の中身（PR#56）

1. `household_groups/{id}` のサブコレクション用 `match /{sub=**}` を `match /{col}/{docId}/{rest=**}` に変更。旧記述は `rules_version = '2'` で「0階層以上」に一致し、**メンバーがグループ文書そのものを全面的に書き換えられる**状態だった
2. メンバーによる更新は、`members` を変えない場合だけに限定（旧条件は他人を外すことを許していた）
3. 自分だけが抜ける更新（脱退・アカウント削除）を許可

## 配備前の確認（済み・未了）

- [x] クライアントの世帯グループへの書き込みは4種で、すべて新ルールに適合（コード確認）
  - 作成: `members == [uid]` ✓ / 参加: `members` と `memberNicknames` のみ更新 ✓ / 貯蓄加算: `totalSavings`・`memberContributions` ✓ / 脱退: 自分だけ除去 ✓
- [x] ルール検証 API で 11/11 件が期待どおり: `python tools/test_household_rules.py okane-bea50`（配備はしない）
- [ ] **実機で世帯機能を一通り確認**（下のチェックリスト）。ルールを厳しくしたため、ここで動かないと本番で壊れる
- [x] 他のアプリが `okane-bea50` を共有していないことの確認: 登録アプリは Android の `com.yourwish.okane` のみ（iOS アプリは未登録。`firebase_options.dart` の iOS 設定が別プロジェクト `petit-works-apps-9029a` を指している問題は別件）

## 実機チェックリスト（2台または2アカウント）

1. アカウントAで世帯を作成 → 招待コードが出る
2. アカウントBが招待コードで参加 → ニックネームが両方に表示される
3. どちらかが貯蓄を加算 → 合計と貢献額が更新される
4. 家族ミッション・社会貢献（寄付/カーボン）の記録を追加できる
5. アカウントBが世帯を脱退 → Aの画面からBが消える
6. アカウントBで「アカウントとデータを削除」→ 世帯から抜ける（A に影響が出ない）

## 配備コマンド

```powershell
# Bash の firebase CLI は壊れているので PowerShell で実行する
firebase deploy --only firestore:rules --project okane-bea50
```

- **`--force` は使わない**。`--dry-run` も使わない（API の有効化などの副作用があるため。検証は上のスクリプトで行う）
- 配備後に再度 `python tools/test_household_rules.py okane-bea50` を流し、11/11 を確認する

## ロールバック

直前のルール（PR#53 時点）に戻す:

```powershell
git show 28d6e53:firestore.rules > firestore.rules.rollback
# 内容を確認してから、firestore.rules に置いて同じコマンドで配備する
firebase deploy --only firestore:rules --project okane-bea50
```

Firebase コンソール（Firestore → ルール → 履歴）からも、前の版に戻せる。
