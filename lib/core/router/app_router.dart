import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/features/auth/presentation/views/login_view.dart';
import 'package:happy_oven/features/auth/presentation/views/recuperar_password_view.dart';

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
  ],
);

final appRouterProvider = Provider<GoRouter>((ref) => appRouter);
