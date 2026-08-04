import 'package:flutter/material.dart';

class AppTheme {
  static const Duration pageTransitionDuration = Duration(milliseconds: 300);
  static const Duration cardHoverDuration = Duration(milliseconds: 200);
  static const Duration buttonPressDuration = Duration(milliseconds: 150);

  static ThemeData lightTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.light,
      ),
      scaffoldBackgroundColor: Colors.grey.shade50,
      appBarTheme: AppBarTheme(
        elevation: 1,
        centerTitle: false,
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }

  static ThemeData darkTheme() {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.dark,
      colorScheme: ColorScheme.fromSeed(
        seedColor: Colors.blue,
        brightness: Brightness.dark,
      ),
      scaffoldBackgroundColor: Colors.grey.shade900,
      appBarTheme: AppBarTheme(
        elevation: 1,
        centerTitle: false,
        backgroundColor: Colors.grey.shade900,
        foregroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          elevation: 2,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
      ),
      cardTheme: CardThemeData(
        elevation: 1,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
      ),
    );
  }
}

class PageRouteAnimations {
  static Route<T> slideTransition<T>(
    Widget page, {
    Offset begin = const Offset(1, 0),
  }) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        const curve = Curves.easeOutCubic;
        return SlideTransition(
          position: animation.drive(
            Tween(begin: begin, end: Offset.zero).chain(
              CurveTween(curve: curve),
            ),
          ),
          child: FadeTransition(
            opacity: animation.drive(
              Tween(begin: 0.0, end: 1.0).chain(
                CurveTween(curve: curve),
              ),
            ),
            child: child,
          ),
        );
      },
      transitionDuration: AppTheme.pageTransitionDuration,
      reverseTransitionDuration: AppTheme.pageTransitionDuration,
    );
  }

  static Route<T> fadeTransition<T>(Widget page) {
    return PageRouteBuilder<T>(
      pageBuilder: (context, animation, secondaryAnimation) => page,
      transitionsBuilder: (context, animation, secondaryAnimation, child) {
        return FadeTransition(
          opacity: animation,
          child: child,
        );
      },
      transitionDuration: const Duration(milliseconds: 200),
      reverseTransitionDuration: const Duration(milliseconds: 200),
    );
  }
}
