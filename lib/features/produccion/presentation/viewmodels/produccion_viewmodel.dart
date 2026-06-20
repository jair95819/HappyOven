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

  Future<String?> iniciarOrden(OrdenProduccion orden) async {
    final ordenActualizada = orden.copyWith(
      estado: EstadoOrden.enProceso,
      fechaInicio: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return actualizarOrden(ordenActualizada);
  }

  Future<String?> cancelarOrden(OrdenProduccion orden) async {
    final ordenActualizada = orden.copyWith(
      estado: EstadoOrden.cancelada,
      fechaFin: DateTime.now(),
      updatedAt: DateTime.now(),
    );
    return actualizarOrden(ordenActualizada);
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

  Future<String?> ejecutar({
    required OrdenProduccion orden,
    required String usuarioId,
    required List<RecetaIngrediente> ingredientes,
    required double rendimiento,
    required String productoId,
  }) async {
    try {
      // 1. Validar stock de todos los insumos primero (para abortar si falta alguno)
      final Map<String, Articulo> insumosModificados = {};
      final Map<String, double> cantidadesRequeridas = {};

      for (final ingrediente in ingredientes) {
        final insumo = await _articulosRepo.getArticuloById(ingrediente.insumoId);
        if (insumo == null) {
          return 'No se encontró el insumo: ${ingrediente.insumoId}';
        }

        final cantidadNecesaria = ingrediente.cantidadRequerida * orden.cantidadLotes;
        if (insumo.stockActual < cantidadNecesaria) {
          return 'Stock insuficiente para procesar la orden. Faltan unidades del insumo requerido.';
        }

        insumosModificados[ingrediente.insumoId] = insumo;
        cantidadesRequeridas[ingrediente.insumoId] = cantidadNecesaria;
      }

      // 2. Obtener el producto final
      final productoFinal = await _articulosRepo.getArticuloById(productoId);
      if (productoFinal == null) {
        return 'No se encontró el producto final asignado a la receta.';
      }

      // 3. Modificar stock de insumos y registrar movimientos (salidas)
      final effectiveUsuarioId = usuarioId.isNotEmpty ? usuarioId : orden.usuarioId;
      if (effectiveUsuarioId.isEmpty) {
        return 'Se requiere un usuario autenticado para registrar los movimientos.';
      }

      for (final ingrediente in ingredientes) {
        final insumo = insumosModificados[ingrediente.insumoId]!;
        final cantidadNecesaria = cantidadesRequeridas[ingrediente.insumoId]!;

        final insumoActualizado = insumo.copyWith(
          stockActual: insumo.stockActual - cantidadNecesaria,
          updatedAt: DateTime.now(),
        );

        await _articulosRepo.updateArticulo(insumoActualizado);

        final movimientoInsumo = Movimiento(
          id: '',
          articuloId: ingrediente.insumoId,
          usuarioId: effectiveUsuarioId,
          recetaId: orden.recetaId,
          ordenProduccionId: orden.id,
          tipoMovimiento: TipoMovimiento.salidaProduccion,
          cantidad: cantidadNecesaria,
          porOcr: false,
          fecha: DateTime.now(),
          observacion: 'Consumo por orden de producción ${orden.id}',
        );

        await _movimientosRepo.registrarMovimiento(movimientoInsumo);
      }

      // 4. Modificar stock del producto final y registrar movimiento (entrada)
      final cantidadProducida = rendimiento * orden.cantidadLotes;
      final productoActualizado = productoFinal.copyWith(
        stockActual: productoFinal.stockActual + cantidadProducida,
        updatedAt: DateTime.now(),
      );

      await _articulosRepo.updateArticulo(productoActualizado);

      final movimientoProducto = Movimiento(
        id: '',
        articuloId: productoId,
        usuarioId: effectiveUsuarioId,
        recetaId: orden.recetaId,
        ordenProduccionId: orden.id,
        tipoMovimiento: TipoMovimiento.entrada,
        cantidad: cantidadProducida,
        porOcr: false,
        fecha: DateTime.now(),
        observacion: 'Producción de receta por orden ${orden.id}',
      );

      await _movimientosRepo.registrarMovimiento(movimientoProducto);

      // 5. Actualizar orden a completada
      final ordenCompletada = orden.copyWith(
        estado: EstadoOrden.completada,
        fechaFin: DateTime.now(),
        cantidadProducida: cantidadProducida.toInt(),
        updatedAt: DateTime.now(),
      );

      await _ordenesRepo.updateOrden(ordenCompletada);

      return null;
    } catch (e) {
      return e.toString();
    }
  }
}
