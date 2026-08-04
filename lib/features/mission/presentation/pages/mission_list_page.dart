import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/mission.dart';
import '../providers/mission_provider.dart';
import '../../../user_profile/presentation/providers/user_provider.dart';
import '../../../../core/analytics/analytics_provider.dart';

class MissionListPage extends ConsumerWidget {
  const MissionListPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text('ログインが必要です')),
      );
    }

    final missionsAsync = ref.watch(missionsStreamProvider(user.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('実行ミッション')),
      body: missionsAsync.when(
        data: (missions) {
          if (missions.isEmpty) {
            return const Center(child: Text('現在ミッションはありません'));
          }
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: missions.length,
            itemBuilder: (context, index) {
              return _buildMissionCard(context, ref, user.uid, missions[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  Widget _buildMissionCard(
      BuildContext context, WidgetRef ref, String uid, Mission mission) {
    final daysLeft = mission.deadline.difference(DateTime.now()).inDays;

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(_iconForType(mission.type), color: Colors.green.shade600),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    mission.title,
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 16,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              mission.description,
              style: TextStyle(color: Colors.grey.shade700, fontSize: 13),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  daysLeft > 0 ? '残り$daysLeft日' : '本日締切',
                  style: TextStyle(
                    fontSize: 12,
                    color: daysLeft <= 1 ? Colors.red : Colors.grey,
                  ),
                ),
                Row(
                  children: [
                    Text(
                      '+${mission.rewardXP} XP',
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        color: Colors.green,
                      ),
                    ),
                    const SizedBox(width: 12),
                    ElevatedButton(
                      onPressed: () => _completeMission(
                          context, ref, uid, mission),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                      ),
                      child: const Text('完了報告'),
                    ),
                  ],
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _completeMission(
      BuildContext context, WidgetRef ref, String uid, Mission mission) async {
    final service = ref.read(missionServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);

    await service.completeMission(uid, mission.id);
    await analytics.logEvent('mission_completed', parameters: {
      'user_id': uid,
      'mission_type': mission.type.index.toString(),
      'reward_xp': mission.rewardXP,
    });

    ref.read(userProvider.notifier).addXP(mission.rewardXP);

    if (context.mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ミッション完了！ +${mission.rewardXP} XP')),
      );
    }
  }

  IconData _iconForType(MissionType type) {
    switch (type) {
      case MissionType.furusatoNozei:
        return Icons.card_giftcard;
      case MissionType.insuranceReview:
        return Icons.shield;
      case MissionType.receiptReduction:
        return Icons.receipt_long;
      case MissionType.savingsTarget:
        return Icons.savings;
      case MissionType.investmentStart:
        return Icons.trending_up;
    }
  }
}
