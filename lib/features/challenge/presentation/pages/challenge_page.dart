import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/challenge.dart';
import '../providers/challenge_provider.dart';
import '../../../user_profile/presentation/providers/user_provider.dart';
import '../../../../core/analytics/analytics_provider.dart';

class ChallengePage extends ConsumerWidget {
  const ChallengePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final challengeAsync = ref.watch(currentChallengeProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('チャレンジイベント')),
      body: challengeAsync.when(
        data: (challenge) {
          if (user == null) {
            return const Center(child: Text('ログインが必要です'));
          }
          return _buildChallengeDetail(context, ref, user.uid, challenge);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text('エラー: $error'),
              const SizedBox(height: 12),
              ElevatedButton(
                onPressed: () => ref.invalidate(currentChallengeProvider),
                child: const Text('再読み込み'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildChallengeDetail(
      BuildContext context, WidgetRef ref, String uid, Challenge challenge) {
    final isParticipating = challenge.isParticipating(uid);
    final ranking = challenge.ranking;

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.deepOrange.shade300, Colors.deepOrange.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.emoji_events, color: Colors.white),
                  const SizedBox(width: 8),
                  Text(
                    challenge.title,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              Text(
                challenge.description,
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 12),
              Text(
                '残り${challenge.daysRemaining}日 • 目標¥${challenge.targetReduction} • 参加者${challenge.participants.length}人',
                style: const TextStyle(color: Colors.white, fontSize: 12),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        if (!isParticipating)
          ElevatedButton.icon(
            onPressed: () => _joinChallenge(context, ref, uid, challenge.id),
            icon: const Icon(Icons.flag),
            label: const Text('チャレンジに参加する'),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.deepOrange.shade600,
              minimumSize: const Size.fromHeight(48),
            ),
          )
        else
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              borderRadius: BorderRadius.circular(8),
              border: Border.all(color: Colors.green.shade300),
            ),
            child: Row(
              children: [
                Icon(Icons.check_circle, color: Colors.green.shade600),
                const SizedBox(width: 8),
                const Text('参加中！完了で XP ×3倍'),
              ],
            ),
          ),
        const SizedBox(height: 24),
        const Text(
          '全国ランキング',
          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 12),
        if (ranking.isEmpty)
          const Center(child: Padding(
            padding: EdgeInsets.all(24),
            child: Text('まだ参加者がいません', style: TextStyle(color: Colors.grey)),
          ))
        else
          ...ranking.asMap().entries.map((entry) {
            final rank = entry.key + 1;
            final participant = entry.value;
            final isMe = participant.uid == uid;
            return Card(
              color: isMe ? Colors.blue.shade50 : null,
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: rank <= 3 ? Colors.amber : Colors.grey.shade300,
                  child: Text('$rank'),
                ),
                title: Text(isMe ? 'あなた' : 'ユーザー${participant.uid.substring(0, 6)}'),
                trailing: Text(
                  '¥${participant.reductionAmount}',
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ),
            );
          }),
      ],
    );
  }

  Future<void> _joinChallenge(
      BuildContext context, WidgetRef ref, String uid, String challengeId) async {
    final service = ref.read(challengeServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);

    try {
      await service.joinChallenge(challengeId, uid);

      try {
        await analytics.logEvent('challenge_joined', parameters: {
          'user_id': uid,
          'challenge_id': challengeId,
        });
      } catch (e) {
        // Analytics failures should never block the user-facing join flow.
        debugPrint('challenge_joined analytics logging failed: $e');
      }

      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('チャレンジに参加しました！')),
        );
      }
    } catch (e) {
      debugPrint('joinChallenge failed: $e');
      if (context.mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('参加に失敗しました')),
        );
      }
    }
  }
}
