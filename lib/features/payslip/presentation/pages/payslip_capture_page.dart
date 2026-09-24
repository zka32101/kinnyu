import 'dart:io';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import '../../domain/services/payslip_ocr_service.dart';
import '../../../simulation/presentation/pages/take_home_pay_page.dart';

/// 給与明細を撮影し、総支給額・差引支給額（手取り）を自動読み取りする画面。
/// 読み取った総支給額（月額）から額面年収を概算し、手取り額シミュレーターに
/// 引き継ぐことができる。
class PayslipCapturePage extends StatefulWidget {
  const PayslipCapturePage({Key? key}) : super(key: key);

  @override
  State<PayslipCapturePage> createState() => _PayslipCapturePageState();
}

class _PayslipCapturePageState extends State<PayslipCapturePage> {
  XFile? _capturedImage;
  final _grossController = TextEditingController();
  final _netController = TextEditingController();
  bool _isRecognizing = false;
  bool _grossWasAutoDetected = false;
  bool _netWasAutoDetected = false;
  final _ocrService = PayslipOcrService();

  @override
  void dispose() {
    _grossController.dispose();
    _netController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _pickImage(ImageSource source) async {
    final picker = ImagePicker();
    final image = await picker.pickImage(source: source, imageQuality: 70);
    if (image == null) return;

    setState(() {
      _capturedImage = image;
      _grossWasAutoDetected = false;
      _netWasAutoDetected = false;
    });

    setState(() => _isRecognizing = true);
    try {
      final result = await _ocrService.extractAmounts(image.path);
      if (!mounted) return;
      setState(() {
        if (result.grossAmount != null) {
          _grossController.text = '${result.grossAmount}';
          _grossWasAutoDetected = true;
        }
        if (result.netAmount != null) {
          _netController.text = '${result.netAmount}';
          _netWasAutoDetected = true;
        }
      });
    } finally {
      if (mounted) setState(() => _isRecognizing = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final grossMonthly = int.tryParse(_grossController.text);

    return Scaffold(
      appBar: AppBar(title: const Text('給与明細OCR')),
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
                '撮影・選択すると総支給額・差引支給額（手取り）を自動で読み取ります。'
                '誤読み取りの場合は手動で修正してください。読み取った内容は端末内でのみ処理され、'
                '保存や外部送信は行いません。',
                style: TextStyle(fontSize: 12),
              ),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: _grossController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '総支給額（月額）',
                prefixText: '¥',
                border: const OutlineInputBorder(),
                suffixIcon: _buildSuffixIcon(_isRecognizing, _grossWasAutoDetected),
              ),
              onChanged: (_) => setState(() => _grossWasAutoDetected = false),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _netController,
              keyboardType: TextInputType.number,
              decoration: InputDecoration(
                labelText: '差引支給額（手取り・月額）',
                prefixText: '¥',
                border: const OutlineInputBorder(),
                suffixIcon: _buildSuffixIcon(_isRecognizing, _netWasAutoDetected),
              ),
              onChanged: (_) => setState(() => _netWasAutoDetected = false),
            ),
            const SizedBox(height: 24),
            ElevatedButton.icon(
              onPressed: grossMonthly == null || grossMonthly <= 0
                  ? null
                  : () => Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => TakeHomePayPage(
                            initialGrossAnnualIncome: grossMonthly * 12,
                          ),
                        ),
                      ),
              icon: const Icon(Icons.calculate),
              label: const Text('手取り計算機で年収の内訳を確認する'),
              style: ElevatedButton.styleFrom(minimumSize: const Size.fromHeight(48)),
            ),
          ],
        ),
      ),
    );
  }

  Widget? _buildSuffixIcon(bool isRecognizing, bool wasAutoDetected) {
    if (isRecognizing) {
      return const Padding(
        padding: EdgeInsets.all(12),
        child: SizedBox(
          width: 16,
          height: 16,
          child: CircularProgressIndicator(strokeWidth: 2),
        ),
      );
    }
    if (wasAutoDetected) {
      return Tooltip(
        message: '自動読み取りされた金額です。違う場合は修正してください',
        child: Icon(Icons.auto_awesome, color: Colors.blue.shade400, size: 20),
      );
    }
    return null;
  }

  Widget _buildImagePreview() {
    if (_capturedImage == null) {
      return Container(
        height: 200,
        decoration: BoxDecoration(
          color: Colors.grey.shade200,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: Icon(Icons.description, size: 64, color: Colors.grey.shade400),
        ),
      );
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.file(
        File(_capturedImage!.path),
        height: 200,
        width: double.infinity,
        fit: BoxFit.cover,
      ),
    );
  }
}
