import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/achievement.dart';
import '../providers/achievements_provider.dart';
import '../../../user_profile/presentation/providers/user_provider.dart';
import '../../../../core/theme/app_colors.dart';

/// 実績・バッジ一覧画面。既存プロバイダーの値から計算した進捗を
/// カテゴリごとにセクション分けして表示する。
class AchievementsPage extends ConsumerWidget {
  const AchievementsPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('実績・バッジ')),
      body: user == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'ログインすると実績・バッジが表示されます',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          : _AchievementsBody(uid: user.uid),
    );
  }
}

class _AchievementsBody extends ConsumerWidget {
  final String uid;

  const _AchievementsBody({required this.uid});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final progressAsync = ref.watch(achievementProgressListProvider(uid));

    return progressAsync.when(
      data: (progressList) {
        final unlockedCount = progressList.where((p) => p.unlocked).length;
        final totalCount = progressList.length;

        final grouped = <AchievementCategory, List<AchievementProgress>>{};
        for (final progress in progressList) {
          grouped
              .putIfAbsent(progress.achievement.category, () => [])
              .add(progress);
        }

        return RefreshIndicator(
          onRefresh: () async {
            ref.invalidate(achievementProgressListProvider(uid));
            await ref.read(achievementProgressListProvider(uid).future);
          },
          child: ListView(
            padding: AppSpacing.paddingMd,
            children: [
              _buildSummaryCard(unlockedCount, totalCount),
              const SizedBox(height: 20),
              for (final category in AchievementCategory.values)
                if (grouped[category] != null &&
                    grouped[category]!.isNotEmpty) ...[
                  _buildCategorySectionHeader(category, grouped[category]!),
                  const SizedBox(height: 10),
                  _buildAchievementGrid(grouped[category]!),
                  const SizedBox(height: 20),
                ],
            ],
          ),
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, stack) => Center(child: Text('エラー: $error')),
    );
  }

  Widget _buildSummaryCard(int unlockedCount, int totalCount) {
    final progress = totalCount == 0 ? 0.0 : unlockedCount / totalCount;

    return Container(
      padding: AppSpacing.paddingLg,
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.amber.shade400, Colors.deepOrange.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: AppSpacing.radiusMedium,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              const Icon(Icons.emoji_events, color: Colors.white, size: 28),
              const SizedBox(width: 10),
              const Text(
                '解除済みの実績',
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Text(
            '解除済み $unlockedCount / 全$totalCount',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 22,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: progress,
              minHeight: 8,
              backgroundColor: Colors.white24,
              valueColor: const AlwaysStoppedAnimation(Colors.white),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCategorySectionHeader(
      AchievementCategory category, List<AchievementProgress> items) {
    final unlockedInCategory = items.where((p) => p.unlocked).length;
    return Row(
      children: [
        Icon(_iconForCategory(category), color: _colorForCategory(category), size: 18),
        const SizedBox(width: 6),
        Text(
          category.label,
          style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
        ),
        const SizedBox(width: 8),
        Text(
          '$unlockedInCategory / ${items.length}',
          style: TextStyle(fontSize: 12, color: Colors.grey.shade600),
        ),
      ],
    );
  }

  Widget _buildAchievementGrid(List<AchievementProgress> items) {
    return GridView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        crossAxisSpacing: 12,
        mainAxisSpacing: 12,
        childAspectRatio: 0.95,
      ),
      itemCount: items.length,
      itemBuilder: (context, index) => _AchievementCard(progress: items[index]),
    );
  }

  IconData _iconForCategory(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.streak:
        return Icons.local_fire_department;
      case AchievementCategory.level:
        return Icons.military_tech;
      case AchievementCategory.mission:
        return Icons.task_alt;
      case AchievementCategory.procedure:
        return Icons.account_balance;
      case AchievementCategory.investment:
        return Icons.trending_up;
    }
  }

  Color _colorForCategory(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.streak:
        return Colors.deepOrange;
      case AchievementCategory.level:
        return Colors.indigo;
      case AchievementCategory.mission:
        return Colors.teal;
      case AchievementCategory.procedure:
        return Colors.blue;
      case AchievementCategory.investment:
        return Colors.green;
    }
  }
}

class _AchievementCard extends StatelessWidget {
  final AchievementProgress progress;

  const _AchievementCard({required this.progress});

  Color _colorForCategory(AchievementCategory category) {
    switch (category) {
      case AchievementCategory.streak:
        return Colors.deepOrange;
      case AchievementCategory.level:
        return Colors.indigo;
      case AchievementCategory.mission:
        return Colors.teal;
      case AchievementCategory.procedure:
        return Colors.blue;
      case AchievementCategory.investment:
        return Colors.green;
    }
  }

  @override
  Widget build(BuildContext context) {
    final achievement = progress.achievement;
    final unlocked = progress.unlocked;
    final color = _colorForCategory(achievement.category);

    return Card(
      elevation: unlocked ? 2 : 0,
      color: unlocked
          ? null
          : Theme.of(context).colorScheme.surfaceContainerHighest,
      shape: RoundedRectangleBorder(
        borderRadius: AppSpacing.radiusMedium,
        side: BorderSide(
          color: unlocked ? color.withAlpha(80) : Colors.grey.shade300,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: unlocked ? color.withAlpha(30) : Colors.grey.shade200,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    achievement.icon,
                    color: unlocked ? color : Colors.grey.shade400,
                    size: 20,
                  ),
                ),
                const Spacer(),
                if (unlocked)
                  Icon(Icons.check_circle, color: color, size: 18),
              ],
            ),
            const SizedBox(height: 8),
            Text(
              achievement.title,
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.bold,
                color: unlocked
                    ? Theme.of(context).colorScheme.onSurface
                    : Theme.of(context).colorScheme.onSurface.withAlpha(150),
              ),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            const SizedBox(height: 4),
            Expanded(
              child: Text(
                achievement.description,
                style: TextStyle(
                  fontSize: 11,
                  color: unlocked
                      ? Theme.of(context).colorScheme.onSurfaceVariant
                      : Theme.of(context).colorScheme.onSurface.withAlpha(100),
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
            if (!unlocked) ...[
              const SizedBox(height: 6),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: progress.progress,
                  minHeight: 5,
                  backgroundColor:
                      Theme.of(context).colorScheme.surfaceContainerHighest,
                  valueColor: AlwaysStoppedAnimation(color.withAlpha(180)),
                ),
              ),
              const SizedBox(height: 3),
              Text(
                '${progress.currentValue} / ${achievement.threshold}',
                style: TextStyle(fontSize: 10, color: Colors.grey.shade500),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
