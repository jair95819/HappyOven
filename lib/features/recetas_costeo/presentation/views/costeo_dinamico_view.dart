import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/models/receta.dart';
import 'package:happy_oven/core/models/receta_ingrediente.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/features/recetas_costeo/presentation/viewmodels/recetas_viewmodel.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/viewmodels/catalogo_viewmodel.dart';
import 'package:happy_oven/core/providers.dart';

class CosteoDinamicoView extends ConsumerStatefulWidget {
  final Receta? receta; // null = crear nueva, no-null = editar
  final Articulo? productoFinal; // pre-seleccionar producto final al crear

  const CosteoDinamicoView({super.key, this.receta, this.productoFinal});

  @override
  ConsumerState<CosteoDinamicoView> createState() => _CosteoDinamicoViewState();
}

class _CosteoDinamicoViewState extends ConsumerState<CosteoDinamicoView> {
  final TextEditingController _nombreController = TextEditingController();
  final TextEditingController _rendimientoController = TextEditingController();
  final TextEditingController _instruccionesController =
      TextEditingController();
  final TextEditingController _precioVentaController = TextEditingController();

  /// Lista local de ingredientes en edición
  final List<_IngredienteLocal> _ingredientes = [];
  bool _modoEdicion = false;
  bool _isSaving = false;

  Articulo? _productoSeleccionado;

  @override
  void initState() {
    super.initState();
    if (widget.receta != null) {
      _modoEdicion = true;
      _nombreController.text = widget.receta!.nombre;
      _rendimientoController.text = widget.receta!.rendimiento
          .toInt()
          .toString();
      _instruccionesController.text = widget.receta!.instrucciones ?? '';
      _productoSeleccionado = _buscarProductoFinalPorId(
        widget.receta!.productoId,
      );
      // Cargar ingredientes existentes desde Supabase
      _cargarIngredientesExistentes();
    } else if (widget.productoFinal != null) {
      _productoSeleccionado = widget.productoFinal;
      _nombreController.text = widget.productoFinal!.nombre;
    }
  }

  Articulo? _buscarProductoFinalPorId(String? id) {
    if (id == null) return null;
    final articulos = ref.read(catalogoViewModelProvider).value ?? [];
    try {
      return articulos.firstWhere(
        (a) => a.id == id && a.tipo == 'producto_final',
      );
    } catch (_) {
      return null;
    }
  }

  Future<void> _cargarIngredientesExistentes() async {
    final repo = ref.read(recetasRepositoryProvider);
    final ings = await repo.getIngredientesPorReceta(widget.receta!.id);
    final articulos = ref.read(catalogoViewModelProvider).value ?? [];

    setState(() {
      for (final ing in ings) {
        Articulo? articulo;
        try {
          articulo = articulos.firstWhere((a) => a.id == ing.insumoId);
        } catch (_) {}
        _ingredientes.add(
          _IngredienteLocal(
            articulo: articulo,
            cantidad: ing.cantidadRequerida,
          ),
        );
      }
    });
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _rendimientoController.dispose();
    _instruccionesController.dispose();
    _precioVentaController.dispose();
    super.dispose();
  }

  double get _costoTotal {
    double total = 0;
    for (final ing in _ingredientes) {
      if (ing.articulo != null) {
        total += ing.articulo!.precioUnitario * ing.cantidad;
      }
    }
    return total;
  }

  double get _costoUnitario {
    final rend = double.tryParse(_rendimientoController.text) ?? 1;
    return rend > 0 ? _costoTotal / rend : 0;
  }

  double get _margenGanancia {
    final pv = double.tryParse(_precioVentaController.text) ?? 0;
    return pv - _costoUnitario;
  }

  double get _rentabilidad {
    if (_costoUnitario <= 0) return 0;
    return (_margenGanancia / _costoUnitario) * 100;
  }

  Color _getColorRentabilidad() {
    final colors = AppTheme.colorsOf(context);
    if (_rentabilidad >= 40) return colors.statusNormal;
    if (_rentabilidad >= 20) return colors.primary;
    if (_rentabilidad > 0) return colors.brownLight;
    return colors.statusCritical;
  }

