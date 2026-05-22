import 'package:happy_oven/core/models/receta.dart';
import 'package:happy_oven/core/models/receta_ingrediente.dart';

/// Interfaz para el acceso a datos de Recetas y sus Ingredientes asociados.
/// Las recetas dictan cómo se transforma uno o varios 'insumos' en un 'producto_final'.
abstract class IRecetasRepository {
  /// Obtiene la lista de todas las recetas almacenadas en la base de datos.
  Future<List<Receta>> getRecetas();

  /// Busca una receta específica por su [id].
  Future<Receta?> getRecetaById(String id);

  /// Obtiene la receta asociada directamente al artículo de tipo producto final indicado por [productoId].
  Future<Receta?> getRecetaByProductoId(String productoId);

  /// Crea una nueva receta maestra y devuelve el objeto con su ID.
  Future<Receta> createReceta(Receta receta);

  /// Actualiza los parámetros de una receta (nombre, rendimiento, costos, etc.).
  Future<Receta> updateReceta(Receta receta);

  /// Elimina una receta y (normalmente por cascada) sus ingredientes.
  Future<void> deleteReceta(String id);

  /// Obtiene la lista de ingredientes (relación receta-insumo) correspondientes a una [recetaId].
  Future<List<RecetaIngrediente>> getIngredientesPorReceta(String recetaId);

  /// Agrega un nuevo ingrediente específico a una receta.
  Future<RecetaIngrediente> addIngrediente(RecetaIngrediente ingrediente);

  /// Remueve un ingrediente específico de la base de datos usando su [id] de la relación.
  Future<void> deleteIngrediente(String id);

  /// Elimina todos los ingredientes actuales de una receta y los reemplaza
  /// masivamente por la nueva lista proporcionada en [ingredientes].
  Future<List<RecetaIngrediente>> reemplazarIngredientes(
    String recetaId,
    List<RecetaIngrediente> ingredientes,
  );
}