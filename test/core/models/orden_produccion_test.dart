import 'package:flutter_test/flutter_test.dart';
import 'package:happy_oven/core/models/enums.dart';
import 'package:happy_oven/core/models/orden_produccion.dart';

void main() {
  group('OrdenProduccion model', () {
    test('fromJson parsea correctamente todos los campos', () {
      final json = {
        'id': 'op1',
        'receta_id': 'rec1',
        'usuario_id': 'u1',
        'cantidad_lotes': 5,
        'cantidad_producida': 0,
        'estado': 'pendiente',
        'fecha_programada': '2026-06-15T08:00:00.000Z',
        'fecha_inicio': null,
        'fecha_fin': null,
        'notas': 'Preparar con anticipación',
        'created_at': '2026-06-10T10:00:00.000Z',
        'updated_at': '2026-06-10T10:00:00.000Z',
      };
      final orden = OrdenProduccion.fromJson(json);
      expect(orden.id, 'op1');
      expect(orden.recetaId, 'rec1');
      expect(orden.usuarioId, 'u1');
      expect(orden.cantidadLotes, 5);
      expect(orden.cantidadProducida, 0);
      expect(orden.estado, EstadoOrden.pendiente);
      expect(orden.fechaProgramada, DateTime.utc(2026, 6, 15, 8, 0, 0));
      expect(orden.fechaInicio, isNull);
      expect(orden.fechaFin, isNull);
      expect(orden.notas, 'Preparar con anticipación');
    });

    test('fromJson parsea estado en_proceso', () {
      final json = {
        'id': 'op2',
        'receta_id': 'rec1',
        'usuario_id': 'u1',
        'cantidad_lotes': 3,
        'cantidad_producida': 0,
        'estado': 'en_proceso',
        'created_at': '2026-06-10T10:00:00.000Z',
        'updated_at': '2026-06-10T10:00:00.000Z',
      };
      final orden = OrdenProduccion.fromJson(json);
      expect(orden.estado, EstadoOrden.enProceso);
    });

    test('fromJson parsea estado completada', () {
      final json = {
        'id': 'op3',
        'receta_id': 'rec1',
        'usuario_id': 'u1',
        'cantidad_lotes': 2,
        'cantidad_producida': 24,
        'estado': 'completada',
        'fecha_inicio': '2026-06-11T08:00:00.000Z',
        'fecha_fin': '2026-06-11T10:30:00.000Z',
        'created_at': '2026-06-10T10:00:00.000Z',
        'updated_at': '2026-06-11T10:30:00.000Z',
      };
      final orden = OrdenProduccion.fromJson(json);
      expect(orden.estado, EstadoOrden.completada);
      expect(orden.cantidadProducida, 24);
      expect(orden.fechaInicio, DateTime.utc(2026, 6, 11, 8, 0, 0));
      expect(orden.fechaFin, DateTime.utc(2026, 6, 11, 10, 30, 0));
    });

    test('fromJson usa safeCast para cantidad_lotes (num → int)', () {
      final json = {
        'id': 'op4',
        'receta_id': 'rec1',
        'usuario_id': 'u1',
        'cantidad_lotes': 2.0,
        'cantidad_producida': 0,
        'estado': 'pendiente',
        'created_at': '2026-06-10T10:00:00.000Z',
        'updated_at': '2026-06-10T10:00:00.000Z',
      };
      final orden = OrdenProduccion.fromJson(json);
      expect(orden.cantidadLotes, 2);
    });

    test('toJson serializa correctamente', () {
      final orden = OrdenProduccion(
        id: 'op1',
        recetaId: 'rec1',
        usuarioId: 'u1',
        cantidadLotes: 5,
        cantidadProducida: 0,
        estado: EstadoOrden.pendiente,
        fechaProgramada: DateTime.utc(2026, 6, 15, 8, 0, 0),
        notas: 'Preparar con anticipación',
        createdAt: DateTime.utc(2026, 6, 10, 10, 0, 0),
        updatedAt: DateTime.utc(2026, 6, 10, 10, 0, 0),
      );
      final json = orden.toJson();
      expect(json['id'], 'op1');
      expect(json['receta_id'], 'rec1');
      expect(json['usuario_id'], 'u1');
      expect(json['cantidad_lotes'], 5);
      expect(json['cantidad_producida'], 0);
      expect(json['estado'], 'pendiente');
      expect(json['fecha_programada'], '2026-06-15T08:00:00.000Z');
      expect(json['notas'], 'Preparar con anticipación');
      expect(json.containsKey('fecha_inicio'), true);
      expect(json['fecha_inicio'], null);
    });

    test('toJson omite id si está vacío', () {
      final orden = OrdenProduccion(
        id: '',
        recetaId: 'rec1',
        usuarioId: 'u1',
        cantidadLotes: 1,
        estado: EstadoOrden.pendiente,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      final json = orden.toJson();
      expect(json.containsKey('id'), false);
    });

    test('estado por defecto es pendiente', () {
      final orden = OrdenProduccion(
        id: 'op5',
        recetaId: 'rec1',
        usuarioId: 'u1',
        cantidadLotes: 1,
        createdAt: DateTime.now(),
        updatedAt: DateTime.now(),
      );
      expect(orden.estado, EstadoOrden.pendiente);
    });

    test('fromJson usa estado por defecto pendiente si es null', () {
      final json = {
        'id': 'op6',
        'receta_id': 'rec1',
        'usuario_id': 'u1',
        'cantidad_lotes': 1,
        'created_at': '2026-06-10T10:00:00.000Z',
        'updated_at': '2026-06-10T10:00:00.000Z',
      };
      final orden = OrdenProduccion.fromJson(json);
      expect(orden.estado, EstadoOrden.pendiente);
    });
  });
}
