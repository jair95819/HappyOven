import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/models/movimiento.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/viewmodels/catalogo_viewmodel.dart';
import 'package:happy_oven/features/registro_movimientos/presentation/viewmodels/movimientos_viewmodel.dart';
import 'package:happy_oven/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class SalidaAlmacenView extends ConsumerStatefulWidget {
  const SalidaAlmacenView({super.key});

  @override
  ConsumerState<SalidaAlmacenView> createState() => _SalidaAlmacenViewState();
}

class _SalidaAlmacenViewState extends ConsumerState<SalidaAlmacenView> {
  _MotivoSalida _motivoSeleccionado = _MotivoSalida.venta;
  Articulo? _productoSeleccionado;
  List<Articulo> _productosDisponibles = [];
  int _cantidad = 1;
  final _observacionController = TextEditingController();

  int get _stockResultante {
    if (_productoSeleccionado == null) return 0;
    return (_productoSeleccionado!.stockActual - _cantidad).clamp(0, 99999).toInt();
  }

  void _incrementar() {
    if (_productoSeleccionado != null && _cantidad < _productoSeleccionado!.stockActual) {
      setState(() => _cantidad++);
    }
  }

  void _decrementar() {
    if (_cantidad > 1) setState(() => _cantidad--);
  }

  void _registrar() async {
    if (_productoSeleccionado == null) return;

    final user = ref.read(authViewModelProvider).usuario;
    if (user == null) return;

    final bool esMerma = _motivoSeleccionado == _MotivoSalida.merma;
    final bool esAjuste = _motivoSeleccionado == _MotivoSalida.ajuste;

    final movimiento = Movimiento(
      id: '',
      articuloId: _productoSeleccionado!.id,
      usuarioId: user.id,
      tipoMovimiento: esMerma ? 'merma' : esAjuste ? 'ajuste' : 'salida_produccion',
      motivoSalida: _motivoSeleccionado == _MotivoSalida.venta ? 'venta' :
                    _motivoSeleccionado == _MotivoSalida.merma ? 'merma' :
                    _motivoSeleccionado == _MotivoSalida.degustacion ? 'degustacion' : 'ajuste',
      cantidad: _cantidad.toDouble(),
      observacion: _observacionController.text.trim().isNotEmpty ? _observacionController.text.trim() : null,
      porOcr: false,
      fecha: DateTime.now(),
    );

    final exito = await ref.read(movimientosViewModelProvider.notifier).registrarMovimiento(
      movimiento,
      _productoSeleccionado!,
      _stockResultante.toDouble(),
    );

    if (exito && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Salida registrada: $_cantidad ${_productoSeleccionado!.unidad} de ${_productoSeleccionado!.nombre}'),
          backgroundColor: AppTheme.colorsOf(context).statusNormal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.radius.brSm),
        ),
      );
      context.pop();
    } else if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Error al registrar la salida.'),
          backgroundColor: AppTheme.colorsOf(context).statusCritical,
        ),
      );
    }
  }

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final catalogoState = ref.watch(catalogoViewModelProvider);
    
    return Scaffold(
      backgroundColor: AppTheme.colorsOf(context).bg,
      body: catalogoState.when(
        data: (articulos) {
          _productosDisponibles = articulos.where((a) => a.tipo == 'producto_final' || a.tipo == 'insumo').toList();
          // Solo inicializar si es nulo y hay disponibles
          if (_productoSeleccionado == null && _productosDisponibles.isNotEmpty) {
            _productoSeleccionado = _productosDisponibles.first;
          }

          return Column(
            children: [
              _buildHeader(context),
              if (_productosDisponibles.isEmpty)
                const Expanded(child: Center(child: Text('No hay productos disponibles')))
              else
                Expanded(child: _buildFormulario(context)),
            ],
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (e, _) => Center(child: Text('Error al cargar productos')),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Container(
      color: AppTheme.colors.accent,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  width: 36, height: 36,
                  decoration: BoxDecoration(
                    borderRadius: AppTheme.radius.brSm,
                    border: Border.all(color: AppTheme.colorsOf(context).accentDark, width: 0.5),
                  ),
                  child: Icon(Icons.arrow_back_rounded, color: AppTheme.colorsOf(context).titleText, size: 18),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Registrar salida', style: AppTheme.font.h3.copyWith(fontSize: 18)),
                  const SizedBox(height: 2),
                  Text('Descuento de productos finales',
                      style: AppTheme.font.caption.copyWith(color: AppTheme.colors.accentDark)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormulario(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors.card,
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
              _buildLabel('Motivo de salida'),
              const SizedBox(height: 8),
              _buildSelectorMotivo(),
              const SizedBox(height: 20),
              _buildLabel('Producto final'),
              const SizedBox(height: 6),
              _buildSelectorProducto(context),
              const SizedBox(height: 20),
              _buildLabel('Cantidad a descontar'),
              const SizedBox(height: 6),
              _buildControlCantidad(),
              const SizedBox(height: 20),
              _buildLabel('Observación (opcional)'),
              const SizedBox(height: 6),
              _buildCampoObservacion(),
              const SizedBox(height: 20),
              _buildResumen(),
              const SizedBox(height: 24),
              GestureDetector(
                onTap: _registrar,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: AppTheme.colors.primary,
                    borderRadius: AppTheme.radius.brMd,
                  ),
                  child: Text('Registrar salida', textAlign: TextAlign.center,
                      style: AppTheme.font.button.copyWith(fontSize: 14)),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorMotivo() {
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true, physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8, mainAxisSpacing: 8, childAspectRatio: 2.8,
      children: _MotivoSalida.values.map((motivo) {
        final activo = _motivoSeleccionado == motivo;
        return GestureDetector(
          onTap: () => setState(() => _motivoSeleccionado = motivo),
          child: Container(
            decoration: BoxDecoration(
              color: activo ? AppTheme.colorsOf(context).titleText : AppTheme.colorsOf(context).surface,
              borderRadius: AppTheme.radius.brSm,
              border: Border.all(color: activo ? AppTheme.colorsOf(context).titleText : AppTheme.colorsOf(context).border, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(motivo.icono, color: activo ? AppTheme.colorsOf(context).accent : AppTheme.colorsOf(context).hint, size: 16),
                const SizedBox(width: 6),
                Text(motivo.etiqueta, style: AppTheme.fontOf(context).bodySmall.copyWith(fontSize: 12,
                  fontWeight: activo ? FontWeight.w500 : FontWeight.normal,
                  color: activo ? AppTheme.colorsOf(context).white : AppTheme.colorsOf(context).hint)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectorProducto(BuildContext context) {
    if (_productoSeleccionado == null) return const SizedBox.shrink();

    return GestureDetector(
      onTap: () => _mostrarSelectorProducto(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.colorsOf(context).primaryLight,
          borderRadius: AppTheme.radius.brSm,
          border: Border.all(color: AppTheme.colorsOf(context).border, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(Icons.inventory_2_outlined, color: AppTheme.colorsOf(context).brownMid, size: 16),
              const SizedBox(width: 10),
              Text(_productoSeleccionado!.nombre, style: AppTheme.fontOf(context).label.copyWith(fontSize: 13)),
            ]),
            Row(children: [
              Text('Stock: ${_productoSeleccionado!.stockActual.toInt()} ${_productoSeleccionado!.unidad}',
                  style: AppTheme.fontOf(context).caption),
              const SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.colorsOf(context).brownMid, size: 18),
            ]),
          ],
        ),
      ),
    );
  }

  void _mostrarSelectorProducto(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radius.xl)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seleccionar producto', style: AppTheme.fontOf(context).h3.copyWith(fontSize: 15)),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _productosDisponibles.length,
                itemBuilder: (context, index) {
                  final p = _productosDisponibles[index];
                  final activo = _productoSeleccionado?.id == p.id;
                  return GestureDetector(
                    onTap: () {
                      setState(() { _productoSeleccionado = p; _cantidad = 1; });
                      Navigator.pop(context);
                    },
                    child: Container(
                      margin: const EdgeInsets.only(bottom: 8),
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                      decoration: BoxDecoration(
                        color: activo ? AppTheme.colorsOf(context).primaryLight : AppTheme.colorsOf(context).surface,
                        borderRadius: AppTheme.radius.brSm,
                        border: Border.all(color: activo ? AppTheme.colorsOf(context).primaryBorder : AppTheme.colorsOf(context).border, width: 0.5),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(p.nombre, style: AppTheme.fontOf(context).bodySmall.copyWith(fontSize: 13,
                            fontWeight: activo ? FontWeight.w500 : FontWeight.normal,
                            color: AppTheme.colorsOf(context).titleText)),
                          Text('Stock: ${p.stockActual.toInt()} ${p.unidad}', style: AppTheme.fontOf(context).caption),
                        ],
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildControlCantidad() {
    if (_productoSeleccionado == null) return const SizedBox.shrink();
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colorsOf(context).primaryLight,
        borderRadius: AppTheme.radius.brSm,
        border: Border.all(color: AppTheme.colorsOf(context).border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                Icon(Icons.remove_circle_outline, color: AppTheme.colorsOf(context).brownMid, size: 16),
                const SizedBox(width: 10),
                Text('$_cantidad', style: AppTheme.fontOf(context).h3.copyWith(fontSize: 16)),
                const SizedBox(width: 6),
                Text(_productoSeleccionado!.unidad, style: AppTheme.fontOf(context).caption.copyWith(fontSize: 12)),
              ]),
            ),
          ),
          Container(
            decoration: BoxDecoration(border: Border(left: BorderSide(color: AppTheme.colorsOf(context).border, width: 0.5))),
            child: Row(children: [
              GestureDetector(
                onTap: _decrementar,
                child: Container(
                  width: 44, height: 46,
                  decoration: BoxDecoration(border: Border(right: BorderSide(color: AppTheme.colorsOf(context).border, width: 0.5))),
                  child: Icon(Icons.remove_rounded, color: AppTheme.colorsOf(context).brownMid, size: 18),
                ),
              ),
              GestureDetector(
                onTap: _incrementar,
                child: SizedBox(width: 44, height: 46,
                    child: Icon(Icons.add_rounded, color: AppTheme.colorsOf(context).brownMid, size: 18)),
              ),
            ]),
          ),
        ],
      ),
    );
  }

  Widget _buildCampoObservacion() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colorsOf(context).primaryLight,
        borderRadius: AppTheme.radius.brSm,
        border: Border.all(color: AppTheme.colorsOf(context).border, width: 0.5),
      ),
      child: TextField(
        controller: _observacionController, maxLines: 3,
        style: AppTheme.fontOf(context).bodySmall.copyWith(fontSize: 13, color: AppTheme.colorsOf(context).titleText),
        decoration: InputDecoration(
          hintText: 'Ej. Venta del turno mañana...',
          hintStyle: AppTheme.fontOf(context).hint.copyWith(fontSize: 13),
          border: InputBorder.none, contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  Widget _buildResumen() {
    if (_productoSeleccionado == null) return const SizedBox.shrink();
    
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);

    final Color colorStock = _stockResultante <= 5 ? colors.statusCritical
        : _stockResultante <= 15 ? colors.primary : colors.statusNormal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(color: colors.surface, borderRadius: AppTheme.radius.brMd),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Stock después de salida', style: font.caption),
            const SizedBox(height: 4),
            RichText(text: TextSpan(children: [
              TextSpan(text: '$_stockResultante ', style: font.h3.copyWith(fontSize: 18, color: colorStock)),
              TextSpan(text: _productoSeleccionado!.unidad, style: font.caption.copyWith(fontSize: 12)),
            ])),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Motivo', style: font.caption),
            const SizedBox(height: 4),
            Text(_motivoSeleccionado.etiqueta, style: font.label.copyWith(
              fontSize: 13, color: colors.primary)),
          ]),
        ],
      ),
    );
  }

  Widget _buildLabel(String texto) {
    return Text(texto.toUpperCase(), style: AppTheme.fontOf(context).label.copyWith(
      fontSize: 10, color: AppTheme.colorsOf(context).brownMid, letterSpacing: 0.5));
  }
}

enum _MotivoSalida {
  venta, merma, degustacion, ajuste;
  String get etiqueta {
    switch (this) {
      case _MotivoSalida.venta: return 'Venta';
      case _MotivoSalida.merma: return 'Merma';
      case _MotivoSalida.degustacion: return 'Degustación';
      case _MotivoSalida.ajuste: return 'Ajuste';
    }
  }
  IconData get icono {
    switch (this) {
      case _MotivoSalida.venta: return Icons.shopping_cart_outlined;
      case _MotivoSalida.merma: return Icons.delete_outline_rounded;
      case _MotivoSalida.degustacion: return Icons.card_giftcard_outlined;
      case _MotivoSalida.ajuste: return Icons.tune_rounded;
    }
  }
}
