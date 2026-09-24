import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// 給与明細OCRの読み取り結果。
class PayslipOcrResult {
  final int? grossAmount; // 総支給額（月額）
  final int? netAmount; // 差引支給額（手取り、月額）

  const PayslipOcrResult({this.grossAmount, this.netAmount});
}

/// 給与明細の写真から総支給額・差引支給額（手取り）を自動抽出するOCRサービス。
/// レシートOCR（ReceiptOcrService）と同じく、端末上でのテキスト認識のみを行い、
/// 外部サーバーへの送信は行わない。
class PayslipOcrService {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.japanese);

  static const _grossKeywords = ['総支給額', '支給合計', '支給額合計', '総支給'];
  static const _netKeywords = ['差引支給額', '差引合計', '手取り', '振込支給額'];
  static final _amountPattern = RegExp(r'[¥￥]?\s?([0-9][0-9,，]{2,10})\s?円?');

  /// 給与明細画像から総支給額・差引支給額を推定して返す。
  /// 認識できなかった項目はnullのままとなり、手動入力にフォールバックする。
  Future<PayslipOcrResult> extractAmounts(String imagePath) async {
    try {
      final inputImage = InputImage.fromFile(File(imagePath));
      final result = await _recognizer.processImage(inputImage);
      return _guessAmounts(result.text);
    } catch (e) {
      // OCR失敗時は手動入力にフォールバックするため、例外は握りつぶす
      return const PayslipOcrResult();
    }
  }

  PayslipOcrResult _guessAmounts(String text) {
    final lines = text.split('\n');
    int? gross;
    int? net;

    for (final line in lines) {
      final matches = _amountPattern.allMatches(line);
      for (final match in matches) {
        final raw = match.group(1);
        if (raw == null) continue;
        final normalized = raw.replaceAll(',', '').replaceAll('，', '');
        final value = int.tryParse(normalized);
        if (value == null || value <= 0) continue;

        if (_grossKeywords.any((k) => line.contains(k))) {
          if (gross == null || value > gross) gross = value;
        }
        if (_netKeywords.any((k) => line.contains(k))) {
          if (net == null || value > net) net = value;
        }
      }
    }

    return PayslipOcrResult(grossAmount: gross, netAmount: net);
  }

  void dispose() {
    _recognizer.close();
  }
}
