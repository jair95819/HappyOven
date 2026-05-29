import 'package:happy_oven/core/models/orden_produccion.dart';

abstract class IOrdenesProduccionRepository {
  Future<List<OrdenProduccion>> getOrdenes();
  Future<List<OrdenProduccion>> getOrdenesPorEstado(String estado);
  Future<OrdenProduccion?> getOrdenById(String id);
  Future<OrdenProduccion> createOrden(OrdenProduccion orden);
  Future<OrdenProduccion> updateOrden(OrdenProduccion orden);
  Future<void> deleteOrden(String id);
}
