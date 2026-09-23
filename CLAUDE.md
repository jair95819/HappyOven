# CLAUDE.md

This file provides guidance to Claude Code (claude.ai/code) when working with code in this repository.

## Project

Happy Oven (`happy_oven`): Flutter + Supabase inventory app for a bakery — ingredients/finished products, recipes with batch costing, production orders, stock in/out movements (incl. OCR of receipts), analytics dashboard, alerts center, PDF reports. UI strings and most identifiers are in Spanish. Longer Spanish-language guide: `docs/GUIA_PROYECTO.md`.

## Commands

```bash
flutter pub get                                          # install dependencies
flutter run                                              # run on a connected device/emulator
flutter analyze                                          # lint (rules in analysis_options.yaml)
flutter test                                             # run all tests
flutter test test/core/models/articulo_test.dart        # run a single test file
flutter test --name "substring of test name"             # run tests matching a name

# Regenerate Mockito mocks after editing @GenerateMocks in test/helpers/test_helpers.dart
dart run build_runner build --delete-conflicting-outputs
```

`TESTS.md` and `README.md` reference Windows paths (`flutter.bat`, `d:\Happy_Oven`); ignore those — develop with plain `flutter`/`dart` on this macOS checkout.

## Architecture

**Feature-first** layout with a shared **`core/`** layer:

- `lib/core/models/` — domain models (`Articulo`, `Receta`, `Movimiento`, `OrdenProduccion`, `Alerta`, `Categoria`, `Perfil`, `RecetaIngrediente`) shared across all features. Each has `fromJson`/`toJson`.
- `lib/core/models/enums.dart` — **critical convention**: Dart enums (`TipoArticulo`, `TipoMovimiento`, `TipoAlerta`, etc.) map to/from Postgres string values via `.dbValue` (write) and `.fromDb(String)` (read). Postgres uses snake_case (`producto_final`, `salida_produccion`, `stock_bajo`); Dart uses camelCase. Always go through these mappers when reading/writing the DB — never pass `enum.name` directly.
- `lib/core/repositories/` — each entity has an interface `i_<name>_repository.dart` and a Supabase implementation `<name>_repository.dart`. Repositories take a `SupabaseService` via constructor and talk to tables directly.
- `lib/core/providers.dart` — central Riverpod wiring: singleton services and every repository are exposed as `Provider`s here. ViewModels read repositories from these providers; do not instantiate repositories directly in features.
- `lib/core/theme/` — `AppTheme` colors + `themeProvider` (light/dark, persisted directly in `shared_preferences` key `theme_mode`). `lib/core/widgets/` — `AppShell` and `bottom_nav_bar.dart`.
- `lib/core/services/` — `SupabaseService` (singleton client + auth helpers), `LocalStorageService` (shared_preferences: `auth_token`, `refresh_token`, `user_id`, `user_email`, theme), `NotificationService` (local push), `StockMonitorService` (periodic 20-min timer that scans stock and raises alerts + notifications), `OcrService` (ML Kit text recognition for receipts).
- `lib/features/<feature>/presentation/{views,viewmodels}/` — UI per feature. Features: `auth`, `visualizacion_inventario`, `recetas_costeo`, `produccion`, `registro_movimientos`, `analitica_alertas`, `configuracion`.

### State management pattern

- Riverpod throughout. Most ViewModels are `StateNotifier<AsyncValue<T>>`, loading data in the constructor and exposing mutation methods that re-fetch on success. The standard error idiom: mutation methods return `String?` (error message, `null` on success) or `bool`.
- The **auth feature alone** follows Clean Architecture: `domain/` (entities, repository interface, use cases) → `data/` (repository impl) → `presentation/`. Use cases (`auth_usecases.dart`) cover login, register, logout, password recovery/reset, profile + password update, current user; their providers live at the top of `auth_viewmodel.dart` (not in `core/providers.dart`). `AuthState.inicializando` is `true` while the persisted session is being restored at startup. Other features go straight **View → ViewModel → Repository → Supabase** with no domain layer.

