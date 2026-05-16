import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:happy_oven/features/auth/presentation/views/login_view.dart';
import 'package:happy_oven/features/auth/presentation/views/recuperar_password_view.dart';
import 'package:happy_oven/features/analitica_alertas/presentation/views/dashboard_inteligente_view.dart';
import 'package:happy_oven/features/analitica_alertas/presentation/views/centro_alertas_view.dart';
import 'package:happy_oven/features/analitica_alertas/presentation/views/reportes_view.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/views/catalogo_general_view.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/views/formulario_articulo_view.dart';
import 'package:happy_oven/features/registro_movimientos/presentation/views/historial_kardex_view.dart';
import 'package:happy_oven/features/registro_movimientos/presentation/views/ingreso_ocr_view.dart';
import 'package:happy_oven/features/registro_movimientos/presentation/views/salida_almacen_view.dart';
import 'package:happy_oven/features/recetas_costeo/presentation/views/recetario_view.dart';
import 'package:happy_oven/features/recetas_costeo/presentation/views/costeo_dinamico_view.dart';
import 'package:happy_oven/features/configuracion/presentation/views/perfil_ajustes_view.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authViewModelProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      final autenticado = authState.autenticado;
      final enLogin =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/recuperar-password';

      // No autenticado intentando entrar a ruta protegida
      if (!autenticado && !enLogin) return '/login';

      // Autenticado intentando entrar al login
      if (autenticado && enLogin) return '/dashboard';

      return null;
    },
    routes: [
      // ── Auth
      GoRoute(path: '/login', builder: (c, s) => const LoginView()),
      GoRoute(
        path: '/recuperar-password',
        builder: (c, s) => const RecuperarPasswordView(),
      ),

      // ── Dashboard
      GoRoute(
        path: '/dashboard',
        builder: (c, s) => const DashboardInteligenteView(),
      ),

      // ── Analítica
      GoRoute(path: '/alertas', builder: (c, s) => const CentroAlertasView()),
      GoRoute(path: '/reportes', builder: (c, s) => const ReportesView()),

      // ── Inventario
      GoRoute(
        path: '/catalogo',
        builder: (c, s) => const CatalogoGeneralView(),
      ),
      GoRoute(
        path: '/catalogo/nuevo',
        builder: (c, s) => const FormularioArticuloView(),
      ),

      // ── Movimientos
      GoRoute(
        path: '/movimientos',
        builder: (c, s) => const HistorialKardexView(),
      ),
      GoRoute(
        path: '/movimientos/ingreso-ocr',
        builder: (c, s) => const IngresoOcrView(),
      ),
      GoRoute(
        path: '/movimientos/salida',
        builder: (c, s) => const SalidaAlmacenView(),
      ),

      // ── Recetas
      GoRoute(path: '/recetas', builder: (c, s) => const RecetarioView()),
      GoRoute(
        path: '/recetas/nueva',
        builder: (c, s) => const CosteoDinamicoView(),
      ),
      GoRoute(
        path: '/recetas/editar',
        builder: (c, s) {
          final receta = s.extra as dynamic;
          return CosteoDinamicoView(receta: receta);
        },
      ),

      // ── Perfil
      GoRoute(path: '/perfil', builder: (c, s) => const PerfilAjustesView()),
    ],
  );
});
