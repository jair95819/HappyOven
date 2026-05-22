import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/models/receta.dart';
import 'package:happy_oven/core/models/receta_ingrediente.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:collection/collection.dart';

class IngredienteEntry {
  Articulo? articulo;
  double cantidad;
  IngredienteEntry({this.articulo, this.cantidad = 0});
}

class CreateRecipeFormState {
  final String nombre;
  final double rendimiento;
  final String? instrucciones;
  final Articulo? productoFinal;
  final double precioVenta;
  final List<IngredienteEntry> ingredientes;

  CreateRecipeFormState({
    this.nombre = '',
    this.rendimiento = 1,
    this.instrucciones,
    this.productoFinal,
    this.precioVenta = 0,
    List<IngredienteEntry>? ingredientes,
  }) : ingredientes = ingredientes ?? [];

  CreateRecipeFormState copyWith({
    String? nombre,
    double? rendimiento,
    String? instrucciones,
    Articulo? productoFinal,
    double? precioVenta,
    List<IngredienteEntry>? ingredientes,
  }) {
    return CreateRecipeFormState(
      nombre: nombre ?? this.nombre,
      rendimiento: rendimiento ?? this.rendimiento,
      instrucciones: instrucciones ?? this.instrucciones,
      productoFinal: productoFinal ?? this.productoFinal,
      precioVenta: precioVenta ?? this.precioVenta,
      ingredientes: ingredientes ?? this.ingredientes,
    );
  }
}

class CreateRecipeFormNotifier extends StateNotifier<CreateRecipeFormState> {
  final Ref ref;
  CreateRecipeFormNotifier(this.ref) : super(CreateRecipeFormState());

  void setNombre(String v) => state = state.copyWith(nombre: v);
  void setRendimiento(double v) => state = state.copyWith(rendimiento: v);
  void setInstrucciones(String? v) => state = state.copyWith(instrucciones: v);
  void setProductoFinal(Articulo? a) => state = state.copyWith(productoFinal: a);
  void setPrecioVenta(double v) => state = state.copyWith(precioVenta: v);

  void addIngrediente() {
    final list = List<IngredienteEntry>.from(state.ingredientes)
      ..add(IngredienteEntry());
    state = state.copyWith(ingredientes: list);
  }

  void removeIngrediente(int index) {
    final list = List<IngredienteEntry>.from(state.ingredientes)..removeAt(index);
    state = state.copyWith(ingredientes: list);
  }

  void updateIngredienteArticulo(int index, Articulo articulo) {
    final list = List<IngredienteEntry>.from(state.ingredientes);
    if (index < 0 || index >= list.length) return;
    list[index].articulo = articulo;
    state = state.copyWith(ingredientes: list);
  }

  void updateIngredienteCantidad(int index, double cantidad) {
    final list = List<IngredienteEntry>.from(state.ingredientes);
    if (index < 0 || index >= list.length) return;
    list[index].cantidad = cantidad;
    state = state.copyWith(ingredientes: list);
  }

  double get costoTotal {
    double total = 0;
    for (final ing in state.ingredientes) {
      final precio = ing.articulo?.precioUnitario ?? 0.0;
      total += precio * ing.cantidad;
    }
    return total;
  }

  double get costoUnitario {
    final r = state.rendimiento <= 0 ? 1 : state.rendimiento;
    return costoTotal / r;
  }

  Receta toRecetaModel() {
    return Receta(
      id: '',
      nombre: state.nombre,
      productoId: state.productoFinal?.id,
      instrucciones: state.instrucciones,
      rendimiento: state.rendimiento,
      createdAt: DateTime.now(),
    );
  }

  List<RecetaIngrediente> toRecetaIngredientes() {
    return state.ingredientes
        .mapIndexed((i, ing) => RecetaIngrediente(
              id: '',
              recetaId: '',
              insumoId: ing.articulo?.id ?? '',
              cantidadRequerida: ing.cantidad,
            ))
        .toList();
  }
}

final createRecipeFormProvider = StateNotifierProvider<CreateRecipeFormNotifier, CreateRecipeFormState>(
  (ref) => CreateRecipeFormNotifier(ref),
);
