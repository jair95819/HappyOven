class Categoria {
  final String id;
  final String nombre;
  final String tipo;
  final int orden;
  final DateTime createdAt;

  Categoria({
    required this.id,
    required this.nombre,
    required this.tipo,
    required this.orden,
    required this.createdAt,
  });

  factory Categoria.fromJson(Map<String, dynamic> json) {
    return Categoria(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      tipo: json['tipo'] as String,
      orden: json['orden'] as int,
      createdAt: DateTime.parse(json['created_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'nombre': nombre,
      'tipo': tipo,
      'orden': orden,
    };
  }
}
