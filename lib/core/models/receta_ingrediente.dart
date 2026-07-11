class RecetaIngrediente {
  final String id;
  final String recetaId;
  final String insumoId; // referencia a articulos.id
  final double cantidadRequerida;
  final String unidad;

  RecetaIngrediente({
    required this.id,
    required this.recetaId,
    required this.insumoId,
    required this.cantidadRequerida,
    this.unidad = 'gr',
  });

  factory RecetaIngrediente.fromJson(Map<String, dynamic> json) {
    return RecetaIngrediente(
      id: json['id'] as String,
      recetaId: json['receta_id'] as String,
      insumoId: json['insumo_id'] as String,
      cantidadRequerida: (json['cantidad_requerida'] as num?)?.toDouble() ?? 0.0,
      unidad: json['unidad'] as String? ?? 'gr',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'receta_id': recetaId,
      'insumo_id': insumoId,
      'cantidad_requerida': cantidadRequerida,
      'unidad': unidad,
    };
  }
}
