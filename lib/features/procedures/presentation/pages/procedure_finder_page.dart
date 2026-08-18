import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/procedure_info.dart';
import '../providers/procedures_provider.dart';
import '../widgets/procedure_list_view.dart';
import '../../../premium/presentation/pages/paywall_page.dart';
import '../../../../core/subscription/subscription_provider.dart';

/// 「制度・補助金を探す」独立ページ。
///
/// ライフステージを選択肢（チップ）で選ぶと、関連する制度・補助金だけに
/// 絞り込んで表示する。選択は永続化され、申請時期が近い制度の
/// リマインダー通知も自動でスケジュールされる（procedures_provider 参照）。
class ProcedureFinderPage extends ConsumerWidget {
  const ProcedureFinderPage({super.key});

  static const int _freeLimit = 6;

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final lifeStage = ref.watch(lifeStageProvider);
    final isPremium = ref.watch(isPremiumProvider);
    final viewedIds = ref.watch(viewedProcedureIdsProvider);

    final procedures = lifeStage == null
        ? ProcedureLibrary.all
        : ProcedureLibrary.byLifeStage(lifeStage);
    final viewedCount = procedures.where((p) => viewedIds.contains(p.id)).length;

    return Scaffold(
      appBar: AppBar(title: const Text('制度・補助金を探す')),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'あなたのライフステージを選ぶと、関連する制度に絞り込めます',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 10),
                Wrap(
                  spacing: 8,
                  runSpacing: 8,
                  children: [
                    ChoiceChip(
                      label: const Text('すべて'),
                      selected: lifeStage == null,
                      onSelected: (_) =>
                          ref.read(lifeStageProvider.notifier).setLifeStage(null),
                    ),
                    ...LifeStage.values.map((stage) => ChoiceChip(
                          label: Text(stage.label),
                          selected: lifeStage == stage,
                          onSelected: (_) => ref
                              .read(lifeStageProvider.notifier)
                              .setLifeStage(stage),
                        )),
                  ],
                ),
                const SizedBox(height: 12),
                Row(
                  children: [
                    Expanded(
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: procedures.isEmpty ? 0 : viewedCount / procedures.length,
                          minHeight: 6,
                          backgroundColor: Colors.grey.shade200,
                        ),
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      '確認済み $viewedCount/${procedures.length}',
                      style: const TextStyle(fontSize: 11, color: Colors.grey),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                const Text(
                  '制度の内容・金額は変更される場合があります。利用の際は記載の窓口で最新情報をご確認ください。',
                  style: TextStyle(fontSize: 11, color: Colors.grey),
                ),
              ],
            ),
          ),
          const Divider(height: 1),
          Expanded(
            child: SingleChildScrollView(
              child: Padding(
                padding: const EdgeInsets.only(top: 12),
                child: ProcedureListView(
                  procedures: procedures,
                  onExpand: (p) =>
                      ref.read(viewedProcedureIdsProvider.notifier).markViewed(p.id),
                  freeLimit: isPremium ? null : _freeLimit,
                  onUnlockTap: () => Navigator.push(
                    context,
                    MaterialPageRoute(builder: (_) => const PaywallPage()),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
