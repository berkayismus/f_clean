import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker/talker.dart';
import 'package:talker_bloc_logger/talker_bloc_logger.dart';

import 'app.dart';
import 'core/di/injection.dart';
import 'core/l10n/strings.g.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);

  await configureDependencies();

  Bloc.observer = TalkerBlocObserver(
    talker: getIt<Talker>(),
    settings: const TalkerBlocLoggerSettings(
      printEventFullData: false,
      printStateFullData: false,
    ),
  );

  // slang'i kayıtlı locale ile senkronize et (cubit SharedPrefs'ten okumuş olur)
  final savedLocale = getIt<SettingsCubit>().state.locale;
  await LocaleSettings.setLocale(
    AppLocaleUtils.parse(savedLocale.languageCode),
  );

  runApp(const App());
}
