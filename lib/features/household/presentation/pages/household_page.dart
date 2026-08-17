import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/household_group.dart';
import '../providers/household_provider.dart';
import '../../../user_profile/presentation/providers/user_provider.dart';
import '../../../../core/analytics/analytics_provider.dart';

class HouseholdPage extends ConsumerWidget {
  const HouseholdPage({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);

    if (user == null) {
      return const Scaffold(body: Center(child: Text('ログインが必要です')));
    }

    final groupAsync = ref.watch(userGroupProvider(user.uid));

    return Scaffold(
      appBar: AppBar(title: const Text('世帯リーグ')),
      body: groupAsync.when(
        data: (group) {
          if (group == null) {
            return _buildNoGroupState(context, ref, user.uid);
          }
          return _buildGroupDetail(context, ref, group);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  Widget _buildNoGroupState(BuildContext context, WidgetRef ref, String uid) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.family_restroom, size: 64, color: Colors.grey.shade400),
            const SizedBox(height: 16),
            const Text(
              '世帯グループに参加していません',
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: () => _showCreateGroupDialog(context, ref, uid),
              icon: const Icon(Icons.add),
              label: const Text('新しい世帯グループを作成'),
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              onPressed: () => _showJoinGroupDialog(context, ref, uid),
              icon: const Icon(Icons.group_add),
              label: const Text('招待コードで参加'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGroupDetail(
      BuildContext context, WidgetRef ref, HouseholdGroup group) {
    return ListView(
      padding: const EdgeInsets.all(16),
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
              Text(
                group.name,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'メンバー ${group.members.length}人',
                style: const TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 16),
              Text(
                '¥${group.totalSavings} / ¥${group.monthlyGoal}',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              ClipRRect(
                borderRadius: BorderRadius.circular(4),
                child: LinearProgressIndicator(
                  value: group.progressRatio,
                  backgroundColor: Colors.white24,
                  color: Colors.white,
                  minHeight: 8,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        Card(
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                const Icon(Icons.vpn_key, color: Colors.grey),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text('招待コード', style: TextStyle(fontSize: 12, color: Colors.grey)),
                      Text(
                        group.id,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          letterSpacing: 2,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  void _showCreateGroupDialog(BuildContext context, WidgetRef ref, String uid) {
    final nameController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('世帯グループを作成'),
        content: TextField(
          controller: nameController,
          decoration: const InputDecoration(
            labelText: '世帯名',
            hintText: '例: 田中家',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              if (nameController.text.trim().isEmpty) return;

              final service = ref.read(householdServiceProvider);
              final analytics = ref.read(analyticsServiceProvider);

              final createdGroup =
                  await service.createGroup(uid: uid, name: nameController.text.trim());
              await analytics.logEvent('household_joined', parameters: {
                'user_id': uid,
              });

              ref.invalidate(userGroupProvider(uid));
              ref.invalidate(groupStreamProvider(createdGroup.id));

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
              }
            },
            child: const Text('作成'),
          ),
        ],
      ),
    );
  }

  void _showJoinGroupDialog(BuildContext context, WidgetRef ref, String uid) {
    final codeController = TextEditingController();

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('招待コードで参加'),
        content: TextField(
          controller: codeController,
          textCapitalization: TextCapitalization.characters,
          decoration: const InputDecoration(
            labelText: '招待コード',
            hintText: '例: AB12CD',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            onPressed: () async {
              final code = codeController.text.trim();
              if (code.isEmpty) return;

              final service = ref.read(householdServiceProvider);
              final analytics = ref.read(analyticsServiceProvider);

              final group = await service.joinGroup(uid: uid, inviteCode: code);

              if (group != null) {
                await analytics.logEvent('household_joined', parameters: {
                  'user_id': uid,
                });
                ref.invalidate(userGroupProvider(uid));
                ref.invalidate(groupStreamProvider(group.id));
              }

              if (dialogContext.mounted) {
                Navigator.pop(dialogContext);
                if (group == null) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('招待コードが見つかりません')),
                  );
                }
              }
            },
            child: const Text('参加'),
          ),
        ],
      ),
    );
  }
}
