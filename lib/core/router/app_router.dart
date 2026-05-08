import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/features/auth/presentation/views/login_view.dart';
import 'package:happy_oven/features/auth/presentation/views/recuperar_password_view.dart';
import 'package:happy_oven/features/analitica_alertas/presentation/views/dashboard_inteligente_view.dart';
import 'package:happy_oven/features/analitica_alertas/presentation/views/centro_alertas_view.dart';
import 'package:happy_oven/features/analitica_alertas/presentation/views/reportes_view.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/views/catalogo_general_view.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/views/formulario_articulo_view.dart';
import 'package:happy_oven/features/registro_movimientos/presentation/views/historial_kardex_view.dart';
import 'package:happy_oven/features/registro_movimientos/presentation/views/ingreso_ocr_view.dart';

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
    GoRoute(
      path: '/reportes',
      builder: (context, state) => const ReportesView(),
    ),
    GoRoute(
      path: '/catalogo',
      builder: (context, state) => const CatalogoGeneralView(),
    ),
    GoRoute(
      path: '/catalogo/nuevo',
      builder: (context, state) => const FormularioArticuloView(),
    ),
    GoRoute(
      path: '/movimientos',
      builder: (context, state) => const HistorialKardexView(),
    ),
    GoRoute(
      path: '/movimientos/ingreso-ocr',
      builder: (context, state) => const IngresoOcrView(),
    ),
  ],
);

final appRouterProvider = Provider<GoRouter>((ref) => appRouter);
