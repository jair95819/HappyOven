class Perfil {
  final String id;
  final String nombreCompleto;
  final String rol;
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
      rol: json['rol'] as String,
      avatarUrl: json['avatar_url'] as String?,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'nombre_completo': nombreCompleto,
      'rol': rol,
      'avatar_url': avatarUrl,
      // created_at is usually not sent on update, but included here for completeness
      'created_at': createdAt.toIso8601String(),
    };
  }
}
