import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/strings.g.dart';
import '../cubit/settings_cubit.dart';
import '../cubit/settings_state.dart';

class SettingsPage extends StatelessWidget {
  const SettingsPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider.value(
      value: getIt<SettingsCubit>(),
      child: const _SettingsView(),
    );
  }
}

class _SettingsView extends StatelessWidget {
  const _SettingsView();

  @override
  Widget build(BuildContext context) {
    final t = context.t.settings;
    return Scaffold(
      appBar: AppBar(title: Text(t.title)),
      body: BlocBuilder<SettingsCubit, SettingsState>(
        builder: (context, state) {
          return ListView(
            children: [
              _SectionHeader(title: t.appearance),
              ListTile(
                leading: const Icon(Icons.brightness_6_outlined),
                title: Text(t.theme),
                subtitle: Text(_themeModeLabel(context, state.themeMode)),
                trailing: SegmentedButton<ThemeMode>(
                  segments: const [
                    ButtonSegment(
                      value: ThemeMode.light,
                      icon: Icon(Icons.light_mode_outlined),
                      tooltip: 'Light',
                    ),
                    ButtonSegment(
                      value: ThemeMode.system,
                      icon: Icon(Icons.auto_mode_outlined),
                      tooltip: 'System',
                    ),
                    ButtonSegment(
                      value: ThemeMode.dark,
                      icon: Icon(Icons.dark_mode_outlined),
                      tooltip: 'Dark',
                    ),
                  ],
                  selected: {state.themeMode},
                  onSelectionChanged: (modes) =>
                      context.read<SettingsCubit>().setThemeMode(modes.first),
                ),
              ),
              const Divider(),
              _SectionHeader(title: t.language),
              RadioGroup<String>(
                groupValue: state.locale.languageCode,
                onChanged: (v) {
                  if (v != null) {
                    context.read<SettingsCubit>().setLocale(Locale(v));
                  }
                },
                child: Column(
                  children: ['en', 'tr']
                      .map(
                        (code) => RadioListTile<String>(
                          title: Text(_localeLabel(context, code)),
                          value: code,
                        ),
                      )
                      .toList(),
                ),
              ),
              if (kDebugMode) ...[
                const Divider(),
                _SectionHeader(title: t.developerTools),
                ListTile(
                  leading: const Icon(Icons.bug_report_outlined),
                  title: Text(t.logs),
                  subtitle: Text(t.viewAppLogs),
                  trailing: const Icon(Icons.chevron_right),
                  onTap: () => Navigator.of(context).push(
                    MaterialPageRoute<void>(
                      builder: (_) => TalkerScreen(talker: getIt<Talker>()),
                    ),
                  ),
                ),
              ],
            ],
          );
        },
      ),
    );
  }

  String _themeModeLabel(BuildContext context, ThemeMode mode) {
    final t = context.t.settings;
    switch (mode) {
      case ThemeMode.light:
        return t.lightMode;
      case ThemeMode.dark:
        return t.darkMode;
      case ThemeMode.system:
        return t.systemMode;
    }
  }

  String _localeLabel(BuildContext context, String code) {
    final t = context.t.settings;
    switch (code) {
      case 'en':
        return t.english;
      case 'tr':
        return t.turkish;
      default:
        return code;
    }
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;
  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 4),
      child: Text(
        title,
        style: Theme.of(context).textTheme.labelLarge?.copyWith(
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
