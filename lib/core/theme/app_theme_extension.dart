import 'package:flutter/material.dart';

@immutable
class AppThemeExtension extends ThemeExtension<AppThemeExtension> {
  const AppThemeExtension({
    required this.spacingXs,
    required this.spacingSm,
    required this.spacingMd,
    required this.spacingLg,
    required this.spacingXl,
    required this.radiusSm,
    required this.radiusMd,
    required this.radiusLg,
    required this.cardColor,
    required this.successColor,
    required this.warningColor,
  });

  final double spacingXs;
  final double spacingSm;
  final double spacingMd;
  final double spacingLg;
  final double spacingXl;
  final double radiusSm;
  final double radiusMd;
  final double radiusLg;
  final Color cardColor;
  final Color successColor;
  final Color warningColor;

  static const light = AppThemeExtension(
    spacingXs: 4,
    spacingSm: 8,
    spacingMd: 16,
    spacingLg: 24,
    spacingXl: 32,
    radiusSm: 4,
    radiusMd: 12,
    radiusLg: 24,
    cardColor: Color(0xFFF5F5F5),
    successColor: Color(0xFF4CAF50),
    warningColor: Color(0xFFFFC107),
  );

  static const dark = AppThemeExtension(
    spacingXs: 4,
    spacingSm: 8,
    spacingMd: 16,
    spacingLg: 24,
    spacingXl: 32,
    radiusSm: 4,
    radiusMd: 12,
    radiusLg: 24,
    cardColor: Color(0xFF1E1E1E),
    successColor: Color(0xFF66BB6A),
    warningColor: Color(0xFFFFCA28),
  );

  @override
  AppThemeExtension copyWith({
    double? spacingXs,
    double? spacingSm,
    double? spacingMd,
    double? spacingLg,
    double? spacingXl,
    double? radiusSm,
    double? radiusMd,
    double? radiusLg,
    Color? cardColor,
    Color? successColor,
    Color? warningColor,
  }) => AppThemeExtension(
    spacingXs: spacingXs ?? this.spacingXs,
    spacingSm: spacingSm ?? this.spacingSm,
    spacingMd: spacingMd ?? this.spacingMd,
    spacingLg: spacingLg ?? this.spacingLg,
    spacingXl: spacingXl ?? this.spacingXl,
    radiusSm: radiusSm ?? this.radiusSm,
    radiusMd: radiusMd ?? this.radiusMd,
    radiusLg: radiusLg ?? this.radiusLg,
    cardColor: cardColor ?? this.cardColor,
    successColor: successColor ?? this.successColor,
    warningColor: warningColor ?? this.warningColor,
  );

  @override
  AppThemeExtension lerp(AppThemeExtension? other, double t) {
    if (other is! AppThemeExtension) return this;
    return AppThemeExtension(
      spacingXs: spacingXs,
      spacingSm: spacingSm,
      spacingMd: spacingMd,
      spacingLg: spacingLg,
      spacingXl: spacingXl,
      radiusSm: radiusSm,
      radiusMd: radiusMd,
      radiusLg: radiusLg,
      cardColor: Color.lerp(cardColor, other.cardColor, t)!,
      successColor: Color.lerp(successColor, other.successColor, t)!,
      warningColor: Color.lerp(warningColor, other.warningColor, t)!,
    );
  }
}

extension AppThemeExtensionX on BuildContext {
  AppThemeExtension get appTheme =>
      Theme.of(this).extension<AppThemeExtension>()!;
}
