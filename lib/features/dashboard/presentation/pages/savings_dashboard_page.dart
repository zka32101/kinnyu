import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../user_profile/presentation/providers/user_provider.dart';
import '../../../user_profile/presentation/providers/streak_provider.dart';
import '../../../investment/presentation/providers/investment_provider.dart';
import '../../../investment/domain/services/market_simulator.dart';
import '../../../mission/presentation/providers/mission_provider.dart';
import '../../../procedures/domain/models/procedure_info.dart';
import '../../../procedures/presentation/providers/procedures_provider.dart';
import '../../../../core/subscription/subscription_provider.dart';
import '../../../premium/presentation/pages/paywall_page.dart';

/// 家計改善ダッシュボード。XP・ストリーク・投資・ミッション・制度確認状況を
/// 1画面にまとめ、これまでの取り組みの成果を可視化する。
class SavingsDashboardPage extends ConsumerWidget {
  const SavingsDashboardPage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('家計改善ダッシュボード')),
      body: user == null
          ? const Center(
              child: Padding(
                padding: EdgeInsets.all(24),
                child: Text(
                  'ログインするとダッシュボードが表示されます',
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            )
          : SingleChildScrollView(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildLevelCard(user.totalXP, user.level),
                  _TrialPromoBanner(streak: user.streak, level: user.level),
                  const SizedBox(height: 20),
                  const Text(
                    'これまでの取り組み',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 12),
                  _buildStatGrid(context, ref, user.uid),
                ],
              ),
            ),
    );
  }

  Widget _buildLevelCard(int totalXP, int level) {
    final xpIntoLevel = totalXP % 100;
    final progress = xpIntoLevel / 100;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.indigo.shade400, Colors.indigo.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'レベル $level',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '累計 $totalXP XP',
            style: const TextStyle(color: Colors.white70, fontSize: 13),
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
          const SizedBox(height: 6),
          Text(
            '次のレベルまで あと${100 - xpIntoLevel}XP',
            style: const TextStyle(color: Colors.white70, fontSize: 11),
          ),
        ],
      ),
    );
  }

  Widget _buildStatGrid(BuildContext context, WidgetRef ref, String uid) {
    final streakAsync = ref.watch(streakStreamProvider(uid));
    final investmentsAsync = ref.watch(activeInvestmentsProvider(uid));
    final missionsAsync = ref.watch(missionsStreamProvider(uid));
    final viewedProcedureIds = ref.watch(viewedProcedureIdsProvider);

    final streakTile = streakAsync.when(
      data: (streak) => _StatTile(
        icon: Icons.local_fire_department,
        color: Colors.deepOrange,
        label: '現在のストリーク',
        value: '${streak.currentStreak}日',
        sub: '最長 ${streak.longestStreak}日',
      ),
      loading: () => const _StatTileLoading(),
      error: (_, __) => const _StatTileError(label: '現在のストリーク'),
    );

    final investmentTile = investmentsAsync.when(
      data: (investments) {
        final invested = investments.fold<int>(0, (sum, i) => sum + i.savingsAmount);
        final currentTotal = investments.fold<double>(0, (sum, i) {
          final currentIndex = MarketSimulator.getCurrentIndexValue(i.investmentType);
          return sum + i.currentValue(currentIndex);
        });
        final profit = currentTotal - invested;
        final isProfit = profit >= 0;
        return _StatTile(
          icon: Icons.trending_up,
          color: Colors.green,
          label: '運用中の投資',
          value: '${investments.length}件',
          sub: investments.isEmpty
              ? '未実施'
              : '${isProfit ? '+' : ''}¥${profit.toStringAsFixed(0)}',
          subColor: investments.isEmpty
              ? Colors.grey
              : (isProfit ? Colors.green.shade700 : Colors.red.shade700),
        );
      },
      loading: () => const _StatTileLoading(),
      error: (_, __) => const _StatTileError(label: '運用中の投資'),
    );

    final missionTile = missionsAsync.when(
      data: (missions) => _StatTile(
        icon: Icons.task_alt,
        color: Colors.teal,
        label: '進行中のミッション',
        value: '${missions.length}件',
        sub: null,
      ),
      loading: () => const _StatTileLoading(),
      error: (_, __) => const _StatTileError(label: '進行中のミッション'),
    );

    final totalProcedures = ProcedureLibrary.all.length;
    final viewedCount =
        ProcedureLibrary.all.where((p) => viewedProcedureIds.contains(p.id)).length;
    final procedureTile = _StatTile(
      icon: Icons.account_balance,
      color: Colors.blue,
      label: '確認済みの制度',
      value: '$viewedCount / $totalProcedures',
      sub: '制度・補助金を探すから確認できます',
    );

    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 12,
      mainAxisSpacing: 12,
      childAspectRatio: 1.3,
      children: [streakTile, investmentTile, missionTile, procedureTile],
    );
  }
}

