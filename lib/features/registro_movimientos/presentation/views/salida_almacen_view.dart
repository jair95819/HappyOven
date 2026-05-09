import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/core/theme/theme.dart';

class SalidaAlmacenView extends StatefulWidget {
  const SalidaAlmacenView({super.key});

  @override
  State<SalidaAlmacenView> createState() => _SalidaAlmacenViewState();
}

class _SalidaAlmacenViewState extends State<SalidaAlmacenView> {
  _MotivoSalida _motivoSeleccionado = _MotivoSalida.venta;
  _ProductoFinal _productoSeleccionado = _productos.first;
  int _cantidad = 1;
  final _observacionController = TextEditingController();

  static final List<_ProductoFinal> _productos = [
    _ProductoFinal(nombre: 'Pan Francés', stock: 120, unidad: 'unid.'),
    _ProductoFinal(nombre: 'Torta Tres Leches', stock: 4, unidad: 'unid.'),
    _ProductoFinal(nombre: 'Croissant', stock: 35, unidad: 'unid.'),
    _ProductoFinal(nombre: 'Pan de Yema', stock: 8, unidad: 'unid.'),
  ];

  int get _stockResultante => (_productoSeleccionado.stock - _cantidad).clamp(0, 99999);

  void _incrementar() {
    if (_cantidad < _productoSeleccionado.stock) setState(() => _cantidad++);
  }

  void _decrementar() {
    if (_cantidad > 1) setState(() => _cantidad--);
  }

