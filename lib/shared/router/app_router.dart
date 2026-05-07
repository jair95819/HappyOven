import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/features/auth/View/login_view.dart';

final GoRouter appRouter = GoRouter(
  initialLocation: '/login',
  routes: [
    GoRoute(
      path: '/login',
      builder: (BuildContext context, GoRouterState state) {
        return const LoginView();
      },
    ),
  ],
);
