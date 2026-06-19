import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/models/orden_produccion.dart';
import 'package:happy_oven/core/models/movimiento.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/models/enums.dart';
import 'package:happy_oven/core/models/receta_ingrediente.dart';
import 'package:happy_oven/core/repositories/ordenes_produccion_repository.dart';
import 'package:happy_oven/core/repositories/i_ordenes_produccion_repository.dart';
import 'package:happy_oven/core/repositories/i_movimientos_repository.dart';
import 'package:happy_oven/core/repositories/i_articulos_repository.dart';
import 'package:happy_oven/core/repositories/i_recetas_repository.dart';
import 'package:happy_oven/core/providers.dart';

final ordenesProduccionProvider =
    StateNotifierProvider<OrdenesProduccionViewModel, AsyncValue<List<OrdenProduccion>>>((ref) {
      return OrdenesProduccionViewModel(
        ref.watch(ordenesProduccionRepositoryProvider),
      );
    });

class OrdenesProduccionViewModel extends StateNotifier<AsyncValue<List<OrdenProduccion>>> {
  final OrdenesProduccionRepository _repository;

  OrdenesProduccionViewModel(this._repository) : super(const AsyncLoading()) {
    cargarOrdenes();
  }

  Future<void> cargarOrdenes() async {
    try {
      state = const AsyncLoading();
      final ordenes = await _repository.getOrdenes();
      state = AsyncData(ordenes);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<String?> crearOrden(OrdenProduccion orden) async {
    try {
      await _repository.createOrden(orden);
      await cargarOrdenes();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> actualizarOrden(OrdenProduccion orden) async {
    try {
      await _repository.updateOrden(orden);
      await cargarOrdenes();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<bool> eliminarOrden(String id) async {
    try {
      await _repository.deleteOrden(id);
      await cargarOrdenes();
      return true;
    } catch (e) {
      return false;
    }
  }
}

// Provider para ejecutar producción (flujo transaccional)
final ejecutarProduccionProvider = Provider<EjecutarProduccion>((ref) {
  return EjecutarProduccion(
    ordenesRepo: ref.watch(ordenesProduccionRepositoryProvider),
    movimientosRepo: ref.watch(movimientosRepositoryProvider),
    articulosRepo: ref.watch(articulosRepositoryProvider),
    recetasRepo: ref.watch(recetasRepositoryProvider),
  );
});

class EjecutarProduccion {
  final IOrdenesProduccionRepository _ordenesRepo;
  final IMovimientosRepository _movimientosRepo;
  final IArticulosRepository _articulosRepo;
  final IRecetasRepository _recetasRepo;

  EjecutarProduccion({
    required IOrdenesProduccionRepository ordenesRepo,
    required IMovimientosRepository movimientosRepo,
    required IArticulosRepository articulosRepo,
    required IRecetasRepository recetasRepo,
  })  : _ordenesRepo = ordenesRepo,
        _movimientosRepo = movimientosRepo,
        _articulosRepo = articulosRepo,
        _recetasRepo = recetasRepo;

  /// Ejecuta una orden de producción:
  /// 1. Descuenta insumos del stock
  /// 2. Aumenta stock del producto terminado
  /// 3. Registra movimientos en el Kardex
  /// 4. Marca orden como completada
  Future<String?> ejecutar({
    required OrdenProduccion orden,
    required String usuarioId,
    required List<RecetaIngrediente> ingredientes,
    required double rendimiento,
    required String productoId,
  }) async {
    try {
      // 0. Validar stock suficiente ANTES de aplicar cualquier cambio (RF-013).
      //    Si algún insumo no alcanza, se aborta la operación sin tocar el stock.
      for (final ing in ingredientes) {
        final insumo = await _articulosRepo.getArticuloById(ing.insumoId);
        if (insumo == null) continue;

        final requerido = ing.cantidadRequerida * orden.cantidadLotes;
        if (insumo.stockActual < requerido) {
          return 'Stock insuficiente para procesar la orden. '
              'Faltan unidades del insumo requerido.';
        }
      }

      // Marcar como en_proceso
      await _ordenesRepo.updateOrden(orden.copyWith(estado: EstadoOrden.enProceso));

      // 1. Descontar insumos
      for (final ing in ingredientes) {
        final insumo = await _articulosRepo.getArticuloById(ing.insumoId);
        if (insumo == null) continue;

        final cantidadConsumir = ing.cantidadRequerida * orden.cantidadLotes;
        final nuevoStock = insumo.stockActual - cantidadConsumir;

        final movimiento = Movimiento(
          id: '',
          articuloId: ing.insumoId,
          usuarioId: usuarioId,
          recetaId: orden.recetaId,
          ordenProduccionId: orden.id,
          tipoMovimiento: TipoMovimiento.salidaProduccion,
          cantidad: cantidadConsumir,
          precioUnitario: insumo.precioUnitario,
          observacion: 'Consumo por producción: ${orden.cantidadLotes} lote(s)',
          porOcr: false,
          fecha: DateTime.now(),
        );
        await _movimientosRepo.registrarMovimiento(movimiento);

        await _articulosRepo.updateArticulo(Articulo(
          id: insumo.id,
          nombre: insumo.nombre,
          categoriaId: insumo.categoriaId,
          tipo: insumo.tipo,
          unidad: insumo.unidad,
          stockActual: nuevoStock,
          stockMinimo: insumo.stockMinimo,
          precioUnitario: insumo.precioUnitario,
          activo: insumo.activo,
          createdAt: insumo.createdAt,
          updatedAt: DateTime.now(),
        ));
      }

      // 2. Aumentar stock del producto terminado
      final producto = await _articulosRepo.getArticuloById(productoId);
      if (producto != null) {
        final cantidadProducida = (rendimiento * orden.cantidadLotes).toInt();
        final nuevoStock = producto.stockActual + cantidadProducida;

        final movimiento = Movimiento(
          id: '',
          articuloId: productoId,
          usuarioId: usuarioId,
          recetaId: orden.recetaId,
          ordenProduccionId: orden.id,
          tipoMovimiento: TipoMovimiento.entrada,
          cantidad: cantidadProducida.toDouble(),
          precioUnitario: producto.precioUnitario,
          observacion: 'Producción completada: ${orden.cantidadLotes} lote(s)',
          porOcr: false,
          fecha: DateTime.now(),
        );
        await _movimientosRepo.registrarMovimiento(movimiento);

        await _articulosRepo.updateArticulo(Articulo(
          id: producto.id,
          nombre: producto.nombre,
          categoriaId: producto.categoriaId,
          tipo: producto.tipo,
          unidad: producto.unidad,
          stockActual: nuevoStock,
          stockMinimo: producto.stockMinimo,
          precioUnitario: producto.precioUnitario,
          activo: producto.activo,
          createdAt: producto.createdAt,
          updatedAt: DateTime.now(),
        ));

        // 3. Marcar orden como completada
        final unidadesProducidas = (rendimiento * orden.cantidadLotes).toInt();
        await _ordenesRepo.updateOrden(OrdenProduccion(
          id: orden.id,
          recetaId: orden.recetaId,
          usuarioId: orden.usuarioId,
          cantidadLotes: orden.cantidadLotes,
          cantidadProducida: unidadesProducidas,
          estado: EstadoOrden.completada,
          fechaProgramada: orden.fechaProgramada,
          fechaInicio: orden.fechaInicio ?? DateTime.now(),
          fechaFin: DateTime.now(),
          notas: orden.notas,
          createdAt: orden.createdAt,
          updatedAt: DateTime.now(),
        ));
      }

      return null;
    } catch (e) {
      // Revertir a pendiente si falla
      try {
        await _ordenesRepo.updateOrden(orden.copyWith(estado: EstadoOrden.pendiente));
      } catch (_) {}
      return e.toString();
    }
  }

  /// Carga la receta y sus ingredientes a partir de la [orden] y ejecuta el
  /// flujo de producción. Devuelve null si todo fue correcto, o un mensaje de
  /// error/validación (p. ej. stock insuficiente) en caso contrario.
  Future<String?> ejecutarOrden({
    required OrdenProduccion orden,
    required String usuarioId,
  }) async {
    final receta = await _recetasRepo.getRecetaById(orden.recetaId);
    if (receta == null) return 'No se encontró la receta de la orden.';

    final productoId = receta.productoId;
    if (productoId == null || productoId.isEmpty) {
      return 'La receta no tiene un producto final asignado.';
    }

    final ingredientes = await _recetasRepo.getIngredientesPorReceta(
      orden.recetaId,
    );
    if (ingredientes.isEmpty) {
      return 'La receta no tiene ingredientes registrados.';
    }

    return ejecutar(
      orden: orden,
      usuarioId: usuarioId,
      ingredientes: ingredientes,
      rendimiento: receta.rendimiento,
      productoId: productoId,
    );
  }
}

extension _OrdenProduccionCopyWith on OrdenProduccion {
  OrdenProduccion copyWith({EstadoOrden? estado}) {
    return OrdenProduccion(
      id: id,
      recetaId: recetaId,
      usuarioId: usuarioId,
      cantidadLotes: cantidadLotes,
      cantidadProducida: cantidadProducida,
      estado: estado ?? this.estado,
      fechaProgramada: fechaProgramada,
      fechaInicio: fechaInicio,
      fechaFin: fechaFin,
      notas: notas,
      createdAt: createdAt,
      updatedAt: updatedAt,
    );
  }
}
