import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../domain/models/pattern_diagnosis.dart';
import '../../../user_profile/presentation/providers/user_provider.dart';
import '../../../../core/analytics/analytics_provider.dart';
import '../../../../core/widgets/lottie_animations.dart';
import '../../../../core/theme/app_theme.dart';
import '../../../../core/services/notification_service.dart';

class DiagnosisResultPage extends ConsumerStatefulWidget {
  final PatternDiagnosis diagnosis;

  const DiagnosisResultPage({Key? key, required this.diagnosis})
      : super(key: key);

  @override
  ConsumerState<DiagnosisResultPage> createState() =>
      _DiagnosisResultPageState();
}

class _DiagnosisResultPageState extends ConsumerState<DiagnosisResultPage> {
  // 端末回転やテキストサイズ変更などによる再ビルドで、アナリティクス送信・
  // ローカル通知が重複して実行されるのを防ぐためのフラグ。
  bool _notifiedOnce = false;

  @override
  Widget build(BuildContext context) {
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      if (!context.mounted) return;
      if (_notifiedOnce) return;
      try {
        final user = ref.read(userProvider);
        final analytics = ref.read(analyticsServiceProvider);
        if (user != null) {
          analytics.logAhaMomentReached(user.uid, widget.diagnosis.patternId);
          await NotificationService().showDiagnosisResultNotification();
          _notifiedOnce = true;
        }
      } catch (e, stack) {
        debugPrint('Failed to show diagnosis result notification: $e\n$stack');
      }
    });

    return Scaffold(
      appBar: AppBar(title: const Text('あなたの診断結果')),
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [Colors.amber.shade200, Colors.amber.shade400],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(12),
              ),
              padding: const EdgeInsets.all(24),
              child: Column(
                children: [
                  if (widget.diagnosis.imageAsset.isNotEmpty)
                    ClipOval(
                      child: Image.asset(
                        widget.diagnosis.imageAsset,
                        width: 96,
                        height: 96,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) => const Icon(
                            Icons.emoji_events,
                            color: Colors.white,
                            size: 48),
                      ),
                    )
                  else
                    const Icon(Icons.emoji_events, color: Colors.white, size: 48),
                  const SizedBox(height: 16),
                  if (widget.diagnosis.typeName.isNotEmpty) ...[
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 12, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(
                        'あなたは「${widget.diagnosis.typeName}」',
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                  ],
                  const Text(
                    'あなたの節約TOP3',
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '月額 ¥${widget.diagnosis.estimatedMonthlySavings.toString()}の節約が見込めます！',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            _buildTipCard(
              title: '1位',
              content: widget.diagnosis.savingsTip1,
              color: Colors.amber,
            ),
            const SizedBox(height: 12),
            _buildTipCard(
              title: '2位',
              content: widget.diagnosis.savingsTip2,
              color: Colors.grey.shade400,
            ),
            const SizedBox(height: 12),
            _buildTipCard(
              title: '3位',
              content: widget.diagnosis.savingsTip3,
              color: Colors.brown.shade300,
            ),
            const SizedBox(height: 24),
            Container(
              decoration: BoxDecoration(
                color: Colors.orange.shade50,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: Colors.orange.shade200),
              ),
              padding: const EdgeInsets.all(12),
              child: Text(
                widget.diagnosis.disclaimer,
                style: TextStyle(
                  fontSize: 12,
                  color: Colors.orange.shade900,
                ),
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: () {
                Navigator.pop(context);
              },
              child: const Text('ホームに戻る'),
            ),
              ],
            ),
          ),
          Positioned.fill(
            child: IgnorePointer(
              child: TweenAnimationBuilder<double>(
                tween: Tween(begin: 0, end: 1),
                duration: const Duration(seconds: 3),
                builder: (context, value, child) {
                  return Opacity(
                    opacity: value < 0.5 ? value * 2 : 1 - (value - 0.5) * 2,
                    child: Container(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.amber.shade200.withOpacity(0.2),
                            Colors.amber.shade400.withOpacity(0.2),
                          ],
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                        ),
                      ),
                    ),
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTipCard({
    required String title,
    required String content,
    required Color color,
  }) {
    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: color),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: color,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            content,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
