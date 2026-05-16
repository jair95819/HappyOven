class Movimiento {
  final String id;
  final String articuloId;
  final String usuarioId;
  final String? recetaId;
  final String tipoMovimiento;
  final String? motivoSalida;
  final double cantidad;
  final double? precioUnitario;
  final String? proveedor;
  final String? observacion;
  final bool porOcr;
  final DateTime fecha;

  Movimiento({
    required this.id,
    required this.articuloId,
    required this.usuarioId,
    this.recetaId,
    required this.tipoMovimiento,
    this.motivoSalida,
    required this.cantidad,
    this.precioUnitario,
    this.proveedor,
    this.observacion,
    required this.porOcr,
    required this.fecha,
  });

  factory Movimiento.fromJson(Map<String, dynamic> json) {
    return Movimiento(
      id: json['id'] as String,
      articuloId: json['articulo_id'] as String,
      usuarioId: json['usuario_id'] as String,
      recetaId: json['receta_id'] as String?,
      tipoMovimiento: json['tipo_movimiento'] as String,
      motivoSalida: json['motivo_salida'] as String?,
      cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0.0,
      precioUnitario: (json['precio_unitario'] as num?)?.toDouble(),
      proveedor: json['proveedor'] as String?,
      observacion: json['observacion'] as String?,
      porOcr: json['por_ocr'] as bool,
      fecha: DateTime.parse(json['fecha'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'articulo_id': articuloId,
      'usuario_id': usuarioId,
      'receta_id': recetaId,
      'tipo_movimiento': tipoMovimiento,
      'motivo_salida': motivoSalida,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'proveedor': proveedor,
      'observacion': observacion,
      'por_ocr': porOcr,
      // la base de datos normalmente genera la fecha por defecto si no se manda,
      // pero si es un registro manual con fecha específica, se envía
      'fecha': fecha.toIso8601String(),
    };
  }
}
