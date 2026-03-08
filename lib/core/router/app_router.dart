import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:talker_flutter/talker_flutter.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/dashboard/presentation/pages/dashboard_page.dart';
import '../../features/settings/presentation/pages/settings_page.dart';
import '../api/token_storage.dart';
import '../di/injection.dart';

part 'app_routes.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: AppRoutes.dashboard,
  debugLogDiagnostics: false,
  redirect: _globalRedirect,
  observers: [TalkerRouteObserver(getIt<Talker>())],
  routes: [
    GoRoute(
      path: AppRoutes.login,
      name: AppRoutes.loginName,
      builder: (context, state) => const LoginPage(),
    ),
    GoRoute(
      path: AppRoutes.dashboard,
      name: AppRoutes.dashboardName,
      builder: (context, state) => const DashboardPage(),
    ),
    GoRoute(
      path: AppRoutes.settings,
      name: AppRoutes.settingsName,
      builder: (context, state) => const SettingsPage(),
    ),
    GoRoute(
      path: '/reset-password/:token',
      name: 'resetPassword',
      builder: (context, state) {
        final token = state.pathParameters['token'] ?? '';
        return Scaffold(body: Center(child: Text('Reset password: $token')));
      },
    ),
  ],
  errorBuilder: (context, state) =>
      Scaffold(body: Center(child: Text('404 — Page not found\n${state.uri}'))),
);

Future<String?> _globalRedirect(
  BuildContext context,
  GoRouterState state,
) async {
  final tokenStorage = getIt<TokenStorage>();
  final isAuthenticated = await tokenStorage.hasAccessToken();
  final isLoginPage = state.matchedLocation == AppRoutes.login;

  if (!isAuthenticated && !isLoginPage) return AppRoutes.login;
  if (isAuthenticated && isLoginPage) return AppRoutes.dashboard;
  return null;
}