class _StatTile extends StatelessWidget {
  final IconData icon;
  final Color color;
  final String label;
  final String value;
  final String? sub;
  final Color? subColor;

  const _StatTile({
    required this.icon,
    required this.color,
    required this.label,
    required this.value,
    this.sub,
    this.subColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withAlpha(15),
        border: Border.all(color: color.withAlpha(60)),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const SizedBox(height: 8),
          Text(
            label,
            style: TextStyle(fontSize: 11, color: color.withAlpha(220)),
          ),
          const Spacer(),
          Text(
            value,
            style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          if (sub != null) ...[
            const SizedBox(height: 2),
            Text(
              sub!,
              style: TextStyle(fontSize: 10, color: subColor ?? Colors.grey),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ],
      ),
    );
  }
}

class _StatTileLoading extends StatelessWidget {
  const _StatTileLoading();

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: const Center(
        child: SizedBox(
          width: 20,
          height: 20,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      ),
    );
  }
}

class _StatTileError extends StatelessWidget {
  final String label;

  const _StatTileError({required this.label});

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.grey.shade100,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontSize: 11, color: Colors.grey)),
          const Spacer(),
          const Text('取得できませんでした', style: TextStyle(fontSize: 12, color: Colors.grey)),
        ],
      ),
    );
  }
}

/// 無料ユーザーのうちエンゲージメントが高い（ストリーク・レベルが一定以上の）
/// 利用者にだけ表示するプレミアム誘導バナー。
///
/// 閉じるボタンが押されたら SharedPreferences に閉じた日時を保存し、
/// 7日間は再表示しない。
class _TrialPromoBanner extends ConsumerStatefulWidget {
  final int streak;
  final int level;

  const _TrialPromoBanner({required this.streak, required this.level});

  @override
  ConsumerState<_TrialPromoBanner> createState() => _TrialPromoBannerState();
}

class _TrialPromoBannerState extends ConsumerState<_TrialPromoBanner> {
  static const _dismissedAtKey = 'dashboard_trial_banner_dismissed_at';
  static const _dismissDuration = Duration(days: 7);

  bool _loadingPrefs = true;
  bool _recentlyDismissed = false;

  @override
  void initState() {
    super.initState();
    _loadDismissedState();
  }

  Future<void> _loadDismissedState() async {
    final prefs = await SharedPreferences.getInstance();
    final dismissedAtStr = prefs.getString(_dismissedAtKey);
    var recentlyDismissed = false;
    if (dismissedAtStr != null) {
      final dismissedAt = DateTime.tryParse(dismissedAtStr);
      if (dismissedAt != null &&
          DateTime.now().difference(dismissedAt) < _dismissDuration) {
        recentlyDismissed = true;
      }
    }
    if (mounted) {
      setState(() {
        _recentlyDismissed = recentlyDismissed;
        _loadingPrefs = false;
      });
    }
  }

  Future<void> _dismiss() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_dismissedAtKey, DateTime.now().toIso8601String());
    if (mounted) {
      setState(() => _recentlyDismissed = true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isPremium = ref.watch(isPremiumProvider);
    final isEngaged = widget.streak >= 3 && widget.level >= 2;

    if (isPremium || !isEngaged || _loadingPrefs || _recentlyDismissed) {
      return const SizedBox.shrink();
    }

    return Padding(
      padding: const EdgeInsets.only(top: 12),
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          border: Border.all(color: Colors.indigo.shade100),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Icon(Icons.workspace_premium,
                color: Colors.indigo.shade400, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'プレミアムでもっと学べます',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.bold,
                      color: Colors.indigo.shade900,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: OutlinedButton(
                      onPressed: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (_) => const PaywallPage(),
                          ),
                        );
                      },
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.indigo.shade700,
                        side: BorderSide(color: Colors.indigo.shade300),
                      ),
                      child: const Text('トライアルを試す'),
                    ),
                  ),
                ],
              ),
            ),
            IconButton(
              icon: const Icon(Icons.close, size: 18),
              color: Colors.indigo.shade300,
              onPressed: _dismiss,
              padding: EdgeInsets.zero,
              constraints: const BoxConstraints(),
            ),
          ],
        ),
      ),
    );
  }
}