  String _getTextoRentabilidad() {
    if (_rentabilidad >= 40) return 'Muy rentable';
    if (_rentabilidad >= 20) return 'Rentable';
    if (_rentabilidad > 0) return 'Revisar';
    return 'No rentable';
  }

  void _agregarIngrediente() {
    setState(() {
      _ingredientes.add(_IngredienteLocal(cantidad: 0));
    });
  }

  void _eliminarIngrediente(int index) {
    setState(() => _ingredientes.removeAt(index));
  }

  void _seleccionarArticulo(int index) {
    final articulos = ref.read(catalogoViewModelProvider).value ?? [];
    final insumos = articulos.where((a) => a.tipo == 'insumo').toList();
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radius.xl),
        ),
      ),
      builder: (_) => DraggableScrollableSheet(
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Seleccionar insumo', style: font.h3.copyWith(fontSize: 15)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: insumos.length,
                  itemBuilder: (context, i) {
                    final a = insumos[i];
                    final yaUsado = _ingredientes.any(
                      (ing) => ing.articulo?.id == a.id,
                    );
                    return ListTile(
                      leading: Icon(
                        Icons.inventory_2_outlined,
                        color: yaUsado ? colors.hint : colors.primary,
                        size: 18,
                      ),
                      title: Text(
                        a.nombre,
                        style: font.bodySmall.copyWith(
                          color: yaUsado ? colors.hint : colors.titleText,
                        ),
                      ),
                      subtitle: Text(
                        'S/ ${a.precioUnitario.toStringAsFixed(2)} / ${a.unidad}',
                        style: font.caption,
                      ),
                      trailing: yaUsado
                          ? Icon(
                              Icons.check_rounded,
                              color: colors.statusNormal,
                              size: 16,
                            )
                          : null,
                      onTap: yaUsado
                          ? null
                          : () {
                              setState(() {
                                _ingredientes[index] = _IngredienteLocal(
                                  articulo: a,
                                  cantidad: _ingredientes[index].cantidad > 0
                                      ? _ingredientes[index].cantidad
                                      : 1,
                                );
                              });
                              Navigator.pop(context);
                            },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _seleccionarProductoFinal() {
    final articulos = ref.read(catalogoViewModelProvider).value ?? [];
    final productos = articulos
        .where((a) => a.tipo == 'producto_final')
        .toList();
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radius.xl),
        ),
      ),
      builder: (_) => DraggableScrollableSheet(
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seleccionar producto final',
                style: font.h3.copyWith(fontSize: 15),
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: productos.length,
                  itemBuilder: (context, i) {
                    final a = productos[i];
                    final seleccionado = _productoSeleccionado?.id == a.id;
                    return ListTile(
                      leading: Icon(
                        Icons.breakfast_dining_outlined,
                        color: seleccionado ? colors.primary : colors.hint,
                        size: 18,
                      ),
                      title: Text(
                        a.nombre,
                        style: font.bodySmall.copyWith(
                          color: seleccionado
                              ? colors.titleText
                              : colors.titleText,
                        ),
                      ),
                      subtitle: Text(
                        'Stock: ${a.stockActual} ${a.unidad}',
                        style: font.caption,
                      ),
                      trailing: seleccionado
                          ? Icon(
                              Icons.check_circle_rounded,
                              color: colors.statusNormal,
                              size: 20,
                            )
                          : null,
                      onTap: () {
                        setState(() => _productoSeleccionado = a);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _guardarReceta() async {
    if (_isSaving) return;
    _isSaving = true;

    final nombre = _nombreController.text.trim();
    final rendimiento = double.tryParse(_rendimientoController.text) ?? 1;
    final instrucciones = _instruccionesController.text.trim();

    if (nombre.isEmpty) {
      _isSaving = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Ingresa un nombre para la receta'),
          backgroundColor: AppTheme.colorsOf(context).statusCritical,
        ),
      );
      return;
    }

    if (_ingredientes.isEmpty || _ingredientes.any((i) => i.articulo == null)) {
      _isSaving = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Todos los ingredientes deben estar vinculados a un insumo',
          ),
          backgroundColor: AppTheme.colorsOf(context).statusCritical,
        ),
      );
      return;
    }

    final ingredientesModelo = _ingredientes
        .map(
          (i) => RecetaIngrediente(
            id: '',
            recetaId: _modoEdicion ? widget.receta!.id : '',
            insumoId: i.articulo!.id,
            cantidadRequerida: i.cantidad,
          ),
        )
        .toList();

    String? error;
    if (_modoEdicion) {
      final recetaActualizada = Receta(
        id: widget.receta!.id,
        nombre: nombre,
        productoId: _productoSeleccionado?.id,
        instrucciones: instrucciones.isNotEmpty ? instrucciones : null,
        rendimiento: rendimiento,
        createdAt: widget.receta!.createdAt,
      );
      error = await ref
          .read(recetasViewModelProvider.notifier)
          .actualizarReceta(recetaActualizada, ingredientesModelo);
    } else {
      final nuevaReceta = Receta(
        id: '',
        nombre: nombre,
        productoId: _productoSeleccionado?.id,
        instrucciones: instrucciones.isNotEmpty ? instrucciones : null,
        rendimiento: rendimiento,
        createdAt: DateTime.now(),
      );
      error = await ref
          .read(recetasViewModelProvider.notifier)
          .crearReceta(nuevaReceta, ingredientesModelo);
    }

    if (error == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            _modoEdicion ? 'Receta actualizada' : 'Receta creada exitosamente',
          ),
          backgroundColor: AppTheme.colorsOf(context).statusNormal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.radius.brSm),
        ),
      );
      context.pop();
    } else if (mounted) {
      _isSaving = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Error al guardar: $error'),
          backgroundColor: AppTheme.colorsOf(context).statusCritical,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);

    return Scaffold(
      backgroundColor: colors.bg,
      body: Column(
        children: [
          _buildHeader(colors, font),
          Expanded(child: _buildBody(colors, font)),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColors colors, AppFont font) {
    return Container(
      color: colors.accent,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _modoEdicion ? 'Editar Receta' : 'Nueva Receta',
                    style: font.h3,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Costeo dinámico en tiempo real',
                    style: font.caption.copyWith(color: colors.accentDark),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.titleText,
                    borderRadius: AppTheme.radius.brSm,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: colors.accent,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(AppColors colors, AppFont font) {
    return Container(
      decoration: BoxDecoration(
        color: colors.bg,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radius.xl),
          topRight: Radius.circular(AppTheme.radius.xl),
        ),
      ),
      transform: Matrix4.translationValues(0, -16, 0),
      child: ClipRRect(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(AppTheme.radius.xl),
          topRight: Radius.circular(AppTheme.radius.xl),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSectionTitle('Información Básica', font),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _nombreController,
                label: 'Nombre de la Receta',
                icon: Icons.edit_outlined,
                colors: colors,
                font: font,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _rendimientoController,
                label: 'Rendimiento (unidades por lote)',
                icon: Icons.production_quantity_limits_outlined,
                colors: colors,
                font: font,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _instruccionesController,
                label: 'Instrucciones (opcional)',
                icon: Icons.description_outlined,
                colors: colors,
                font: font,
                maxLines: 3,
              ),
              const SizedBox(height: 20),

              _buildSectionTitle('Producto final', font),
              const SizedBox(height: 12),
              _buildSelectorProductoFinal(colors, font),
              const SizedBox(height: 20),

              _buildSectionTitle('Ingredientes', font),
              const SizedBox(height: 12),
              _buildIngredientesList(colors, font),
              const SizedBox(height: 12),
              _buildAgregarIngredienteBtn(colors, font),
              const SizedBox(height: 20),

              _buildSectionTitle('Análisis de Costos', font),
              const SizedBox(height: 12),
              _buildCostoResumen(colors, font),
              const SizedBox(height: 16),

              _buildSectionTitle('Simulador de Precio', font),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _precioVentaController,
                label: 'Precio de Venta por unidad (S/)',
                icon: Icons.attach_money_rounded,
                colors: colors,
                font: font,
                onChanged: () => setState(() {}),
              ),
              const SizedBox(height: 12),
              _buildRentabilidadCard(colors, font),
              const SizedBox(height: 24),

              _buildBotonGuardar(colors, font),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String titulo, AppFont font) {
    return Text(
      titulo,
      style: font.label.copyWith(fontSize: 14, fontWeight: FontWeight.w600),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required AppColors colors,
    required AppFont font,
    VoidCallback? onChanged,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: AppTheme.radius.brSm,
        border: Border.all(color: colors.border),
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        onChanged: (_) => onChanged?.call(),
        style: font.bodySmall.copyWith(fontSize: 13, color: colors.titleText),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: font.hint.copyWith(fontSize: 13),
          prefixIcon: Icon(icon, color: colors.primary, size: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorProductoFinal(AppColors colors, AppFont font) {
    return GestureDetector(
      onTap: _seleccionarProductoFinal,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: AppTheme.radius.brSm,
          border: Border.all(color: colors.border),
        ),
        child: Row(
          children: [
            Icon(
              _productoSeleccionado != null
                  ? Icons.breakfast_dining_outlined
                  : Icons.add_circle_outline,
              color: _productoSeleccionado != null
                  ? colors.primary
                  : colors.hint,
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _productoSeleccionado?.nombre ??
                    'Seleccionar producto final...',
                style: font.bodySmall.copyWith(
                  fontSize: 12,
                  color: _productoSeleccionado != null
                      ? colors.titleText
                      : colors.hint,
                ),
              ),
            ),
            if (_productoSeleccionado != null)
              GestureDetector(
                onTap: () => setState(() => _productoSeleccionado = null),
                child: Icon(Icons.close_rounded, color: colors.hint, size: 16),
              )
            else
              Icon(
                Icons.keyboard_arrow_down_rounded,
                color: colors.hint,
                size: 16,
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientesList(AppColors colors, AppFont font) {
    if (_ingredientes.isEmpty) {
      return Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: AppTheme.radius.brMd,
        ),
        child: Center(
          child: Text(
            'Sin ingredientes. Toca "+" para agregar.',
            style: font.caption.copyWith(fontSize: 12),
          ),
        ),
      );
    }

    return Column(
      children: _ingredientes.asMap().entries.map((entry) {
        int idx = entry.key;
        _IngredienteLocal ing = entry.value;
        final costo = ing.articulo != null
            ? ing.articulo!.precioUnitario * ing.cantidad
            : 0.0;

        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: colors.card,
              borderRadius: AppTheme.radius.brSm,
              border: Border.all(color: colors.border),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => _seleccionarArticulo(idx),
                          child: Container(
                            padding: const EdgeInsets.symmetric(
                              horizontal: 8,
                              vertical: 6,
                            ),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: AppTheme.radius.brSm,
                            ),
                            child: Row(
                              children: [
                                Icon(
                                  ing.articulo != null
                                      ? Icons.inventory_2_outlined
                                      : Icons.add_circle_outline,
                                  color: ing.articulo != null
                                      ? colors.primary
                                      : colors.statusCritical,
                                  size: 14,
                                ),
                                const SizedBox(width: 6),
                                Expanded(
                                  child: Text(
                                    ing.articulo?.nombre ??
                                        'Seleccionar insumo...',
                                    style: font.label.copyWith(
                                      fontSize: 12,
                                      color: ing.articulo != null
                                          ? colors.titleText
                                          : colors.statusCritical,
                                    ),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                Icon(
                                  Icons.keyboard_arrow_down_rounded,
                                  color: colors.hint,
                                  size: 14,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      GestureDetector(
                        onTap: () => _eliminarIngrediente(idx),
                        child: Container(
                          width: 24,
                          height: 24,
                          decoration: BoxDecoration(
                            color: colors.dangerLight,
                            borderRadius: BorderRadius.circular(6),
                          ),
                          child: Icon(
                            Icons.delete_outline_rounded,
                            color: colors.statusCritical,
                            size: 14,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      Expanded(
                        flex: 2,
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primaryLight,
                            borderRadius: AppTheme.radius.brSm,
                            border: Border.all(
                              color: colors.border,
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'CANTIDAD',
                                style: font.caption.copyWith(
                                  fontSize: 8,
                                  color: colors.brownMid,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 2),
                              TextFormField(
                                initialValue: ing.cantidad > 0
                                    ? ing.cantidad.toString()
                                    : '',
                                keyboardType:
                                    const TextInputType.numberWithOptions(
                                      decimal: true,
                                    ),
                                style: font.label.copyWith(fontSize: 13),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                onChanged: (v) {
                                  setState(() {
                                    _ingredientes[idx] = _IngredienteLocal(
                                      articulo: ing.articulo,
                                      cantidad: double.tryParse(v) ?? 0,
                                    );
                                  });
                                },
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primaryLight,
                            borderRadius: AppTheme.radius.brSm,
                            border: Border.all(
                              color: colors.border,
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'UNIDAD',
                                style: font.caption.copyWith(
                                  fontSize: 8,
                                  color: colors.brownMid,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                ing.articulo?.unidad ?? '-',
                                style: font.label.copyWith(fontSize: 13),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 6),
                      Expanded(
                        child: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 8,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: colors.primaryLight,
                            borderRadius: AppTheme.radius.brSm,
                            border: Border.all(
                              color: colors.border,
                              width: 0.5,
                            ),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'COSTO',
                                style: font.caption.copyWith(
                                  fontSize: 8,
                                  color: colors.brownMid,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Text(
                                'S/ ${costo.toStringAsFixed(2)}',
                                style: font.h3.copyWith(
                                  fontSize: 13,
                                  color: colors.primary,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildAgregarIngredienteBtn(AppColors colors, AppFont font) {
    return GestureDetector(
      onTap: _agregarIngrediente,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: colors.primaryLight,
          borderRadius: AppTheme.radius.brSm,
          border: Border.all(color: colors.primaryBorder),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: colors.primary, size: 16),
            const SizedBox(width: 6),
            Text(
              'Agregar Ingrediente',
              style: font.label.copyWith(fontSize: 13, color: colors.primary),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostoResumen(AppColors colors, AppFont font) {
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: AppTheme.radius.brSm,
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Costo Total del Lote:',
                  style: font.caption.copyWith(fontSize: 12),
                ),
                Text(
                  'S/ ${_costoTotal.toStringAsFixed(2)}',
                  style: font.label.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: colors.border, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Costo por Unidad:',
                  style: font.caption.copyWith(fontSize: 12),
                ),
                Text(
                  'S/ ${_costoUnitario.toStringAsFixed(2)}',
                  style: font.label.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRentabilidadCard(AppColors colors, AppFont font) {
    Color colorRent = _getColorRentabilidad();
    String textoRent = _getTextoRentabilidad();

    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: AppTheme.radius.brSm,
        border: Border.all(color: colors.border),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Margen por Unidad:',
                  style: font.caption.copyWith(fontSize: 12),
                ),
                Text(
                  'S/ ${_margenGanancia.toStringAsFixed(2)}',
                  style: font.label.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorRent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: colors.border, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rentabilidad:',
                  style: font.caption.copyWith(fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorRent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_rentabilidad.toStringAsFixed(1)}% - $textoRent',
                    style: font.label.copyWith(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorRent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonGuardar(AppColors colors, AppFont font) {
    return GestureDetector(
      onTap: _isSaving ? null : _guardarReceta,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _isSaving ? colors.hint : colors.accent,
          borderRadius: AppTheme.radius.brSm,
        ),
        child: _isSaving
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: colors.titleText,
                ),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_outlined, color: colors.titleText, size: 16),
                  const SizedBox(width: 8),
                  Text(
                    _modoEdicion ? 'Actualizar Receta' : 'Guardar Receta',
                    style: font.label.copyWith(
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}

/// Modelo local temporal para manejar la selección de ingredientes en el formulario.
class _IngredienteLocal {
  final Articulo? articulo;
  final double cantidad;

  _IngredienteLocal({this.articulo, required this.cantidad});
}
