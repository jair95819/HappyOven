import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/models/movimiento.dart';
import 'package:happy_oven/core/models/enums.dart';
import 'package:happy_oven/core/theme/theme.dart';
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
      body: Column(
        children: [
          _buildHeader(context, colors, font),
          Expanded(child: _buildFormulario(context, colors, font, productos)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColors colors, AppFont font) {
    return Container(
      color: colors.accent,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 36,
                  height: 36,
                  decoration: BoxDecoration(
                    borderRadius: AppTheme.radius.brSm,
                    border: Border.all(color: colors.accentDark, width: 0.5),
                  ),
                  child: Icon(
                    Icons.arrow_back_rounded,
                    color: colors.titleText,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Registrar salida', style: font.h3),
                  const SizedBox(height: 2),
                  Text(
                    _tipoSeleccionado == TipoArticulo.productoFinal
                        ? 'Descuento de productos finales'
                        : 'Descuento de materia prima',
                    style: font.caption.copyWith(color: colors.accentDark),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormulario(
    BuildContext context,
    AppColors colors,
    AppFont font,
    List<Articulo> productos,
  ) {
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
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
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLabel('Motivo de salida', colors, font),
              const SizedBox(height: 8),
              _buildSelectorMotivo(colors, font),
              const SizedBox(height: 20),
              _buildLabel('Producto final', colors, font),
              const SizedBox(height: 6),
              _buildSelectorProducto(context, colors, font, productos),
              const SizedBox(height: 20),
              _buildLabel('Cantidad a descontar', colors, font),
              const SizedBox(height: 6),
              _buildControlCantidad(colors, font),
              const SizedBox(height: 20),
              _buildLabel('Justificación (obligatoria)', colors, font),
              const SizedBox(height: 6),
              _buildCampoObservacion(colors, font),
              const SizedBox(height: 20),
              _buildResumen(colors, font),
              const SizedBox(height: 24),
              _buildBotonRegistrar(colors, font),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLabel(String texto, AppColors colors, AppFont font) {
    return Text(
      texto.toUpperCase(),
      style: font.caption.copyWith(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: colors.brownMid,
        letterSpacing: 0.5,
      ),
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
              color: activo ? colors.titleText : colors.surface,
              borderRadius: AppTheme.radius.brSm,
              border: Border.all(
                color: activo ? colors.titleText : colors.border,
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  _iconoMotivo(motivo),
                  color: activo ? colors.accent : colors.hint,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  _etiquetaMotivo(motivo),
                  style: font.label.copyWith(
                    fontSize: 12,
                    fontWeight: activo ? FontWeight.w500 : FontWeight.normal,
                    color: activo ? colors.white : colors.hint,
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
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: colors.primaryLight,
          borderRadius: AppTheme.radius.brSm,
          border: Border.all(color: colors.primaryBorder, width: 0.5),
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
                    '${_productoSeleccionado!.unidad}',
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
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seleccionar producto', style: font.h3.copyWith(fontSize: 15)),
            const SizedBox(height: 16),
            ...productos.map((p) {
              final activo = _productoSeleccionado?.id == p.id;
              return GestureDetector(
                onTap: () {
                  setState(() {
                    _productoSeleccionado = p;
                    _cantidad = 1;
                  });
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: activo ? colors.primaryLight : colors.surface,
                    borderRadius: AppTheme.radius.brSm,
                    border: Border.all(
                      color: activo ? colors.primaryBorder : colors.border,
                      width: 0.5,
                    ),
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
                        'Stock: ${p.stockActual.toStringAsFixed(0)} ${p.unidad}',
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
        color: colors.primaryLight,
        borderRadius: AppTheme.radius.brSm,
        border: Border.all(color: colors.primaryBorder, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(
                    Icons.remove_circle_outline,
                    color: colors.brownMid,
                    size: 16,
                  ),
                  const SizedBox(width: 10),
                  Text('$_cantidad', style: font.h3.copyWith(fontSize: 16)),
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
        color: colors.primaryLight,
        borderRadius: AppTheme.radius.brSm,
        border: Border.all(color: colors.primaryBorder, width: 0.5),
      ),
      child: TextField(
        controller: _observacionController,
        maxLines: 3,
        style: font.bodySmall.copyWith(color: colors.titleText),
        decoration: InputDecoration(
          hintText: 'Ej. Venta del turno mañana...',
          hintStyle: font.hint,
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
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
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppTheme.radius.brSm,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Stock después de salida', style: font.caption),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$_stockResultante ',
                      style: font.h3.copyWith(fontSize: 18, color: colorStock),
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
    return GestureDetector(
      onTap: _guardando ? null : _registrar,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 15),
        decoration: BoxDecoration(
          color: _guardando ? colors.hint : colors.primary,
          borderRadius: AppTheme.radius.brSm,
        ),
        child: _guardando
            ? Center(
                child: SizedBox(
                  width: 18,
                  height: 18,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    color: colors.white,
                  ),
                ),
              )
            : Text(
                'Registrar salida',
                textAlign: TextAlign.center,
                style: font.label.copyWith(fontSize: 14, color: colors.white),
              ),
      ),
    );
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
