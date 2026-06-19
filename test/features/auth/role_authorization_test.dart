import 'package:flutter_test/flutter_test.dart';
import 'package:happy_oven/core/models/enums.dart';
import 'package:happy_oven/features/auth/domain/entities/user.dart';
import 'package:happy_oven/core/router/app_router.dart';

User _user({required RolUsuario rol}) => User(
      id: 'u1',
      nombre: 'Usuario',
      email: 'u1@happyoven.com',
      rol: rol,
      createdAt: DateTime(2026, 1, 1),
      activo: true,
    );

void main() {
  group('CP-01 / RF-002 - Autorización por rol', () {
    test('CA030 - User identifica correctamente el rol Administrador', () {
      final admin = _user(rol: RolUsuario.admin);
      expect(admin.esAdmin, isTrue);
      expect(admin.rolLabel, 'Administrador');
    });

    test('CA031 - User identifica correctamente el rol Operario', () {
      final operario = _user(rol: RolUsuario.operador);
      expect(operario.esAdmin, isFalse);
      expect(operario.rolLabel, 'Operario');
    });

    test('CA032 - El rol por defecto es operador (mínimo privilegio)', () {
      final u = User(
        id: 'u2',
        nombre: 'Nuevo',
        email: 'n@happyoven.com',
        createdAt: DateTime(2026, 1, 1),
        activo: true,
      );
      expect(u.esAdmin, isFalse);
    });

    test(
        'CA033 - Las rutas de módulos exclusivos de Admin se marcan como restringidas',
        () {
      // Módulos exclusivos del Administrador (recetas, categorías, reportes).
      expect(esRutaSoloAdmin('/recetas'), isTrue);
      expect(esRutaSoloAdmin('/recetas/nueva'), isTrue);
      expect(esRutaSoloAdmin('/recetas/editar'), isTrue);
      expect(esRutaSoloAdmin('/categorias'), isTrue);
      expect(esRutaSoloAdmin('/reportes'), isTrue);
    });

    test('CA034 - Las rutas comunes NO se restringen al Operario', () {
      expect(esRutaSoloAdmin('/dashboard'), isFalse);
      expect(esRutaSoloAdmin('/catalogo'), isFalse);
      expect(esRutaSoloAdmin('/produccion'), isFalse);
      expect(esRutaSoloAdmin('/movimientos'), isFalse);
      expect(esRutaSoloAdmin('/alertas'), isFalse);
    });
  });
}
