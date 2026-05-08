import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class SalidaAlmacenView extends StatefulWidget {
  const SalidaAlmacenView({super.key});

  @override
  State<SalidaAlmacenView> createState() => _SalidaAlmacenViewState();
}

class _SalidaAlmacenViewState extends State<SalidaAlmacenView> {
  static const _olive = Color(0xFFC8CA9E);
  static const _oliveDark = Color(0xFF4A4A38);
  static const _orange = Color(0xFFFF8C42);
  static const _orangeLight = Color(0xFFFFF3EB);
  static const _brownMid = Color(0xFFA8714A);
  static const _brownLight = Color(0xFFD4A47A);
  static const _beige = Color(0xFFF5F0E8);
  static const _beigeDeep = Color(0xFFEDE5D6);
  static const _textDark = Color(0xFF2C2C2A);
  static const _textMuted = Color(0xFFBFB5A0);
  static const _success = Color(0xFF3B6D11);

  _MotivoSalida _motivoSeleccionado = _MotivoSalida.venta;
  _ProductoFinal _productoSeleccionado = _productos.first;
  int _cantidad = 1;
  final _observacionController = TextEditingController();

  // Datos de ejemplo — luego vendrán del ViewModel
  static final List<_ProductoFinal> _productos = [
    _ProductoFinal(nombre: 'Pan Francés', stock: 120, unidad: 'unid.'),
    _ProductoFinal(nombre: 'Torta Tres Leches', stock: 4, unidad: 'unid.'),
    _ProductoFinal(nombre: 'Croissant', stock: 35, unidad: 'unid.'),
    _ProductoFinal(nombre: 'Pan de Yema', stock: 8, unidad: 'unid.'),
  ];

  int get _stockResultante =>
      (_productoSeleccionado.stock - _cantidad).clamp(0, 99999);

  void _incrementar() {
    if (_cantidad < _productoSeleccionado.stock) {
      setState(() => _cantidad++);
    }
  }

  void _decrementar() {
    if (_cantidad > 1) setState(() => _cantidad--);
  }

