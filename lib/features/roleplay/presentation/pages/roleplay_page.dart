import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/roleplay_scenario.dart';
import '../../../procedures/domain/models/procedure_info.dart';
import '../../../procedures/presentation/widgets/procedure_list_view.dart';
import '../providers/roleplay_provider.dart';
import '../../../user_profile/presentation/providers/user_provider.dart';
import '../../../../core/analytics/analytics_provider.dart';

class RoleplayPage extends ConsumerStatefulWidget {
  const RoleplayPage({Key? key}) : super(key: key);

  @override
  ConsumerState<RoleplayPage> createState() => _RoleplayPageState();
}

class _RoleplayPageState extends ConsumerState<RoleplayPage> {
  RoleplayScenario? scenario;
  int currentDecisionIndex = -1; // -1 = intro screen
  final List<int> selectedAnswers = [];
  int totalScore = 0;
  bool started = false;
  bool _resultSaved = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('家計ロールプレイ')),
      body: scenario == null
          ? _buildScenarioSelection(context)
          : !started
              ? _buildIntro(context)
              : currentDecisionIndex >= scenario!.decisions.length
                  ? _buildResult(context)
                  : _buildDecision(
                      context, scenario!.decisions[currentDecisionIndex]),
    );
  }

  Widget _buildScenarioSelection(BuildContext context) {
    final scenarios = RoleplayScenarios.all();
    final icons = [
      Icons.family_restroom,
      Icons.person,
      Icons.elderly,
    ];
    final colors = [
      Colors.indigo,
      Colors.teal,
      Colors.deepOrange,
    ];
    const images = [
      'assets/images/roleplay/roleplay_young_family.png',
      'assets/images/roleplay/roleplay_single_professional.png',
      'assets/images/roleplay/roleplay_pre_retirement.png',
    ];

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        const Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: Text(
            'シナリオを選んでください',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
        ),
        const Text(
          '自分に近い立場や、気になるライフステージを選んで、お金の判断を練習しましょう。',
          style: TextStyle(fontSize: 13, color: Colors.grey),
        ),
        const SizedBox(height: 16),
        ...List.generate(scenarios.length, (index) {
          final s = scenarios[index];
          return Card(
            margin: const EdgeInsets.only(bottom: 12),
            child: InkWell(
              borderRadius: BorderRadius.circular(12),
              onTap: () {
                setState(() {
                  scenario = s;
                  currentDecisionIndex = -1;
                  selectedAnswers.clear();
                  totalScore = 0;
                  started = false;
                });
              },
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 28,
                      backgroundColor: colors[index].withAlpha(30),
                      child: ClipOval(
                        child: Image.asset(
                          images[index],
                          width: 56,
                          height: 56,
                          fit: BoxFit.cover,
                          errorBuilder: (context, error, stackTrace) =>
                              Icon(icons[index], color: colors[index]),
                        ),
                      ),
                    ),
                    const SizedBox(width: 16),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            s.title,
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                            style: const TextStyle(
                                fontWeight: FontWeight.bold, fontSize: 15),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${s.familyComposition}・全${s.decisions.length}問',
                            style: const TextStyle(
                                fontSize: 12, color: Colors.grey),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: Colors.grey),
                  ],
                ),
              ),
            ),
          );
        }),
      ],
    );
  }

  Widget _buildIntro(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.indigo.shade50,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  scenario!.title,
                  style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 12),
                Text(scenario!.description, style: const TextStyle(fontSize: 14)),
                const SizedBox(height: 12),
                Text('年収: ¥${scenario!.annualIncome}', style: const TextStyle(fontSize: 13)),
                Text('家族構成: ${scenario!.familyComposition}', style: const TextStyle(fontSize: 13)),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            '失敗しても実損はありません。気軽にお金の判断を練習しましょう。',
            style: TextStyle(fontSize: 12, color: Colors.grey),
          ),
          const Spacer(),
          ElevatedButton(
            onPressed: () {
              setState(() {
                started = true;
                currentDecisionIndex = 0;
              });
              final user = ref.read(userProvider);
              if (user != null) {
                ref.read(analyticsServiceProvider).logEvent(
                  'roleplay_started',
                  parameters: {'user_id': user.uid},
                );
              }
            },
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: const Text('シミュレーションを開始'),
          ),
          const SizedBox(height: 8),
          TextButton(
            onPressed: () {
              setState(() {
                scenario = null;
              });
            },
            child: const Text('別のシナリオを選ぶ'),
          ),
        ],
      ),
    );
  }

  Widget _buildDecision(BuildContext context, RoleplayDecision decision) {
    final procedures = ProcedureLibrary.byIds(decision.relatedProcedureIds);

    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(4),
            child: LinearProgressIndicator(
              value: (currentDecisionIndex + 1) / scenario!.decisions.length,
              minHeight: 6,
              backgroundColor: Colors.grey.shade200,
            ),
          ),
          const SizedBox(height: 24),
          Text(
            decision.question,
            style: Theme.of(context).textTheme.headlineSmall,
          ),
          if (procedures.isNotEmpty) ...[
            const SizedBox(height: 12),
            InkWell(
              borderRadius: BorderRadius.circular(20),
              onTap: () => showProcedureListSheet(
                context,
                title: 'このシーンで使える制度・手続き',
                procedures: procedures,
              ),
              child: Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: Colors.indigo.shade50,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: Colors.indigo.shade200),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.account_balance, size: 16, color: Colors.indigo.shade600),
                    const SizedBox(width: 6),
                    Text(
                      '使える制度・補助金を見る（${procedures.length}件）',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w600,
                        color: Colors.indigo.shade600,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 24),
          ...List.generate(decision.options.length, (index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 12),
              child: ElevatedButton(
                onPressed: () => _selectAnswer(decision, index),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                ),
                child: Text(
                  decision.options[index],
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }),
        ],
      ),
    );
  }

  void _selectAnswer(RoleplayDecision decision, int index) {
    setState(() {
      selectedAnswers.add(index);
      totalScore += decision.scoreDeltas[index];
    });

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('解説'),
        content: Text(decision.explanation ?? ''),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              setState(() {
                currentDecisionIndex++;
              });
            },
            child: const Text('次へ'),
          ),
        ],
      ),
    );
  }

  Widget _buildResult(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (_resultSaved) return;
      final user = ref.read(userProvider);
      if (user != null) {
        final service = ref.read(roleplayServiceProvider);
        try {
          await service.saveResult(
            user.uid,
            RoleplayResult(
              scenario: scenario!.type,
              selectedAnswers: selectedAnswers,
              score: totalScore,
              createdAt: DateTime.now(),
            ),
          );
          ref.read(userProvider.notifier).addXP(totalScore);
          _resultSaved = true;
        } catch (e) {
          debugPrint('Failed to save roleplay result: $e');
        }
      }
    });

    // 満点に対する達成度で評価コメントを出す
    final maxScore = scenario!.decisions.fold<int>(
      0,
      (sum, d) => sum + d.scoreDeltas.reduce((a, b) => a > b ? a : b),
    );
    final ratio = maxScore > 0 ? totalScore / maxScore : 0.0;
    final String rank;
    final String comment;
    final String mascotAsset;
    if (ratio >= 0.9) {
      rank = '💯 マネーマスター';
      comment = 'お見事！お金の判断力は完璧です。';
      mascotAsset = 'assets/images/mascot/mascot_levelup.png';
    } else if (ratio >= 0.7) {
      rank = '🌟 しっかり者';
      comment = '堅実な判断ができています。この調子！';
      mascotAsset = 'assets/images/mascot/mascot_correct.png';
    } else if (ratio >= 0.4) {
      rank = '📈 成長中';
      comment = '基本はOK。解説を振り返ってさらにレベルアップ！';
      mascotAsset = 'assets/images/mascot/mascot_normal.png';
    } else {
      rank = '🌱 これから';
      comment = '大丈夫、練習あるのみ。もう一度挑戦してみましょう。';
      mascotAsset = 'assets/images/mascot/mascot_incorrect.png';
    }

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Image.asset(
              mascotAsset,
              width: 100,
              height: 100,
              errorBuilder: (context, error, stackTrace) => const Icon(
                  Icons.emoji_events, color: Colors.amber, size: 72),
            ),
            const SizedBox(height: 16),
            const Text('シミュレーション完了', style: TextStyle(fontSize: 18)),
            const SizedBox(height: 8),
            Text(
              '$totalScore / $maxScore XP',
              style: const TextStyle(
                fontSize: 36,
                fontWeight: FontWeight.bold,
                color: Colors.indigo,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              rank,
              style: const TextStyle(
                  fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            Text(
              comment,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14, color: Colors.grey),
            ),
            const SizedBox(height: 16),
            OutlinedButton.icon(
              onPressed: () => showProcedureListSheet(
                context,
                title: '${scenario!.title}\nで使える制度・手続きまとめ',
                procedures: ProcedureLibrary.byLifeStage(scenario!.type.lifeStage),
              ),
              icon: const Icon(Icons.account_balance),
              label: const Text('使える制度・補助金をまとめて見る'),
              style: OutlinedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              onPressed: () {
                setState(() {
                  scenario = null;
                  started = false;
                  currentDecisionIndex = -1;
                  selectedAnswers.clear();
                  totalScore = 0;
                });
              },
              style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(48)),
              child: const Text('他のシナリオに挑戦'),
            ),
            const SizedBox(height: 8),
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('ホームに戻る'),
            ),
          ],
        ),
      ),
    );
  }
}
