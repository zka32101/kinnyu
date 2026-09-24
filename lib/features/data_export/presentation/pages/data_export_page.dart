import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:share_plus/share_plus.dart';
import '../../domain/services/data_export_service.dart';
import '../../../subscription_audit/presentation/providers/subscription_audit_provider.dart';
import '../../../savings_goal/presentation/providers/savings_goal_provider.dart';
import '../../../furusato_gift/presentation/providers/furusato_gift_provider.dart';
import '../../../user_profile/presentation/providers/user_provider.dart';

/// サブスク・貯金目標・ふるさと納税の記録をExcelファイルとして出力・共有する画面。
class DataExportPage extends ConsumerStatefulWidget {
  const DataExportPage({Key? key}) : super(key: key);

  @override
  ConsumerState<DataExportPage> createState() => _DataExportPageState();
}

class _DataExportPageState extends ConsumerState<DataExportPage> {
  bool _isExporting = false;

  Future<void> _export(String uid) async {
    setState(() => _isExporting = true);
    try {
      final subscriptions = await ref.read(subscriptionsStreamProvider(uid).future);
      final savingsGoals = await ref.read(savingsGoalsStreamProvider(uid).future);
      final furusatoGifts = await ref.read(furusatoGiftsStreamProvider(uid).future);

      final file = await DataExportService.export(
        subscriptions: subscriptions,
        savingsGoals: savingsGoals,
        furusatoGifts: furusatoGifts,
      );

      final shareResult = await Share.shareXFiles(
        [XFile(file.path)],
        text: 'お金コレ！ データエクスポート',
      );
      // ユーザーが共有シートを閉じただけの場合は例外にならないため、
      // デバッグ用にログのみ残す（_isExporting のリセットは finally で行う）。
      if (shareResult.status == ShareResultStatus.dismissed) {
        debugPrint('Data export share sheet was dismissed by the user');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('エクスポートに失敗しました: $e')),
        );
      }
    } finally {
      if (mounted) setState(() => _isExporting = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);
    final uid = user?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('データエクスポート')),
      body: uid == null
          ? const Center(child: Text('ログインしてください'))
          : _buildBody(uid),
    );
  }

  Widget _buildBody(String uid) {
    final subscriptionsAsync = ref.watch(subscriptionsStreamProvider(uid));
    final savingsGoalsAsync = ref.watch(savingsGoalsStreamProvider(uid));
    final furusatoGiftsAsync = ref.watch(furusatoGiftsStreamProvider(uid));

    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.blue.shade50,
            borderRadius: BorderRadius.circular(8),
          ),
          child: const Text(
            'サブスク・貯金目標・ふるさと納税の記録をExcelファイル（.xlsx）に出力し、'
            '確定申告や他の家計簿アプリへの引き継ぎに活用できます。',
            style: TextStyle(fontSize: 12, color: Colors.blueGrey),
          ),
        ),
        const SizedBox(height: 20),
        _buildCountCard(
          icon: Icons.subscriptions,
          color: Colors.orange,
          label: 'サブスク',
          count: subscriptionsAsync.value?.length,
        ),
        const SizedBox(height: 8),
        _buildCountCard(
          icon: Icons.flag,
          color: Colors.pink,
          label: '貯金目標',
          count: savingsGoalsAsync.value?.length,
        ),
        const SizedBox(height: 8),
        _buildCountCard(
          icon: Icons.volunteer_activism,
          color: Colors.red,
          label: 'ふるさと納税',
          count: furusatoGiftsAsync.value?.length,
        ),
        const SizedBox(height: 24),
        ElevatedButton.icon(
          onPressed: _isExporting ? null : () => _export(uid),
          icon: _isExporting
              ? const SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                )
              : const Icon(Icons.file_download),
          label: Text(_isExporting ? '出力中...' : 'Excelで出力・共有する'),
          style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
        ),
      ],
    );
  }

  Widget _buildCountCard({
    required IconData icon,
    required Color color,
    required String label,
    required int? count,
  }) {
    return Card(
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: color.withAlpha(30),
          child: Icon(icon, color: color),
        ),
        title: Text(label),
        trailing: Text(
          count == null ? '...' : '$count件',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
    );
  }
}
