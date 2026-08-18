import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/mission.dart';
import '../providers/mission_provider.dart';
import '../../../user_profile/presentation/providers/user_provider.dart';
import '../../../../core/analytics/analytics_provider.dart';

class MissionListPage extends ConsumerStatefulWidget {
  const MissionListPage({Key? key}) : super(key: key);

  @override
  ConsumerState<MissionListPage> createState() => _MissionListPageState();
}

class _MissionListPageState extends ConsumerState<MissionListPage> {
  // 完了処理中のミッションIDを保持し、完了ボタンの多重タップを防ぐ。
  String? _completingMissionId;

  @override
  Widget build(BuildContext context) {
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
              return _buildMissionCard(context, user.uid, missions[index]);
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  Widget _buildMissionCard(BuildContext context, String uid, Mission mission) {
    final daysLeft = mission.deadline.difference(DateTime.now()).inDays;
    final isCompleting = _completingMissionId == mission.id;

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
                  mission.isExpired
                      ? '期限切れ'
                      : (daysLeft > 0 ? '残り$daysLeft日' : '本日締切'),
                  style: TextStyle(
                    fontSize: 12,
                    color: mission.isExpired
                        ? Colors.grey
                        : (daysLeft <= 1 ? Colors.red : Colors.grey),
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
                      onPressed: (isCompleting || mission.isExpired)
                          ? null
                          : () => _completeMission(context, uid, mission),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.green.shade600,
                      ),
                      child: isCompleting
                          ? const SizedBox(
                              height: 16,
                              width: 16,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Text('完了報告'),
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
      BuildContext context, String uid, Mission mission) async {
    // 既に処理中であれば何もしない（多重タップ防止）
    if (_completingMissionId != null) {
      return;
    }

    // 期限切れのミッションは完了できない
    if (mission.isExpired) {
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('このミッションは期限切れのため完了できません')),
        );
      }
      return;
    }

    final service = ref.read(missionServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);

    setState(() {
      _completingMissionId = mission.id;
    });

    try {
      // Firestore の更新が成功した場合のみ、XP付与・成功表示を行う。
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
    } catch (e) {
      debugPrint('completeMission error: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('ミッションの完了に失敗しました。もう一度お試しください。')),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _completingMissionId = null;
        });
      }
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
