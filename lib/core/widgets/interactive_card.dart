import 'package:flutter/material.dart';
import '../theme/app_theme.dart';

/// ホバー・プレスアニメーション付きカード
class InteractiveCard extends StatefulWidget {
  final Widget child;
  final VoidCallback? onTap;
  final Color? backgroundColor;
  final EdgeInsets padding;
  final Duration duration;

  const InteractiveCard({
    Key? key,
    required this.child,
    this.onTap,
    this.backgroundColor,
    this.padding = const EdgeInsets.all(16),
    this.duration = const Duration(milliseconds: 200),
  }) : super(key: key);

  @override
  State<InteractiveCard> createState() => _InteractiveCardState();
}

class _InteractiveCardState extends State<InteractiveCard>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _scaleAnimation;
  late Animation<double> _elevationAnimation;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: widget.duration,
      vsync: this,
    );
    _scaleAnimation = Tween<double>(begin: 1.0, end: 0.98).animate(
      CurveTween(curve: Curves.easeOutCubic).animate(_controller),
    );
    _elevationAnimation = Tween<double>(begin: 0, end: 8).animate(
      CurveTween(curve: Curves.easeOutCubic).animate(_controller),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: GestureDetector(
        onTapDown: (_) => _controller.forward(),
        onTapUp: (_) {
          _controller.reverse();
          widget.onTap?.call();
        },
        onTapCancel: () => _controller.reverse(),
        child: ScaleTransition(
          scale: _scaleAnimation,
          child: AnimatedBuilder(
            animation: _elevationAnimation,
            builder: (context, child) {
              return Container(
                decoration: BoxDecoration(
                  color: widget.backgroundColor ?? Colors.white,
                  borderRadius: BorderRadius.circular(12),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.08),
                      blurRadius: 4 + _elevationAnimation.value,
                      offset: Offset(0, 2 + _elevationAnimation.value / 2),
                    ),
                  ],
                ),
                padding: widget.padding,
                child: child,
              );
            },
            child: widget.child,
          ),
        ),
      ),
    );
  }
}

/// ボタンホバーアニメーション付き
class InteractiveButton extends StatefulWidget {
  final String label;
  final VoidCallback onPressed;
  final Color? backgroundColor;
  final Icon? icon;

  const InteractiveButton({
    Key? key,
    required this.label,
    required this.onPressed,
    this.backgroundColor,
    this.icon,
  }) : super(key: key);

  @override
  State<InteractiveButton> createState() => _InteractiveButtonState();
}

class _InteractiveButtonState extends State<InteractiveButton>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      duration: AppTheme.buttonPressDuration,
      vsync: this,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MouseRegion(
      onEnter: (_) => _controller.forward(),
      onExit: (_) => _controller.reverse(),
      child: ScaleTransition(
        scale: Tween<double>(begin: 1.0, end: 1.05).animate(
          CurveTween(curve: Curves.easeOutCubic).animate(_controller),
        ),
        child: ElevatedButton.icon(
          onPressed: widget.onPressed,
          icon: widget.icon ?? const SizedBox.shrink(),
          label: Text(widget.label),
          style: ElevatedButton.styleFrom(
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            backgroundColor: widget.backgroundColor,
          ),
        ),
      ),
    );
  }
}