  void _registrar() {
    // TODO: conectar con MovimientosViewModel → registrarSalida()
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          'Salida registrada: $_cantidad ${_productoSeleccionado.unidad} de ${_productoSeleccionado.nombre}',
        ),
        backgroundColor: _success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
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
      backgroundColor: _beige,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildFormulario(context)),
        ],
      ),
    );
  }

  // ── Header oliva
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: _olive,
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
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(color: _oliveDark, width: 0.5),
                  ),
                  child: const Icon(
                    Icons.arrow_back_rounded,
                    color: _textDark,
                    size: 18,
                  ),
                ),
              ),
              const SizedBox(width: 14),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Registrar salida',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w500,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Descuento de productos finales',
                    style: TextStyle(fontSize: 11, color: _oliveDark),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Formulario
  Widget _buildFormulario(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
      ),
      transform: Matrix4.translationValues(0, -16, 0),
      child: ClipRRect(
        borderRadius: const BorderRadius.only(
          topLeft: Radius.circular(24),
          topRight: Radius.circular(24),
        ),
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 26, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Motivo
              _buildLabel('Motivo de salida'),
              const SizedBox(height: 8),
              _buildSelectorMotivo(),
              const SizedBox(height: 20),

              // Producto
              _buildLabel('Producto final'),
              const SizedBox(height: 6),
              _buildSelectorProducto(context),
              const SizedBox(height: 20),

              // Cantidad
              _buildLabel('Cantidad a descontar'),
              const SizedBox(height: 6),
              _buildControlCantidad(),
              const SizedBox(height: 20),

              // Observación
              _buildLabel('Observación (opcional)'),
              const SizedBox(height: 6),
              _buildCampoObservacion(),
              const SizedBox(height: 20),

              // Resumen
              _buildResumen(),
              const SizedBox(height: 24),

              // Botón registrar
              GestureDetector(
                onTap: _registrar,
                child: Container(
                  padding: const EdgeInsets.symmetric(vertical: 15),
                  decoration: BoxDecoration(
                    color: _orange,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: const Text(
                    'Registrar salida',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Selector motivo
  Widget _buildSelectorMotivo() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 8,
      mainAxisSpacing: 8,
      childAspectRatio: 2.8,
      children: _MotivoSalida.values.map((motivo) {
        final activo = _motivoSeleccionado == motivo;
        return GestureDetector(
          onTap: () => setState(() => _motivoSeleccionado = motivo),
          child: Container(
            decoration: BoxDecoration(
              color: activo ? _textDark : _beige,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(
                color: activo ? _textDark : _beigeDeep,
                width: 0.5,
              ),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  motivo.icono,
                  color: activo ? _olive : _textMuted,
                  size: 16,
                ),
                const SizedBox(width: 6),
                Text(
                  motivo.etiqueta,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: activo ? FontWeight.w500 : FontWeight.normal,
                    color: activo ? Colors.white : _textMuted,
                  ),
                ),
              ],
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Selector producto
  Widget _buildSelectorProducto(BuildContext context) {
    return GestureDetector(
      onTap: () => _mostrarSelectorProducto(context),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: _orangeLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _brownLight, width: 0.5),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Row(
              children: [
                Icon(
                  Icons.breakfast_dining_outlined,
                  color: _brownMid,
                  size: 16,
                ),
                const SizedBox(width: 10),
                Text(
                  _productoSeleccionado.nombre,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _textDark,
                  ),
                ),
              ],
            ),
            Row(
              children: [
                Text(
                  'Stock: ${_productoSeleccionado.stock} ${_productoSeleccionado.unidad}',
                  style: TextStyle(fontSize: 10, color: _textMuted),
                ),
                const SizedBox(width: 6),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _brownMid,
                  size: 18,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarSelectorProducto(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Seleccionar producto',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 16),
            ..._productos.map((p) {
              final activo = _productoSeleccionado == p;
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
                    color: activo ? _orangeLight : _beige,
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: activo ? _brownLight : _beigeDeep,
                      width: 0.5,
                    ),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        p.nombre,
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: activo
                              ? FontWeight.w500
                              : FontWeight.normal,
                          color: _textDark,
                        ),
                      ),
                      Text(
                        'Stock: ${p.stock} ${p.unidad}',
                        style: TextStyle(fontSize: 11, color: _textMuted),
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

  // ── Control cantidad +/-
  Widget _buildControlCantidad() {
    return Container(
      decoration: BoxDecoration(
        color: _orangeLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _brownLight, width: 0.5),
      ),
      child: Row(
        children: [
          Expanded(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(
                children: [
                  Icon(Icons.remove_circle_outline, color: _brownMid, size: 16),
                  const SizedBox(width: 10),
                  Text(
                    '$_cantidad',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w500,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    _productoSeleccionado.unidad,
                    style: TextStyle(fontSize: 12, color: _textMuted),
                  ),
                ],
              ),
            ),
          ),
          // Botones
          Container(
            decoration: BoxDecoration(
              border: Border(left: BorderSide(color: _brownLight, width: 0.5)),
            ),
            child: Row(
              children: [
                // Menos
                GestureDetector(
                  onTap: _decrementar,
                  child: Container(
                    width: 44,
                    height: 46,
                    decoration: BoxDecoration(
                      border: Border(
                        right: BorderSide(color: _brownLight, width: 0.5),
                      ),
                    ),
                    child: Icon(
                      Icons.remove_rounded,
                      color: _brownMid,
                      size: 18,
                    ),
                  ),
                ),
                // Más
                GestureDetector(
                  onTap: _incrementar,
                  child: SizedBox(
                    width: 44,
                    height: 46,
                    child: Icon(Icons.add_rounded, color: _brownMid, size: 18),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  // ── Campo observación
  Widget _buildCampoObservacion() {
    return Container(
      decoration: BoxDecoration(
        color: _orangeLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _brownLight, width: 0.5),
      ),
      child: TextField(
        controller: _observacionController,
        maxLines: 3,
        style: TextStyle(fontSize: 13, color: _textDark),
        decoration: InputDecoration(
          hintText: 'Ej. Venta del turno mañana...',
          hintStyle: TextStyle(color: _textMuted, fontSize: 13),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.all(14),
        ),
      ),
    );
  }

  // ── Resumen
  Widget _buildResumen() {
    final Color colorStock = _stockResultante <= 5
        ? const Color(0xFFA32D2D)
        : _stockResultante <= 15
        ? _orange
        : _success;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      decoration: BoxDecoration(
        color: _beige,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Stock después de salida',
                style: TextStyle(fontSize: 10, color: _textMuted),
              ),
              const SizedBox(height: 4),
              RichText(
                text: TextSpan(
                  children: [
                    TextSpan(
                      text: '$_stockResultante ',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w500,
                        color: colorStock,
                      ),
                    ),
                    TextSpan(
                      text: _productoSeleccionado.unidad,
                      style: TextStyle(fontSize: 12, color: _textMuted),
                    ),
                  ],
                ),
              ),
            ],
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text('Motivo', style: TextStyle(fontSize: 10, color: _textMuted)),
              const SizedBox(height: 4),
              Text(
                _motivoSeleccionado.etiqueta,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _orange,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  // ── Label
  Widget _buildLabel(String texto) {
    return Text(
      texto.toUpperCase(),
      style: TextStyle(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: _brownMid,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ── Enums y modelos locales temporales
enum _MotivoSalida {
  venta,
  merma,
  degustacion,
  ajuste;

  String get etiqueta {
    switch (this) {
      case _MotivoSalida.venta:
        return 'Venta';
      case _MotivoSalida.merma:
        return 'Merma';
      case _MotivoSalida.degustacion:
        return 'Degustación';
      case _MotivoSalida.ajuste:
        return 'Ajuste';
    }
  }

  IconData get icono {
    switch (this) {
      case _MotivoSalida.venta:
        return Icons.shopping_cart_outlined;
      case _MotivoSalida.merma:
        return Icons.delete_outline_rounded;
      case _MotivoSalida.degustacion:
        return Icons.card_giftcard_outlined;
      case _MotivoSalida.ajuste:
        return Icons.tune_rounded;
    }
  }
}

class _ProductoFinal {
  final String nombre;
  final int stock;
  final String unidad;

  const _ProductoFinal({
    required this.nombre,
    required this.stock,
    required this.unidad,
  });
}
