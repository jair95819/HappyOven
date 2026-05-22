import 'package:happy_oven/core/models/articulo.dart';

/// Interfaz que define el contrato para el manejo de Artículos en el inventario.
/// Un artículo puede ser un 'insumo' (ej. harina) o un 'producto_final' (ej. torta).
abstract class IArticulosRepository {
  /// Obtiene todos los artículos registrados en el catálogo.
  Future<List<Articulo>> getArticulos();

  /// Obtiene únicamente los artículos que son de tipo 'insumo'.
  Future<List<Articulo>> getInsumos();

  /// Obtiene únicamente los artículos que son de tipo 'producto_final'.
  Future<List<Articulo>> getProductosFinales();

  /// Busca un artículo específico por su [id]. Retorna null si no existe.
  Future<Articulo?> getArticuloById(String id);

  /// Crea un nuevo artículo en la base de datos y lo devuelve con su ID asignado.
  Future<Articulo> createArticulo(Articulo articulo);

  /// Actualiza la información de un artículo existente.
  Future<Articulo> updateArticulo(Articulo articulo);

  /// Elimina permanentemente un artículo del catálogo usando su [id].
  Future<void> deleteArticulo(String id);
}