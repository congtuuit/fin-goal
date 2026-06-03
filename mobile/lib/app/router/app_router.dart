import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/pages/login_page.dart';
import '../../features/auth/presentation/pages/splash_page.dart';
import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/goals/presentation/pages/goal_selection_page.dart';
import '../../features/onboarding/presentation/pages/onboarding_page.dart';
import '../../features/scenarios/presentation/pages/monthly_checkin_page.dart';
import '../../features/scenarios/presentation/pages/scenario_dashboard_page.dart';
import '../../features/scenarios/presentation/pages/what_if_page.dart';
import '../../features/profile/presentation/providers/profile_provider.dart';
import 'routes.dart';

/// GoRouter provider — manually created (no code generation needed for router).
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuth = authState.valueOrNull != null;
      final isAuthRoute = state.matchedLocation == AppRoutes.login;
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isOnboardingRoute = state.matchedLocation == AppRoutes.onboarding;

      // Still loading auth state — don't redirect yet
      if (authState.isLoading) return null;

      // Not authenticated → go to login
      if (!isAuth && !isAuthRoute && !isSplash) return AppRoutes.login;

      if (isAuth) {
        // Still checking onboarding state
        if (hasCompletedOnboarding.isLoading) return null;

        final hasOnboarded = hasCompletedOnboarding.valueOrNull ?? false;

        if (!hasOnboarded) {
          // Must complete onboarding first
          if (!isOnboardingRoute) return AppRoutes.onboarding;
        } else {
          // Already onboarded → skip login, splash, and onboarding
          if (isAuthRoute || isSplash || isOnboardingRoute) {
            return AppRoutes.home;
          }
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: AppRoutes.splash,
        builder: (_, __) => const SplashPage(),
      ),
      GoRoute(
        path: AppRoutes.login,
        builder: (_, __) => const LoginPage(),
      ),
      GoRoute(
        path: AppRoutes.onboarding,
        builder: (_, __) => const OnboardingPage(),
      ),
      GoRoute(
        path: AppRoutes.home,
        builder: (_, __) => const ScenarioDashboardPage(),
        routes: [
          GoRoute(
            path: 'goal-selection',
            builder: (_, __) => const GoalSelectionPage(),
          ),
          GoRoute(
            path: 'what-if',
            builder: (_, __) => const WhatIfPage(),
          ),
          GoRoute(
            path: 'monthly-checkin',
            builder: (_, __) => const MonthlyCheckinPage(),
          ),
        ],
      ),
    ],
    errorBuilder: (context, state) => Scaffold(
      body: Center(
        child: Text(
          'Trang không tồn tại\n${state.uri}',
          textAlign: TextAlign.center,
        ),
      ),
    ),
  );
});
