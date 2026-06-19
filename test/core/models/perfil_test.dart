import 'package:flutter_test/flutter_test.dart';
import 'package:happy_oven/core/models/enums.dart';
import 'package:happy_oven/core/models/perfil.dart';

void main() {
  group('Perfil model', () {
    test('fromJson parsea correctamente todos los campos', () {
      final json = {
        'id': 'p1',
        'nombre_completo': 'Juan Pérez',
        'rol': 'admin',
        'avatar_url': 'https://example.com/avatar.png',
        'created_at': '2026-06-01T10:00:00.000Z',
      };
      final perfil = Perfil.fromJson(json);
      expect(perfil.id, 'p1');
      expect(perfil.nombreCompleto, 'Juan Pérez');
      expect(perfil.rol, RolUsuario.admin);
      expect(perfil.avatarUrl, 'https://example.com/avatar.png');
      expect(perfil.createdAt, DateTime.utc(2026, 6, 1, 10, 0, 0));
    });

    test('fromJson parsea rol operador', () {
      final json = {
        'id': 'p2',
        'nombre_completo': 'Ana López',
        'rol': 'operador',
        'created_at': '2026-06-01T10:00:00.000Z',
      };
      final perfil = Perfil.fromJson(json);
      expect(perfil.rol, RolUsuario.operador);
    });

    test('fromJson usa operador como rol por defecto', () {
      final json = {
        'id': 'p3',
        'nombre_completo': 'Test',
        'rol': 'rol_desconocido',
        'created_at': '2026-06-01T10:00:00.000Z',
      };
      final perfil = Perfil.fromJson(json);
      expect(perfil.rol, RolUsuario.operador);
    });

    test('fromJson maneja avatar_url null', () {
      final json = {
        'id': 'p4',
        'nombre_completo': 'Sin Avatar',
        'rol': 'operador',
        'created_at': '2026-06-01T10:00:00.000Z',
      };
      final perfil = Perfil.fromJson(json);
      expect(perfil.avatarUrl, isNull);
    });

    test('toJson serializa correctamente (sin created_at)', () {
      final perfil = Perfil(
        id: 'p1',
        nombreCompleto: 'Juan Pérez',
        rol: RolUsuario.admin,
        avatarUrl: 'https://example.com/avatar.png',
        createdAt: DateTime.utc(2026, 6, 1, 10, 0, 0),
      );
      final json = perfil.toJson();
      expect(json['id'], 'p1');
      expect(json['nombre_completo'], 'Juan Pérez');
      expect(json['rol'], 'admin');
      expect(json['avatar_url'], 'https://example.com/avatar.png');
      expect(json.containsKey('created_at'), false);
    });

    test('toJson omite id si está vacío', () {
      final perfil = Perfil(
        id: '',
        nombreCompleto: 'Nuevo Usuario',
        rol: RolUsuario.operador,
        createdAt: DateTime.now(),
      );
      final json = perfil.toJson();
      expect(json.containsKey('id'), false);
    });

    test('toJson maneja avatar_url null', () {
      final perfil = Perfil(
        id: 'p2',
        nombreCompleto: 'Sin Foto',
        rol: RolUsuario.operador,
        createdAt: DateTime.now(),
      );
      final json = perfil.toJson();
      expect(json['avatar_url'], null);
    });

    test('fromJson maneja created_at null', () {
      final json = {
        'id': 'p5',
        'nombre_completo': 'Test',
        'rol': 'operador',
      };
      final perfil = Perfil.fromJson(json);
      expect(perfil.createdAt, isA<DateTime>());
    });
  });
}
