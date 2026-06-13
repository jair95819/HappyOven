import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/models/movimiento.dart';
import 'package:happy_oven/core/models/orden_produccion.dart';
import 'package:happy_oven/core/models/receta_ingrediente.dart';
import 'package:happy_oven/features/produccion/presentation/viewmodels/produccion_viewmodel.dart';

import '../../helpers/test_helpers.mocks.dart';

Articulo _articulo({
  required String id,
  required String tipo,
  required double stock,
  double precio = 1.0,
}) {
  return Articulo(
    id: id,
    nombre: id,
    tipo: tipo,
    unidad: 'kg',
    stockActual: stock,
    stockMinimo: 0,
    precioUnitario: precio,
    activo: true,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

OrdenProduccion _orden({int lotes = 1}) {
  return OrdenProduccion(
    id: 'orden-1',
    recetaId: 'receta-1',
    usuarioId: 'user-1',
    cantidadLotes: lotes,
    createdAt: DateTime(2026, 1, 1),
    updatedAt: DateTime(2026, 1, 1),
  );
}

void main() {
  late MockIOrdenesProduccionRepository ordenesRepo;
  late MockIMovimientosRepository movimientosRepo;
  late MockIArticulosRepository articulosRepo;
  late MockIRecetasRepository recetasRepo;
  late EjecutarProduccion sut;

  setUp(() {
    ordenesRepo = MockIOrdenesProduccionRepository();
    movimientosRepo = MockIMovimientosRepository();
    articulosRepo = MockIArticulosRepository();
    recetasRepo = MockIRecetasRepository();
    sut = EjecutarProduccion(
      ordenesRepo: ordenesRepo,
      movimientosRepo: movimientosRepo,
      articulosRepo: articulosRepo,
      recetasRepo: recetasRepo,
    );
  });

  group('EjecutarProduccion.ejecutar', () {
    test(
        'CA028 - RF-013: aborta y devuelve alerta cuando el stock es insuficiente, '
        'sin modificar inventario ni orden', () async {
      // Harina: 15kg disponibles; la orden de 2 lotes requiere 10kg x 2 = 20kg.
      when(articulosRepo.getArticuloById('harina'))
          .thenAnswer((_) async => _articulo(id: 'harina', tipo: 'insumo', stock: 15));

      final resultado = await sut.ejecutar(
        orden: _orden(lotes: 2),
        usuarioId: 'user-1',
        ingredientes: [
          RecetaIngrediente(
              id: 'i1', recetaId: 'receta-1', insumoId: 'harina', cantidadRequerida: 10),
        ],
        rendimiento: 20,
        productoId: 'pan',
      );

      expect(
        resultado,
        'Stock insuficiente para procesar la orden. '
        'Faltan unidades del insumo requerido.',
      );
      // No debe tocar la orden, ni registrar movimientos, ni modificar stock.
      verifyNever(ordenesRepo.updateOrden(any));
      verifyNever(movimientosRepo.registrarMovimiento(any));
      verifyNever(articulosRepo.updateArticulo(any));
    });

    test(
        'CA029 - RF-011: descuenta el insumo, registra el producto terminado y '
        'completa la orden cuando hay stock suficiente', () async {
      // Harina: 15kg; la orden de 1 lote requiere 10kg -> debe quedar en 5kg.
      when(articulosRepo.getArticuloById('harina'))
          .thenAnswer((_) async => _articulo(id: 'harina', tipo: 'insumo', stock: 15));
      when(articulosRepo.getArticuloById('pan'))
          .thenAnswer((_) async => _articulo(id: 'pan', tipo: 'producto_final', stock: 0));
      when(ordenesRepo.updateOrden(any))
          .thenAnswer((inv) async => inv.positionalArguments[0] as OrdenProduccion);
      when(movimientosRepo.registrarMovimiento(any))
          .thenAnswer((inv) async => inv.positionalArguments[0] as Movimiento);
      when(articulosRepo.updateArticulo(any))
          .thenAnswer((inv) async => inv.positionalArguments[0] as Articulo);

      final resultado = await sut.ejecutar(
        orden: _orden(lotes: 1),
        usuarioId: 'user-1',
        ingredientes: [
          RecetaIngrediente(
              id: 'i1', recetaId: 'receta-1', insumoId: 'harina', cantidadRequerida: 10),
        ],
        rendimiento: 20,
        productoId: 'pan',
      );

      expect(resultado, isNull);

      // El stock de harina actualizado debe ser 15 - 10 = 5.
      final capturados =
          verify(articulosRepo.updateArticulo(captureAny)).captured.cast<Articulo>();
      final harinaActualizada = capturados.firstWhere((a) => a.id == 'harina');
      expect(harinaActualizada.stockActual, 5);

      // Se registran dos movimientos (salida de insumo + entrada de producto).
      verify(movimientosRepo.registrarMovimiento(any)).called(2);
      // La orden termina en estado 'completada'.
      final ordenesActualizadas = verify(ordenesRepo.updateOrden(captureAny))
          .captured
          .cast<OrdenProduccion>();
      expect(ordenesActualizadas.last.estado, 'completada');
    });
  });
}
