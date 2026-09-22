import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/models/enums.dart';
import 'package:happy_oven/core/models/movimiento.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/viewmodels/catalogo_viewmodel.dart';
import 'package:happy_oven/features/registro_movimientos/presentation/viewmodels/movimientos_viewmodel.dart';
import 'package:happy_oven/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class IngresoAlmacenView extends ConsumerStatefulWidget {
  final Articulo? articulo;

  const IngresoAlmacenView({super.key, this.articulo});

  @override
  ConsumerState<IngresoAlmacenView> createState() => _IngresoAlmacenViewState();
}

class _IngresoAlmacenViewState extends ConsumerState<IngresoAlmacenView> {
  Articulo? _articuloSeleccionado;
  final _cantidadController = TextEditingController();
  final _precioController = TextEditingController();
  final _proveedorController = TextEditingController();
  final _observacionController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.articulo != null) {
      _articuloSeleccionado = widget.articulo;
      _precioController.text = widget.articulo!.precioUnitario > 0
          ? widget.articulo!.precioUnitario.toStringAsFixed(2)
          : '';
    }
  }

  @override
  void dispose() {
    _cantidadController.dispose();
    _precioController.dispose();
    _proveedorController.dispose();
    _observacionController.dispose();
    super.dispose();
  }

  void _seleccionarArticulo() {
    final articulos = ref.read(catalogoViewModelProvider).valueOrNull ?? [];
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
                'Seleccionar artículo',
                style: font.h3.copyWith(fontSize: 15),
              ),
              SizedBox(height: AppTheme.spacing.md),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: articulos.length,
                  itemBuilder: (_, i) {
                    final a = articulos[i];
                    return ListTile(
                      leading: Icon(
                        a.tipo == TipoArticulo.insumo
                            ? Icons.inventory_2_outlined
                            : Icons.breakfast_dining_outlined,
                        color: colors.primary,
                        size: 18,
                      ),
                      title: Text(a.nombre, style: font.bodySmall),
                      subtitle: Text(
                        'Stock: ${a.stockActual} ${a.unidad}',
                        style: font.caption,
                      ),
                      onTap: () {
                        setState(() {
                          _articuloSeleccionado = a;
                          _precioController.text = a.precioUnitario > 0
                              ? a.precioUnitario.toStringAsFixed(2)
                              : '';
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

  Future<void> _guardar() async {
    if (_isSaving) return;
    if (_articuloSeleccionado == null) {
      _mostrarError('Selecciona un artículo');
      return;
    }
    final cantidad = double.tryParse(_cantidadController.text);
    if (cantidad == null || cantidad <= 0) {
      _mostrarError('Ingresa una cantidad válida');
      return;
    }
    if (_observacionController.text.trim().isEmpty) {
      _mostrarError(
        'La justificación es obligatoria para registrar el ingreso',
      );
      return;
    }

    setState(() => _isSaving = true);

    final authState = ref.read(authViewModelProvider);
    final usuarioId = authState.usuario?.id ?? '';

    final nuevoStock = _articuloSeleccionado!.stockActual + cantidad;
    final movimiento = Movimiento(
      id: '',
      articuloId: _articuloSeleccionado!.id,
      usuarioId: usuarioId,
      tipoMovimiento: TipoMovimiento.entrada,
      cantidad: cantidad,
      precioUnitario: double.tryParse(_precioController.text),
      proveedor: _proveedorController.text.trim().isEmpty
          ? null
          : _proveedorController.text.trim(),
      observacion: _observacionController.text.trim().isEmpty
          ? null
          : _observacionController.text.trim(),
      porOcr: false,
      fecha: DateTime.now(),
    );

    final ok = await ref
        .read(movimientosViewModelProvider.notifier)
        .registrarMovimiento(movimiento, _articuloSeleccionado!, nuevoStock);

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '${_articuloSeleccionado!.nombre}: +$cantidad ${_articuloSeleccionado!.unidad}',
          ),
          backgroundColor: AppTheme.colorsOf(context).statusNormal,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } else if (mounted) {
      _isSaving = false;
      _mostrarError('Error al registrar entrada');
    }
  }

  void _mostrarError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(msg),
        backgroundColor: AppTheme.colorsOf(context).statusCritical,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);

    return Scaffold(
      backgroundColor: colors.bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(0, 0, 0, 20),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 430),
              child: Container(
                margin: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 12,
                ),
                decoration: BoxDecoration(
                  color: colors.bg,
                  borderRadius: BorderRadius.circular(24),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildHeader(colors, font),
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.fromLTRB(18, 12, 18, 18),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _buildSelectorArticulo(colors, font),
                          const SizedBox(height: 22),
                          Text(
                            'TIPO DE MOVIMIENTO',
                            style: font.caption.copyWith(
                              fontSize: 11,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w700,
                              color: colors.brownMid,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: const Color(0xFF2C7A4B),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      const Icon(
                                        Icons.arrow_downward_rounded,
                                        color: Colors.white,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Entrada',
                                        style: font.label.copyWith(
                                          color: Colors.white,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w700,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.arrow_upward_rounded,
                                        color: colors.hint,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Salida',
                                        style: font.label.copyWith(
                                          color: colors.hint,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 8),
                              Expanded(
                                child: Container(
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment: MainAxisAlignment.center,
                                    children: [
                                      Icon(
                                        Icons.sync_rounded,
                                        color: colors.hint,
                                        size: 18,
                                      ),
                                      const SizedBox(width: 8),
                                      Text(
                                        'Ajuste',
                                        style: font.label.copyWith(
                                          color: colors.hint,
                                          fontSize: 12,
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 22),
                          Text(
                            'INFORMACIÓN DEL MOVIMIENTO',
                            style: font.caption.copyWith(
                              fontSize: 11,
                              letterSpacing: 0.5,
                              fontWeight: FontWeight.w700,
                              color: colors.brownMid,
                            ),
                          ),
                          const SizedBox(height: 10),
                          Row(
                            children: [
                              Expanded(
                                child: Text(
                                  'Cantidad *',
                                  style: font.caption.copyWith(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: colors.brownMid,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Align(
                                  alignment: Alignment.centerLeft,
                                  child: Text(
                                    'Fecha *',
                                    style: font.caption.copyWith(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w600,
                                      color: colors.brownMid,
                                    ),
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 8),
                          Row(
                            children: [
                              Expanded(
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 14,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    children: [
                                      Expanded(
                                        child: TextField(
                                          controller: _cantidadController,
                                          keyboardType:
                                              const TextInputType.numberWithOptions(
                                                decimal: true,
                                              ),
                                          style: font.bodySmall.copyWith(
                                            fontSize: 14,
                                            color: colors.titleText,
                                          ),
                                          decoration: const InputDecoration(
                                            border: InputBorder.none,
                                            isDense: true,
                                            contentPadding: EdgeInsets.zero,
                                          ),
                                        ),
                                      ),
                                      Text(
                                        'kg',
                                        style: font.label.copyWith(
                                          color: colors.titleText,
                                          fontSize: 13,
                                        ),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Expanded(
                                child: Container(
                                  height: 48,
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 12,
                                  ),
                                  decoration: BoxDecoration(
                                    color: colors.surface,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Row(
                                    mainAxisAlignment:
                                        MainAxisAlignment.spaceBetween,
                                    children: [
                                      Text(
                                        '06/05/2026',
                                        style: font.bodySmall.copyWith(
                                          fontSize: 14,
                                          color: colors.titleText,
                                        ),
                                      ),
                                      Icon(
                                        Icons.calendar_today_rounded,
                                        size: 18,
                                        color: colors.brownMid,
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 18),
                          Text(
                            'Descripción *',
                            style: font.caption.copyWith(
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                              color: colors.brownMid,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Container(
                            height: 56,
                            padding: const EdgeInsets.symmetric(horizontal: 14),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Align(
                              alignment: Alignment.centerLeft,
                              child: TextField(
                                controller: _observacionController,
                                style: font.bodySmall.copyWith(
                                  fontSize: 14,
                                  color: colors.titleText,
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            height: 50,
                            decoration: BoxDecoration(
                              color: const Color(0xFF2C7A4B),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                const Icon(
                                  Icons.save_alt_rounded,
                                  color: Colors.white,
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Guardar movimiento',
                                  style: font.label.copyWith(
                                    color: Colors.white,
                                    fontSize: 15,
                                    fontWeight: FontWeight.w700,
                                  ),
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Row(
                            mainAxisAlignment: MainAxisAlignment.spaceBetween,
                            children: [
                              Text(
                                'HISTORIAL DE MOVIMIENTOS',
                                style: font.caption.copyWith(
                                  fontWeight: FontWeight.w700,
                                  color: colors.brownMid,
                                  fontSize: 11,
                                  letterSpacing: 0.5,
                                ),
                              ),
                              Text(
                                'Ver todos →',
                                style: font.caption.copyWith(
                                  color: colors.primary,
                                  fontWeight: FontWeight.w600,
                                  fontSize: 11,
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 10),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: colors.surface,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              children: [
                                Row(
                                  children: [
                                    Expanded(
                                      child: Text(
                                        'FECHA',
                                        style: font.caption.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: colors.brownMid,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'TIPO',
                                        style: font.caption.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: colors.brownMid,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'CANT.',
                                        style: font.caption.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: colors.brownMid,
                                        ),
                                      ),
                                    ),
                                    Expanded(
                                      child: Text(
                                        'STOCK',
                                        style: font.caption.copyWith(
                                          fontSize: 10,
                                          fontWeight: FontWeight.w700,
                                          color: colors.brownMid,
                                        ),
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 8),
                                _buildHistoryRow(
                                  '06/05/2026',
                                  'Entrada',
                                  '+10 kg',
                                  '5.2 kg',
                                  colors,
                                  font,
                                  true,
                                ),
                                _buildHistoryRow(
                                  '05/05/2026',
                                  'Salida',
                                  '-2 kg',
                                  '-4.8 kg',
                                  colors,
                                  font,
                                  false,
                                ),
                                _buildHistoryRow(
                                  '04/05/2026',
                                  'Ajuste',
                                  '+0.5 kg',
                                  '-2.8 kg',
                                  colors,
                                  font,
                                  false,
                                ),
                                _buildHistoryRow(
                                  '02/05/2026',
                                  'Entrada',
                                  '+5 kg',
                                  '-3.3 kg',
                                  colors,
                                  font,
                                  true,
                                ),
                              ],
                            ),
                          ),
                          const SizedBox(height: 18),
                          Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 12,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFEBF5EE),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Row(
                              children: [
                                const Icon(
                                  Icons.check_circle_rounded,
                                  color: Color(0xFF2C7A4B),
                                  size: 18,
                                ),
                                const SizedBox(width: 10),
                                Text(
                                  'Impacto del movimiento',
                                  style: font.label.copyWith(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w700,
                                    color: const Color(0xFF2C7A4B),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildHistoryRow(
    String fecha,
    String tipo,
    String cant,
    String stock,
    AppColors colors,
    AppFont font,
    bool positive,
  ) {
    return Padding(
      padding: const EdgeInsets.only(top: 8),
      child: Row(
        children: [
          Expanded(
            child: Text(
              fecha,
              style: font.caption.copyWith(
                fontSize: 10,
                color: colors.titleText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              tipo,
              style: font.caption.copyWith(
                fontSize: 10,
                color: positive ? const Color(0xFF2C7A4B) : colors.titleText,
              ),
            ),
          ),
          Expanded(
            child: Text(
              cant,
              style: font.caption.copyWith(
                fontSize: 10,
                color: positive
                    ? const Color(0xFF2C7A4B)
                    : colors.statusCritical,
              ),
            ),
          ),
          Expanded(
            child: Text(
              stock,
              style: font.caption.copyWith(
                fontSize: 10,
                color: colors.titleText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColors colors, AppFont font) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(18, 14, 18, 16),
      decoration: BoxDecoration(color: colors.bg),
      child: Row(
        children: [
          GestureDetector(
            onTap: () => context.pop(),
            child: Container(
              width: 32,
              height: 32,
              decoration: BoxDecoration(
                color: colors.surface,
                borderRadius: BorderRadius.circular(10),
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
              Text(
                'Registrar movimientos',
                style: font.h3.copyWith(fontSize: 22),
              ),
              const SizedBox(height: 2),
              Text(
                'Historial y registro de movimientos',
                style: font.caption.copyWith(color: colors.accentDark),
              ),
            ],
          ),
        ],
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
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: AppTheme.radius.brSm,
        border: Border.all(color: colors.border),
        boxShadow: AppTheme.shadows.cardSm,
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: maxLines == 1 ? TextInputType.number : TextInputType.text,
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

  Widget _buildSelectorArticulo(AppColors colors, AppFont font) {
    return GestureDetector(
      onTap: _seleccionarArticulo,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(
          horizontal: AppTheme.spacing.md,
          vertical: AppTheme.spacing.sm + 4,
        ),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: AppTheme.radius.brSm,
          border: Border.all(color: colors.border),
          boxShadow: AppTheme.shadows.cardSm,
        ),
        child: Row(
          children: [
            Icon(
              _articuloSeleccionado != null
                  ? Icons.inventory_2_outlined
                  : Icons.add_circle_outline,
              color: _articuloSeleccionado != null
                  ? colors.primary
                  : colors.hint,
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _articuloSeleccionado?.nombre ?? 'Seleccionar artículo...',
                    style: font.bodySmall.copyWith(
                      fontSize: 12,
                      color: _articuloSeleccionado != null
                          ? colors.titleText
                          : colors.hint,
                    ),
                  ),
                  if (_articuloSeleccionado != null)
                    Text(
                      'Stock actual: ${_articuloSeleccionado!.stockActual} ${_articuloSeleccionado!.unidad}',
                      style: font.caption.copyWith(fontSize: 10),
                    ),
                ],
              ),
            ),
            if (_articuloSeleccionado != null)
              GestureDetector(
                onTap: () => setState(() => _articuloSeleccionado = null),
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

  Widget _buildBotonGuardar(AppColors colors, AppFont font) {
    return GestureDetector(
      onTap: _isSaving ? null : _guardar,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.md),
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
                    'Registrar Entrada',
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
