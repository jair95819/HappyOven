import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';

import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/models/movimiento.dart';
import 'package:happy_oven/features/registro_movimientos/presentation/viewmodels/ingreso_ocr_registrador.dart';

import '../../helpers/test_helpers.mocks.dart';

Articulo _articulo({
  required String id,
  required String nombre,
  double stockActual = 0,
}) =>
    Articulo(
      id: id,
      nombre: nombre,
      tipo: 'insumo',
      unidad: 'kg',
      stockActual: stockActual,
      stockMinimo: 0,
      precioUnitario: 1,
      activo: true,
      createdAt: DateTime(2026),
      updatedAt: DateTime(2026),
    );

ItemOcrIngreso _item(
  String nombre, {
  double cantidad = 5,
  String unidad = 'kg',
  double precio = 2,
}) =>
    ItemOcrIngreso(
      nombre: nombre,
      cantidad: cantidad,
      unidad: unidad,
      precioUnitario: precio,
    );

void main() {
  late MockIArticulosRepository articulos;
  late MockIMovimientosRepository movimientos;

  setUp(() {
    articulos = MockIArticulosRepository();
    movimientos = MockIMovimientosRepository();

    // Por defecto, registrar movimiento y actualizar artículo tienen éxito.
    when(movimientos.registrarMovimiento(any))
        .thenAnswer((inv) async => inv.positionalArguments.first as Movimiento);
    when(articulos.updateArticulo(any))
        .thenAnswer((inv) async => inv.positionalArguments.first as Articulo);
  });

  Future<ResultadoIngresoOcr> registrar(
    List<ItemOcrIngreso> items,
    List<Articulo> catalogo,
  ) =>
      registrarIngresoOcr(
        items: items,
        catalogo: catalogo,
        usuarioId: 'user-1',
        proveedor: 'Molinos del Norte',
        articulosRepository: articulos,
        movimientosRepository: movimientos,
      );

  group('registrarIngresoOcr() - ítem que coincide con el catálogo', () {
    test('registra el movimiento sin crear un artículo nuevo', () async {
      final catalogo = [_articulo(id: 'art-1', nombre: 'Harina de trigo')];

      final res = await registrar([_item('Harina trigo')], catalogo);

      expect(res.exitosos, 1);
      expect(res.creados, 0);
      expect(res.fallidos, 0);

      verifyNever(articulos.createArticulo(any));
      verify(movimientos.registrarMovimiento(any)).called(1);
    });

    test('actualiza el stock sumando la cantidad al existente', () async {
      final catalogo = [
        _articulo(id: 'art-1', nombre: 'Azúcar', stockActual: 10),
      ];

      await registrar([_item('Azucar', cantidad: 7)], catalogo);

      final actualizado = verify(articulos.updateArticulo(captureAny))
          .captured
          .single as Articulo;
      expect(actualizado.id, 'art-1');
      expect(actualizado.stockActual, 17); // 10 existentes + 7 ingresados
    });
  });

  group('registrarIngresoOcr() - ítem que NO coincide con el catálogo', () {
    test('crea un insumo nuevo en lugar de descartar la línea', () async {
      final catalogo = [_articulo(id: 'art-1', nombre: 'Harina de trigo')];

      when(articulos.createArticulo(any)).thenAnswer(
        (inv) async {
          final a = inv.positionalArguments.first as Articulo;
          return _articulo(id: 'art-nuevo', nombre: a.nombre);
        },
      );

      final res = await registrar(
        [_item('Chocolate amargo', cantidad: 3, precio: 8)],
        catalogo,
      );

      expect(res.exitosos, 1);
      expect(res.creados, 1);
      expect(res.fallidos, 0);

      // Se creó el insumo con los datos detectados (tipo insumo, stock inicial 0).
      final creado = verify(articulos.createArticulo(captureAny))
          .captured
          .single as Articulo;
      expect(creado.nombre, 'Chocolate amargo');
      expect(creado.tipo, 'insumo');
      expect(creado.stockActual, 0);

      // El movimiento de entrada usa el ID asignado por la BD al insumo nuevo.
      final mov = verify(movimientos.registrarMovimiento(captureAny))
          .captured
          .single as Movimiento;
      expect(mov.articuloId, 'art-nuevo');
      expect(mov.cantidad, 3);
      expect(mov.porOcr, isTrue);

      // El stock del insumo nuevo queda en la cantidad ingresada.
      final stockFinal = verify(articulos.updateArticulo(captureAny))
          .captured
          .single as Articulo;
      expect(stockFinal.stockActual, 3);
    });

    test('cuenta como fallido si la creación del insumo lanza error', () async {
      when(articulos.createArticulo(any)).thenThrow(Exception('db error'));

      final res = await registrar([_item('Producto raro')], const []);

      expect(res.exitosos, 0);
      expect(res.creados, 0);
      expect(res.fallidos, 1);
      verifyNever(movimientos.registrarMovimiento(any));
    });

    test('no duplica el insumo cuando dos líneas tienen el mismo nombre nuevo',
        () async {
      var contador = 0;
      when(articulos.createArticulo(any)).thenAnswer((inv) async {
        contador++;
        final a = inv.positionalArguments.first as Articulo;
        return _articulo(id: 'art-nuevo-$contador', nombre: a.nombre);
      });

      final res = await registrar(
        [_item('Esencia de vainilla'), _item('Esencia vainilla')],
        const [],
      );

      expect(res.exitosos, 2);
      // Solo se crea una vez; la segunda línea reutiliza el insumo recién creado.
      expect(res.creados, 1);
      verify(articulos.createArticulo(any)).called(1);
    });
  });

  group('registrarIngresoOcr() - boleta mixta', () {
    test('combina coincidencias, creaciones y fallos en el resumen', () async {
      final catalogo = [_articulo(id: 'art-1', nombre: 'Harina de trigo')];

      // Crear "Mantequilla" funciona; crear "Levadura" falla.
      when(articulos.createArticulo(any)).thenAnswer((inv) async {
        final a = inv.positionalArguments.first as Articulo;
        if (a.nombre == 'Levadura') throw Exception('db error');
        return _articulo(id: 'art-mant', nombre: a.nombre);
      });

      final res = await registrar(
        [_item('Harina trigo'), _item('Mantequilla'), _item('Levadura')],
        catalogo,
      );

      expect(res.exitosos, 2); // Harina (match) + Mantequilla (creada)
      expect(res.creados, 1); // Mantequilla
      expect(res.fallidos, 1); // Levadura
    });

    test('un error al registrar el movimiento cuenta como fallido', () async {
      final catalogo = [_articulo(id: 'art-1', nombre: 'Harina de trigo')];
      when(movimientos.registrarMovimiento(any))
          .thenThrow(Exception('db error'));

      final res = await registrar([_item('Harina trigo')], catalogo);

      expect(res.exitosos, 0);
      expect(res.fallidos, 1);
    });
  });

  test('no muta la lista de catálogo recibida al crear insumos', () async {
    when(articulos.createArticulo(any)).thenAnswer((inv) async {
      final a = inv.positionalArguments.first as Articulo;
      return _articulo(id: 'art-nuevo', nombre: a.nombre);
    });

    final catalogo = [_articulo(id: 'art-1', nombre: 'Harina de trigo')];

    await registrar([_item('Nuevo insumo')], catalogo);

    expect(catalogo.length, 1); // la copia interna no afecta al original
  });
}
