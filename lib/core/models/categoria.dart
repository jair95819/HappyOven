import 'package:happy_oven/core/models/enums.dart';

class Categoria {
  final String id;
  final String nombre;
  final TipoArticulo tipo;
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
      tipo: TipoArticulo.fromDb(json['tipo'] as String? ?? 'insumo'),
      orden: (json['orden'] as num?)?.toInt() ?? 0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'nombre': nombre,
      'tipo': tipo.dbValue,
      'orden': orden,
    };
  }
}
