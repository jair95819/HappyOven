class Articulo {
  final String id;
  final String nombre;
  final String? categoriaId;
  final String tipo;
  final String unidad;
  final double stockActual;
  final double stockMinimo;
  final double precioUnitario;
  final bool activo;
  final DateTime createdAt;
  final DateTime updatedAt;

  Articulo({
    required this.id,
    required this.nombre,
    this.categoriaId,
    required this.tipo,
    required this.unidad,
    required this.stockActual,
    required this.stockMinimo,
    required this.precioUnitario,
    required this.activo,
    required this.createdAt,
    required this.updatedAt,
  });

  factory Articulo.fromJson(Map<String, dynamic> json) {
    return Articulo(
      id: json['id'] as String,
      nombre: json['nombre'] as String,
      categoriaId: json['categoria_id'] as String?,
      tipo: json['tipo'] as String,
      unidad: json['unidad'] as String,
      stockActual: (json['stock_actual'] as num).toDouble(),
      stockMinimo: (json['stock_minimo'] as num).toDouble(),
      precioUnitario: (json['precio_unitario'] as num).toDouble(),
      activo: json['activo'] as bool,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'nombre': nombre,
      'categoria_id': categoriaId,
      'tipo': tipo,
      'unidad': unidad,
      'stock_actual': stockActual,
      'stock_minimo': stockMinimo,
      'precio_unitario': precioUnitario,
      'activo': activo,
    };
  }
}
