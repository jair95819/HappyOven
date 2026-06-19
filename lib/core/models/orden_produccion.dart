import 'package:happy_oven/core/models/enums.dart';

class OrdenProduccion {
  final String id;
  final String recetaId;
  final String usuarioId;
  final int cantidadLotes;
  final int cantidadProducida;
  final EstadoOrden estado;
  final DateTime? fechaProgramada;
  final DateTime? fechaInicio;
  final DateTime? fechaFin;
  final String? notas;
  final DateTime createdAt;
  final DateTime updatedAt;

  OrdenProduccion({
    required this.id,
    required this.recetaId,
    required this.usuarioId,
    required this.cantidadLotes,
    this.cantidadProducida = 0,
    this.estado = EstadoOrden.pendiente,
    this.fechaProgramada,
    this.fechaInicio,
    this.fechaFin,
    this.notas,
    required this.createdAt,
    required this.updatedAt,
  });

  factory OrdenProduccion.fromJson(Map<String, dynamic> json) {
    return OrdenProduccion(
      id: json['id'] as String,
      recetaId: json['receta_id'] as String,
      usuarioId: json['usuario_id'] as String,
      cantidadLotes: (json['cantidad_lotes'] as num?)?.toInt() ?? 1,
      cantidadProducida: (json['cantidad_producida'] as num?)?.toInt() ?? 0,
      estado: EstadoOrden.fromDb(json['estado'] as String? ?? 'pendiente'),
      fechaProgramada: json['fecha_programada'] != null
          ? DateTime.parse(json['fecha_programada'] as String)
          : null,
      fechaInicio: json['fecha_inicio'] != null
          ? DateTime.parse(json['fecha_inicio'] as String)
          : null,
      fechaFin: json['fecha_fin'] != null
          ? DateTime.parse(json['fecha_fin'] as String)
          : null,
      notas: json['notas'] as String?,
      createdAt: DateTime.parse(json['created_at'] as String),
      updatedAt: DateTime.parse(json['updated_at'] as String),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'receta_id': recetaId,
      'usuario_id': usuarioId,
      'cantidad_lotes': cantidadLotes,
      'cantidad_producida': cantidadProducida,
      'estado': estado.dbValue,
      'fecha_programada': fechaProgramada?.toIso8601String(),
      'fecha_inicio': fechaInicio?.toIso8601String(),
      'fecha_fin': fechaFin?.toIso8601String(),
      'notas': notas,
    };
  }
}
