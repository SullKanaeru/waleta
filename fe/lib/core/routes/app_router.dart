import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../features/dashboard/screens/dashboard_screen.dart';
import '../../features/envelopes/screens/envelopes_screen.dart';
import '../../features/journal/screens/journal_screen.dart';
import '../../features/activity/screens/cashflow_screen.dart';
import '../../features/activity/screens/camera_scanner_screen.dart';
import '../../features/activity/screens/calculator_screen.dart';
import '../../features/statistics/screens/statistics_screen.dart';
import '../../features/settings/screens/settings_screen.dart';
import '../../features/envelopes/screens/envelope_detail_screen.dart';
import '../../features/envelopes/models/envelope.dart';
import '../../features/envelopes/providers/envelope_provider.dart';
import '../../features/accounts/screens/accounts_screen.dart';
import '../../features/auth/screens/login_screen.dart';
import '../../features/auth/screens/register_screen.dart';
import '../../features/auth/providers/auth_provider.dart';

import '../../shared/layouts/main_layout.dart';
import '../theme/app_colors.dart';

final routerProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/',
    redirect: (context, state) {
      final isLoggedIn = authState.isLoggedIn;
      final isGoingToLogin = state.matchedLocation == '/login';
      final isGoingToRegister = state.matchedLocation == '/register';

      if (isLoggedIn && (isGoingToLogin || isGoingToRegister)) {
        return '/';
      }
      return null;
    },
    routes: [
      GoRoute(path: '/login', builder: (context, state) => const LoginScreen()),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return MainLayout(navigationShell: navigationShell);
        },
        branches: [
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/',
                builder: (context, state) => const DashboardScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/envelopes',
                builder: (context, state) => const EnvelopesScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/cashflow',
                builder: (context, state) => const CashflowScreen(),
              ),
              GoRoute(
                path: '/income',
                builder: (context, state) => const CashflowScreen(),
              ),
              GoRoute(
                path: '/activity',
                builder: (context, state) => const CashflowScreen(),
              ),
            ],
          ),
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/statistics',
                builder: (context, state) => const StatisticsScreen(),
              ),
            ],
          ),
        ],
      ),
      GoRoute(
        path: '/journal',
        builder: (context, state) => const JournalScreen(),
      ),
      GoRoute(
        path: '/accounts',
        builder: (context, state) => const AccountsScreen(),
      ),
      GoRoute(
        path: '/settings',
        builder: (context, state) => const SettingsScreen(),
      ),
      GoRoute(
        path: '/scan',
        builder: (context, state) => const CameraScannerScreen(),
      ),
      GoRoute(
        path: '/calculator',
        builder: (context, state) => const CalculatorScreen(),
      ),
      GoRoute(
        path: '/envelope/:id',
        builder: (context, state) {
          final id = state.pathParameters['id'] ?? 'kebutuhan';
          Envelope? envelope;
          if (state.extra is Envelope) {
            envelope = state.extra as Envelope;
          } else {
            // Find envelope from envelopesProvider
            final container = ProviderScope.containerOf(context);
            final envelopes = container.read(envelopesProvider).value;
            try {
              envelope = envelopes?.firstWhere((e) => e.id == id);
            } catch (_) {
              envelope = null;
            }
          }

          envelope ??= Envelope(
            id: id,
            name: id == 'kebutuhan'
                ? 'Kebutuhan'
                : (id == 'keinginan' ? 'Keinginan' : 'Tabungan'),
            allocatedAmount: 0,
            iconData: id == 'kebutuhan'
                ? LucideIcons.shoppingBag
                : (id == 'keinginan' ? LucideIcons.coffee : LucideIcons.wallet),
            color: id == 'kebutuhan'
                ? AppColors.primary
                : (id == 'keinginan' ? AppColors.accentAmber : Colors.teal),
          );

          return EnvelopeDetailScreen(envelope: envelope);
        },
      ),
    ],
  );
});
