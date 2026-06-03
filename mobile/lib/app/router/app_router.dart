import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import 'package:fin_goal/features/auth/presentation/pages/login_page.dart';
import 'package:fin_goal/features/auth/presentation/pages/splash_page.dart';
import 'package:fin_goal/features/auth/presentation/providers/auth_provider.dart';
import 'package:fin_goal/features/goals/presentation/pages/goal_selection_page.dart';
import 'package:fin_goal/features/onboarding/presentation/pages/onboarding_page.dart';
import 'package:fin_goal/features/scenarios/presentation/pages/monthly_checkin_page.dart';
import 'package:fin_goal/features/scenarios/presentation/pages/scenario_dashboard_page.dart';
import 'package:fin_goal/features/scenarios/presentation/pages/what_if_page.dart';
import 'package:fin_goal/features/profile/presentation/providers/profile_provider.dart';
import 'package:fin_goal/features/profile/presentation/pages/settings_page.dart';
import 'package:fin_goal/features/premium/presentation/pages/paywall_page.dart';
import 'package:fin_goal/features/premium/presentation/pages/payment_page.dart';
import 'package:fin_goal/features/scenarios/domain/entities/monthly_record.dart';
import 'package:fin_goal/app/router/routes.dart';

/// GoRouter provider — manually created (no code generation needed for router).
final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authStateProvider);
  final hasCompletedOnboarding = ref.watch(hasCompletedOnboardingProvider);

  return GoRouter(
    initialLocation: AppRoutes.splash,
    debugLogDiagnostics: true,
    redirect: (context, state) {
      final isAuth = authState.value != null;
      final isAuthRoute = state.matchedLocation == AppRoutes.login;
      final isSplash = state.matchedLocation == AppRoutes.splash;
      final isOnboardingRoute = state.matchedLocation == AppRoutes.onboarding;

      // Still loading auth state — don't redirect yet
      if (authState.isLoading) return null;

      // Not authenticated → go to login
      if (!isAuth && !isAuthRoute) return AppRoutes.login;

      if (isAuth) {
        // Still checking onboarding state
        if (hasCompletedOnboarding.isLoading) return null;

        final hasOnboarded = hasCompletedOnboarding.value ?? false;

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
        path: AppRoutes.profile,
        builder: (_, __) => const SettingsPage(),
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
            builder: (_, state) {
              final record = state.extra as MonthlyRecord?;
              return MonthlyCheckinPage(existingRecord: record);
            },
          ),
          GoRoute(
            path: 'paywall',
            builder: (_, __) => const PaywallPage(),
          ),
          GoRoute(
            path: 'payment',
            builder: (_, state) {
              final extra = state.extra as Map<String, dynamic>? ?? {};
              return PaymentPage(
                title: extra['title'] as String? ?? 'Gói Premium',
                price: extra['price'] as String? ?? '0₫',
              );
            },
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
