import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class IngresoOcrView extends StatefulWidget {
  const IngresoOcrView({super.key});

  @override
  State<IngresoOcrView> createState() => _IngresoOcrViewState();
}

class _IngresoOcrViewState extends State<IngresoOcrView> {
  static const _olive = Color(0xFFC8CA9E);
  static const _oliveDark = Color(0xFF4A4A38);
  static const _orange = Color(0xFFFF8C42);
  static const _orangeLight = Color(0xFFFFF3EB);
  static const _brownMid = Color(0xFFA8714A);
  static const _brownLight = Color(0xFFD4A47A);
  static const _beige = Color(0xFFF5F0E8);
  static const _beigeDeep = Color(0xFFEDE5D6);
  static const _textDark = Color(0xFF2C2C2A);
  static const _textGray = Color(0xFF5F5E5A);
  static const _textMuted = Color(0xFFBFB5A0);
  static const _danger = Color(0xFFA32D2D);
  static const _dangerLight = Color(0xFFFCEBEB);
  static const _success = Color(0xFF3B6D11);
  static const _successLight = Color(0xFFEAF3DE);
  static const _successBorde = Color(0xFFC2DFA8);

  // false = cámara, true = confirmación
  bool _mostrandoConfirmacion = false;

  // Proveedor y fecha detectados por OCR
  final _proveedorController = TextEditingController(
    text: 'Molinos del Norte S.A.',
  );
  final _fechaController = TextEditingController(text: '07/05/2026');

  // Lista de insumos detectados — luego vendrán del OCR real
  final List<_ItemOCR> _items = [
    _ItemOCR(
      nombre: 'Harina de trigo',
      cantidad: 50,
      unidad: 'kg',
      precioUnitario: 2.80,
    ),
    _ItemOCR(
      nombre: 'Mantequilla',
      cantidad: 20,
      unidad: 'kg',
      precioUnitario: 8.50,
    ),
    _ItemOCR(
      nombre: 'Huevos',
      cantidad: 180,
      unidad: 'unid.',
      precioUnitario: 0.35,
    ),
    _ItemOCR(
      nombre: 'Azúcar',
      cantidad: 25,
      unidad: 'kg',
      precioUnitario: 3.20,
    ),
  ];

  double get _totalBoleta =>
      _items.fold(0, (sum, i) => sum + (i.cantidad * i.precioUnitario));

  final List<String> _unidades = ['kg', 'litros', 'unidades', 'gramos', 'ml'];

