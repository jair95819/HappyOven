import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/features/auth/presentation/views/login_view.dart';
import 'package:happy_oven/features/auth/presentation/views/recuperar_password_view.dart';
import 'package:happy_oven/features/analitica_alertas/presentation/views/dashboard_inteligente_view.dart';
import 'package:happy_oven/features/analitica_alertas/presentation/views/centro_alertas_view.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginView();
      },
    ),
    GoRoute(
      path: '/recuperar-password',
      builder: (context, state) => const RecuperarPasswordView(),
    ),
    GoRoute(
      path: '/dashboard',
      builder: (context, state) => const DashboardInteligenteView(),
    ),
    GoRoute(
      path: '/alertas',
      builder: (context, state) => const CentroAlertasView(),
    ),
  ],
);

final appRouterProvider = Provider<GoRouter>((ref) => appRouter);
