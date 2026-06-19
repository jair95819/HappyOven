class Receta {
  final String id;
  final String nombre;
  final String? productoId;
  final String? instrucciones;
  final double rendimiento;
  final int tiempoProduccionMin;
  final double costoLote;
  final DateTime createdAt;
  final DateTime updatedAt;

  Receta({
    required this.id,
    required this.nombre,
    this.productoId,
    this.instrucciones,
    required this.rendimiento,
    this.tiempoProduccionMin = 60,
    this.costoLote = 0.0,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Receta.fromJson(Map<String, dynamic> json) {
    return Receta(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      productoId:
          json['producto_id'] as String? ?? json['articulo_id'] as String?,
      instrucciones:
          json['instrucciones'] as String? ?? json['preparacion'] as String?,
      rendimiento: (json['rendimiento_unidades'] as num?)?.toDouble() ?? 0.0,
      tiempoProduccionMin: (json['tiempo_produccion_min'] as num?)?.toInt() ?? 60,
      costoLote: (json['costo_lote'] as num?)?.toDouble() ?? 0.0,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
      updatedAt: json['updated_at'] != null
          ? DateTime.parse(json['updated_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'nombre': nombre,
      'producto_id': productoId,
      'instrucciones': instrucciones,
      'rendimiento_unidades': rendimiento.toInt(),
      'tiempo_produccion_min': tiempoProduccionMin,
      'costo_lote': costoLote,
    };
  }
}
