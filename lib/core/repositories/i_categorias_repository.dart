import 'package:happy_oven/core/models/categoria.dart';

/// Interfaz para el acceso a datos de las Categorías de artículos.
abstract class ICategoriasRepository {
  /// Obtiene la lista completa de todas las categorías disponibles.
  Future<List<Categoria>> getCategorias();

  /// Obtiene las categorías filtradas por un [tipo] específico (ej. insumo o producto).
  Future<List<Categoria>> getCategoriasPorTipo(String tipo);

  /// Crea una nueva categoría y la devuelve con su ID asignado.
  Future<Categoria> createCategoria(Categoria categoria);

  /// Actualiza los datos (como el nombre o tipo) de una categoría existente.
  Future<Categoria> updateCategoria(Categoria categoria);

  /// Elimina una categoría específica usando su [id].
  Future<void> deleteCategoria(String id);
}