  @override
  void dispose() {
    _proveedorController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  void _simularEscaneo() {
    // TODO: reemplazar con google_mlkit_text_recognition real
    setState(() => _mostrandoConfirmacion = true);
  }

  void _confirmarTodo() {
    // TODO: conectar con MovimientosViewModel → registrarIngresoMasivo()
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_items.length} insumos registrados correctamente'),
        backgroundColor: _success,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      ),
    );
    context.pop();
  }

  void _agregarItem() {
    setState(() {
      _items.add(
        _ItemOCR(nombre: '', cantidad: 0, unidad: 'kg', precioUnitario: 0),
      );
    });
  }

  void _eliminarItem(int index) {
    setState(() => _items.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mostrandoConfirmacion
          ? _beige
          : const Color(0xFF1A1A1A),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _mostrandoConfirmacion
            ? _buildConfirmacion(context)
            : _buildCamara(context),
      ),
    );
  }

  // ── ESTADO 1: Cámara
  Widget _buildCamara(BuildContext context) {
    return Column(
      children: [
        // Top bar oscuro
        Container(
          color: const Color(0xFF1A1A1A),
          child: SafeArea(
            bottom: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  GestureDetector(
                    onTap: () => context.pop(),
                    child: Container(
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: const Color(0xFF444444),
                          width: 0.5,
                        ),
                      ),
                      child: const Icon(
                        Icons.arrow_back_rounded,
                        color: Colors.white,
                        size: 18,
                      ),
                    ),
                  ),
                  Column(
                    children: [
                      const Text(
                        'Escanear boleta',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                          color: Colors.white,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Apunta la cámara a la boleta',
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.white.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),
          ),
        ),

        // Visor cámara
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(16),
              child: Stack(
                children: [
                  // Fondo simulado cámara
                  Container(color: const Color(0xFF2A2A2A)),
                  // Guías de encuadre
                  Positioned(
                    top: 16,
                    left: 16,
                    child: _guia(top: true, left: true),
                  ),
                  Positioned(
                    top: 16,
                    right: 16,
                    child: _guia(top: true, left: false),
                  ),
                  Positioned(
                    bottom: 16,
                    left: 16,
                    child: _guia(top: false, left: true),
                  ),
                  Positioned(
                    bottom: 16,
                    right: 16,
                    child: _guia(top: false, left: false),
                  ),
                  // Línea de escaneo
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.18,
                    left: 16,
                    right: 16,
                    child: Container(
                      height: 1.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            Colors.transparent,
                            _orange,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  // Texto centro
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          color: Colors.white.withOpacity(0.3),
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Encuadra la boleta completa',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withOpacity(0.4),
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

        // Controles cámara
        Container(
          color: const Color(0xFF1A1A1A),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              // Galería
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF444444),
                    width: 0.5,
                  ),
                ),
                child: Icon(
                  Icons.photo_library_outlined,
                  color: Colors.white.withOpacity(0.6),
                  size: 20,
                ),
              ),
              // Botón captura
              GestureDetector(
                onTap: _simularEscaneo,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: _orange, width: 3),
                  ),
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: const BoxDecoration(
                        color: _orange,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              // Flash
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: const Color(0xFF444444),
                    width: 0.5,
                  ),
                ),
                child: Icon(
                  Icons.bolt_outlined,
                  color: Colors.white.withOpacity(0.6),
                  size: 20,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _guia({required bool top, required bool left}) {
    return Container(
      width: 24,
      height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: top ? BorderSide(color: _orange, width: 2.5) : BorderSide.none,
          bottom: !top
              ? BorderSide(color: _orange, width: 2.5)
              : BorderSide.none,
          left: left ? BorderSide(color: _orange, width: 2.5) : BorderSide.none,
          right: !left
              ? BorderSide(color: _orange, width: 2.5)
              : BorderSide.none,
        ),
        borderRadius: BorderRadius.only(
          topLeft: top && left ? const Radius.circular(3) : Radius.zero,
          topRight: top && !left ? const Radius.circular(3) : Radius.zero,
          bottomLeft: !top && left ? const Radius.circular(3) : Radius.zero,
          bottomRight: !top && !left ? const Radius.circular(3) : Radius.zero,
        ),
      ),
    );
  }

  // ── ESTADO 2: Confirmación
  Widget _buildConfirmacion(BuildContext context) {
    return Column(
      children: [
        _buildHeaderConfirmacion(context),
        Expanded(child: _buildListaItems()),
      ],
    );
  }

  Widget _buildHeaderConfirmacion(BuildContext context) {
    return Container(
      color: _olive,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 14, 20, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  GestureDetector(
                    onTap: () => setState(() => _mostrandoConfirmacion = false),
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
                        'Confirmar ingreso',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w500,
                          color: _textDark,
                        ),
                      ),
                      Text(
                        'Revisa y corrige si es necesario',
                        style: TextStyle(fontSize: 11, color: _oliveDark),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              // Info proveedor
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.store_outlined, color: _brownMid, size: 15),
                        const SizedBox(width: 8),
                        Text(
                          _proveedorController.text,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _textDark,
                          ),
                        ),
                      ],
                    ),
                    Text(
                      _fechaController.text,
                      style: TextStyle(fontSize: 11, color: _textMuted),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              // Badge OCR
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: _successLight,
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(color: _successBorde, width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.document_scanner_outlined,
                      color: _success,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'OCR detectó ${_items.length} insumos en la boleta',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        color: _success,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildListaItems() {
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
        child: Column(
          children: [
            // Header lista
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Insumos detectados',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                      color: _textDark,
                    ),
                  ),
                  GestureDetector(
                    onTap: _agregarItem,
                    child: Row(
                      children: [
                        Icon(Icons.add_rounded, color: _orange, size: 16),
                        const SizedBox(width: 4),
                        Text(
                          'Agregar ítem',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                            color: _orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // Lista scrollable
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _buildItemCard(index),
              ),
            ),

            // Total y botones
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              decoration: BoxDecoration(
                color: Colors.white,
                border: Border(top: BorderSide(color: _beigeDeep, width: 0.5)),
              ),
              child: Column(
                children: [
                  // Total
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: _beige,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total boleta',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _textDark,
                          ),
                        ),
                        Text(
                          'S/ ${_totalBoleta.toStringAsFixed(2)}',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w500,
                            color: _orange,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  // Botones
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _mostrandoConfirmacion = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: _beigeDeep, width: 0.5),
                            ),
                            child: Text(
                              'Volver a escanear',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: _textGray,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: _confirmarTodo,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              color: _orange,
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: const Text(
                              'Confirmar todo',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w500,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildItemCard(int index) {
    final item = _items[index];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: _beigeDeep, width: 0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nombre + eliminar
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.nombre,
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w500,
                    color: _textDark,
                  ),
                  decoration: InputDecoration(
                    hintText: 'Nombre del insumo',
                    hintStyle: TextStyle(color: _textMuted, fontSize: 12),
                    border: InputBorder.none,
                    isDense: true,
                    contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) => item.nombre = v,
                ),
              ),
              GestureDetector(
                onTap: () => _eliminarItem(index),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: _dangerLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: _danger,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          // Cantidad, unidad, precio
          Row(
            children: [
              Expanded(
                child: _buildMiniCampo(
                  label: 'CANTIDAD',
                  valor: item.cantidad == 0 ? '' : item.cantidad.toString(),
                  esNumero: true,
                  onChanged: (v) => item.cantidad = double.tryParse(v) ?? 0,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(child: _buildSelectorUnidadMini(index)),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMiniCampo(
                  label: 'PRECIO/u',
                  valor: item.precioUnitario == 0
                      ? ''
                      : item.precioUnitario.toString(),
                  esNumero: true,
                  prefijo: 'S/',
                  onChanged: (v) =>
                      item.precioUnitario = double.tryParse(v) ?? 0,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCampo({
    required String label,
    required String valor,
    required bool esNumero,
    String? prefijo,
    required Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: _orangeLight,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: _brownLight, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 8,
              color: _brownMid,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          TextFormField(
            initialValue: prefijo != null && valor.isNotEmpty
                ? '$prefijo$valor'
                : valor,
            keyboardType: esNumero
                ? const TextInputType.numberWithOptions(decimal: true)
                : TextInputType.text,
            inputFormatters: esNumero
                ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))]
                : null,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _textDark,
            ),
            decoration: const InputDecoration(
              border: InputBorder.none,
              isDense: true,
              contentPadding: EdgeInsets.zero,
            ),
            onChanged: onChanged,
          ),
        ],
      ),
    );
  }

  Widget _buildSelectorUnidadMini(int index) {
    return GestureDetector(
      onTap: () => _mostrarSelectorUnidad(index),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: _orangeLight,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: _brownLight, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UNIDAD',
              style: TextStyle(
                fontSize: 8,
                color: _brownMid,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _items[index].unidad,
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w500,
                    color: _textDark,
                  ),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: _brownMid,
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarSelectorUnidad(int index) {
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
              'Seleccionar unidad',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
                color: _textDark,
              ),
            ),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: _unidades.map((u) {
                final activo = _items[index].unidad == u;
                return GestureDetector(
                  onTap: () {
                    setState(() => _items[index].unidad = u);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 16,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: activo ? _textDark : _beige,
                      borderRadius: BorderRadius.circular(999),
                      border: Border.all(
                        color: activo ? _textDark : _beigeDeep,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      u,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: activo
                            ? FontWeight.w500
                            : FontWeight.normal,
                        color: activo ? Colors.white : _textMuted,
                      ),
                    ),
                  ),
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Modelo local temporal
class _ItemOCR {
  String nombre;
  double cantidad;
  String unidad;
  double precioUnitario;

  _ItemOCR({
    required this.nombre,
    required this.cantidad,
    required this.unidad,
    required this.precioUnitario,
  });
}
