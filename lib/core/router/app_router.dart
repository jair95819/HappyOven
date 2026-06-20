import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/core/widgets/app_shell.dart';
import 'package:happy_oven/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:happy_oven/features/auth/presentation/views/login_view.dart';
import 'package:happy_oven/features/auth/presentation/views/recuperar_password_view.dart';
import 'package:happy_oven/features/analitica_alertas/presentation/views/dashboard_inteligente_view.dart';
import 'package:happy_oven/features/analitica_alertas/presentation/views/centro_alertas_view.dart';
import 'package:happy_oven/features/analitica_alertas/presentation/views/reportes_view.dart';
import 'package:happy_oven/features/analitica_alertas/presentation/views/sugerencias_compra_view.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/models/receta.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/views/catalogo_general_view.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/views/formulario_articulo_view.dart';
import 'package:happy_oven/features/registro_movimientos/presentation/views/historial_kardex_view.dart';
import 'package:happy_oven/features/registro_movimientos/presentation/views/ingreso_ocr_view.dart';
import 'package:happy_oven/features/registro_movimientos/presentation/views/salida_almacen_view.dart';
import 'package:happy_oven/features/registro_movimientos/presentation/views/ingreso_almacen_view.dart';
import 'package:happy_oven/features/recetas_costeo/presentation/views/recetario_view.dart';
import 'package:happy_oven/features/recetas_costeo/presentation/views/costeo_dinamico_view.dart';
import 'package:happy_oven/features/produccion/presentation/views/ordenes_produccion_list_view.dart';
import 'package:happy_oven/features/produccion/presentation/views/nueva_orden_produccion_view.dart';
import 'package:happy_oven/features/configuracion/presentation/views/perfil_ajustes_view.dart';
import 'package:happy_oven/features/configuracion/presentation/views/editar_perfil_view.dart';
import 'package:happy_oven/features/configuracion/presentation/views/cambiar_password_view.dart';
import 'package:happy_oven/features/configuracion/presentation/views/gestion_categorias_view.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/views/historial_articulo_view.dart';

/// Prefijos de rutas restringidas exclusivamente al rol Administrador.
/// Un Operario que intente acceder será redirigido al dashboard.
const rutasSoloAdmin = ['/recetas', '/categorias', '/reportes'];

/// Determina si la [location] pertenece a un módulo exclusivo de Administrador.
/// Función pura, expuesta para pruebas de la lógica de autorización (RF-002).
bool esRutaSoloAdmin(String location) {
  return rutasSoloAdmin.any((r) => location == r || location.startsWith('$r/'));
}

final appRouterProvider = Provider<GoRouter>((ref) {
  final goRouter = GoRouter(
    initialLocation: '/splash',
    errorBuilder: (context, state) => const LoginView(),
    redirect: (context, state) {
      final authState = ref.read(authViewModelProvider);
      final enSplash = state.matchedLocation == '/splash';

      // Mientras se restaura la sesión, permanecer en el splash.
      if (authState.inicializando) {
        return enSplash ? null : '/splash';
      }

      final autenticado = authState.autenticado;
      final enLogin =
          state.matchedLocation == '/login' ||
          state.matchedLocation == '/recuperar-password';

      // Terminada la restauración: ir al login siempre.
      // Nunca redirigimos del splash al dashboard: el usuario debe
      // iniciar sesión explícitamente.
      if (enSplash) return '/login';

      if (!autenticado && !enLogin) return '/login';

      // Autorización por rol: bloquear módulos exclusivos de Admin.
      if (autenticado && !(authState.usuario?.esAdmin ?? false)) {
        if (esRutaSoloAdmin(state.matchedLocation)) {
          return '/dashboard';
        }
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (c, s) => const Scaffold(
          body: Center(child: CircularProgressIndicator()),
        ),
      ),
      GoRoute(path: '/login', builder: (c, s) => const LoginView()),
      GoRoute(
        path: '/recuperar-password',
        builder: (c, s) => const RecuperarPasswordView(),
      ),

      StatefulShellRoute.indexedStack(
        builder: (context, state, navigationShell) {
          return AppShell(navigationShell: navigationShell);
        },
        branches: [
          // Dashboard tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/dashboard',
                builder: (c, s) => const DashboardInteligenteView(),
                routes: [
                  GoRoute(
                    path: 'sugerencias',
                    builder: (c, s) => const SugerenciasCompraView(),
                  ),
                ],
              ),
            ],
          ),

          // Inventario tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/catalogo',
                builder: (c, s) => const CatalogoGeneralView(),
              ),
              GoRoute(
                path: '/catalogo/nuevo',
                builder: (c, s) => FormularioArticuloView(
                  articulo: s.extra is Articulo ? s.extra as Articulo? : null,
                ),
              ),
              GoRoute(
                path: '/catalogo/historial/:id',
                builder: (c, s) => HistorialArticuloView(
                  articuloId: s.pathParameters['id']!,
                ),
              ),
            ],
          ),

          // Recetas tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/recetas',
                builder: (c, s) => const RecetarioView(),
              ),
              GoRoute(
                path: '/recetas/nueva',
                builder: (c, s) => CosteoDinamicoView(
                  productoFinal: s.extra is Articulo ? s.extra as Articulo? : null,
                ),
              ),
              GoRoute(
                path: '/recetas/editar',
                builder: (c, s) => CosteoDinamicoView(
                  receta: s.extra is Receta ? s.extra as Receta? : null,
                ),
              ),
            ],
          ),

          // Producción tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/produccion',
                builder: (c, s) => const OrdenesProduccionListView(),
              ),
              GoRoute(
                path: '/produccion/nueva',
                builder: (c, s) => NuevaOrdenProduccionView(
                  receta: s.extra is Receta ? s.extra as Receta? : null,
                ),
              ),
            ],
          ),

          // Movimientos tab
          StatefulShellBranch(
            routes: [
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
              GoRoute(
                path: '/movimientos/entrada',
                builder: (c, s) => const IngresoAlmacenView(),
              ),
            ],
          ),

          // Alertas tab
          StatefulShellBranch(
            routes: [
              GoRoute(
                path: '/alertas',
                builder: (c, s) => const CentroAlertasView(),
              ),
              GoRoute(
                path: '/reportes',
                builder: (c, s) => const ReportesView(),
              ),
              GoRoute(
                path: '/perfil',
                builder: (c, s) => const PerfilAjustesView(),
                routes: [
                  GoRoute(
                    path: 'editar',
                    builder: (c, s) => const EditarPerfilView(),
                  ),
                  GoRoute(
                    path: 'password',
                    builder: (c, s) => const CambiarPasswordView(),
                  ),
                ],
              ),
              GoRoute(
                path: '/categorias',
                builder: (c, s) => const GestionCategoriasView(),
              ),
            ],
          ),
        ],
      ),
    ],
  );

  // Escuchar cambios de autenticación para refrescar el redirect,
  // sin necesidad de recrear el GoRouter completo.
  ref.listen(authViewModelProvider, (_, _) {
    goRouter.refresh();
  });

  return goRouter;
});
