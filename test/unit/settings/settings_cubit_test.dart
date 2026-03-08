import 'package:bloc_test/bloc_test.dart';
import 'package:f_clean/core/utils/constants.dart';
import 'package:f_clean/features/settings/presentation/cubit/settings_cubit.dart';
import 'package:f_clean/features/settings/presentation/cubit/settings_state.dart';
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:mocktail/mocktail.dart';
import 'package:shared_preferences/shared_preferences.dart';

class MockSharedPreferences extends Mock implements SharedPreferences {}

void main() {
  late MockSharedPreferences mockPrefs;

  setUp(() {
    mockPrefs = MockSharedPreferences();
    when(() => mockPrefs.getInt(AppConstants.themeModeKey)).thenReturn(null);
    when(() => mockPrefs.getString(AppConstants.localeKey)).thenReturn(null);
  });

  group('SettingsCubit', () {
    test('initial state uses system theme and default locale', () {
      final cubit = SettingsCubit(mockPrefs);
      expect(cubit.state.themeMode, ThemeMode.system);
      expect(cubit.state.locale.languageCode, 'en');
    });

    blocTest<SettingsCubit, SettingsState>(
      'setThemeMode updates themeMode',
      build: () {
        when(
          () => mockPrefs.setInt(any(), any()),
        ).thenAnswer((_) async => true);
        return SettingsCubit(mockPrefs);
      },
      act: (cubit) => cubit.setThemeMode(ThemeMode.dark),
      expect: () => [const SettingsState(themeMode: ThemeMode.dark)],
    );

    blocTest<SettingsCubit, SettingsState>(
      'setLocale updates locale',
      build: () {
        when(
          () => mockPrefs.setString(any(), any()),
        ).thenAnswer((_) async => true);
        return SettingsCubit(mockPrefs);
      },
      act: (cubit) => cubit.setLocale(const Locale('tr')),
      expect: () => [const SettingsState(locale: Locale('tr'))],
    );
  });
}