  void _registrar() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('Salida registrada: $_cantidad ${_productoSeleccionado.unidad} de ${_productoSeleccionado.nombre}'),
        backgroundColor: AppTheme.colors.statusNormal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radius.brSm),
      ),
    );
    context.pop();
  }

  @override
  void dispose() {
    _observacionController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colors.bg,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildFormulario(context)),
        ],
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
                    border: Border.all(color: AppTheme.colors.accentDark, width: 0.5),
                  ),
                  child: Icon(Icons.arrow_back_rounded, color: AppTheme.colors.titleText, size: 18),
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
              color: activo ? AppTheme.colors.titleText : AppTheme.colors.surface,
              borderRadius: AppTheme.radius.brSm,
              border: Border.all(color: activo ? AppTheme.colors.titleText : AppTheme.colors.border, width: 0.5),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(motivo.icono, color: activo ? AppTheme.colors.accent : AppTheme.colors.hint, size: 16),
                const SizedBox(width: 6),
                Text(motivo.etiqueta, style: AppTheme.font.bodySmall.copyWith(fontSize: 12,
                  fontWeight: activo ? FontWeight.w500 : FontWeight.normal,
                  color: activo ? AppTheme.colors.white : AppTheme.colors.hint)),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectorProducto(BuildContext context) {
    return GestureDetector(
      onTap: () => _mostrarSelectorProducto(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.colors.primaryLight,
          borderRadius: AppTheme.radius.brSm,
          border: Border.all(color: AppTheme.colors.border, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(children: [
              Icon(Icons.breakfast_dining_outlined, color: AppTheme.colors.brownMid, size: 16),
              const SizedBox(width: 10),
              Text(_productoSeleccionado.nombre, style: AppTheme.font.label.copyWith(fontSize: 13)),
            ]),
            Row(children: [
              Text('Stock: ${_productoSeleccionado.stock} ${_productoSeleccionado.unidad}',
                  style: AppTheme.font.caption),
              const SizedBox(width: 6),
              Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.colors.brownMid, size: 18),
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
            Text('Seleccionar producto', style: AppTheme.font.h3.copyWith(fontSize: 15)),
            const SizedBox(height: 16),
            ..._productos.map((p) {
              final activo = _productoSeleccionado == p;
              return GestureDetector(
                onTap: () {
                  setState(() { _productoSeleccionado = p; _cantidad = 1; });
                  Navigator.pop(context);
                },
                child: Container(
                  margin: const EdgeInsets.only(bottom: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: activo ? AppTheme.colors.primaryLight : AppTheme.colors.surface,
                    borderRadius: AppTheme.radius.brSm,
                    border: Border.all(color: activo ? AppTheme.colors.primaryBorder : AppTheme.colors.border, width: 0.5),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(p.nombre, style: AppTheme.font.bodySmall.copyWith(fontSize: 13,
                        fontWeight: activo ? FontWeight.w500 : FontWeight.normal,
                        color: AppTheme.colors.titleText)),
                      Text('Stock: ${p.stock} ${p.unidad}', style: AppTheme.font.caption),
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

  Widget _buildControlCantidad() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors.primaryLight,
        borderRadius: AppTheme.radius.brSm,
        border: Border.all(color: AppTheme.colors.border, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                Icon(Icons.remove_circle_outline, color: AppTheme.colors.brownMid, size: 16),
                const SizedBox(width: 10),
                Text('$_cantidad', style: AppTheme.font.h3.copyWith(fontSize: 16)),
                const SizedBox(width: 6),
                Text(_productoSeleccionado.unidad, style: AppTheme.font.caption.copyWith(fontSize: 12)),
              ]),
            ),
          ),
          Container(
            decoration: BoxDecoration(border: Border(left: BorderSide(color: AppTheme.colors.border, width: 0.5))),
            child: Row(children: [
              GestureDetector(
                onTap: _decrementar,
                child: Container(
                  width: 44, height: 46,
                  decoration: BoxDecoration(border: Border(right: BorderSide(color: AppTheme.colors.border, width: 0.5))),
                  child: Icon(Icons.remove_rounded, color: AppTheme.colors.brownMid, size: 18),
                ),
              ),
              GestureDetector(
                onTap: _incrementar,
                child: SizedBox(width: 44, height: 46,
                    child: Icon(Icons.add_rounded, color: AppTheme.colors.brownMid, size: 18)),
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
        color: AppTheme.colors.primaryLight,
        borderRadius: AppTheme.radius.brSm,
        border: Border.all(color: AppTheme.colors.border, width: 0.5),
      ),
      child: TextField(
        controller: _observacionController, maxLines: 3,
        style: AppTheme.font.bodySmall.copyWith(fontSize: 13, color: AppTheme.colors.titleText),
        decoration: InputDecoration(
          hintText: 'Ej. Venta del turno mañana...',
          hintStyle: AppTheme.font.hint.copyWith(fontSize: 13),
          border: InputBorder.none, contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  Widget _buildResumen() {
    final Color colorStock = _stockResultante <= 5 ? AppTheme.colors.statusCritical
        : _stockResultante <= 15 ? AppTheme.colors.primary : AppTheme.colors.statusNormal;
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(color: AppTheme.colors.surface, borderRadius: AppTheme.radius.brMd),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text('Stock después de salida', style: AppTheme.font.caption),
            const SizedBox(height: 4),
            RichText(text: TextSpan(children: [
              TextSpan(text: '$_stockResultante ', style: AppTheme.font.h3.copyWith(fontSize: 18, color: colorStock)),
              TextSpan(text: _productoSeleccionado.unidad, style: AppTheme.font.caption.copyWith(fontSize: 12)),
            ])),
          ]),
          Column(crossAxisAlignment: CrossAxisAlignment.end, children: [
            Text('Motivo', style: AppTheme.font.caption),
            const SizedBox(height: 4),
            Text(_motivoSeleccionado.etiqueta, style: AppTheme.font.label.copyWith(
              fontSize: 13, color: AppTheme.colors.primary)),
          ]),
        ],
      ),
    );
  }

  Widget _buildLabel(String texto) {
    return Text(texto.toUpperCase(), style: AppTheme.font.label.copyWith(
      fontSize: 10, color: AppTheme.colors.brownMid, letterSpacing: 0.5));
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

class _ProductoFinal {
  final String nombre; final int stock; final String unidad;
  const _ProductoFinal({required this.nombre, required this.stock, required this.unidad});
}
