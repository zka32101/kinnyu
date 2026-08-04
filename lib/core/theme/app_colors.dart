import 'package:flutter/material.dart';

class AppColors {
  // Primary colors
  static const Color primaryBlue = Color(0xFF2196F3);
  static const Color primaryGreen = Color(0xFF4CAF50);
  static const Color primaryAmber = Color(0xFFFFC107);
  static const Color primaryRed = Color(0xFFF44336);
  static const Color primaryIndigo = Color(0xFF3F51B5);
  static const Color primaryOrange = Color(0xFFFF9800);

  // Semantic colors
  static const Color success = primaryGreen;
  static const Color warning = primaryOrange;
  static const Color error = primaryRed;
  static const Color info = primaryBlue;

  // Neutral colors
  static const Color textPrimary = Color(0xFF212121);
  static const Color textSecondary = Color(0xFF757575);
  static const Color textHint = Color(0xFFBDBDBD);
  static const Color divider = Color(0xFFE0E0E0);
  static const Color backgroundLight = Color(0xFFFAFAFA);

  // Card backgrounds
  static const Color cardSavings = Color(0xFFE3F2FD);
  static const Color cardTax = Color(0xFFFFF3E0);
  static const Color cardInvest = Color(0xFFE8F5E9);
  static const Color cardInsurance = Color(0xFFFFEBEE);
  static const Color cardDiagnosis = Color(0xFFF3E5F5);
  static const Color cardInvestment = Color(0xFFFFF8E1);
  static const Color cardRoleplay = Color(0xFFE0F2F1);

  // Category colors with shades
  static final Map<String, Color> categoryColors = {
    'savings': primaryBlue,
    'tax': primaryOrange,
    'invest': primaryGreen,
    'insurance': primaryRed,
  };

  static final Map<String, Color> categoryBackgrounds = {
    'savings': cardSavings,
    'tax': cardTax,
    'invest': cardInvest,
    'insurance': cardInsurance,
  };
}

class AppSpacing {
  // Base spacing unit (4dp)
  static const double xs = 4.0;
  static const double sm = 8.0;
  static const double md = 16.0;
  static const double lg = 24.0;
  static const double xl = 32.0;
  static const double xxl = 48.0;

  // Common padding
  static const EdgeInsets paddingSm = EdgeInsets.all(sm);
  static const EdgeInsets paddingMd = EdgeInsets.all(md);
  static const EdgeInsets paddingLg = EdgeInsets.all(lg);

  // Common padding (horizontal)
  static const EdgeInsets paddingHorizontalMd =
      EdgeInsets.symmetric(horizontal: md);
  static const EdgeInsets paddingHorizontalLg =
      EdgeInsets.symmetric(horizontal: lg);

  // Common padding (vertical)
  static const EdgeInsets paddingVerticalMd = EdgeInsets.symmetric(vertical: md);
  static const EdgeInsets paddingVerticalLg = EdgeInsets.symmetric(vertical: lg);

  // Border radius
  static const double borderRadiusSmall = 8.0;
  static const double borderRadiusMedium = 12.0;
  static const double borderRadiusLarge = 16.0;
  static const double borderRadiusXL = 24.0;

  static final BorderRadius radiusSmall =
      BorderRadius.circular(borderRadiusSmall);
  static final BorderRadius radiusMedium =
      BorderRadius.circular(borderRadiusMedium);
  static final BorderRadius radiusLarge = BorderRadius.circular(borderRadiusLarge);
  static final BorderRadius radiusXL = BorderRadius.circular(borderRadiusXL);
}

class AppTypography {
  // Display styles
  static const TextStyle displayLarge = TextStyle(
    fontSize: 32,
    fontWeight: FontWeight.bold,
    height: 1.25,
  );

  static const TextStyle displayMedium = TextStyle(
    fontSize: 28,
    fontWeight: FontWeight.bold,
    height: 1.29,
  );

  static const TextStyle displaySmall = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    height: 1.33,
  );

  // Headline styles
  static const TextStyle headlineLarge = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.bold,
    height: 1.27,
  );

  static const TextStyle headlineMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.bold,
    height: 1.33,
  );

  static const TextStyle headlineSmall = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.w600,
    height: 1.5,
  );

  // Body styles
  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    height: 1.5,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    height: 1.43,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    height: 1.33,
  );

  // Label styles
  static const TextStyle labelLarge = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    height: 1.43,
  );

  static const TextStyle labelMedium = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.w600,
    height: 1.33,
  );

  static const TextStyle labelSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.w600,
    height: 1.45,
  );
}
