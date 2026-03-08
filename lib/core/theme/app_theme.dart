import 'package:flex_color_scheme/flex_color_scheme.dart';
import 'package:flutter/material.dart';

import 'app_theme_extension.dart';

abstract class AppTheme {
  static ThemeData get light => FlexThemeData.light(
    scheme: FlexScheme.aquaBlue,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 9,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 10,
      blendOnColors: false,
      useMaterial3Typography: true,
      useM2StyleDividerInM3: true,
      defaultRadius: 12.0,
    ),
    useMaterial3: true,
    extensions: const [AppThemeExtension.light],
  );

  static ThemeData get dark => FlexThemeData.dark(
    scheme: FlexScheme.aquaBlue,
    surfaceMode: FlexSurfaceMode.levelSurfacesLowScaffold,
    blendLevel: 15,
    subThemesData: const FlexSubThemesData(
      blendOnLevel: 20,
      blendOnColors: true,
      useMaterial3Typography: true,
      useM2StyleDividerInM3: true,
      defaultRadius: 12.0,
    ),
    useMaterial3: true,
    extensions: const [AppThemeExtension.dark],
  );
}
