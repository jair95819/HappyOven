class RecetaIngrediente {
  final String id;
  final String recetaId;
  final String insumoId; // referencia a articulos.id
  final double cantidadRequerida;

  RecetaIngrediente({
    required this.id,
    required this.recetaId,
    required this.insumoId,
    required this.cantidadRequerida,
  });

  factory RecetaIngrediente.fromJson(Map<String, dynamic> json) {
    return RecetaIngrediente(
      id: json['id'] as String,
      recetaId: json['receta_id'] as String,
      insumoId: json['articulo_id'] as String,
      cantidadRequerida: (json['cantidad'] as num).toDouble(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'receta_id': recetaId,
      'articulo_id': insumoId,
      'cantidad': cantidadRequerida,
    };
  }
}