### Startup

`main.dart` runs `AppLoader`, which initializes (in order) `LocalStorageService`, `SupabaseService`, `intl` date formatting for `es`, and `NotificationService`, showing a spinner until done, then renders `HappyOvenApp` (`MaterialApp.router`, locale `es_ES`). `HappyOvenApp` listens for deep links via `app_links`: `happyoven://reset-password` navigates to `/reset-password`.

### Routing & authorization

`lib/core/router/app_router.dart` defines a single `GoRouter` (`appRouterProvider`), refreshed (not rebuilt) whenever `authViewModelProvider` changes:
- `initialLocation` is `/splash`. While `authState.inicializando`, everything redirects to `/splash`; once done, `/splash` **always** goes to `/login` (no automatic jump to the dashboard — users must log in explicitly).
- Unauthenticated users are forced to `/login`; `/login`, `/recuperar-password` and `/reset-password` (`CambiarPasswordView(resetFlow: true)`) are reachable without auth. These live outside the shell.
- **Role-based access**: routes whose prefix is in `rutasSoloAdmin` (`/recetas`, `/categorias`, `/reportes`) are admin-only — non-admins (`usuario.esAdmin == false`) are redirected to `/dashboard`. Matching is done by the pure function `esRutaSoloAdmin` (tested in `test/features/auth/role_authorization_test.dart`). Add new admin-only routes to that list.
- The main shell uses `StatefulShellRoute.indexedStack` via `AppShell` + `bottom_nav_bar.dart` with 5 tabs/branches:
  - Inicio: `/dashboard`
  - Inventario: `/catalogo`, `/catalogo/nuevo`, `/catalogo/movimiento/:id` (`IngresoAlmacenView` for a given `Articulo`), `/catalogo/historial/:id`
  - Recetas: `/recetas`, `/recetas/nueva`, `/recetas/editar`
  - Reporte: `/reportes`, `/alertas`
  - Configuración: `/perfil` (+ `/perfil/editar`, `/perfil/password`), `/categorias`
- Some views have **no route** in the router (`OrdenesProduccionListView`, `NuevaOrdenProduccionView`, `SalidaAlmacenView`, `HistorialKardexView`, `IngresoOcrView`, `SugerenciasCompraView`); check how they're reached before assuming they're live, and add a route if wiring them up.
- Routes pass models between screens via `state.extra` (e.g. editing an `Articulo` or `Receta`).

### Backend

- Supabase URL and anon key are currently **hardcoded** in `lib/main.dart` (`SupabaseService().initialize(...)`).
- Postgres schema lives in `database/schema.sql` (tables: `perfiles`, `categorias`, `articulos`, `recetas`, `receta_ingredientes`, `ordenes_produccion`, `movimientos`, `alertas`). `seed_data.sql` (generated by `generate_seed.py`) provides sample data. User profile + role is stored in `perfiles` and fetched separately from Supabase Auth.
- RLS is enabled on every table, but the policies in `schema.sql` are fully permissive (`FOR ALL USING (true) WITH CHECK (true)`); admin restrictions are enforced only client-side by the router.
- `functions/index.js` is currently a placeholder stub.

### Testing

Tests use `mockito` against the repository **interfaces** (`i_*_repository.dart`). Mocks are declared in `test/helpers/test_helpers.dart` (`@GenerateMocks`) and generated into `test/helpers/test_helpers.mocks.dart` — rerun build_runner after changing that annotation list. Existing coverage: model serialization (`test/core/models/`), repositories (`test/core/repositories/`), `OcrService`, `StockMonitorService`, the auth viewmodel, role authorization, the recipe-form notifier, and feature logic under `test/features/` (weekly consumption, reports data, purchase suggestions, production execution, OCR entry registration, mandatory justification on movements).
