import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/features/recetas_costeo/presentation/viewmodels/create_recipe_form_viewmodel.dart';
import 'package:happy_oven/core/models/articulo.dart';

void main() {
  test('CreateRecipeFormNotifier basic flow', () {
    final container = ProviderContainer();
    addTearDown(container.dispose);

    final notifier = container.read(createRecipeFormProvider.notifier);

    // initial
    var state = container.read(createRecipeFormProvider);
    expect(state.nombre, '');
    expect(state.rendimiento, 1);
    expect(state.ingredientes.isEmpty, true);

    // add ingrediente
    notifier.addIngrediente();
    state = container.read(createRecipeFormProvider);
    expect(state.ingredientes.length, 1);

    // set articulo and cantidad
    final art = Articulo(
      id: 'a1',
      nombre: 'Harina',
      categoriaId: null,
      tipo: 'insumo',
      unidad: 'kg',
      stockActual: 100,
      stockMinimo: 1,
      precioUnitario: 5.0,
      activo: true,
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    notifier.updateIngredienteArticulo(0, art);
    notifier.updateIngredienteCantidad(0, 2.0);

    state = container.read(createRecipeFormProvider);
    expect(state.ingredientes[0].articulo?.id, 'a1');
    expect(state.ingredientes[0].cantidad, 2.0);

    // costo total
    final costoTotal = container.read(createRecipeFormProvider.notifier).costoTotal;
    expect(costoTotal, 10.0);

    // rendimiento -> costo unitario
    notifier.setRendimiento(2);
    final costoUnitario = container.read(createRecipeFormProvider.notifier).costoUnitario;
    expect(costoUnitario, 5.0);
  });
}
