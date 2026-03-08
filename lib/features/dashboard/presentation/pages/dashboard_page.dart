import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/di/injection.dart';
import '../../../../core/l10n/strings.g.dart';
import '../../../../core/router/app_router.dart';
import '../../../auth/presentation/bloc/auth_bloc.dart';
import '../../../auth/presentation/bloc/auth_event.dart';
import '../../../auth/presentation/bloc/auth_state.dart';

class DashboardPage extends StatelessWidget {
  const DashboardPage({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => getIt<AuthBloc>()..add(const AppStarted()),
      child: const _DashboardView(),
    );
  }
}

class _DashboardView extends StatelessWidget {
  const _DashboardView();

  @override
  Widget build(BuildContext context) {
    return BlocListener<AuthBloc, AuthState>(
      listener: (context, state) {
        if (state is AuthUnauthenticated) {
          context.goNamed(AppRoutes.loginName);
        }
      },
      child: Scaffold(
        appBar: AppBar(
          title: Text(context.t.dashboard.title),
          actions: [
            IconButton(
              icon: const Icon(Icons.settings_outlined),
              onPressed: () => context.pushNamed(AppRoutes.settingsName),
            ),
            IconButton(
              icon: const Icon(Icons.logout_outlined),
              onPressed: () =>
                  context.read<AuthBloc>().add(const LogoutRequested()),
            ),
          ],
        ),
        body: BlocBuilder<AuthBloc, AuthState>(
          builder: (context, state) {
            if (state is AuthLoading) {
              return const Center(child: CircularProgressIndicator());
            }
            final userName = state is AuthAuthenticated
                ? state.user.name
                : 'User';
            return RefreshIndicator(
              onRefresh: () async =>
                  context.read<AuthBloc>().add(const AppStarted()),
              child: ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _WelcomeCard(userName: userName),
                  const SizedBox(height: 16),
                  const _StatsRow(),
                  const SizedBox(height: 16),
                  const _RecentActivity(),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}

class _WelcomeCard extends StatelessWidget {
  final String userName;
  const _WelcomeCard({required this.userName});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: Theme.of(context).colorScheme.primaryContainer,
              child: Text(
                userName.isNotEmpty ? userName[0].toUpperCase() : 'U',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    context.t.dashboard.welcomeBack,
                    style: Theme.of(context).textTheme.bodySmall,
                  ),
                  Text(
                    userName,
                    style: Theme.of(context).textTheme.titleMedium?.copyWith(
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _StatsRow extends StatelessWidget {
  const _StatsRow();

  @override
  Widget build(BuildContext context) {
    final t = context.t.dashboard;
    return Row(
      children: [
        Expanded(
          child: _StatCard(label: t.projects, value: '12'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(label: t.tasks, value: '48'),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _StatCard(label: t.done, value: '36'),
        ),
      ],
    );
  }
}

class _StatCard extends StatelessWidget {
  final String label;
  final String value;
  const _StatCard({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 20, horizontal: 12),
        child: Column(
          children: [
            Text(
              value,
              style: Theme.of(
                context,
              ).textTheme.headlineMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(label, style: Theme.of(context).textTheme.bodySmall),
          ],
        ),
      ),
    );
  }
}

class _RecentActivity extends StatelessWidget {
  const _RecentActivity();

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: Text(
              context.t.dashboard.recentActivity,
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
          ),
          const Divider(height: 1),
          ...List.generate(
            5,
            (i) => ListTile(
              leading: CircleAvatar(
                backgroundColor: Theme.of(
                  context,
                ).colorScheme.secondaryContainer,
                child: const Icon(Icons.check, size: 16),
              ),
              title: Text('Task ${i + 1} completed'),
              subtitle: Text('${i + 1} hour${i == 0 ? '' : 's'} ago'),
            ),
          ),
        ],
      ),
    );
  }
}
