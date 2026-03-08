import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';

class SettingsState extends Equatable {
  final ThemeMode themeMode;
  final Locale locale;

  const SettingsState({
    this.themeMode = ThemeMode.system,
    this.locale = const Locale('en'),
  });

  SettingsState copyWith({ThemeMode? themeMode, Locale? locale}) =>
      SettingsState(
        themeMode: themeMode ?? this.themeMode,
        locale: locale ?? this.locale,
      );

  @override
  List<Object?> get props => [themeMode, locale];
}
