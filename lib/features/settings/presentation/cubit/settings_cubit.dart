import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:injectable/injectable.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../../core/utils/constants.dart';
import 'settings_state.dart';

@singleton
class SettingsCubit extends Cubit<SettingsState> {
  final SharedPreferences _prefs;

  SettingsCubit(this._prefs) : super(const SettingsState()) {
    _loadSettings();
  }

  void _loadSettings() {
    final themeModeIndex =
        _prefs.getInt(AppConstants.themeModeKey) ?? ThemeMode.system.index;
    final localeCode =
        _prefs.getString(AppConstants.localeKey) ?? AppConstants.defaultLocale;

    emit(
      SettingsState(
        themeMode: ThemeMode.values[themeModeIndex],
        locale: Locale(localeCode),
      ),
    );
  }

  Future<void> setThemeMode(ThemeMode mode) async {
    await _prefs.setInt(AppConstants.themeModeKey, mode.index);
    emit(state.copyWith(themeMode: mode));
  }

  Future<void> setLocale(Locale locale) async {
    await _prefs.setString(AppConstants.localeKey, locale.languageCode);
    emit(state.copyWith(locale: locale));
  }

  Future<void> toggleTheme() async {
    final next = state.themeMode == ThemeMode.light
        ? ThemeMode.dark
        : ThemeMode.light;
    await setThemeMode(next);
  }
}
