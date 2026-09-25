import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/widgets/ho_ui.dart';
import 'package:happy_oven/features/recetas_costeo/presentation/views/widgets/receta_widgets.dart';
import 'package:happy_oven/core/models/receta.dart';
import 'package:happy_oven/core/models/receta_ingrediente.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/models/enums.dart';
import 'package:happy_oven/features/recetas_costeo/presentation/viewmodels/recetas_viewmodel.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/viewmodels/catalogo_viewmodel.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/views/formulario_articulo_view.dart';
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
  final TextEditingController _manoObraController = TextEditingController();
  final TextEditingController _empaqueController = TextEditingController();
  final TextEditingController _gastosGeneralesController =
      TextEditingController();

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
        (a) => a.id == id && a.tipo == TipoArticulo.productoFinal,
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
    _manoObraController.dispose();
    _empaqueController.dispose();
    _gastosGeneralesController.dispose();
    super.dispose();
  }

  double get _costoInsumos {
    double total = 0;
    for (final ing in _ingredientes) {
      if (ing.articulo != null) {
        total += ing.articulo!.precioUnitario * ing.cantidad;
      }
    }
    return total;
  }

  double get _costoManoObra => double.tryParse(_manoObraController.text) ?? 0;
  double get _costoEmpaque => double.tryParse(_empaqueController.text) ?? 0;
  double get _costoGastosGenerales =>
      double.tryParse(_gastosGeneralesController.text) ?? 0;

  double get _costoTotal =>
      _costoInsumos + _costoManoObra + _costoGastosGenerales;

  double get _costoUnitario {
    final rend = double.tryParse(_rendimientoController.text) ?? 1;
    return rend > 0 ? (_costoTotal / rend) + _costoEmpaque : 0;
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
    final insumos = articulos
        .where((a) => a.tipo == TipoArticulo.insumo)
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
      builder: (_) {
        String filtro = '';
        return StatefulBuilder(
          builder: (context, setModalState) {
            final insumosFiltrados = filtro.isEmpty
                ? insumos
                : insumos
                      .where(
                        (a) => a.nombre.toLowerCase().contains(
                          filtro.toLowerCase(),
                        ),
                      )
                      .toList();

            return DraggableScrollableSheet(
              maxChildSize: 0.85,
              minChildSize: 0.4,
              initialChildSize: 0.6,
              expand: false,
              builder: (context, scrollController) => Padding(
                padding: EdgeInsets.fromLTRB(
                  AppTheme.spacing.lg,
                  AppTheme.spacing.lg,
                  AppTheme.spacing.lg,
                  AppTheme.spacing.lg,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Seleccionar insumo',
                      style: font.h3.copyWith(fontSize: 15),
                    ),
                    SizedBox(height: AppTheme.spacing.md),
                    // ── Campo de búsqueda
                    Container(
                      decoration: BoxDecoration(
                        color: colors.surface,
                        borderRadius: AppTheme.radius.brSm,
                        border: Border.all(color: colors.border),
                        boxShadow: AppTheme.shadows.cardSm,
                      ),
                      child: TextField(
                        autofocus: true,
                        onChanged: (value) =>
                            setModalState(() => filtro = value),
                        style: font.bodySmall.copyWith(
                          fontSize: 13,
                          color: colors.titleText,
                        ),
                        decoration: InputDecoration(
                          hintText: 'Buscar insumo por nombre...',
                          hintStyle: font.hint.copyWith(fontSize: 13),
                          prefixIcon: Icon(
                            Icons.search_rounded,
                            color: colors.primary,
                            size: 20,
                          ),
                          suffixIcon: filtro.isNotEmpty
                              ? GestureDetector(
                                  onTap: () => setModalState(() => filtro = ''),
                                  child: Icon(
                                    Icons.close_rounded,
                                    color: colors.hint,
                                    size: 18,
                                  ),
                                )
                              : null,
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(
                            horizontal: AppTheme.spacing.sm + 4,
                            vertical: AppTheme.spacing.sm + 2,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),
                    // ── Contador de resultados
                    Text(
                      '${insumosFiltrados.length} insumo${insumosFiltrados.length != 1 ? 's' : ''}',
                      style: font.caption.copyWith(fontSize: 11),
                    ),
                    const SizedBox(height: 8),
                    Expanded(
                      child: insumosFiltrados.isEmpty
                          ? Center(
                              child: Column(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.search_off_rounded,
                                    color: colors.hint,
                                    size: 36,
                                  ),
                                  const SizedBox(height: 8),
                                  Text(
                                    'No se encontraron insumos',
                                    style: font.hint.copyWith(fontSize: 13),
                                  ),
                                ],
                              ),
                            )
                          : ListView.builder(
                              controller: scrollController,
                              itemCount: insumosFiltrados.length,
                              itemBuilder: (context, i) {
                                final a = insumosFiltrados[i];
                                final yaUsado = _ingredientes.any(
                                  (ing) => ing.articulo?.id == a.id,
                                );
                                return ListTile(
                                  leading: Icon(
                                    Icons.inventory_2_outlined,
                                    color: yaUsado
                                        ? colors.hint
                                        : colors.primary,
                                    size: 18,
                                  ),
                                  title: Text(
                                    a.nombre,
                                    style: font.bodySmall.copyWith(
                                      color: yaUsado
                                          ? colors.hint
                                          : colors.titleText,
                                    ),
                                  ),
                                  subtitle: Text(
                                    a.precioUnitario > 0
                                        ? 'S/ ${a.precioUnitario.toStringAsFixed(2)} / ${a.unidad}'
                                        : 'Sin precio / ${a.unidad}',
                                    style: font.caption,
                                  ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      if (yaUsado)
                                        Icon(
                                          Icons.check_rounded,
                                          color: colors.statusNormal,
                                          size: 16,
                                        ),
                                      IconButton(
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(),
                                        icon: Icon(
                                          Icons.edit,
                                          size: 16,
                                          color: colors.primary,
                                        ),
                                        onPressed: () async {
                                          Navigator.pop(context);
                                          final Articulo? actualizado =
                                              await Navigator.of(
                                                context,
                                              ).push<Articulo?>(
                                                MaterialPageRoute(
                                                  builder: (_) =>
                                                      FormularioArticuloView(
                                                        articulo: a,
                                                      ),
                                                ),
                                              );
                                          if (actualizado != null) {
                                            setState(() {
                                              _ingredientes[index] =
                                                  _IngredienteLocal(
                                                    articulo: actualizado,
                                                    cantidad:
                                                        _ingredientes[index]
                                                                .cantidad >
                                                            0
                                                        ? _ingredientes[index]
                                                              .cantidad
                                                        : 1,
                                                  );
                                            });
                                          }
                                        },
                                      ),
                                    ],
                                  ),
                                  onTap: yaUsado
                                      ? null
                                      : () {
                                          setState(() {
                                            _ingredientes[index] =
                                                _IngredienteLocal(
                                                  articulo: a,
                                                  cantidad:
                                                      _ingredientes[index]
                                                              .cantidad >
                                                          0
                                                      ? _ingredientes[index]
                                                            .cantidad
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
            );
          },
        );
      },
    );
  }

  void _seleccionarProductoFinal() {
    final articulos = ref.read(catalogoViewModelProvider).value ?? [];
    final productos = articulos
        .where((a) => a.tipo == TipoArticulo.productoFinal)
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
          padding: EdgeInsets.fromLTRB(
            AppTheme.spacing.lg,
            AppTheme.spacing.lg,
            AppTheme.spacing.lg,
            AppTheme.spacing.lg,
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Seleccionar producto final',
                style: font.h3.copyWith(fontSize: 15),
              ),
              SizedBox(height: AppTheme.spacing.md),
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

    if (_productoSeleccionado == null) {
      _isSaving = false;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text(
            'Selecciona un producto final para vincular la receta',
          ),
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
            unidad: i.articulo!.unidad.dbValue,
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
        updatedAt: DateTime.now(),
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
        updatedAt: DateTime.now(),
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
      appBar: HoTopBar(
        title: _modoEdicion ? 'Editar receta' : 'Registrar nueva receta',
        subtitle: 'Completa la información de tu receta',
        onBack: () => context.pop(),
      ),
      body: _buildBody(colors, font),
    );
  }

  Widget _buildBody(AppColors colors, AppFont font) {
    final rendimiento = double.tryParse(_rendimientoController.text) ?? 0;
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildSectionTitle('Nombre de la receta', font),
          const SizedBox(height: 6),
          _buildTextField(
            controller: _nombreController,
            label: 'Ej. Alfajores de Maicena',
            icon: Icons.sell_outlined,
            colors: colors,
            font: font,
          ),
          const SizedBox(height: 20),
          _buildSectionTitle('Producto final', font),
          const SizedBox(height: 6),
          _buildSelectorProductoFinal(colors, font),
          const SizedBox(height: 20),
          _buildSectionTitle('Rendimiento de la receta', font),
          const SizedBox(height: 6),
          Row(
            children: [
              SizedBox(
                width: 88,
                child: TextField(
                  controller: _rendimientoController,
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  onChanged: (_) => setState(() {}),
                  style: TextStyle(fontSize: 15, color: colors.titleText),
                  decoration: hoInputDecoration(context, hint: '10'),
                ),
              ),
              const SizedBox(width: 8),
              Expanded(
                child: InputDecorator(
                  decoration: hoInputDecoration(
                    context,
                    suffixIcon: Icon(
                      Icons.keyboard_arrow_down_rounded,
                      color: colors.bodyText,
                    ),
                  ),
                  child: Text(
                    _productoSeleccionado?.unidad.dbValue ?? 'unidades',
                    style: TextStyle(fontSize: 15, color: colors.titleText),
                  ),
                ),
              ),
            ],
          ),
          if (rendimiento > 0) ...[
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: colors.successLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Esta receta producirá ${rendimiento % 1 == 0 ? rendimiento.toInt() : rendimiento} ${_productoSeleccionado?.unidad.dbValue ?? 'unidades'}.',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                  color: colors.successDeep,
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          HoSectionLabel(
            'Ingredientes',
            trailing: _buildAgregarIngredienteBtn(colors, font),
          ),
          const SizedBox(height: 8),
          _buildIngredientesList(colors, font),
          if (_tieneInsumosSinPrecio && _ingredientes.isNotEmpty) ...[
            const SizedBox(height: 8),
            GestureDetector(
              onTap: () => context.push('/catalogo'),
              child: Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: colors.dangerLight,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      color: colors.statusCritical,
                      size: 16,
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Algunos insumos no tienen precio. Edítalos en el catálogo.',
                        style: TextStyle(
                          fontSize: 12,
                          color: colors.statusCritical,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
          const SizedBox(height: 20),
          _buildSectionTitle('Resumen de costos', font),
          const SizedBox(height: 8),
          _buildCostoResumen(colors, font),
          const SizedBox(height: 12),
          _buildMasOpciones(colors, font),
          const SizedBox(height: 20),
          _buildBotonGuardar(colors, font),
        ],
      ),
    );
  }

  /// Campos que no están en el diseño pero la lógica ya usa
  /// (instrucciones y costos adicionales), plegados para no alterar la vista.
  Widget _buildMasOpciones(AppColors colors, AppFont font) {
    return Theme(
      data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
      child: ExpansionTile(
        tilePadding: EdgeInsets.zero,
        childrenPadding: const EdgeInsets.only(bottom: 8),
        title: Text(
          'Más opciones (instrucciones y costos adicionales)',
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.w700,
            color: colors.bodyText,
          ),
        ),
        children: [
          _buildTextField(
            controller: _instruccionesController,
            label: 'Instrucciones / descripción (opcional)',
            icon: Icons.description_outlined,
            colors: colors,
            font: font,
            maxLines: 3,
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _manoObraController,
            label: 'Mano de obra por lote (S/)',
            icon: Icons.engineering_outlined,
            colors: colors,
            font: font,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _empaqueController,
            label: 'Empaque por unidad (S/)',
            icon: Icons.inventory_outlined,
            colors: colors,
            font: font,
            onChanged: () => setState(() {}),
          ),
          const SizedBox(height: 10),
          _buildTextField(
            controller: _gastosGeneralesController,
            label: 'Gastos generales por lote (S/)',
            icon: Icons.miscellaneous_services_outlined,
            colors: colors,
            font: font,
            onChanged: () => setState(() {}),
          ),
        ],
      ),
    );
  }

  Widget _buildSectionTitle(String titulo, AppFont font) {
    return HoSectionLabel(titulo);
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
    return TextField(
      controller: controller,
      maxLines: maxLines,
      onChanged: (_) => onChanged?.call(),
      style: TextStyle(fontSize: 15, color: colors.titleText),
      decoration: hoInputDecoration(context, hint: label, icon: icon),
    );
  }

  Widget _buildSelectorProductoFinal(AppColors colors, AppFont font) {
    return GestureDetector(
      onTap: _seleccionarProductoFinal,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 15),
        decoration: BoxDecoration(
          color: colors.primaryLight.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
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
                  fontSize: 15,
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
          color: colors.card,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Text(
          'Sin ingredientes. Toca "Agregar ingrediente".',
          textAlign: TextAlign.center,
          style: TextStyle(fontSize: 12, color: colors.hint),
        ),
      );
    }
    return Column(
      children: [
        for (var idx = 0; idx < _ingredientes.length; idx++)
          Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: _filaIngrediente(colors, idx),
          ),
      ],
    );
  }

  Widget _filaIngrediente(AppColors colors, int idx) {
    final ing = _ingredientes[idx];
    final color = coloresIngrediente[idx % coloresIngrediente.length];
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(8),
            ),
            alignment: Alignment.center,
            child: Container(
              width: 10,
              height: 10,
              decoration: BoxDecoration(color: color, shape: BoxShape.circle),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: GestureDetector(
              onTap: () => _seleccionarArticulo(idx),
              behavior: HitTestBehavior.opaque,
              child: Text(
                ing.articulo?.nombre ?? 'Seleccionar insumo...',
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: ing.articulo != null
                      ? colors.titleText
                      : colors.statusCritical,
                ),
              ),
            ),
          ),
          const SizedBox(width: 6),
          Container(
            width: 64,
            padding: const EdgeInsets.symmetric(horizontal: 6),
            decoration: BoxDecoration(
              color: colors.bg,
              borderRadius: BorderRadius.circular(8),
            ),
            child: TextFormField(
              key: ValueKey('cant-$idx-${ing.articulo?.id}'),
              initialValue: ing.cantidad > 0 ? ing.cantidad.toString() : '',
              textAlign: TextAlign.center,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              style: TextStyle(fontSize: 13, color: colors.titleText),
              decoration: const InputDecoration(
                isDense: true,
                border: InputBorder.none,
                hintText: '0',
                contentPadding: EdgeInsets.symmetric(vertical: 8),
              ),
              onChanged: (v) => setState(() {
                _ingredientes[idx] = _IngredienteLocal(
                  articulo: ing.articulo,
                  cantidad: double.tryParse(v) ?? 0,
                );
              }),
            ),
          ),
          const SizedBox(width: 6),
          GestureDetector(
            onTap: () => _seleccionarArticulo(idx),
            child: Container(
              width: 80,
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 8),
              decoration: BoxDecoration(
                color: colors.bg,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Text(
                      ing.articulo?.unidad.dbValue ?? '-',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: TextStyle(fontSize: 12, color: colors.titleText),
                    ),
                  ),
                  Icon(
                    Icons.keyboard_arrow_down_rounded,
                    size: 14,
                    color: colors.bodyText,
                  ),
                ],
              ),
            ),
          ),
          IconButton(
            visualDensity: VisualDensity.compact,
            onPressed: () => _eliminarIngrediente(idx),
            icon: Icon(
              Icons.delete_outline_rounded,
              size: 18,
              color: colors.statusCritical,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAgregarIngredienteBtn(AppColors colors, AppFont font) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Material(
        color: colors.card,
        shape: StadiumBorder(side: BorderSide(color: colors.border)),
        child: InkWell(
          customBorder: const StadiumBorder(),
          onTap: _agregarIngrediente,
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(Icons.add_rounded, color: colors.titleText, size: 16),
                const SizedBox(width: 4),
                Text(
                  'Agregar ingrediente',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: colors.titleText,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCostoResumen(AppColors colors, AppFont font) {
    return Row(
      children: [
        Expanded(
          child: HoCostCard(
            label: 'Costo total de la receta',
            value: 'S/ ${_costoTotal.toStringAsFixed(2)}',
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: HoCostCard(
            label: 'Costo por unidad (aprox.)',
            value: 'S/ ${_costoUnitario.toStringAsFixed(2)}',
          ),
        ),
      ],
    );
  }

  bool get _tieneInsumosSinPrecio {
    return _ingredientes.any((ing) => (ing.articulo?.precioUnitario ?? 0) <= 0);
  }

  Widget _buildBotonGuardar(AppColors colors, AppFont font) {
    return HoPrimaryButton(
      label: _modoEdicion ? 'Actualizar receta' : 'Guardar receta',
      icon: Icons.save_outlined,
      loading: _isSaving,
      onPressed: _guardarReceta,
    );
  }
}

/// Modelo local temporal para manejar la selección de ingredientes en el formulario.
class _IngredienteLocal {
  final Articulo? articulo;
  final double cantidad;

  _IngredienteLocal({this.articulo, required this.cantidad});
}
