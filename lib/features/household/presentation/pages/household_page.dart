import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/household_group.dart';
import '../providers/household_provider.dart';
import '../providers/household_budget_provider.dart';
import '../../../user_profile/presentation/providers/user_provider.dart';
import '../../../../core/analytics/analytics_provider.dart';
import '../../../../core/theme/app_colors.dart';
import 'household_budget_page.dart';
import '../widgets/budget_settings_dialog.dart';

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
          return _buildGroupDetail(context, ref, group, user.uid);
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (error, stack) => Center(child: Text('エラー: $error')),
      ),
    );
  }

  Widget _buildNoGroupState(BuildContext context, WidgetRef ref, String uid) {
    return Center(
      child: Padding(
        padding: AppSpacing.paddingLg,
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
      BuildContext context, WidgetRef ref, HouseholdGroup group, String uid) {
    final amountFormat = NumberFormat('#,###');
    return ListView(
      padding: AppSpacing.paddingMd,
      children: [
        Container(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [Colors.blue.shade300, Colors.blue.shade600],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: AppSpacing.radiusMedium,
          ),
          padding: AppSpacing.paddingLg,
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
                '¥${amountFormat.format(group.totalSavings)} / ¥${amountFormat.format(group.monthlyGoal)}',
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
            padding: AppSpacing.paddingMd,
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
        const SizedBox(height: 16),
        _buildContributionRanking(context, group, uid),
        const SizedBox(height: 16),
        ElevatedButton.icon(
          onPressed: () => Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => HouseholdBudgetPage(groupId: group.id),
            ),
          ),
          icon: const Icon(Icons.attach_money),
          label: const Text('世帯予算を表示'),
          style: ElevatedButton.styleFrom(
            backgroundColor: Colors.blue.shade600,
            foregroundColor: Colors.white,
          ),
        ),
        const SizedBox(height: 8),
        OutlinedButton.icon(
          onPressed: () => _showLeaveGroupDialog(context, ref, uid),
          icon: const Icon(Icons.logout, color: AppColors.error),
          label: const Text('グループを退会する', style: TextStyle(color: AppColors.error)),
          style: OutlinedButton.styleFrom(
            side: const BorderSide(color: AppColors.error),
          ),
        ),
      ],
    );
  }

  Widget _buildContributionRanking(
      BuildContext context, HouseholdGroup group, String uid) {
    final amountFormat = NumberFormat('#,###');
    final entries = group.members.map((memberUid) {
      final amount = group.memberContributions[memberUid] ?? 0;
      final nickname = group.memberNicknames[memberUid] ?? 'メンバー';
      return (uid: memberUid, nickname: nickname, amount: amount);
    }).toList()
      ..sort((a, b) => b.amount.compareTo(a.amount));

    return Card(
      child: Padding(
        padding: AppSpacing.paddingMd,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              '貢献額ランキング',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 12),
            for (var i = 0; i < entries.length; i++)
              Container(
                decoration: entries[i].uid == uid
                    ? BoxDecoration(
                        color: Theme.of(context)
                            .colorScheme
                            .primaryContainer
                            .withAlpha(60),
                        borderRadius: AppSpacing.radiusSmall,
                      )
                    : null,
                padding: const EdgeInsets.symmetric(
                    vertical: 6, horizontal: 8),
                margin: const EdgeInsets.symmetric(vertical: 2),
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
                      style: const TextStyle(fontSize: 14),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        entries[i].nickname,
                        style: const TextStyle(fontSize: 14),
                      ),
                    ),
                    Text(
                      '¥${amountFormat.format(entries[i].amount)}',
                      style: const TextStyle(
                          fontSize: 14, fontWeight: FontWeight.bold),
                    ),
                  ],
                ),
              ),
          ],
        ),
      ),
    );
  }

  void _showCreateGroupDialog(BuildContext context, WidgetRef ref, String uid) {
    final nameController = TextEditingController();
    final nicknameController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('世帯グループを作成'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(
                  labelText: '世帯名',
                  hintText: '例: 田中家',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nicknameController,
                decoration: const InputDecoration(
                  labelText: 'ニックネーム',
                  hintText: '例: パパ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  isSubmitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      if (nameController.text.trim().isEmpty) return;

                      setDialogState(() => isSubmitting = true);

                      final service = ref.read(householdServiceProvider);
                      final analytics = ref.read(analyticsServiceProvider);

                      try {
                        final nickname = nicknameController.text.trim();
                        final createdGroup = await service.createGroup(
                            uid: uid,
                            name: nameController.text.trim(),
                            nickname: nickname.isEmpty ? 'メンバー' : nickname);

                        // 新規グループの予算を初期化
                        await service.initializeBudget(createdGroup.id);

                        await analytics.logEvent('household_joined',
                            parameters: {
                              'user_id': uid,
                            });

                        ref.invalidate(userGroupProvider(uid));
                        ref.invalidate(groupStreamProvider(createdGroup.id));
                        ref.invalidate(householdBudgetProvider(createdGroup.id));

                        if (dialogContext.mounted) {
                          Navigator.pop(dialogContext);
                        }
                      } catch (e) {
                        debugPrint('createGroup error: $e');
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(content: Text('作成に失敗しました: $e')),
                          );
                        }
                      } finally {
                        if (dialogContext.mounted) {
                          setDialogState(() => isSubmitting = false);
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('作成'),
            ),
          ],
        ),
      ),
    );
  }

  void _showJoinGroupDialog(BuildContext context, WidgetRef ref, String uid) {
    final codeController = TextEditingController();
    final nicknameController = TextEditingController();
    bool isSubmitting = false;

    showDialog(
      context: context,
      builder: (dialogContext) => StatefulBuilder(
        builder: (_, setDialogState) => AlertDialog(
          title: const Text('招待コードで参加'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: const InputDecoration(
                  labelText: '招待コード',
                  hintText: '例: AB12CD',
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: nicknameController,
                decoration: const InputDecoration(
                  labelText: 'ニックネーム',
                  hintText: '例: ママ',
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed:
                  isSubmitting ? null : () => Navigator.pop(dialogContext),
              child: const Text('キャンセル'),
            ),
            ElevatedButton(
              onPressed: isSubmitting
                  ? null
                  : () async {
                      final code = codeController.text.trim();
                      if (code.isEmpty) return;

                      setDialogState(() => isSubmitting = true);

                      final service = ref.read(householdServiceProvider);
                      final analytics = ref.read(analyticsServiceProvider);

                      try {
                        final nickname = nicknameController.text.trim();
                        final group = await service.joinGroup(
                            uid: uid,
                            inviteCode: code,
                            nickname: nickname.isEmpty ? 'メンバー' : nickname);

                        if (group != null) {
                          await analytics.logEvent('household_joined',
                              parameters: {
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
                      } catch (e) {
                        debugPrint('joinGroup error: $e');
                        if (dialogContext.mounted) {
                          ScaffoldMessenger.of(dialogContext).showSnackBar(
                            SnackBar(content: Text('参加に失敗しました: $e')),
                          );
                        }
                      } finally {
                        if (dialogContext.mounted) {
                          setDialogState(() => isSubmitting = false);
                        }
                      }
                    },
              child: isSubmitting
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('参加'),
            ),
          ],
        ),
      ),
    );
  }

  void _showLeaveGroupDialog(BuildContext context, WidgetRef ref, String uid) {
    final groupAsync = ref.read(userGroupProvider(uid));
    final currentGroupId = groupAsync.asData?.value?.id;

    showDialog(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('グループを退会しますか？'),
        content: const Text('退会すると、これまでの貢献額の記録はグループから削除されます。'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext),
            child: const Text('キャンセル'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.error,
                foregroundColor: Colors.white),
            onPressed: () async {
              if (currentGroupId == null) {
                Navigator.pop(dialogContext);
                return;
              }

              final service = ref.read(householdServiceProvider);

              try {
                await service.leaveGroup(uid: uid, groupId: currentGroupId);
                ref.invalidate(userGroupProvider(uid));
                ref.invalidate(groupStreamProvider(currentGroupId));

                if (dialogContext.mounted) {
                  Navigator.pop(dialogContext);
                }
              } catch (e) {
                debugPrint('leaveGroup error: $e');
                if (dialogContext.mounted) {
                  ScaffoldMessenger.of(dialogContext).showSnackBar(
                    SnackBar(content: Text('退会に失敗しました: $e')),
                  );
                }
              }
            },
            child: const Text('退会する'),
          ),
        ],
      ),
    );
  }
}
