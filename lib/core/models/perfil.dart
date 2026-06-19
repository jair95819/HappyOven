import 'package:happy_oven/core/models/enums.dart';

class Perfil {
  final String id;
  final String nombreCompleto;
  final RolUsuario rol;
  final String? avatarUrl;
  final DateTime createdAt;

  Perfil({
    required this.id,
    required this.nombreCompleto,
    required this.rol,
    this.avatarUrl,
    required this.createdAt,
  });

  factory Perfil.fromJson(Map<String, dynamic> json) {
    return Perfil(
      id: json['id'] as String,
      nombreCompleto: json['nombre_completo'] as String,
      rol: RolUsuario.fromDb(json['rol'] as String? ?? 'operador'),
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'nombre_completo': nombreCompleto,
      'rol': rol.dbValue,
      'avatar_url': avatarUrl,
    };
  }
}
