import 'package:happy_oven/core/models/enums.dart';

class Movimiento {
  final String id;
  final String articuloId;
  final String usuarioId;
  final String? recetaId;
  final String? ordenProduccionId;
  final TipoMovimiento tipoMovimiento;
  final MotivoSalida? motivoSalida;
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
    this.ordenProduccionId,
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
      ordenProduccionId: json['orden_produccion_id'] as String?,
      tipoMovimiento: TipoMovimiento.fromDb(json['tipo_movimiento'] as String? ?? 'entrada'),
      motivoSalida: json['motivo_salida'] != null
          ? MotivoSalida.fromDb(json['motivo_salida'] as String)
          : null,
      cantidad: (json['cantidad'] as num?)?.toDouble() ?? 0.0,
      precioUnitario: (json['precio_unitario'] as num?)?.toDouble(),
      proveedor: json['proveedor'] as String?,
      observacion: json['observacion'] as String?,
      porOcr: json['por_ocr'] as bool? ?? false,
      fecha: DateTime.parse(json['fecha'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'articulo_id': articuloId,
      'usuario_id': usuarioId,
      'receta_id': recetaId,
      'orden_produccion_id': ordenProduccionId,
      'tipo_movimiento': tipoMovimiento.dbValue,
      'motivo_salida': motivoSalida?.dbValue,
      'cantidad': cantidad,
      'precio_unitario': precioUnitario,
      'proveedor': proveedor,
      'observacion': observacion,
      'por_ocr': porOcr,
      'fecha': fecha.toIso8601String(),
    };
  }
}
