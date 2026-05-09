class Receta {
  final String id;
  final String nombre;
  final int rendimientoUnidades;
  final int tiempoProduccionMin;
  final double costoLote;
  final DateTime createdAt;
  final DateTime updatedAt;

  Receta({
    required this.id,
    required this.nombre,
    required this.rendimientoUnidades,
    required this.tiempoProduccionMin,
    required this.costoLote,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Receta.fromJson(Map<String, dynamic> json) {
    return Receta(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      rendimientoUnidades: json['rendimiento_unidades'] as int,
      tiempoProduccionMin: json['tiempo_produccion_min'] as int,
      costoLote: (json['costo_lote'] as num).toDouble(),
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'nombre': nombre,
      'rendimiento_unidades': rendimientoUnidades,
      'tiempo_produccion_min': tiempoProduccionMin,
      'costo_lote': costoLote,
    };
  }
}
