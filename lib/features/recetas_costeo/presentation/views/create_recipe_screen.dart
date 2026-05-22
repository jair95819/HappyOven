import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/features/recetas_costeo/presentation/viewmodels/create_recipe_form_viewmodel.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/features/recetas_costeo/presentation/viewmodels/recetas_viewmodel.dart';
import 'package:happy_oven/core/models/receta.dart';
import 'package:happy_oven/core/models/receta_ingrediente.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/viewmodels/catalogo_viewmodel.dart';

class CreateRecipeScreen extends ConsumerStatefulWidget {
  final Articulo? productoFinal;
  const CreateRecipeScreen({Key? key, this.productoFinal}) : super(key: key);

  @override
  ConsumerState<CreateRecipeScreen> createState() => _CreateRecipeScreenState();
}

class _CreateRecipeScreenState extends ConsumerState<CreateRecipeScreen> {
  final _rendimientoCtrl = TextEditingController(text: '1');
  final _nombreCtrl = TextEditingController();
  final _instrCtrl = TextEditingController();
  final _precioVentaCtrl = TextEditingController();

  @override
  void dispose() {
    _rendimientoCtrl.dispose();
    _nombreCtrl.dispose();
    _instrCtrl.dispose();
    _precioVentaCtrl.dispose();
    super.dispose();
  }

  @override
  void initState() {
    super.initState();
    if (widget.productoFinal != null) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(createRecipeFormProvider.notifier).setProductoFinal(widget.productoFinal);
      });
    }
  }

  Future<void> _selectArticulo(int index) async {
    final articulos = ref.read(catalogoViewModelProvider).value ?? [];
    final selected = await showModalBottomSheet<Articulo>(
      context: context,
      isScrollControlled: true,
      builder: (_) => DraggableScrollableSheet(
        initialChildSize: 0.5,
        expand: false,
        builder: (context, controller) => ListView.builder(
          controller: controller,
          itemCount: articulos.length,
          itemBuilder: (context, i) {
            final a = articulos[i];
            return ListTile(
              title: Text(a.nombre),
              subtitle: Text('Stock: ${a.stockActual} ${a.unidad}'),
              onTap: () => Navigator.pop(context, a),
            );
          },
        ),
      ),
    );
    if (selected != null) {
      ref.read(createRecipeFormProvider.notifier).updateIngredienteArticulo(index, selected);
    }
  }

  Future<void> _guardar() async {
    final formState = ref.read(createRecipeFormProvider);
    final formNotifier = ref.read(createRecipeFormProvider.notifier);
    if (formState.nombre.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Ingrese nombre')));
      return;
    }
    if (formState.ingredientes.isEmpty || formState.ingredientes.any((i) => i.articulo == null)) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Vincule todos los ingredientes')));
      return;
    }

    final receta = formNotifier.toRecetaModel();
    final ingredientes = formNotifier.toRecetaIngredientes();

    final error = await ref.read(recetasViewModelProvider.notifier).crearReceta(receta, ingredientes);
    if (error == null) {
      ScaffoldMessenger.of(context).showSnackBar(const SnackBar(content: Text('Receta creada')));
      context.pop();
    } else {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('Error: $error')));
    }
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(createRecipeFormProvider);
    final notifier = ref.read(createRecipeFormProvider.notifier);
    final articulosState = ref.watch(catalogoViewModelProvider);
    final articulos = articulosState.valueOrNull ?? [];
    final colors = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Crear Receta')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(controller: _nombreCtrl, decoration: const InputDecoration(labelText: 'Nombre'), onChanged: notifier.setNombre),
            const SizedBox(height: 8),
            TextField(controller: _rendimientoCtrl, decoration: const InputDecoration(labelText: 'Rendimiento'), keyboardType: TextInputType.number, onChanged: (v) => notifier.setRendimiento(double.tryParse(v) ?? 1)),
            const SizedBox(height: 8),
            TextField(controller: _instrCtrl, decoration: const InputDecoration(labelText: 'Instrucciones (opcional)'), maxLines: 3, onChanged: notifier.setInstrucciones),
            const SizedBox(height: 16),
            const Text('Ingredientes', style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 8),
            Column(
              children: state.ingredientes.asMap().entries.map((e) {
                final idx = e.key;
                final ing = e.value;
                return Card(
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Row(
                      children: [
                        Expanded(
                          child: DropdownButton<Articulo?>(
                            isExpanded: true,
                            value: ing.articulo,
                            hint: const Text('Seleccionar insumo'),
                            items: articulos.map((a) => DropdownMenuItem(value: a, child: Text(a.nombre))).toList(),
                            onChanged: (a) {
                              if (a != null) notifier.updateIngredienteArticulo(idx, a);
                            },
                          ),
                        ),
                        const SizedBox(width: 8),
                        SizedBox(
                          width: 90,
                          child: TextField(
                            keyboardType: TextInputType.numberWithOptions(decimal: true),
                            decoration: const InputDecoration(hintText: 'Cantidad'),
                            onChanged: (v) => notifier.updateIngredienteCantidad(idx, double.tryParse(v) ?? 0),
                          ),
                        ),
                        IconButton(onPressed: () => notifier.removeIngrediente(idx), icon: const Icon(Icons.delete_outline)),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 8),
            ElevatedButton.icon(onPressed: notifier.addIngrediente, icon: const Icon(Icons.add), label: const Text('Agregar Insumo')),
            const SizedBox(height: 16),
            Text('Costo total lote: S/ ${state.ingredientes.fold<double>(0, (p, c) => p + ((c.articulo?.precioUnitario ?? 0) * c.cantidad)).toStringAsFixed(2)}'),
            const SizedBox(height: 16),
            ElevatedButton(onPressed: _guardar, child: const Text('Guardar Receta')),
          ],
        ),
      ),
    );
  }
}
