import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/household_group.dart';
import '../../domain/models/family_mission.dart';
import '../providers/household_provider.dart';
import '../providers/family_mission_provider.dart';
import '../../../../core/theme/app_colors.dart';

/// 家族間の家計共有ダッシュボード。
/// 世帯グループの貢献額ランキングと、今週の家族ミッションの進捗を
/// 1画面にまとめて表示する。
class FamilyDashboardPage extends ConsumerWidget {
  final String groupId;
  final String uid;

  const FamilyDashboardPage({Key? key, required this.groupId, required this.uid})
      : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final groupAsync = ref.watch(groupStreamProvider(groupId));
    final missionAsync = ref.watch(weeklyFamilyMissionProvider(groupId));

    return Scaffold(
      appBar: AppBar(title: const Text('家族ダッシュボード')),
      body: groupAsync.when(
        data: (group) {
          if (group == null) {
            return const Center(child: Text('グループが見つかりません'));
          }
          return ListView(
            padding: AppSpacing.paddingMd,
            children: [
              _buildMemberBreakdown(context, group, uid),
              const SizedBox(height: 20),
              const Text('今週の家族ミッション',
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
              const SizedBox(height: 12),
              missionAsync.when(
                data: (mission) => mission == null
                    ? const Text('現在進行中のミッションはありません',
                        style: TextStyle(color: Colors.grey))
                    : _buildMissionCard(mission),
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, st) => Text('エラー: $error'),
              ),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, st) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  Widget _buildMemberBreakdown(
      BuildContext context, HouseholdGroup group, String uid) {
    final amountFormat = NumberFormat('#,###');
    final entries = group.members.map((memberUid) {
      final amount = group.memberContributions[memberUid] ?? 0;
      final nickname = group.memberNicknames[memberUid] ?? 'メンバー';
      final share = group.totalSavings > 0 ? amount / group.totalSavings : 0.0;
      return (uid: memberUid, nickname: nickname, amount: amount, share: share);
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text('メンバー別 貯蓄内訳',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                Text(
                  '合計 ¥${amountFormat.format(group.totalSavings)}',
                  style: const TextStyle(fontSize: 12, color: Colors.grey),
                ),
              ],
            ),
            const SizedBox(height: 16),
            for (final entry in entries)
              Padding(
                padding: const EdgeInsets.only(bottom: 12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 14,
                          backgroundColor: entry.uid == uid
                              ? Theme.of(context).colorScheme.primary
                              : Colors.grey.shade400,
                          child: Text(
                            entry.nickname.isNotEmpty ? entry.nickname[0] : '?',
                            style: const TextStyle(color: Colors.white, fontSize: 12),
                          ),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            entry.nickname,
                            style: TextStyle(
                              fontWeight:
                                  entry.uid == uid ? FontWeight.bold : FontWeight.normal,
                            ),
                          ),
                        ),
                        Text('¥${amountFormat.format(entry.amount)}',
                            style: const TextStyle(fontWeight: FontWeight.bold)),
                      ],
                    ),
                    const SizedBox(height: 6),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(4),
                      child: LinearProgressIndicator(
                        value: entry.share.clamp(0.0, 1.0),
                        minHeight: 6,
                        backgroundColor: Colors.grey.shade200,
                        color: entry.uid == uid
                            ? Theme.of(context).colorScheme.primary
                            : Colors.grey.shade400,
                      ),
                    ),
                  ],
                ),
              ),
            const SizedBox(height: 8),
            Text(
              '世帯目標: ¥${amountFormat.format(group.monthlyGoal)}（達成率${(group.progressRatio * 100).toStringAsFixed(0)}%）',
              style: const TextStyle(fontSize: 12, color: Colors.grey),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMissionCard(FamilyMission mission) {
    final amountFormat = NumberFormat('#,###');
    final ranking = mission.ranking;

    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(mission.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(mission.title,
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                ),
                if (mission.isCompleted)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: Colors.green.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text('達成！',
                        style: TextStyle(
                            color: Colors.green.shade800,
                            fontSize: 11,
                            fontWeight: FontWeight.bold)),
                  ),
              ],
            ),
            const SizedBox(height: 6),
            Text(mission.description,
                style: const TextStyle(fontSize: 12, color: Colors.grey)),
            const SizedBox(height: 12),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: mission.progressRatio,
                minHeight: 8,
                backgroundColor: Colors.grey.shade200,
                color: mission.isCompleted ? Colors.green : Colors.orange,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              '¥${amountFormat.format(mission.totalContribution)} / ¥${amountFormat.format(mission.targetAmount)}'
              '（残り${mission.daysRemaining.clamp(0, 999)}日）',
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
            ),
            if (ranking.isNotEmpty) ...[
              const SizedBox(height: 16),
              const Text('参加者ランキング',
                  style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
              const SizedBox(height: 8),
              for (var i = 0; i < ranking.length; i++)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 4),
                  child: Row(
                    children: [
                      Text(
                        i == 0
                            ? '🏆'
                            : i == 1
                                ? '🥈'
                                : i == 2
                                    ? '🥉'
                                    : '${i + 1}位',
                        style: const TextStyle(fontSize: 13),
                      ),
                      const SizedBox(width: 8),
                      Expanded(child: Text(ranking[i].nickname)),
                      Text('${ranking[i].score}pt',
                          style: const TextStyle(fontWeight: FontWeight.w600)),
                    ],
                  ),
                ),
            ],
            if (mission.eventProposal != null) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text('達成後のお楽しみ: ${mission.eventProposal}',
                    style: const TextStyle(fontSize: 12)),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
