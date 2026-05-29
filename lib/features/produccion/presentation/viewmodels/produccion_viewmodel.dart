import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/models/orden_produccion.dart';
import 'package:happy_oven/core/models/movimiento.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/models/receta_ingrediente.dart';
import 'package:happy_oven/core/repositories/ordenes_produccion_repository.dart';
import 'package:happy_oven/core/repositories/movimientos_repository.dart';
import 'package:happy_oven/core/repositories/articulos_repository.dart';
import 'package:happy_oven/core/repositories/recetas_repository.dart';
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
  final OrdenesProduccionRepository _ordenesRepo;
  final MovimientosRepository _movimientosRepo;
  final ArticulosRepository _articulosRepo;
  final RecetasRepository _recetasRepo;

  EjecutarProduccion({
    required OrdenesProduccionRepository ordenesRepo,
    required MovimientosRepository movimientosRepo,
    required ArticulosRepository articulosRepo,
    required RecetasRepository recetasRepo,
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
      // Marcar como en_proceso
      await _ordenesRepo.updateOrden(orden.copyWith(estado: 'en_proceso'));

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
          tipoMovimiento: 'salida_produccion',
          motivoSalida: null,
          cantidad: cantidadConsumir,
          precioUnitario: insumo.precioUnitario,
          proveedor: null,
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
          stockActual: nuevoStock < 0 ? 0 : nuevoStock,
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
          tipoMovimiento: 'entrada',
          motivoSalida: null,
          cantidad: cantidadProducida.toDouble(),
          precioUnitario: producto.precioUnitario,
          proveedor: null,
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
          estado: 'completada',
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
        await _ordenesRepo.updateOrden(orden.copyWith(estado: 'pendiente'));
      } catch (_) {}
      return e.toString();
    }
  }
}

extension _OrdenProduccionCopyWith on OrdenProduccion {
  OrdenProduccion copyWith({String? estado}) {
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
