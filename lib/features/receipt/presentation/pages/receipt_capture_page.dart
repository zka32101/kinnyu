import 'dart:io';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/models/receipt.dart';
import '../../domain/models/receipt_quiz_generator.dart';
import '../providers/receipt_provider.dart';
import '../../../user_profile/presentation/providers/user_provider.dart';
import '../../../../core/analytics/analytics_provider.dart';
import 'receipt_quiz_page.dart';

class ReceiptCapturePage extends ConsumerStatefulWidget {
  const ReceiptCapturePage({Key? key}) : super(key: key);

  @override
  ConsumerState<ReceiptCapturePage> createState() => _ReceiptCapturePageState();
}

class _ReceiptCapturePageState extends ConsumerState<ReceiptCapturePage> {
  XFile? capturedImage;
  ReceiptCategory selectedCategory = ReceiptCategory.convenience;
  final amountController = TextEditingController();
  bool isSaving = false;

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 70);
    if (image != null) {
      setState(() => capturedImage = image);
    }
  }

  @override
  Widget build(BuildContext context) {
    final user = ref.watch(userProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('レシートを記録')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildImagePreview(),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.camera),
                    icon: const Icon(Icons.camera_alt),
                    label: const Text('撮影'),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: OutlinedButton.icon(
                    onPressed: () => _pickImage(ImageSource.gallery),
                    icon: const Icon(Icons.photo_library),
                    label: const Text('ギャラリー'),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.blue.shade50,
                borderRadius: BorderRadius.circular(8),
              ),
              child: const Text(
                '現在は金額・カテゴリを手動入力してください（自動読み取り機能は準備中です）',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<ReceiptCategory>(
              value: selectedCategory,
              decoration: const InputDecoration(labelText: 'カテゴリ'),
              items: ReceiptCategory.values.map((category) {
                return DropdownMenuItem(
                  value: category,
                  child: Text(ReceiptCategoryInfo.displayNames[category]!),
                );
              }).toList(),
              onChanged: (value) {
                setState(() => selectedCategory = value!);
              },
            ),
            const SizedBox(height: 16),
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: '金額',
                prefixText: '¥',
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: isSaving || user == null
                  ? null
                  : () => _saveAndGenerateQuiz(user.uid),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
              child: isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('記録してクイズを作成'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildImagePreview() {
    if (capturedImage == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(Icons.receipt_long, size: 64, color: Colors.grey.shade400),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(capturedImage!.path),
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }

  Future<void> _saveAndGenerateQuiz(String uid) async {
    final amount = int.tryParse(amountController.text);
    if (amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('正しい金額を入力してください')),
      );
      return;
    }

    setState(() => isSaving = true);

    final service = ref.read(receiptServiceProvider);
    final analytics = ref.read(analyticsServiceProvider);

    try {
      final receipt = await service.saveReceipt(
        uid: uid,
        category: selectedCategory,
        amount: amount,
        imagePath: capturedImage?.path,
      );

      await analytics.logEvent('receipt_uploaded', parameters: {
        'user_id': uid,
        'category': selectedCategory.index.toString(),
        'amount': amount,
      });

      final quiz = ReceiptQuizGenerator.generate(receipt);

      if (mounted) {
        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => ReceiptQuizPage(question: quiz, receipt: receipt),
          ),
        );
      }
    } catch (e) {
      debugPrint('ReceiptCapturePage: failed to save receipt: $e');
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('保存に失敗しました')),
        );
      }
    } finally {
      if (mounted) {
        setState(() => isSaving = false);
      }
    }
  }
}
