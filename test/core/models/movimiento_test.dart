import 'package:flutter_test/flutter_test.dart';
import 'package:happy_oven/core/models/movimiento.dart';
import 'package:happy_oven/core/models/enums.dart';

void main() {
  // ═══════════════════════════════════════════════════════
  // CA026 — Movimiento.fromJson(Map)
  // Deserializar JSON a Movimiento
  // ═══════════════════════════════════════════════════════
  group('CA026 - Movimiento.fromJson()', () {
    test('crea Movimiento desde JSON completo', () {
      final json = {
        'id': 'm1',
        'articulo_id': 'a1',
        'usuario_id': 'u1',
        'receta_id': 'r1',
        'tipo_movimiento': 'entrada',
        'motivo_salida': null,
        'cantidad': 50.0,
        'precio_unitario': 5.0,
        'proveedor': 'Distribuidora XYZ',
        'observacion': 'Compra semanal',
        'por_ocr': true,
        'fecha': '2025-06-15T14:30:00Z',
      };

      final mov = Movimiento.fromJson(json);

      expect(mov.id, 'm1');
      expect(mov.articuloId, 'a1');
      expect(mov.usuarioId, 'u1');
      expect(mov.recetaId, 'r1');
      expect(mov.tipoMovimiento, TipoMovimiento.entrada);
      expect(mov.motivoSalida, isNull);
      expect(mov.cantidad, 50.0);
      expect(mov.precioUnitario, 5.0);
      expect(mov.proveedor, 'Distribuidora XYZ');
      expect(mov.observacion, 'Compra semanal');
      expect(mov.porOcr, true);
      expect(mov.fecha.year, 2025);
    });

    test('usa defaults para campos opcionales', () {
      final json = {
        'id': 'm2',
        'articulo_id': 'a1',
        'usuario_id': 'u1',
        'tipo_movimiento': 'salida_produccion',
        'fecha': '2025-06-15T00:00:00Z',
      };

      final mov = Movimiento.fromJson(json);

      expect(mov.cantidad, 0.0);
      expect(mov.porOcr, false);
      expect(mov.precioUnitario, isNull);
      expect(mov.proveedor, isNull);
      expect(mov.recetaId, isNull);
    });
  });

  // ═══════════════════════════════════════════════════════
  // CA027 — Movimiento.toJson()
  // Serializar Movimiento a JSON
  // ═══════════════════════════════════════════════════════
  group('CA027 - Movimiento.toJson()', () {
    test('incluye todos los campos', () {
      final mov = Movimiento(
        id: 'm1', articuloId: 'a1', usuarioId: 'u1',
        recetaId: 'r1', tipoMovimiento: TipoMovimiento.entrada,
        motivoSalida: MotivoSalida.venta, cantidad: 25,
        precioUnitario: 5.0, proveedor: 'Proveedor X',
        observacion: 'Nota', porOcr: false,
        fecha: DateTime(2025, 6, 15),
      );

      final json = mov.toJson();

      expect(json['articulo_id'], 'a1');
      expect(json['usuario_id'], 'u1');
      expect(json['receta_id'], 'r1');
      expect(json['tipo_movimiento'], 'entrada');
      expect(json['motivo_salida'], 'venta');
      expect(json['cantidad'], 25);
      expect(json['precio_unitario'], 5.0);
      expect(json['proveedor'], 'Proveedor X');
      expect(json['observacion'], 'Nota');
      expect(json['por_ocr'], false);
      expect(json['fecha'], isA<String>());
    });

    test('omite id cuando está vacío', () {
      final mov = Movimiento(
        id: '', articuloId: 'a1', usuarioId: 'u1',
        tipoMovimiento: TipoMovimiento.entrada, cantidad: 10,
        porOcr: false, fecha: DateTime(2025),
      );

      expect(mov.toJson().containsKey('id'), false);
    });

    test('fecha se serializa en formato ISO 8601', () {
      final fecha = DateTime(2025, 6, 15, 14, 30);
      final mov = Movimiento(
        id: 'm1', articuloId: 'a1', usuarioId: 'u1',
        tipoMovimiento: TipoMovimiento.entrada, cantidad: 10,
        porOcr: false, fecha: fecha,
      );

      expect(mov.toJson()['fecha'], fecha.toIso8601String());
    });
  });
}
