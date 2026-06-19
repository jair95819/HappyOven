# Tests — HappyOven

Ejecutar todos los tests:

```bash
flutter test
```

Ejecutar un archivo específico:

```bash
flutter test test/core/models/articulo_test.dart
flutter test test/core/models/movimiento_test.dart
flutter test test/core/models/receta_test.dart
flutter test test/core/models/alerta_test.dart
flutter test test/core/models/categoria_test.dart
flutter test test/core/models/orden_produccion_test.dart
flutter test test/core/models/perfil_test.dart
flutter test test/core/models/receta_ingrediente_test.dart
```

Ejecutar tests por nombre:

```bash
flutter test --name "CA033"
```

Regenerar mocks de Mockito (después de editar `@GenerateMocks`):

```bash
dart run build_runner build --delete-conflicting-outputs
```

## Cobertura actual (~23 archivos de test)

### Modelos (7/8 probados)
- `Articulo` ✅ — fromJson/toJson, nulls, tipos enum
- `Movimiento` ✅ — fromJson/toJson, opcionales, tipos enum
- `Receta` ✅ — fromJson/toJson, fallbacks, campos nuevos
- `Alerta` ✅ — fromJson/toJson, nulls, tipo enum
- `Categoria` ✅ — fromJson/toJson, safeCast, tipo enum
- `OrdenProduccion` ✅ — fromJson/toJson, estados enum, fechas
- `Perfil` ✅ — fromJson/toJson, rol enum, avatar
- `RecetaIngrediente` ✅ — fromJson/toJson, defaults

### Repositorios (5/6 probados via interfaces)
- `ArticulosRepository` ✅ — CRUD + filtros
- `MovimientosRepository` ✅ — registro + consultas
- `RecetasRepository` ✅ — CRUD + ingredientes
- `AlertasRepository` ✅ — (cubierto por stock_monitor_service_test)
- `OrdenesProduccionRepository` ✅ — (cubierto por ejecutar_produccion_test)
- `CategoriasRepository` ❌ — pendiente

### Servicios (2/5 probados)
- `OcrService` ✅ — parseo completo
- `StockMonitorService` ✅ — monitoreo + alertas
- `SupabaseService` ❌ — pendiente
- `LocalStorageService` ❌ — pendiente
- `NotificationService` ❌ — pendiente

### ViewModels (4/10 probados)
- `CreateRecipeFormNotifier` ✅
- `EjecutarProduccion` ✅
- `IngresoOcrRegistrador` ✅
- `AlertasViewModel`/`DashboardViewModel`/`SugerenciasViewModel` — parcial (lógica de negocio)
- `CatalogoViewModel` ❌
- `RecetasViewModel` ❌
- `MovimientosViewModel` ❌
- `AuthViewModel` ❌

### Vistas/Widgets (2/~20 probados)
- `SalidaAlmacenView` ✅ — justificación obligatoria
- `IngresoAlmacenView` ✅ — justificación obligatoria
- Resto de vistas ❌ — pendiente

## Convención de nombres

- `CA-XXX` = Caso de prueba unitario
- `CP-XX` = Caso de prueba funcional
- `RF-XXX` = Requisito funcional referenciado
