abstract class AppConstants {
  // Shared Preferences keys
  static const String themeModeKey = 'theme_mode';
  static const String localeKey = 'locale';

  // Supported locales
  static const List<String> supportedLocales = ['en', 'tr'];
  static const String defaultLocale = 'en';

  // Animation durations
  static const Duration shortAnimation = Duration(milliseconds: 200);
  static const Duration mediumAnimation = Duration(milliseconds: 350);
  static const Duration longAnimation = Duration(milliseconds: 500);

  // Pagination
  static const int defaultPageSize = 20;
}
