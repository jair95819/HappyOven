class Receta {
  final String id;
  final String nombre;
  final String? productoId; // Artículo de tipo 'producto_final' que produce esta receta
  final String? instrucciones;
  final double rendimiento; // Cantidad de unidades que produce un lote
  final DateTime createdAt;

  Receta({
    required this.id,
    required this.nombre,
    this.productoId,
    this.instrucciones,
    required this.rendimiento,
    required this.createdAt,
  });

  factory Receta.fromJson(Map<String, dynamic> json) {
    return Receta(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      productoId: json['producto_id'] as String? ?? json['articulo_id'] as String?,
      instrucciones: json['instrucciones'] as String? ?? json['preparacion'] as String?,
      rendimiento: (json['rendimiento_unidades'] as num).toDouble(),
      createdAt: json['created_at'] != null ? DateTime.parse(json['created_at'] as String) : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'nombre': nombre,
      'producto_id': productoId,
      'rendimiento_unidades': rendimiento.toInt(),
    };
  }
}
