import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../quiz/domain/models/question.dart';
import '../../../quiz/presentation/pages/quiz_page.dart';
import '../../../quiz/presentation/pages/initial_diagnosis_page.dart';
import '../../../quiz/presentation/pages/diagnosis_result_page.dart';
import '../../../quiz/domain/models/pattern_diagnosis.dart';
import '../../../mission/presentation/pages/mission_list_page.dart';
import '../../../mission/presentation/providers/mission_provider.dart';
import '../../../investment/presentation/pages/investment_portfolio_page.dart';
import '../../../benchmark/presentation/pages/benchmark_page.dart';
import '../../../household/presentation/pages/household_page.dart';
import '../../../challenge/presentation/pages/challenge_page.dart';
import '../../../roleplay/presentation/pages/roleplay_page.dart';
import '../../../receipt/presentation/pages/receipt_capture_page.dart';
import '../../../glossary/presentation/pages/glossary_page.dart';
import '../../../simulation/presentation/pages/simulation_hub_page.dart';
import '../../../user_profile/presentation/providers/user_provider.dart';
import '../../../user_profile/presentation/providers/streak_provider.dart';
import '../../../procedures/presentation/pages/procedure_finder_page.dart';
import '../../../procedures/presentation/providers/procedures_provider.dart';
import '../../../procedures/domain/models/procedure_info.dart';
import '../../../dashboard/presentation/pages/savings_dashboard_page.dart';
import '../../../about/presentation/pages/about_page.dart';
import '../../../achievements/presentation/pages/achievements_page.dart';
import '../../../../core/widgets/lottie_animations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../core/services/notification_service.dart';
import '../../../../core/services/engagement_tracker.dart';
import '../../../../core/services/home_widget_service.dart';

class HomePage extends ConsumerWidget {
  const HomePage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final uid = user?.uid;
    final streakDays = uid == null
        ? 0
        : ref.watch(streakStreamProvider(uid)).when(
              data: (streak) => streak.currentStreak,
              loading: () => 0,
              error: (_, __) => 0,
            );
    final pendingMissionCount = uid == null
        ? 0
        : ref.watch(missionsStreamProvider(uid)).when(
              data: (missions) => missions.length,
              loading: () => 0,
              error: (_, __) => 0,
            );
    final unviewedProcedureCount = (ProcedureLibrary.all.length -
            ref.watch(viewedProcedureIdsProvider).length)
        .clamp(0, ProcedureLibrary.all.length)
        .toInt();

