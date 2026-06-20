import 'package:happy_oven/core/models/enums.dart';

class Articulo {
  final String id;
  final String nombre;
  final String? categoriaId;
  final TipoArticulo tipo;
  final UnidadMedida unidad;
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
      tipo: TipoArticulo.fromDb(json['tipo'] as String? ?? 'insumo'),
      unidad: UnidadMedida.fromDb(json['unidad'] as String? ?? 'unidades'),
      stockActual: (json['stock_actual'] as num?)?.toDouble() ?? 0.0,
      stockMinimo: (json['stock_minimo'] as num?)?.toDouble() ?? 0.0,
      precioUnitario: (json['precio_unitario'] as num?)?.toDouble() ?? 0.0,
      activo: json['activo'] as bool? ?? true,
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
      'categoria_id': categoriaId,
      'tipo': tipo.dbValue,
      'unidad': unidad.dbValue,
      'stock_actual': stockActual,
      'stock_minimo': stockMinimo,
      'precio_unitario': precioUnitario,
      'activo': activo,
    };
  }

  Articulo copyWith({
    String? id,
    String? nombre,
    String? categoriaId,
    TipoArticulo? tipo,
    UnidadMedida? unidad,
    double? stockActual,
    double? stockMinimo,
    double? precioUnitario,
    bool? activo,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return Articulo(
      id: id ?? this.id,
      nombre: nombre ?? this.nombre,
      categoriaId: categoriaId ?? this.categoriaId,
      tipo: tipo ?? this.tipo,
      unidad: unidad ?? this.unidad,
      stockActual: stockActual ?? this.stockActual,
      stockMinimo: stockMinimo ?? this.stockMinimo,
      precioUnitario: precioUnitario ?? this.precioUnitario,
      activo: activo ?? this.activo,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

