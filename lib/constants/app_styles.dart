import 'package:flutter/material.dart';
import 'app_colors.dart';

/// アプリケーション全体で使用するスタイル定義
class AppStyles {
  // Border radius
  static const double radiusSmall = 8.0;
  static const double radiusMedium = 12.0;
  static const double radiusLarge = 16.0;

  // Padding and spacing
  static const double paddingXSmall = 4.0;
  static const double paddingSmall = 8.0;
  static const double paddingMedium = 16.0;
  static const double paddingLarge = 24.0;
  static const double paddingXLarge = 32.0;

  // Shadow styles
  static const List<BoxShadow> shadowSmall = [
    BoxShadow(
      color: Color(0x1A000000),
      blurRadius: 4,
      offset: Offset(0, 1),
    ),
  ];

  static const List<BoxShadow> shadowMedium = [
    BoxShadow(
      color: Color(0x24000000),
      blurRadius: 8,
      offset: Offset(0, 2),
    ),
  ];

  static const List<BoxShadow> shadowLarge = [
    BoxShadow(
      color: Color(0x33000000),
      blurRadius: 12,
      offset: Offset(0, 4),
    ),
  ];

  // Card decoration with shadow
  static BoxDecoration cardDecoration({
    Color color = AppColors.bgSecondary,
    double radius = radiusMedium,
    List<BoxShadow>? shadows,
    Border? border,
  }) {
    return BoxDecoration(
      color: color,
      borderRadius: BorderRadius.circular(radius),
      boxShadow: shadows ?? shadowSmall,
      border: border ?? Border.all(color: AppColors.border),
    );
  }

  // Gradient decoration
  static BoxDecoration gradientDecoration({
    required List<Color> colors,
    Alignment begin = Alignment.topLeft,
    Alignment end = Alignment.bottomRight,
    double radius = radiusLarge,
  }) {
    return BoxDecoration(
      gradient: LinearGradient(
        colors: colors,
        begin: begin,
        end: end,
      ),
      borderRadius: BorderRadius.circular(radius),
    );
  }

  // App bar decoration
  static BoxDecoration appBarDecoration() {
    return BoxDecoration(
      color: AppColors.bgSecondary,
      border: Border(bottom: BorderSide(color: AppColors.border)),
    );
  }

  // Text styles
  static const TextStyle headingLarge = TextStyle(
    fontSize: 24,
    fontWeight: FontWeight.bold,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingMedium = TextStyle(
    fontSize: 18,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle headingSmall = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.w600,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyLarge = TextStyle(
    fontSize: 16,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodyMedium = TextStyle(
    fontSize: 14,
    fontWeight: FontWeight.normal,
    color: AppColors.textPrimary,
  );

  static const TextStyle bodySmall = TextStyle(
    fontSize: 12,
    fontWeight: FontWeight.normal,
    color: AppColors.textSecondary,
  );

  static const TextStyle captionSmall = TextStyle(
    fontSize: 11,
    fontWeight: FontWeight.normal,
    color: AppColors.textTertiary,
  );

  // Button styles
  static ButtonStyle primaryButtonStyle() {
    return ElevatedButton.styleFrom(
      backgroundColor: AppColors.primary,
      foregroundColor: AppColors.white,
      padding: const EdgeInsets.symmetric(
        horizontal: paddingLarge,
        vertical: paddingMedium,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
      elevation: 0,
    );
  }

  static ButtonStyle secondaryButtonStyle() {
    return OutlinedButton.styleFrom(
      foregroundColor: AppColors.primary,
      side: const BorderSide(color: AppColors.primary, width: 2),
      padding: const EdgeInsets.symmetric(
        horizontal: paddingLarge,
        vertical: paddingMedium,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(radiusMedium),
      ),
    );
  }

  // Loading indicator style
  static const ProgressIndicatorThemeData progressIndicatorTheme =
      ProgressIndicatorThemeData(
    color: AppColors.primary,
    linearMinHeight: 4,
  );
}
