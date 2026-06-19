import 'package:happy_oven/core/models/enums.dart';

class Alerta {
  final String id;
  final String? articuloId;
  final TipoAlerta tipo;
  final String titulo;
  final String mensaje;
  final bool leida;
  final DateTime createdAt;

  Alerta({
    required this.id,
    this.articuloId,
    required this.tipo,
    required this.titulo,
    required this.mensaje,
    required this.leida,
    required this.createdAt,
  });

  factory Alerta.fromJson(Map<String, dynamic> json) {
    return Alerta(
      id: json['id'] as String,
      articuloId: json['articulo_id'] as String?,
      tipo: TipoAlerta.fromDb(json['tipo'] as String? ?? 'stock_bajo'),
      titulo: json['titulo'] as String,
      mensaje: json['mensaje'] as String,
      leida: json['leida'] as bool? ?? false,
      createdAt: json['created_at'] != null
          ? DateTime.parse(json['created_at'] as String)
          : DateTime.now(),
    );
  }

  Map<String, dynamic> toJson() {
    return {
      if (id.isNotEmpty) 'id': id,
      'articulo_id': articuloId,
      'tipo': tipo.dbValue,
      'titulo': titulo,
      'mensaje': mensaje,
      'leida': leida,
    };
  }
}
