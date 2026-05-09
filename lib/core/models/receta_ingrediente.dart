class RecetaIngrediente {
  final String id;
  final String recetaId;
  final String articuloId;
  final double cantidad;
  final String unidad;

  RecetaIngrediente({
    required this.id,
    required this.recetaId,
    required this.articuloId,
    required this.cantidad,
    required this.unidad,
  });

  factory RecetaIngrediente.fromJson(Map<String, dynamic> json) {
    return RecetaIngrediente(
      id: json['id'] as String,
      recetaId: json['receta_id'] as String,
      articuloId: json['articulo_id'] as String,
      cantidad: (json['cantidad'] as num).toDouble(),
      unidad: json['unidad'] as String,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'receta_id': recetaId,
      'articulo_id': articuloId,
      'cantidad': cantidad,
      'unidad': unidad,
    };
  }
}
