enum TipoArticulo {
  insumo,
  productoFinal;

  String get dbValue {
    switch (this) {
      case TipoArticulo.productoFinal:
        return 'producto_final';
      default:
        return name;
    }
  }

  static TipoArticulo fromDb(String value) {
    switch (value) {
      case 'producto_final':
        return TipoArticulo.productoFinal;
      case 'insumo':
        return TipoArticulo.insumo;
      default:
        return TipoArticulo.insumo;
    }
  }
}

enum TipoMovimiento {
  entrada,
  salidaProduccion,
  merma,
  ajuste;

  String get dbValue {
    switch (this) {
      case TipoMovimiento.salidaProduccion:
        return 'salida_produccion';
      default:
        return name;
    }
  }

  static TipoMovimiento fromDb(String value) {
    switch (value) {
      case 'salida_produccion':
        return TipoMovimiento.salidaProduccion;
      case 'entrada':
        return TipoMovimiento.entrada;
      case 'merma':
        return TipoMovimiento.merma;
      case 'ajuste':
        return TipoMovimiento.ajuste;
      default:
        return TipoMovimiento.entrada;
    }
  }
}

enum MotivoSalida {
  venta,
  merma,
  degustacion,
  ajuste;

  String get dbValue => name;
  static MotivoSalida fromDb(String value) {
    return MotivoSalida.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => MotivoSalida.venta,
    );
  }
}

enum TipoAlerta {
  stockBajo,
  anomalia,
  ia,
  ingreso;

  String get dbValue {
    switch (this) {
      case TipoAlerta.stockBajo:
        return 'stock_bajo';
      default:
        return name;
    }
  }

  static TipoAlerta fromDb(String value) {
    switch (value) {
      case 'stock_bajo':
        return TipoAlerta.stockBajo;
      case 'anomalia':
        return TipoAlerta.anomalia;
      case 'ia':
        return TipoAlerta.ia;
      case 'ingreso':
        return TipoAlerta.ingreso;
      default:
        return TipoAlerta.stockBajo;
    }
  }
}

enum UnidadMedida {
  kg,
  litros,
  unidades,
  gramos,
  ml;

  String get dbValue => name;
  static UnidadMedida fromDb(String value) {
    return UnidadMedida.values.firstWhere(
      (e) => e.dbValue == value,
      orElse: () => UnidadMedida.unidades,
    );
  }

  static List<String> get valores => UnidadMedida.values.map((e) => e.dbValue).toList();
}