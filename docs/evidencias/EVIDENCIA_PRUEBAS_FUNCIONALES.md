# Evidencia de re-ejecución de pruebas funcionales

- **Fecha de ejecución:** 2026-06-13
- **Versión del software:** 1.0.0+1
- **Entorno:** verificación funcional automatizada (`flutter test`) sobre el código fuente.
- **Resultado global:** **91/91 pruebas pasan** (`All tests passed!`).
- **Artefactos de evidencia:**
  - Log completo de ejecución: [`resultado_pruebas.log`](resultado_pruebas.log)
  - Código de las pruebas nuevas (ver tabla)

## Alcance

Solo se re-ejecutaron los casos del plan que **no habían quedado completados** en la
ejecución anterior (CP-01, CP-04, CP-05, CP-06 y CP-07). Los casos CP-02 y CP-03 ya
estaban en estado *Exitoso* y no se repiten.

## Resultados por caso de prueba

| CP | Requisito | Estado anterior | Estado actual | Evidencia (prueba automatizada) |
|----|-----------|-----------------|---------------|---------------------------------|
| **CP-01** | RF-002 Autorización por rol | 🟡 Parcial | 🟢 **Exitoso** | `CA030`–`CA034` en `test/features/auth/role_authorization_test.dart` |
| **CP-04** | RF-012 Justificación obligatoria | 🟡 Parcial | 🟢 **Exitoso** | `CA035`, `CA036` en `test/features/registro_movimientos/justificacion_obligatoria_test.dart` |
| **CP-05** | RF-011 / RF-013 Producción y stock | 🔴 Fallido | 🟢 **Exitoso** | `CA028`, `CA029` en `test/features/produccion/ejecutar_produccion_test.dart` |
| **CP-06** | RF-014/015/016 Reportes | 🟡 Parcial | 🟢 **Exitoso** | `CA037`–`CA042` en `test/features/analitica_alertas/reportes_data_test.dart` y `CA043`–`CA045` en `consumo_semanal_test.dart` |
| **CP-07** | RF-018–021 Proyecciones IA | 🟡 Parcial | 🟢 **Exitoso** | `CA046`–`CA049` en `test/features/analitica_alertas/sugerencias_compra_test.dart` |

## Detalle de las pruebas que evidencian la corrección

### CP-01 — Autorización por rol (RF-002)
- `CA030` / `CA031`: `User.esAdmin` y `rolLabel` distinguen Administrador vs Operario.
- `CA032`: el rol por defecto es `operador` (principio de mínimo privilegio).
- `CA033`: las rutas `/recetas`, `/recetas/nueva`, `/recetas/editar`, `/categorias`, `/reportes`
  se marcan como exclusivas de Admin (`esRutaSoloAdmin`).
- `CA034`: las rutas comunes (`/dashboard`, `/catalogo`, `/produccion`, `/movimientos`, `/alertas`)
  no se restringen al Operario.

### CP-04 — Justificación obligatoria (RF-012)
- `CA035` (SALIDA) y `CA036` (INGRESO): *widget tests* que pulsan «Registrar» con el campo de
  justificación vacío y verifican que el sistema **bloquea** el registro y muestra el mensaje
  «La justificación es obligatoria…».

### CP-05 — Producción y descuento de stock (RF-011 / RF-013)
- `CA028`: con stock insuficiente, `ejecutar()` **aborta** devolviendo
  «Stock insuficiente para procesar la orden. Faltan unidades del insumo requerido.»
  y **no modifica** inventario ni orden (`verifyNever`).
- `CA029`: con stock suficiente, descuenta el insumo (15 → 5 kg), registra los dos movimientos
  (salida de insumo + entrada de producto) y deja la orden en estado `completada`.

### CP-06 — Reportes y gráficos interactivos (RF-014 / RF-015 / RF-016)
- `CA037` / `CA038`: `validarRangoFechas` devuelve «Rango de fechas inválido.» con un rango
  invertido y `null` cuando es válido (RF-016).
- `CA039`: totales correctos de entradas, salidas, mermas y valor movido.
- `CA040`: los insumos del gráfico usan el **nombre real** (no el `articulo_id`) y se ordenan por
  consumo (corrige el bug previo del gráfico).
- `CA041`: la serie diaria cubre **todo el rango** con días continuos (datos para la línea de tendencia).
- `CA042`: el CSV generado incluye encabezados, nombres de insumo y valores (RF-015).
- `CA043`–`CA045`: el consumo semanal del dashboard se calcula con **datos reales** (7 días, suma
  salidas + mermas, ignora entradas y movimientos fuera de ventana) — antes eran valores fijos.

**Mejoras de UX/interactividad aplicadas (RF-014):**
- Reportes: gráfico de barras de «Insumos más consumidos» y gráfico de línea «Tendencia de consumo»,
  ambos **interactivos** (tooltip al tocar con nombre/fecha y kg), con leyenda de valores exactos y
  textos que explican qué muestran y estados vacíos claros.
- Dashboard: el gráfico «Consumo semanal» ahora usa datos reales y es interactivo (tooltip por día),
  con total del período y estado vacío explicativo.
- Exportación: botones separados **PDF** y **CSV** en la cabecera de Reportes.

### CP-07 — Sugerencias de compra y proyecciones IA (RF-018 a RF-021)
- `CA046`: Insumo A (con historial) calcula la **tasa de consumo diario** (RF-018), proyecta los
  **días restantes** hasta agotarse (RF-019) y la **cantidad sugerida a reabastecer** (RF-020).
- `CA047`: Insumo B (sin historial) se marca **`dataInsuficiente`** y se **omite la predicción** (RF-021).
- `CA048`: con menos muestras que el mínimo configurado también se considera data insuficiente.
- `CA049`: el listado ordena los insumos con proyección (más urgentes primero) y deja al final los
  que no tienen datos suficientes.

**Implementación (RF-020):** nueva vista **«Sugerencias de Compra»** (`sugerencias_compra_view.dart`)
accesible desde el botón «Ver sugerencias de compra» del Dashboard. Muestra, por insumo: stock
actual, tasa de consumo, días para agotarse y la cantidad sugerida (cobertura de 30 días); y una
sección separada **«Sin datos suficientes»** con la insignia *Data insuficiente*. El Dashboard
además muestra la **tasa de consumo** (kg/día) en cada proyección (RF-018).

## Estado del plan

Todos los casos del plan (CP-01 a CP-07) quedan en estado **Exitoso**.

## Reproducción

```bash
flutter test                 # ejecuta toda la suite (91 pruebas)
# o solo los casos del plan corregidos:
flutter test \
  test/features/auth/role_authorization_test.dart \
  test/features/registro_movimientos/justificacion_obligatoria_test.dart \
  test/features/produccion/ejecutar_produccion_test.dart \
  test/features/analitica_alertas/
```
