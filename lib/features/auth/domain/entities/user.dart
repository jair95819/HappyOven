import 'package:happy_oven/core/models/enums.dart';

class User {
  final String id;
  final String nombre;
  final String email;
  final String? fotoPerfil;
  final RolUsuario rol;
  final DateTime createdAt;
  final bool activo;

  User({
    required this.id,
    required this.nombre,
    required this.email,
    this.fotoPerfil,
    this.rol = RolUsuario.operador,
    required this.createdAt,
    required this.activo,
  });

  /// Verdadero si el usuario tiene el rol de administrador.
  bool get esAdmin => rol.esAdmin;

  /// Etiqueta legible del rol para mostrar en la interfaz.
  String get rolLabel => esAdmin ? 'Administrador' : 'Operario';

  // Copiar con cambios
  User copyWith({
    String? id,
    String? nombre,
    String? email,
    String? fotoPerfil,
    RolUsuario? rol,
    DateTime? createdAt,
    bool? activo,
  }) {
    return User(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
      rol: rol ?? this.rol,
      createdAt: createdAt ?? this.createdAt,
      activo: activo ?? this.activo,
    );
  }
}
