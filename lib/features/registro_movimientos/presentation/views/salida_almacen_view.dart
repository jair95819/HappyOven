import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/models/movimiento.dart';
import 'package:happy_oven/core/models/enums.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/widgets/ho_ui.dart';
import 'package:happy_oven/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:happy_oven/features/registro_movimientos/presentation/viewmodels/movimientos_viewmodel.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/viewmodels/catalogo_viewmodel.dart';

class SalidaAlmacenView extends ConsumerStatefulWidget {
  const SalidaAlmacenView({super.key});

  @override
  ConsumerState<SalidaAlmacenView> createState() => _SalidaAlmacenViewState();
}

class _SalidaAlmacenViewState extends ConsumerState<SalidaAlmacenView> {
  MotivoSalida _motivoSeleccionado = MotivoSalida.venta;
  TipoArticulo _tipoSeleccionado = TipoArticulo.productoFinal;
  Articulo? _productoSeleccionado;
  double _cantidad = 1;
  final _cantidadController = TextEditingController(text: '1');
  final _observacionController = TextEditingController();
  bool _guardando = false;

  @override
  void dispose() {
    _cantidadController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  double get _stockResultante =>
      ((_productoSeleccionado?.stockActual ?? 0) - _cantidad)
          .clamp(0, 99999)
          .toDouble();

  /// Paso de incremento/decremento adecuado a la unidad de medida del artículo:
  /// unidades enteras de a 1, pesos/volúmenes en fracciones más finas.
  double get _paso {
    switch (_productoSeleccionado?.unidad) {
      case UnidadMedida.gramos:
      case UnidadMedida.ml:
        return 50;
      case UnidadMedida.kg:
      case UnidadMedida.litros:
        return 0.5;
      case UnidadMedida.unidades:
      case null:
        return 1;
    }
  }

  /// Formatea una cantidad eliminando decimales sobrantes (1.0 → "1", 0.50 → "0.5").
  String _fmt(double v) {
    if (v == v.roundToDouble()) return v.toInt().toString();
    return v
        .toStringAsFixed(2)
        .replaceAll(RegExp(r'0+$'), '')
        .replaceAll(RegExp(r'\.$'), '');
  }

  void _setCantidad(double v) {
    setState(() {
      _cantidad = v;
      _cantidadController.text = _fmt(v);
      _cantidadController.selection = TextSelection.collapsed(
        offset: _cantidadController.text.length,
      );
    });
  }

  void _onCantidadChanged(String value) {
    final parsed = double.tryParse(value.replaceAll(',', '.'));
    setState(() => _cantidad = parsed ?? 0);
  }

  void _cambiarTipo(TipoArticulo tipo) {
    if (_tipoSeleccionado == tipo) return;
    setState(() {
      _tipoSeleccionado = tipo;
      _productoSeleccionado = null;
      _cantidad = 1;
      _cantidadController.text = '1';
    });
  }

  void _incrementar() {
    if (_productoSeleccionado == null) return;
    final nuevo = _cantidad + _paso;
    _setCantidad(
      nuevo > _productoSeleccionado!.stockActual
          ? _productoSeleccionado!.stockActual
          : nuevo,
    );
  }

  void _decrementar() {
    final nuevo = _cantidad - _paso;
    _setCantidad(nuevo < 0 ? 0 : nuevo);
  }

  Future<void> _registrar() async {
    if (_productoSeleccionado == null) {
      _mostrarError('Selecciona un producto');
      return;
    }
    if (_cantidad <= 0) {
      _mostrarError('La cantidad debe ser mayor a 0');
      return;
    }
    if (_cantidad > _productoSeleccionado!.stockActual) {
      _mostrarError('No hay suficiente stock disponible');
      return;
    }
    if (_observacionController.text.trim().isEmpty) {
      _mostrarError('La justificación es obligatoria para registrar la salida');
      return;
    }

    setState(() => _guardando = true);

    final authState = ref.read(authViewModelProvider);
    final usuarioId = authState.usuario?.id ?? '';

    final movimiento = Movimiento(
      id: '',
      articuloId: _productoSeleccionado!.id,
      usuarioId: usuarioId,
      tipoMovimiento: _tipoMovimientoDeMotivo(_motivoSeleccionado),
      motivoSalida: _motivoSeleccionado,
      cantidad: _cantidad,
      observacion: _observacionController.text.trim().isEmpty
          ? null
          : _observacionController.text.trim(),
      porOcr: false,
      fecha: DateTime.now(),
    );

    final nuevoStock = _productoSeleccionado!.stockActual - _cantidad;

    final exito = await ref
        .read(movimientosViewModelProvider.notifier)
        .registrarMovimiento(movimiento, _productoSeleccionado!, nuevoStock);

    setState(() => _guardando = false);

    if (!mounted) return;

    if (exito) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            'Salida registrada: ${_fmt(_cantidad)} '
            '${_productoSeleccionado!.unidad.dbValue} '
            'de ${_productoSeleccionado!.nombre}',
          ),
          backgroundColor: AppTheme.colorsOf(context).statusNormal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.radius.brSm),
        ),
      );
      context.pop();
    } else {
      _mostrarError('Error al registrar la salida. Intenta de nuevo.');
    }
  }

  void _mostrarError(String msg) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.colorsOf(context).statusCritical,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radius.brSm),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);

    // Carga los artículos reales desde Supabase, filtrados por el tipo elegido
    // (producto final o materia prima).
    final catalogoState = ref.watch(catalogoViewModelProvider);
    final productos = catalogoState.maybeWhen(
      data: (lista) =>
          lista.where((a) => a.tipo == _tipoSeleccionado && a.activo).toList(),
      orElse: () => <Articulo>[],
    );

    // Inicializar producto seleccionado si está vacío
    if (_productoSeleccionado == null && productos.isNotEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        setState(() => _productoSeleccionado = productos.first);
      });
    }

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: HoTopBar(
        title: 'Registrar movimientos',
        subtitle: _tipoSeleccionado == TipoArticulo.productoFinal
            ? 'Salida · descuento de productos finales'
            : 'Salida · descuento de materia prima',
        onBack: () =>
            context.canPop() ? context.pop() : context.go('/dashboard'),
      ),
      body: _buildFormulario(context, colors, font, productos),
    );
  }

  Widget _buildFormulario(
    BuildContext context,
    AppColors colors,
    AppFont font,
    List<Articulo> productos,
  ) {
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildLabel('Tipo de movimiento', colors, font),
          const SizedBox(height: 8),
          _buildSelectorMovimiento(colors),
          const SizedBox(height: 20),
          _buildLabel('Tipo de artículo', colors, font),
          const SizedBox(height: 8),
          _buildSelectorTipo(colors, font),
          const SizedBox(height: 20),
          _buildLabel('Motivo de salida', colors, font),
          const SizedBox(height: 8),
          _buildSelectorMotivo(colors, font),
          const SizedBox(height: 20),
          _buildLabel(
            _tipoSeleccionado == TipoArticulo.productoFinal
                ? 'Producto final'
                : 'Materia prima',
            colors,
            font,
          ),
          const SizedBox(height: 8),
          _buildSelectorProducto(context, colors, font, productos),
          const SizedBox(height: 20),
          _buildLabel('Cantidad a descontar', colors, font),
          const SizedBox(height: 8),
          _buildControlCantidad(colors, font),
          const SizedBox(height: 20),
          _buildLabel('Justificación (obligatoria)', colors, font),
          const SizedBox(height: 8),
          _buildCampoObservacion(colors, font),
          const SizedBox(height: 20),
          _buildResumen(colors, font),
          const SizedBox(height: 20),
          _buildBotonRegistrar(colors, font),
        ],
      ),
    );
  }

  Widget _buildSelectorMovimiento(AppColors colors) {
    Widget boton(
      String label,
      IconData icon,
      Color color,
      bool selected,
      VoidCallback? onTap,
    ) {
      return Expanded(
        child: Material(
          color: selected ? color : colors.card,
          borderRadius: BorderRadius.circular(16),
          child: InkWell(
            borderRadius: BorderRadius.circular(16),
            onTap: onTap,
            child: Container(
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: selected ? color : colors.border),
              ),
              child: Column(
                children: [
                  Icon(icon, size: 20, color: selected ? colors.white : color),
                  const SizedBox(height: 6),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                      color: selected ? colors.white : colors.titleText,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        boton(
          'Entrada',
          Icons.download_rounded,
          colors.statusNormal,
          false,
          () => context.pushReplacement('/movimientos/entrada'),
        ),
        const SizedBox(width: 8),
        boton('Salida', Icons.upload_rounded, colors.primary, true, null),
        const SizedBox(width: 8),
        boton(
          'Ajuste',
          Icons.sync_rounded,
          const Color(0xFF7C3AED),
          false,
          // TODO: movimiento de ajuste.
          () => ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Próximamente')),
          ),
        ),
      ],
    );
  }

  Widget _buildLabel(String texto, AppColors colors, AppFont font) {
    return HoSectionLabel(texto);
  }

  Widget _buildSelectorTipo(AppColors colors, AppFont font) {
    Widget chip(TipoArticulo tipo, String etiqueta, IconData icono) {
      final activo = _tipoSeleccionado == tipo;
      return Expanded(
        child: GestureDetector(
          onTap: () => _cambiarTipo(tipo),
          child: Container(
            padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.sm + 3),
            decoration: BoxDecoration(
              color: activo ? colors.primary : colors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: activo ? colors.primary : colors.border,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  icono,
                  color: activo ? colors.white : colors.bodyText,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  etiqueta,
                  style: font.label.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: activo ? colors.white : colors.titleText,
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    return Row(
      children: [
        chip(
          TipoArticulo.productoFinal,
          'Producto final',
          Icons.breakfast_dining_outlined,
        ),
        const SizedBox(width: 8),
        chip(TipoArticulo.insumo, 'Materia prima', Icons.egg_alt_outlined),
      ],
    );
  }

  Widget _buildSelectorMotivo(AppColors colors, AppFont font) {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.8,
      children: MotivoSalida.values.map((motivo) {
        final activo = _motivoSeleccionado == motivo;
        return GestureDetector(
          onTap: () => setState(() => _motivoSeleccionado = motivo),
          child: Container(
            decoration: BoxDecoration(
              color: activo ? colors.primary : colors.card,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: activo ? colors.primary : colors.border,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _iconoMotivo(motivo),
                  color: activo ? colors.white : colors.bodyText,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _etiquetaMotivo(motivo),
                  style: font.label.copyWith(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: activo ? colors.white : colors.titleText,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectorProducto(
    BuildContext context,
    AppColors colors,
    AppFont font,
    List<Articulo> productos,
  ) {
    return GestureDetector(
      onTap: () => _mostrarSelectorProducto(context, colors, font, productos),
      child: Container(
        padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.md, vertical: AppTheme.spacing.sm + 4),
        decoration: BoxDecoration(
          color: colors.primaryLight.withValues(alpha: 0.6),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: colors.border),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.breakfast_dining_outlined,
                  color: colors.brownMid,
                  size: 16,
                ),
                const SizedBox(width: 10),
                Text(
                  _productoSeleccionado?.nombre ?? 'Seleccionar producto',
                  style: font.label.copyWith(
                    fontSize: 13,
                    color: _productoSeleccionado != null
                        ? colors.titleText
                        : colors.hint,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                if (_productoSeleccionado != null)
                  Text(
                    'Stock: ${_productoSeleccionado!.stockActual.toStringAsFixed(0)} '
                    '${_productoSeleccionado!.unidad.dbValue}',
                    style: font.caption,
                  ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colors.brownMid,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarSelectorProducto(
    BuildContext context,
    AppColors colors,
    AppFont font,
    List<Articulo> productos,
  ) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(AppTheme.radius.xl),
        ),
      ),
      builder: (_) => Padding(
        padding: EdgeInsets.fromLTRB(AppTheme.spacing.lg, AppTheme.spacing.lg, AppTheme.spacing.lg, AppTheme.spacing.xl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seleccionar producto', style: font.h3.copyWith(fontSize: 15)),
            SizedBox(height: AppTheme.spacing.md),
            ...productos.map((p) {
              final activo = _productoSeleccionado?.id == p.id;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _productoSeleccionado = p;
                    _cantidad = 1;
                    _cantidadController.text = '1';
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: EdgeInsets.symmetric(
                    horizontal: AppTheme.spacing.md,
                    vertical: AppTheme.spacing.sm + 4,
                  ),
                  decoration: BoxDecoration(
                    color: activo ? colors.primaryLight : colors.surface,
                    borderRadius: AppTheme.radius.brSm,
                    border: Border.all(
                      color: activo ? colors.primaryBorder : colors.border,
                      width: 0.5,
                    ),
                    boxShadow: AppTheme.shadows.cardSm,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        p.nombre,
                        style: font.label.copyWith(
                          fontSize: 13,
                          fontWeight: activo
                              ? FontWeight.w500
                              : FontWeight.normal,
                        ),
                      ),
                      Text(
                        'Stock: ${p.stockActual.toStringAsFixed(0)} ${p.unidad.dbValue}',
                        style: font.caption,
                      ),
                    ],
                  ),
                ),
              );
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildControlCantidad(AppColors colors, AppFont font) {
    return Container(
      decoration: BoxDecoration(
        color: colors.primaryLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.md),
              child: Row(
                children: [
                  Expanded(
                    child: TextField(
                      controller: _cantidadController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      inputFormatters: [
                        FilteringTextInputFormatter.allow(RegExp(r'[0-9.,]')),
                      ],
                      onChanged: _onCantidadChanged,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: colors.titleText,
                      ),
                      decoration: const InputDecoration(
                        isDense: true,
                        border: InputBorder.none,
                        contentPadding: EdgeInsets.symmetric(vertical: 13),
                      ),
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _productoSeleccionado?.unidad.dbValue ?? '',
                    style: font.caption,
                  ),
                ],
              ),
            ),
          ),
          Container(
            decoration: BoxDecoration(
              border: Border(
                left: BorderSide(color: colors.primaryBorder, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                GestureDetector(
                  onTap: _decrementar,
                  child: Container(
                    width: 44,
                    height: 46,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(
                          color: colors.primaryBorder,
                          width: 0.5,
                        ),
                      ),
                    ),
                    child: Icon(
                      Icons.remove_rounded,
                      color: colors.brownMid,
                      size: 18,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: _incrementar,
                  child: SizedBox(
                    width: 44,
                    height: 46,
                    child: Icon(
                      Icons.add_rounded,
                      color: colors.brownMid,
                      size: 18,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoObservacion(AppColors colors, AppFont font) {
    return Container(
      decoration: BoxDecoration(
        color: colors.primaryLight.withValues(alpha: 0.6),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: TextField(
        controller: _observacionController,
        maxLines: 3,
        style: font.bodySmall.copyWith(color: colors.titleText),
        decoration: InputDecoration(
          hintText: 'Ej. Venta del turno mañana...',
          hintStyle: font.hint,
          border: InputBorder.none,
          contentPadding: EdgeInsets.all(AppTheme.spacing.md),
        ),
      ),
    );
  }

  Widget _buildResumen(AppColors colors, AppFont font) {
    Color colorStock;
    if (_stockResultante <= 5) {
      colorStock = colors.statusCritical;
    } else if (_stockResultante <= 15) {
      colorStock = colors.primary;
    } else {
      colorStock = colors.statusNormal;
    }

    return Container(
      padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.md, vertical: AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colors.border),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stock después de salida', style: font.caption),
              const SizedBox(height: 4),
              Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: '${_fmt(_stockResultante)} ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: colorStock,
                      ),
                    ),
                    TextSpan(
                      text: _productoSeleccionado?.unidad.dbValue ?? '',
                      style: font.caption,
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Motivo', style: font.caption),
              const SizedBox(height: 4),
              Text(
                _etiquetaMotivo(_motivoSeleccionado),
                style: font.label.copyWith(fontSize: 13, color: colors.primary),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildBotonRegistrar(AppColors colors, AppFont font) {
    return HoPrimaryButton(
      label: 'Registrar salida',
      icon: Icons.save_outlined,
      loading: _guardando,
      onPressed: _registrar,
    );
  }
}

/// Traduce el motivo de salida al tipo de movimiento de kardex correspondiente,
/// para que mermas y ajustes (p. ej. materia prima podrida) queden bien
/// clasificados en el historial y la analítica, no como salida de producción.
TipoMovimiento _tipoMovimientoDeMotivo(MotivoSalida motivo) {
  switch (motivo) {
    case MotivoSalida.merma:
      return TipoMovimiento.merma;
    case MotivoSalida.ajuste:
      return TipoMovimiento.ajuste;
    case MotivoSalida.venta:
    case MotivoSalida.degustacion:
      return TipoMovimiento.salidaProduccion;
  }
}

String _etiquetaMotivo(MotivoSalida motivo) {
  switch (motivo) {
    case MotivoSalida.venta:
      return 'Venta';
    case MotivoSalida.merma:
      return 'Merma';
    case MotivoSalida.degustacion:
      return 'Degustación';
    case MotivoSalida.ajuste:
      return 'Ajuste';
  }
}

IconData _iconoMotivo(MotivoSalida motivo) {
  switch (motivo) {
    case MotivoSalida.venta:
      return Icons.shopping_cart_outlined;
    case MotivoSalida.merma:
      return Icons.delete_outline_rounded;
    case MotivoSalida.degustacion:
      return Icons.card_giftcard_outlined;
    case MotivoSalida.ajuste:
      return Icons.tune_rounded;
  }
}