    // ホーム表示時に通知をスケジュール・エンゲージメント記録・ウィジェット同期を行う
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      try {
        await EngagementTracker.recordAppOpen();
        final preferredHour = await EngagementTracker.getPreferredHour();
        await NotificationService().scheduleStreakReminder(
          hour: preferredHour ?? 20,
          currentStreak: streakDays,
        );
        await NotificationService().scheduleWeeklyRecommendation(
          pendingMissionCount: pendingMissionCount,
          unviewedProcedureCount: unviewedProcedureCount,
        );
      } catch (e) {
        debugPrint('Failed to schedule notifications: $e');
      }
      if (user != null) {
        await HomeWidgetService.updateWidgetData(
          streak: streakDays,
          totalXP: user.totalXP,
          level: user.level,
        );
      }
    });

    return Scaffold(
      appBar: AppBar(
        title: const Text('金融オンライン大学'),
        centerTitle: true,
        elevation: 0,
        actions: [
          IconButton(
            icon: const Icon(Icons.family_restroom),
            tooltip: '世帯リーグ',
            onPressed: () {
              Navigator.push(
                context,
                PageRouteAnimations.slideTransition(const HouseholdPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.bar_chart),
            tooltip: 'ベンチマーク',
            onPressed: () {
              Navigator.push(
                context,
                PageRouteAnimations.slideTransition(const BenchmarkPage()),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.emoji_events),
            tooltip: 'チャレンジ',
            onPressed: () {
              Navigator.push(
                context,
                PageRouteAnimations.slideTransition(const ChallengePage()),
              );
            },
          ),
          PopupMenuButton<String>(
            icon: const Icon(Icons.more_vert),
            tooltip: 'その他',
            onSelected: (value) {
              switch (value) {
                case 'achievements':
                  Navigator.push(
                    context,
                    PageRouteAnimations.slideTransition(const AchievementsPage()),
                  );
                  break;
                case 'glossary':
                  Navigator.push(
                    context,
                    PageRouteAnimations.slideTransition(const GlossaryPage()),
                  );
                  break;
                case 'about':
                  Navigator.push(
                    context,
                    PageRouteAnimations.slideTransition(const AboutPage()),
                  );
                  break;
              }
            },
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: 'achievements',
                child: Row(
                  children: [
                    Icon(Icons.military_tech),
                    SizedBox(width: 12),
                    Text('実績・バッジ'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'glossary',
                child: Row(
                  children: [
                    Icon(Icons.menu_book),
                    SizedBox(width: 12),
                    Text('用語辞典'),
                  ],
                ),
              ),
              PopupMenuItem(
                value: 'about',
                child: Row(
                  children: [
                    Icon(Icons.info_outline),
                    SizedBox(width: 12),
                    Text('このアプリについて'),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildStreakCard(streakDays),
            const SizedBox(height: 24),
            uid != null
                ? _buildTodayMissionCard(context, ref, uid)
                : const SizedBox.shrink(),
            const SizedBox(height: 24),
            _buildSectionHeader('学ぶ・診断する'),
            const SizedBox(height: 12),
            _buildDiagnosisPrompt(context),
            if (user?.diagnosisPatternId != null) ...[
              const SizedBox(height: 24),
              _buildPersonalizedTipCard(context, user!.diagnosisPatternId!),
            ],
            const SizedBox(height: 24),
            _buildCategoryGrid(context),
            const SizedBox(height: 24),
            _buildSectionHeader('シミュレーション・投資'),
            const SizedBox(height: 12),
            _buildSimulationPromptCard(context),
            const SizedBox(height: 24),
            _buildInvestmentPromptCard(context),
            const SizedBox(height: 24),
            _buildSectionHeader('サポート'),
            const SizedBox(height: 12),
            _buildProcedureFinderPromptCard(context, ref),
            const SizedBox(height: 24),
            _buildRoleplayPromptCard(context),
            const SizedBox(height: 24),
            _buildDashboardPromptCard(context),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () {
          Navigator.push(
            context,
            PageRouteAnimations.slideTransition(const ReceiptCapturePage()),
          );
        },
        icon: const Icon(Icons.receipt_long),
        label: const Text('レシート記録'),
      ),
    );
  }

  Widget _buildSectionHeader(String title) {
    return Text(
      title,
      style: TextStyle(
        fontSize: 13,
        fontWeight: FontWeight.bold,
        color: Colors.grey.shade600,
      ),
    );
  }

  Widget _buildProcedureFinderPromptCard(BuildContext context, WidgetRef ref) {
    final lifeStage = ref.watch(lifeStageProvider);

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteAnimations.slideTransition(const ProcedureFinderPage()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.blue.shade50,
          border: Border.all(color: Colors.blue.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.account_balance, color: Colors.blue.shade700, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '制度・補助金を探す',
                    style: TextStyle(
                      color: Colors.blue.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    lifeStage == null
                        ? 'ライフステージを選ぶと、あなたに合った制度をお知らせします'
                        : '${lifeStage.label}向けの制度・補助金をチェックしよう',
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: Colors.blue.shade700),
          ],
        ),
      ),
    );
  }

  Widget _buildDashboardPromptCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteAnimations.slideTransition(const SavingsDashboardPage()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          border: Border.all(color: Colors.green.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.dashboard, color: Colors.green.shade700, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '家計改善ダッシュボード',
                    style: TextStyle(
                      color: Colors.green.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'あなたの成長・貯まる様子をまとめて確認しよう',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: Colors.green.shade700),
          ],
        ),
      ),
    );
  }

  Widget _buildRoleplayPromptCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteAnimations.slideTransition(const RoleplayPage()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.indigo.shade50,
          border: Border.all(color: Colors.indigo.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.family_restroom, color: Colors.indigo.shade600, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '家計ロールプレイ',
                    style: TextStyle(
                      color: Colors.indigo.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '仮想人生でお金の判断を練習しよう',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: Colors.indigo.shade600),
          ],
        ),
      ),
    );
  }

  Widget _buildSimulationPromptCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteAnimations.slideTransition(const SimulationHubPage()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.teal.shade50,
          border: Border.all(color: Colors.teal.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.calculate, color: Colors.teal.shade700, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '家計・投資シミュレーション',
                    style: TextStyle(
                      color: Colors.teal.shade700,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '数字を入れて将来のお金を計算してみよう',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: Colors.teal.shade700),
          ],
        ),
      ),
    );
  }

  Widget _buildInvestmentPromptCard(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteAnimations.slideTransition(const InvestmentPortfolioPage()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.amber.shade50,
          border: Border.all(color: Colors.amber.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.savings, color: Colors.amber.shade800, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '見える投資',
                    style: TextStyle(
                      color: Colors.amber.shade800,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    '節約額が貯まる・増える様子を確認しよう',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: Colors.amber.shade800),
          ],
        ),
      ),
    );
  }

  Widget _buildDiagnosisPrompt(BuildContext context) {
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteAnimations.slideTransition(const InitialDiagnosisPage()),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          border: Border.all(color: Colors.purple.shade300),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.lightbulb, color: Colors.purple.shade600, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '家計診断クイズ',
                    style: TextStyle(
                      color: Colors.purple.shade600,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'あなたの節約TOP3を発見しましょう',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: Colors.purple.shade600),
          ],
        ),
      ),
    );
  }

  /// 初回家計診断の結果パターンに基づいた「あなたへのおすすめ」カード。
  /// 診断未実施のユーザーには表示しない（呼び出し元でnullチェック済み）。
  Widget _buildPersonalizedTipCard(BuildContext context, String patternId) {
    final diagnosis = PatternDiagnosisGenerator.getDiagnosis(patternId);
    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          PageRouteAnimations.slideTransition(
            DiagnosisResultPage(diagnosis: diagnosis),
          ),
        );
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.purple.shade50,
          border: Border.all(color: Colors.purple.shade200),
          borderRadius: BorderRadius.circular(12),
        ),
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            Icon(Icons.auto_awesome, color: Colors.purple.shade400, size: 28),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'あなたへのおすすめ（${diagnosis.typeName}）',
                    style: TextStyle(
                      color: Colors.purple.shade400,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    diagnosis.savingsTip1,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            ),
            Icon(Icons.arrow_forward, color: Colors.purple.shade400),
          ],
        ),
      ),
    );
  }

  Widget _buildStreakCard(int streakDays) {
    return Stack(
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade300, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'ストリーク',
                style: TextStyle(
                  color: Colors.white70,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '$streakDays日間',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 32,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Container(
                decoration: BoxDecoration(
                  color: Colors.white12,
                  borderRadius: BorderRadius.circular(8),
                ),
                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                child: const Text(
                  '今日の学習を完了してストリークを続けよう！',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                  ),
                ),
              ),
            ],
          ),
        ),
        if (streakDays > 0)
          Positioned(
            top: 12,
            right: 12,
            child: LottieAnimations.streakUpdateAnimation(),
          ),
        Positioned(
          bottom: 8,
          right: 12,
          child: Image.asset(
            streakDays > 0
                ? 'assets/images/mascot/mascot_streak.png'
                : 'assets/images/mascot/mascot_normal.png',
            width: 56,
            height: 56,
            errorBuilder: (context, error, stackTrace) => const SizedBox.shrink(),
          ),
        ),
      ],
    );
  }

  Widget _buildTodayMissionCard(BuildContext context, WidgetRef ref, String uid) {
    final missionsAsync = ref.watch(missionsStreamProvider(uid));

    return missionsAsync.when(
      data: (missions) {
        final activeMission = missions.isNotEmpty ? missions.first : null;
        return GestureDetector(
          onTap: () {
            Navigator.push(
              context,
              PageRouteAnimations.slideTransition(const MissionListPage()),
            );
          },
          child: Container(
            decoration: BoxDecoration(
              color: Colors.green.shade50,
              border: Border.all(color: Colors.green.shade300),
              borderRadius: BorderRadius.circular(12),
            ),
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                Icon(Icons.task_alt, color: Colors.green.shade600, size: 28),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '今週のミッション${missions.length > 1 ? ' (${missions.length}件)' : ''}',
                        style: TextStyle(
                          color: Colors.green.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        activeMission?.title ?? '実行ミッションを確認する',
                        style: const TextStyle(fontSize: 12, color: Colors.grey),
                      ),
                    ],
                  ),
                ),
                Icon(Icons.arrow_forward, color: Colors.green.shade600),
              ],
            ),
          ),
        );
      },
      loading: () => const SizedBox(
        height: 72,
        child: Center(child: CircularProgressIndicator()),
      ),
      error: (_, __) => const SizedBox.shrink(),
    );
  }

  Widget _buildCategoryGrid(BuildContext context) {
    final categories = [
      {
        'title': '貯蓄',
        'icon': Icons.savings,
        'color': AppColors.categoryColors['savings'] ?? Colors.blue,
        'category': QuizCategory.savings
      },
      {
        'title': '税金',
        'icon': Icons.receipt,
        'color': AppColors.categoryColors['tax'] ?? Colors.orange,
        'category': QuizCategory.tax
      },
      {
        'title': '投資',
        'icon': Icons.trending_up,
        'color': AppColors.categoryColors['invest'] ?? Colors.green,
        'category': QuizCategory.invest
      },
      {
        'title': '保険',
        'icon': Icons.shield,
        'color': AppColors.categoryColors['insurance'] ?? Colors.red,
        'category': QuizCategory.insurance
      },
    ];

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'ジャンルを選択',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        GridView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
          ),
          itemCount: categories.length,
          itemBuilder: (buildContext, index) {
            final category = categories[index];
            return _buildCategoryTile(
              context,
              title: category['title'] as String,
              icon: category['icon'] as IconData,
              color: category['color'] as Color,
              category: category['category'] as QuizCategory,
            );
          },
        ),
      ],
    );
  }

  Widget _buildCategoryTile(BuildContext context,
      {required String title, required IconData icon, required Color color, required QuizCategory category}) {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [color.withAlpha(128), color.withAlpha(200)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: () {
            Navigator.push(
              context,
              PageRouteAnimations.slideTransition(QuizPage(category: category)),
            );
          },
          borderRadius: BorderRadius.circular(12),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(icon, color: Colors.white, size: 40),
              const SizedBox(height: 8),
              Text(
                title,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
