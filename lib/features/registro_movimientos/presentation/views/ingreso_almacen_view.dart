import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/widgets/ho_ui.dart';
import 'package:intl/intl.dart';
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
                        'Stock: ${a.stockActual} ${a.unidad.dbValue}',
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
            '${_articuloSeleccionado!.nombre}: +$cantidad ${_articuloSeleccionado!.unidad.dbValue}',
          ),
          backgroundColor: AppTheme.colorsOf(context).statusNormal,
          behavior: SnackBarBehavior.floating,
        ),
      );
      context.pop();
    } else if (mounted) {
      setState(() => _isSaving = false);
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
    final art = _articuloSeleccionado;
    final unidad = art?.unidad.dbValue ?? '';
    final cantidad = double.tryParse(_cantidadController.text) ?? 0;

    return Scaffold(
      backgroundColor: colors.bg,
      appBar: HoTopBar(
        title: 'Registrar movimientos',
        subtitle: 'Historial y registro de movimientos',
        onBack: () =>
            context.canPop() ? context.pop() : context.go('/dashboard'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _buildSelectorArticulo(colors),
            const SizedBox(height: 20),
            const HoSectionLabel('Tipo de movimiento'),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: _tipoButton(
                    colors,
                    label: 'Entrada',
                    icon: Icons.download_rounded,
                    color: colors.statusNormal,
                    selected: true,
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _tipoButton(
                    colors,
                    label: 'Salida',
                    icon: Icons.upload_rounded,
                    color: colors.primary,
                    selected: false,
                    onTap: () => context.pushReplacement('/movimientos/salida'),
                  ),
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: _tipoButton(
                    colors,
                    label: 'Ajuste',
                    icon: Icons.sync_rounded,
                    color: const Color(0xFF7C3AED),
                    selected: false,
                    // TODO: movimiento de ajuste.
                    onTap: () => ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text('Próximamente')),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            const HoSectionLabel('Información del movimiento'),
            const SizedBox(height: 8),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _campo(
                    colors,
                    'Cantidad *',
                    TextField(
                      controller: _cantidadController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      onChanged: (_) => setState(() {}),
                      style: TextStyle(fontSize: 15, color: colors.titleText),
                      decoration: hoInputDecoration(
                        context,
                        hint: '0',
                        suffixText: unidad,
                      ),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _campo(
                    colors,
                    'Fecha',
                    InputDecorator(
                      decoration: hoInputDecoration(
                        context,
                        suffixIcon: Icon(
                          Icons.calendar_today_rounded,
                          size: 18,
                          color: colors.bodyText,
                        ),
                      ),
                      child: Text(
                        DateFormat('dd/MM/yyyy').format(DateTime.now()),
                        style: TextStyle(fontSize: 15, color: colors.titleText),
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: _campo(
                    colors,
                    'Precio unit. (S/)',
                    TextField(
                      controller: _precioController,
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      style: TextStyle(fontSize: 15, color: colors.titleText),
                      decoration: hoInputDecoration(context, hint: '0.00'),
                    ),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: _campo(
                    colors,
                    'Proveedor',
                    TextField(
                      controller: _proveedorController,
                      style: TextStyle(fontSize: 15, color: colors.titleText),
                      decoration: hoInputDecoration(context, hint: 'Opcional'),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            _campo(
              colors,
              'Descripción *',
              TextField(
                controller: _observacionController,
                style: TextStyle(fontSize: 15, color: colors.titleText),
                decoration: hoInputDecoration(
                  context,
                  hint: 'Ej. Compra a proveedor La Molina',
                ),
              ),
            ),
            const SizedBox(height: 20),
            HoPrimaryButton(
              label: 'Registrar Entrada',
              icon: Icons.save_outlined,
              color: colors.statusNormal,
              loading: _isSaving,
              onPressed: _guardar,
            ),
            if (art != null) ...[
              const SizedBox(height: 20),
              _buildHistorial(colors, art),
              const SizedBox(height: 16),
              _buildImpacto(colors, art, cantidad),
            ],
          ],
        ),
      ),
    );
  }

  Widget _campo(AppColors colors, String label, Widget child) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Text(label, style: TextStyle(fontSize: 11, color: colors.bodyText)),
        const SizedBox(height: 6),
        child,
      ],
    );
  }

  Widget _tipoButton(
    AppColors colors, {
    required String label,
    required IconData icon,
    required Color color,
    required bool selected,
    VoidCallback? onTap,
  }) {
    return Material(
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
    );
  }

  Widget _buildHistorial(AppColors colors, Articulo art) {
    final movimientos =
        (ref.watch(movimientosViewModelProvider).valueOrNull ?? [])
            .where((m) => m.articuloId == art.id)
            .take(5)
            .toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        HoSectionLabel(
          'Historial de movimientos',
          trailing: GestureDetector(
            onTap: () => context.push('/catalogo/historial/${art.id}'),
            child: Text(
              'Ver todos →',
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w700,
                color: colors.primary,
              ),
            ),
          ),
        ),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: colors.card,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: colors.border),
          ),
          clipBehavior: Clip.antiAlias,
          child: Column(
            children: [
              Container(
                color: colors.bg,
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                child: Row(
                  children: [
                    Expanded(child: _th(colors, 'Fecha')),
                    Expanded(child: _th(colors, 'Tipo')),
                    Expanded(child: _th(colors, 'Cant.', end: true)),
                  ],
                ),
              ),
              if (movimientos.isEmpty)
                Padding(
                  padding: const EdgeInsets.all(14),
                  child: Text(
                    'Sin movimientos registrados',
                    style: TextStyle(fontSize: 12, color: colors.hint),
                  ),
                )
              else
                for (final m in movimientos) _buildHistoryRow(colors, m, art),
            ],
          ),
        ),
      ],
    );
  }

  Widget _th(AppColors colors, String t, {bool end = false}) => Text(
    t.toUpperCase(),
    textAlign: end ? TextAlign.right : TextAlign.left,
    style: TextStyle(
      fontSize: 10,
      fontWeight: FontWeight.w700,
      color: colors.bodyText,
    ),
  );

  Widget _buildHistoryRow(AppColors colors, Movimiento m, Articulo art) {
    final entrada = m.tipoMovimiento == TipoMovimiento.entrada;
    final color = entrada ? colors.statusNormal : colors.primary;
    final cant = m.cantidad % 1 == 0
        ? m.cantidad.toInt().toString()
        : m.cantidad.toStringAsFixed(2);
    return Container(
      decoration: BoxDecoration(
        border: Border(top: BorderSide(color: colors.border)),
      ),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Row(
        children: [
          Expanded(
            child: Text(
              DateFormat('dd/MM/yyyy').format(m.fecha),
              style: TextStyle(fontSize: 11, color: colors.bodyText),
            ),
          ),
          Expanded(
            child: Text(
              entrada ? 'Entrada' : 'Salida',
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: color,
              ),
            ),
          ),
          Expanded(
            child: Text(
              '${entrada ? '+' : '-'}$cant ${art.unidad.dbValue}',
              textAlign: TextAlign.right,
              style: TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w700,
                color: colors.titleText,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImpacto(AppColors colors, Articulo art, double cantidad) {
    String fmt(double v) =>
        v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(2);
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.successLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Container(
            width: 32,
            height: 32,
            decoration: BoxDecoration(
              color: colors.statusNormal,
              shape: BoxShape.circle,
            ),
            child: Icon(Icons.check_rounded, size: 16, color: colors.white),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Impacto del movimiento',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: colors.successDeep,
                  ),
                ),
                Text(
                  'Stock: ${fmt(art.stockActual)} → ${fmt(art.stockActual + cantidad)} ${art.unidad.dbValue}',
                  style: TextStyle(fontSize: 13, color: colors.bodyText),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorArticulo(AppColors colors) {
    final art = _articuloSeleccionado;
    return HoCard(
      onTap: _seleccionarArticulo,
      padding: const EdgeInsets.all(14),
      radius: 16,
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: colors.primaryLight,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(
              art != null ? Icons.grain_rounded : Icons.add_rounded,
              color: colors.primary,
              size: 22,
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Insumo seleccionado',
                  style: TextStyle(fontSize: 11, color: colors.bodyText),
                ),
                Text(
                  art?.nombre ?? 'Seleccionar artículo...',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: art != null ? colors.titleText : colors.hint,
                  ),
                ),
                if (art != null)
                  Text(
                    'Stock actual: ${art.stockActual} ${art.unidad.dbValue}',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colors.successDeep,
                    ),
                  ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, color: colors.bodyText),
        ],
      ),
    );
  }
}
