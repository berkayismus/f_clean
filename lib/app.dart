import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_localizations/flutter_localizations.dart';

import 'core/di/injection.dart';
import 'core/l10n/strings.g.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/settings/presentation/cubit/settings_cubit.dart';
import 'features/settings/presentation/cubit/settings_state.dart';

class App extends StatelessWidget {
  const App({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider<SettingsCubit>.value(
      value: getIt<SettingsCubit>(),
      child: BlocConsumer<SettingsCubit, SettingsState>(
        listenWhen: (prev, curr) => prev.locale != curr.locale,
        listener: (context, settings) {
          // slang'i SettingsCubit locale değişimiyle senkronize et
          LocaleSettings.setLocale(
            AppLocaleUtils.parse(settings.locale.languageCode),
          );
        },
        builder: (context, settings) {
          return TranslationProvider(
            child: MaterialApp.router(
              title: 'F Clean',
              debugShowCheckedModeBanner: false,
              // Routing
              routerConfig: appRouter,
              // Theming
              theme: AppTheme.light,
              darkTheme: AppTheme.dark,
              themeMode: settings.themeMode,
              // Localisation
              locale: settings.locale,
              supportedLocales: AppLocaleUtils.supportedLocales,
              localizationsDelegates: const [
                GlobalMaterialLocalizations.delegate,
                GlobalWidgetsLocalizations.delegate,
                GlobalCupertinoLocalizations.delegate,
              ],
            ),
          );
        },
      ),
    );
  }
}
