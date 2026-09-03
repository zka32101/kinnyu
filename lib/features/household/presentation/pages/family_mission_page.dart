import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../providers/family_mission_provider.dart';
import '../widgets/family_mission_card.dart';

/// 家族ミッション表示ページ
class FamilyMissionPage extends ConsumerWidget {
  final String groupId;

  const FamilyMissionPage({
    Key? key,
    required this.groupId,
  }) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final activeMissionsAsync = ref.watch(activeFamilyMissionsProvider(groupId));
    final allMissionsAsync = ref.watch(familyMissionsProvider(groupId));

    return Scaffold(
      appBar: AppBar(
        title: const Text('家族ミッション 🏠'),
        elevation: 0,
      ),
      body: SingleChildScrollView(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // 進行中のミッション
              Text(
                '今週のミッション',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              activeMissionsAsync.when(
                data: (missions) {
                  if (missions.isEmpty) {
                    return Container(
                      padding: const EdgeInsets.all(20),
                      alignment: Alignment.center,
                      child: Column(
                        children: [
                          Icon(
                            Icons.event_note,
                            size: 64,
                            color: Colors.grey[300],
                          ),
                          const SizedBox(height: 12),
                          Text(
                            '現在、進行中のミッションはありません',
                            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: Colors.grey[600],
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  return Column(
                    children: missions.map((mission) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: FamilyMissionCard(
                          mission: mission,
                          onTap: () {
                            _showMissionDetails(context, ref, groupId, mission);
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const Center(child: CircularProgressIndicator()),
                error: (error, _) => Center(
                  child: Text('エラーが発生しました: $error'),
                ),
              ),

              const SizedBox(height: 32),

              // 過去のミッション
              Text(
                '過去のミッション',
                style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              allMissionsAsync.when(
                data: (missions) {
                  final pastMissions =
                      missions.where((m) => !m.isActive).toList();

                  if (pastMissions.isEmpty) {
                    return Text(
                      '過去のミッション記録はありません',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    );
                  }

                  return Column(
                    children: pastMissions
                        .take(5) // 最新5件のみ表示
                        .map((mission) {
                      return Padding(
                        padding: const EdgeInsets.only(bottom: 12),
                        child: FamilyMissionCard(
                          mission: mission,
                          onTap: () {
                            _showMissionDetails(context, ref, groupId, mission);
                          },
                        ),
                      );
                    }).toList(),
                  );
                },
                loading: () => const SizedBox.shrink(),
                error: (error, _) => const SizedBox.shrink(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// ミッション詳細ダイアログを表示
  void _showMissionDetails(
    BuildContext context,
    WidgetRef ref,
    String groupId,
    FamilyMission mission,
  ) {
    showModalBottomSheet(
      context: context,
      builder: (context) => _MissionDetailsSheet(
        groupId: groupId,
        mission: mission,
      ),
    );
  }
}

/// ミッション詳細シート
class _MissionDetailsSheet extends ConsumerWidget {
  final String groupId;
  final FamilyMission mission;

  const _MissionDetailsSheet({
    required this.groupId,
    required this.mission,
  });

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reportAsync =
        ref.watch(familyMissionReportProvider((groupId, mission.id)));

    return Container(
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisSize: MainAxisSize.min,
        children: [
          // ヘッダー
          Row(
            children: [
              Text(
                mission.emoji,
                style: const TextStyle(fontSize: 32),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      mission.title,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      mission.description,
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // レポート情報
          reportAsync.when(
            data: (report) => Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // 進捗
                _buildReportSection(
                  context,
                  'ミッション進捗',
                  Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('${(report['progressRatio'] * 100).toStringAsFixed(0)}% 達成'),
                          Text('${report['totalContribution']}円 / ${report['targetAmount']}円'),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(4),
                        child: LinearProgressIndicator(
                          value: report['progressRatio'] as double,
                          minHeight: 10,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // メンバー情報
                _buildReportSection(
                  context,
                  'メンバー情報',
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('参加者: ${report['memberCount']}人'),
                      const SizedBox(height: 8),
                      Text(
                        'トップ: ${report['topPerformer']} (${report['topContribution']}円)',
                        style: const TextStyle(fontWeight: FontWeight.bold),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // イベント提案
                if (report['isCompleted'] as bool) ...[
                  _buildReportSection(
                    context,
                    'リワード提案',
                    Text(report['eventProposal'] ?? ''),
                  ),
                  const SizedBox(height: 16),
                ],
              ],
            ),
            loading: () => const CircularProgressIndicator(),
            error: (error, _) => Text('エラー: $error'),
          ),

          // アクションボタン
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('閉じる'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReportSection(
    BuildContext context,
    String title,
    Widget content,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontWeight: FontWeight.bold,
            color: Colors.grey[700],
          ),
        ),
        const SizedBox(height: 8),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.grey[100],
            borderRadius: BorderRadius.circular(8),
          ),
          child: content,
        ),
      ],
    );
  }
}

// 必要なインポート
import '../../domain/models/family_mission.dart';
