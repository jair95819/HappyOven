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
  const IngresoAlmacenView({super.key});

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
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radius.xl))),
      builder: (_) => DraggableScrollableSheet(
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Seleccionar artículo', style: font.h3.copyWith(fontSize: 15)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: articulos.length,
                  itemBuilder: (_, i) {
                    final a = articulos[i];
                    return ListTile(
                      leading: Icon(
                        a.tipo == TipoArticulo.insumo ? Icons.inventory_2_outlined : Icons.breakfast_dining_outlined,
                        color: colors.primary, size: 18,
                      ),
                      title: Text(a.nombre, style: font.bodySmall),
                      subtitle: Text('Stock: ${a.stockActual} ${a.unidad}', style: font.caption),
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
      _mostrarError('La justificación es obligatoria para registrar el ingreso');
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
      proveedor: _proveedorController.text.trim().isEmpty ? null : _proveedorController.text.trim(),
      observacion: _observacionController.text.trim().isEmpty ? null : _observacionController.text.trim(),
      porOcr: false,
      fecha: DateTime.now(),
    );

    final ok = await ref.read(movimientosViewModelProvider.notifier)
        .registrarMovimiento(movimiento, _articuloSeleccionado!, nuevoStock);

    if (ok && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${_articuloSeleccionado!.nombre}: +$cantidad ${_articuloSeleccionado!.unidad}'),
        backgroundColor: AppTheme.colorsOf(context).statusNormal,
        behavior: SnackBarBehavior.floating,
      ));
      context.pop();
    } else if (mounted) {
      _isSaving = false;
      _mostrarError('Error al registrar entrada');
    }
  }

  void _mostrarError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.colorsOf(context).statusCritical,
    ));
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
          Expanded(
            child: Container(
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
                      _buildSectionTitle('Artículo', font),
                      const SizedBox(height: 12),
                      _buildSelectorArticulo(colors, font),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Cantidad', font),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _cantidadController,
                        label: 'Cantidad a ingresar',
                        icon: Icons.add_circle_outline,
                        colors: colors, font: font,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Precio unitario (opcional)', font),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _precioController,
                        label: 'S/ Precio por unidad',
                        icon: Icons.attach_money_rounded,
                        colors: colors, font: font,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Proveedor (opcional)', font),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _proveedorController,
                        label: 'Nombre del proveedor',
                        icon: Icons.business_outlined,
                        colors: colors, font: font,
                      ),
                      const SizedBox(height: 20),
                      _buildSectionTitle('Justificación (obligatoria)', font),
                      const SizedBox(height: 12),
                      _buildTextField(
                        controller: _observacionController,
                        label: 'Motivo del ingreso (ej. compra a proveedor)',
                        icon: Icons.description_outlined,
                        colors: colors, font: font,
                        maxLines: 2,
                      ),
                      const SizedBox(height: 24),
                      _buildBotonGuardar(colors, font),
                    ],
                  ),
                ),
              ),
            ),
          ),
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
                  Text('Entrada de Almacén', style: font.h3),
                  const SizedBox(height: 2),
                  Text('Registrar ingreso de stock', style: font.caption.copyWith(color: colors.accentDark)),
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
                  child: Icon(Icons.close_rounded, color: colors.accent, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String titulo, AppFont font) {
    return Text(titulo, style: font.label.copyWith(fontSize: 14, fontWeight: FontWeight.w600));
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
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSelectorArticulo(AppColors colors, AppFont font) {
    return GestureDetector(
      onTap: _seleccionarArticulo,
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
              _articuloSeleccionado != null ? Icons.inventory_2_outlined : Icons.add_circle_outline,
              color: _articuloSeleccionado != null ? colors.primary : colors.hint,
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
                      color: _articuloSeleccionado != null ? colors.titleText : colors.hint,
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
              Icon(Icons.keyboard_arrow_down_rounded, color: colors.hint, size: 16),
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
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _isSaving ? colors.hint : colors.accent,
          borderRadius: AppTheme.radius.brSm,
        ),
        child: _isSaving
            ? SizedBox(
                height: 18, width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: colors.titleText),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_outlined, color: colors.titleText, size: 16),
                  const SizedBox(width: 8),
                  Text('Registrar Entrada', style: font.label.copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}
