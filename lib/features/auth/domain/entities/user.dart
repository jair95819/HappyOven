class User {
  final String id;
  final String nombre;
  final String email;
  final String? fotoPerfil;
  final DateTime createdAt;
  final bool activo;

  User({
    required this.id,
    required this.nombre,
    required this.email,
    this.fotoPerfil,
    required this.createdAt,
    required this.activo,
  });

  // Copiar con cambios
  User copyWith({
    String? id,
    String? nombre,
    String? email,
    String? fotoPerfil,
    DateTime? createdAt,
    bool? activo,
  }) {
    return User(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      email: email ?? this.email,
      fotoPerfil: fotoPerfil ?? this.fotoPerfil,
      createdAt: createdAt ?? this.createdAt,
      activo: activo ?? this.activo,
    );
  }
}
