import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// レシート画像から合計金額を自動抽出するOCRサービス。
/// 端末上でのテキスト認識のみを行い、外部サーバーへの送信は行わない。
class ReceiptOcrService {
  final TextRecognizer _recognizer =
      TextRecognizer(script: TextRecognitionScript.japanese);

  /// 「合計」「小計」などのキーワード付近、またはレシート内で最も大きい
  /// 金額らしき数値を推定して返す。認識できなければ null を返す。
  Future<int?> extractTotalAmount(String imagePath) async {
    try {
      final inputImage = InputImage.fromFile(File(imagePath));
      final result = await _recognizer.processImage(inputImage);
      return _guessTotalAmount(result.text);
    } catch (e) {
      // OCR失敗時は手動入力にフォールバックするため、例外は握りつぶして null を返す
      return null;
    }
  }

  int? _guessTotalAmount(String text) {
    final lines = text.split('\n');
    final totalKeywords = ['合計', '合計金額', 'お会計', '総額', 'total', 'ご購入金額'];
    final amountPattern = RegExp(r'[¥￥]?\s?([0-9][0-9,，]{1,10})\s?円?');

    int? bestFromKeywordLine;
    final allAmounts = <int>[];

    for (final line in lines) {
      final matches = amountPattern.allMatches(line);
      for (final match in matches) {
        final raw = match.group(1);
        if (raw == null) continue;
        final normalized = raw.replaceAll(',', '').replaceAll('，', '');
        final value = int.tryParse(normalized);
        if (value == null || value <= 0) continue;

        allAmounts.add(value);

        final lowerLine = line.toLowerCase();
        final isKeywordLine =
            totalKeywords.any((k) => lowerLine.contains(k.toLowerCase()));
        if (isKeywordLine) {
          // 同じ行に複数候補がある場合は最大値を採用（小計より合計が大きいことが多い）
          if (bestFromKeywordLine == null || value > bestFromKeywordLine) {
            bestFromKeywordLine = value;
          }
        }
      }
    }

    if (bestFromKeywordLine != null) return bestFromKeywordLine;
    if (allAmounts.isEmpty) return null;

    // キーワード行が見つからない場合、レシート上で最も大きい金額を合計とみなす
    allAmounts.sort();
    return allAmounts.last;
  }

  void dispose() {
    _recognizer.close();
  }
}
