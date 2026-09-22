import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import '../../domain/models/furusato_gift.dart';
import '../providers/furusato_gift_provider.dart';
import '../../../user_profile/presentation/providers/user_provider.dart';

class FurusatoGiftPage extends ConsumerWidget {
  /// ふるさと納税控除上限額シミュレーターから遷移した場合の上限額（円）。
  /// 直接このページを開いた場合はnullで、上限との比較表示を省略する。
  final int? donationLimit;

  const FurusatoGiftPage({Key? key, this.donationLimit}) : super(key: key);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(userProvider);
    final uid = user?.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('ふるさと納税 返礼品トラッカー')),
      body: uid == null
          ? const Center(child: Text('ログインしてください'))
          : _GiftList(uid: uid, donationLimit: donationLimit),
      floatingActionButton: uid == null
          ? null
          : FloatingActionButton(
              onPressed: () => _showAddSheet(context, uid),
              child: const Icon(Icons.add),
            ),
    );
  }

  void _showAddSheet(BuildContext context, String uid) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      builder: (_) => _AddGiftSheet(uid: uid),
    );
  }
}

class _GiftList extends ConsumerWidget {
  final String uid;
  final int? donationLimit;

  const _GiftList({required this.uid, this.donationLimit});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final giftsAsync = ref.watch(furusatoGiftsStreamProvider(uid));
    final currentYear = DateTime.now().year;

    return giftsAsync.when(
      data: (gifts) {
        final thisYearGifts =
            gifts.where((g) => g.taxYear == currentYear).toList();
        final totalThisYear =
            thisYearGifts.fold<int>(0, (sum, g) => sum + g.donationAmount);

        if (gifts.isEmpty) {
          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              _buildSummaryCard(totalThisYear, currentYear),
              const SizedBox(height: 32),
              const Center(
                child: Text(
                  'まだ返礼品が登録されていません。\n右下の＋ボタンから記録してみましょう。',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
              ),
            ],
          );
        }

        return ListView(
          padding: const EdgeInsets.all(16),
          children: [
            _buildSummaryCard(totalThisYear, currentYear),
            const SizedBox(height: 20),
            const Text('寄付履歴', style: TextStyle(fontWeight: FontWeight.bold)),
            const SizedBox(height: 8),
            ...gifts.map((g) => _GiftTile(uid: uid, gift: g)),
          ],
        );
      },
      loading: () => const Center(child: CircularProgressIndicator()),
      error: (error, st) => Center(child: Text('エラー: $error')),
    );
  }

  Widget _buildSummaryCard(int totalThisYear, int currentYear) {
    final amountFormat = NumberFormat('#,###');
    final remaining =
        donationLimit != null ? (donationLimit! - totalThisYear) : null;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.red.shade300, Colors.red.shade700],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('$currentYear年の寄付合計',
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 8),
          Text(
            '¥${amountFormat.format(totalThisYear)}',
            style: const TextStyle(
                color: Colors.white, fontSize: 28, fontWeight: FontWeight.bold),
          ),
          if (remaining != null) ...[
            const SizedBox(height: 12),
            Text(
              remaining >= 0
                  ? '控除上限まであと¥${amountFormat.format(remaining)}'
                  : '控除上限を¥${amountFormat.format(-remaining)}超えています',
              style: const TextStyle(color: Colors.white70, fontSize: 12),
            ),
            const SizedBox(height: 8),
            ClipRRect(
              borderRadius: BorderRadius.circular(4),
              child: LinearProgressIndicator(
                value: donationLimit! > 0
                    ? (totalThisYear / donationLimit!).clamp(0.0, 1.0)
                    : 0.0,
                backgroundColor: Colors.white24,
                color: Colors.white,
                minHeight: 6,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _GiftTile extends ConsumerWidget {
  final String uid;
  final FurusatoGift gift;

  const _GiftTile({required this.uid, required this.gift});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final amountFormat = NumberFormat('#,###');
    final service = ref.read(furusatoGiftServiceProvider);

    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        title: Text(gift.itemName),
        subtitle: Text(
          '${gift.municipality} ・ ¥${amountFormat.format(gift.donationAmount)} ・ '
          '${DateFormat('yyyy/MM/dd').format(gift.donatedDate)}',
        ),
        trailing: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Tooltip(
              message: gift.isReceiptSubmitted
                  ? 'ワンストップ特例・確定申告 手続き済み'
                  : '手続き未了（タップで切り替え）',
              child: IconButton(
                icon: Icon(
                  gift.isReceiptSubmitted
                      ? Icons.check_circle
                      : Icons.radio_button_unchecked,
                  color: gift.isReceiptSubmitted ? Colors.green : Colors.grey,
                ),
                onPressed: () => service.setReceiptSubmitted(
                  uid: uid,
                  giftId: gift.id,
                  isReceiptSubmitted: !gift.isReceiptSubmitted,
                ),
              ),
            ),
            IconButton(
              icon: const Icon(Icons.delete_outline, color: Colors.grey),
              onPressed: () => service.deleteGift(uid, gift.id),
            ),
          ],
        ),
      ),
    );
  }
}

class _AddGiftSheet extends ConsumerStatefulWidget {
  final String uid;

  const _AddGiftSheet({required this.uid});

  @override
  ConsumerState<_AddGiftSheet> createState() => _AddGiftSheetState();
}

class _AddGiftSheetState extends ConsumerState<_AddGiftSheet> {
  final _municipalityController = TextEditingController();
  final _itemNameController = TextEditingController();
  final _amountController = TextEditingController();
  DateTime _donatedDate = DateTime.now();
  bool _isSaving = false;

  @override
  void dispose() {
    _municipalityController.dispose();
    _itemNameController.dispose();
    _amountController.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    final municipality = _municipalityController.text.trim();
    final itemName = _itemNameController.text.trim();
    final amount = int.tryParse(_amountController.text);
    if (municipality.isEmpty || itemName.isEmpty || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('自治体名・返礼品名・金額を正しく入力してください')),
      );
      return;
    }

    setState(() => _isSaving = true);
    try {
      final service = ref.read(furusatoGiftServiceProvider);
      await service.addGift(
        uid: widget.uid,
        municipality: municipality,
        itemName: itemName,
        donationAmount: amount,
        taxYear: _donatedDate.year,
        donatedDate: _donatedDate,
      );
      if (mounted) Navigator.pop(context);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('登録に失敗しました')),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _donatedDate,
      firstDate: DateTime(DateTime.now().year - 5),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _donatedDate = picked);
  }

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: EdgeInsets.only(
        left: 16,
        right: 16,
        top: 16,
        bottom: MediaQuery.of(context).viewInsets.bottom + 16,
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text('返礼品を記録', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
          const SizedBox(height: 16),
          TextField(
            controller: _municipalityController,
            decoration: const InputDecoration(
              labelText: '寄付先自治体',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _itemNameController,
            decoration: const InputDecoration(
              labelText: '返礼品名',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          TextField(
            controller: _amountController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: '寄付金額',
              prefixText: '¥',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 12),
          ListTile(
            contentPadding: EdgeInsets.zero,
            title: const Text('寄付日'),
            subtitle: Text(DateFormat('yyyy年M月d日').format(_donatedDate)),
            trailing: const Icon(Icons.calendar_today),
            onTap: _pickDate,
          ),
          const SizedBox(height: 20),
          ElevatedButton(
            onPressed: _isSaving ? null : _save,
            style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            child: _isSaving
                ? const SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Text('登録する'),
          ),
        ],
      ),
    );
  }
}
