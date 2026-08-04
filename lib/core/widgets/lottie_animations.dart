import 'package:flutter/material.dart';

/// フィードバック・成功アニメーション用のウィジェット群
/// TweenAnimationBuilder を使用した自作アニメーション
/// 将来：Lottie ^3.1.0 で複雑なアニメーションに置き換え可能

class LottieAnimations {
  /// 正解時のアニメーション（コイン舞い散る効果）
  static Widget correctAnswerAnimation({
    Duration duration = const Duration(seconds: 2),
    VoidCallback? onComplete,
  }) {
    return SizedBox(
      width: 100,
      height: 100,
      child: Stack(
        alignment: Alignment.center,
        children: [
          // Lottie アニメーション（本番化時に実装）
          // 現在はプレースホルダー
          Container(
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.green.shade100,
            ),
            child: Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 60,
            ),
          ),
          // フローティングコイン効果（複数出現）
          ...List.generate(5, (index) {
            return Positioned(
              top: 10 + (index * 8),
              left: 30 + (index * 10),
              child: TweenAnimationBuilder<Offset>(
                tween: Tween(
                  begin: Offset.zero,
                  end: Offset(0, -50),
                ),
                duration: duration,
                builder: (context, offset, child) {
                  return Transform.translate(
                    offset: offset,
                    child: Opacity(
                      opacity: 1 - (offset.dy / -50),
                      child: Icon(
                        Icons.monetization_on,
                        color: Colors.amber,
                        size: 20,
                      ),
                    ),
                  );
                },
                onEnd: onComplete,
              ),
            );
          }),
        ],
      ),
    );
  }

  /// 不正解時のアニメーション（首振り効果）
  static Widget incorrectAnswerAnimation({
    Duration duration = const Duration(seconds: 1),
  }) {
    return SizedBox(
      width: 100,
      height: 100,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: duration,
        builder: (context, value, child) {
          final rotation = (value * 3) * 3.14159 / 2; // 3回転
          return Transform.rotate(
            angle: rotation * 0.1, // 首振り効果
            child: Container(
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: Colors.red.shade100,
              ),
              child: Icon(
                Icons.cancel,
                color: Colors.red,
                size: 60,
              ),
            ),
          );
        },
      ),
    );
  }

  /// Aha Moment のゴールドエフェクト（全画面）
  static Widget ahaMomentEffect() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [
            Colors.amber.shade200,
            Colors.amber.shade400,
            Colors.amber.shade200,
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TweenAnimationBuilder<double>(
              tween: Tween(begin: 0, end: 1),
              duration: const Duration(seconds: 2),
              builder: (context, value, child) {
                return Transform.scale(
                  scale: 0.5 + (value * 0.5),
                  child: Opacity(
                    opacity: value > 0.5 ? 1 - (value - 0.5) * 2 : value * 2,
                    child: Icon(
                      Icons.emoji_events,
                      size: 100,
                      color: Colors.amber.shade800,
                    ),
                  ),
                );
              },
            ),
            const SizedBox(height: 20),
            Text(
              '節約TOP3が明らかに！',
              style: TextStyle(
                fontSize: 28,
                fontWeight: FontWeight.bold,
                color: Colors.amber.shade900,
              ),
            ),
          ],
        ),
      ),
    );
  }

  /// ストリーク更新時の炎のエフェクト
  static Widget streakUpdateAnimation({
    Duration duration = const Duration(seconds: 1),
  }) {
    return SizedBox(
      width: 60,
      height: 60,
      child: TweenAnimationBuilder<double>(
        tween: Tween(begin: 0, end: 1),
        duration: duration,
        builder: (context, value, child) {
          return Transform.scale(
            scale: 1 + (value * 0.3),
            child: Opacity(
              opacity: 1 - value,
              child: Icon(
                Icons.local_fire_department,
                size: 50,
                color: Colors.orange.shade600,
              ),
            ),
          );
        },
      ),
    );
  }

  /// 成功パーティクル
  static Widget successParticles({
    Duration duration = const Duration(seconds: 2),
  }) {
    return SizedBox.expand(
      child: Stack(
        children: List.generate(10, (index) {
          return Positioned(
            left: (index * 10 % 100).toDouble(),
            top: (index * 5 % 100).toDouble(),
            child: TweenAnimationBuilder<Offset>(
              tween: Tween(
                begin: Offset.zero,
                end: Offset(
                  ((index % 2) * 2 - 1) * 30,
                  -100,
                ),
              ),
              duration: duration,
              builder: (context, offset, child) {
                return Transform.translate(
                  offset: offset,
                  child: Opacity(
                    opacity: 1 - (offset.dy / -100),
                    child: Icon(
                      Icons.star,
                      color: Colors.amber,
                      size: 12,
                    ),
                  ),
                );
              },
            ),
          );
        }),
      ),
    );
  }
}

/// クイズ画面用のアニメーション付きボタン
class AnimatedQuizButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final bool isCorrect;
  final bool isSelected;

  const AnimatedQuizButton({
    Key? key,
    required this.label,
    required this.onPressed,
    required this.isCorrect,
    required this.isSelected,
  }) : super(key: key);

  @override
  State<AnimatedQuizButton> createState() => _AnimatedQuizButtonState();
}

class _AnimatedQuizButtonState extends State<AnimatedQuizButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: const Duration(milliseconds: 300),
      vsync: this,
    );
  }

  @override
  void didUpdateWidget(AnimatedQuizButton oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.isSelected && !oldWidget.isSelected) {
      _controller.forward();
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ScaleTransition(
      scale: Tween<double>(begin: 1, end: 0.95).animate(_controller),
      child: ElevatedButton(
        onPressed: widget.onPressed,
        style: ElevatedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16),
          backgroundColor: widget.isSelected
              ? (widget.isCorrect ? Colors.green.shade200 : Colors.red.shade200)
              : Colors.blue.shade100,
        ),
        child: Text(
          widget.label,
          style: const TextStyle(color: Colors.black87),
        ),
      ),
    );
  }
}
