import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/core/theme/theme.dart';

class IngresoOcrView extends StatefulWidget {
  const IngresoOcrView({super.key});

  @override
  State<IngresoOcrView> createState() => _IngresoOcrViewState();
}

class _IngresoOcrViewState extends State<IngresoOcrView> {
  bool _mostrandoConfirmacion = false;

  final _proveedorController = TextEditingController(text: 'Molinos del Norte S.A.');
  final _fechaController = TextEditingController(text: '07/05/2026');

  final List<_ItemOCR> _items = [
    _ItemOCR(nombre: 'Harina de trigo', cantidad: 50, unidad: 'kg', precioUnitario: 2.80),
    _ItemOCR(nombre: 'Mantequilla', cantidad: 20, unidad: 'kg', precioUnitario: 8.50),
    _ItemOCR(nombre: 'Huevos', cantidad: 180, unidad: 'unid.', precioUnitario: 0.35),
    _ItemOCR(nombre: 'Azúcar', cantidad: 25, unidad: 'kg', precioUnitario: 3.20),
  ];

  double get _totalBoleta => _items.fold(0, (sum, i) => sum + (i.cantidad * i.precioUnitario));
  final List<String> _unidades = ['kg', 'litros', 'unidades', 'gramos', 'ml'];

  @override
  void dispose() {
    _proveedorController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  void _simularEscaneo() {
    setState(() => _mostrandoConfirmacion = true);
  }

  void _confirmarTodo() {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${_items.length} insumos registrados correctamente'),
        backgroundColor: AppTheme.colors.statusNormal,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: AppTheme.radius.brSm),
      ),
    );
    context.pop();
  }

  void _agregarItem() {
    setState(() => _items.add(_ItemOCR(nombre: '', cantidad: 0, unidad: 'kg', precioUnitario: 0)));
  }

  void _eliminarItem(int index) {
    setState(() => _items.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _mostrandoConfirmacion ? AppTheme.colors.bg : const Color(0xFF1A1A1A),
      body: AnimatedSwitcher(
        duration: const Duration(milliseconds: 300),
        child: _mostrandoConfirmacion ? _buildConfirmacion(context) : _buildCamara(context),
      ),
    );
  }

  // ── ESTADO 1: Cámara
  Widget _buildCamara(BuildContext context) {
    return Column(
      children: [
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
                      width: 36, height: 36,
                      decoration: BoxDecoration(
                        borderRadius: AppTheme.radius.brSm,
                        border: Border.all(color: const Color(0xFF444444), width: 0.5),
                      ),
                      child: const Icon(Icons.arrow_back_rounded, color: Colors.white, size: 18),
                    ),
                  ),
                  Column(
                    children: [
                      Text('Escanear boleta', style: AppTheme.font.label.copyWith(
                        color: Colors.white, fontSize: 16, fontWeight: FontWeight.w500)),
                      const SizedBox(height: 2),
                      Text('Apunta la cámara a la boleta',
                          style: AppTheme.font.caption.copyWith(color: Colors.white.withValues(alpha: 0.5))),
                    ],
                  ),
                  const SizedBox(width: 36),
                ],
              ),
            ),
          ),
        ),
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radius.lg),
              child: Stack(
                children: [
                  Container(color: const Color(0xFF2A2A2A)),
                  Positioned(top: 16, left: 16, child: _guia(top: true, left: true)),
                  Positioned(top: 16, right: 16, child: _guia(top: true, left: false)),
                  Positioned(bottom: 16, left: 16, child: _guia(top: false, left: true)),
                  Positioned(bottom: 16, right: 16, child: _guia(top: false, left: false)),
                  Positioned(
                    top: MediaQuery.of(context).size.height * 0.18,
                    left: 16, right: 16,
                    child: Container(
                      height: 1.5,
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [Colors.transparent, AppTheme.colors.primary, Colors.transparent],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.receipt_long_outlined, color: Colors.white.withValues(alpha: 0.3), size: 48),
                        const SizedBox(height: 12),
                        Text('Encuadra la boleta completa',
                            style: TextStyle(fontSize: 13, color: Colors.white.withValues(alpha: 0.4))),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        Container(
          color: const Color(0xFF1A1A1A),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  borderRadius: AppTheme.radius.brMd,
                  border: Border.all(color: const Color(0xFF444444), width: 0.5),
                ),
                child: Icon(Icons.photo_library_outlined, color: Colors.white.withValues(alpha: 0.6), size: 20),
              ),
              GestureDetector(
                onTap: _simularEscaneo,
                child: Container(
                  width: 64, height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(color: AppTheme.colors.primary, width: 3),
                  ),
                  child: Center(
                    child: Container(
                      width: 50, height: 50,
                      decoration: BoxDecoration(color: AppTheme.colors.primary, shape: BoxShape.circle),
                    ),
                  ),
                ),
              ),
              Container(
                width: 42, height: 42,
                decoration: BoxDecoration(
                  borderRadius: AppTheme.radius.brMd,
                  border: Border.all(color: const Color(0xFF444444), width: 0.5),
                ),
                child: Icon(Icons.bolt_outlined, color: Colors.white.withValues(alpha: 0.6), size: 20),
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _guia({required bool top, required bool left}) {
    return Container(
      width: 24, height: 24,
      decoration: BoxDecoration(
        border: Border(
          top: top ? BorderSide(color: AppTheme.colors.primary, width: 2.5) : BorderSide.none,
          bottom: !top ? BorderSide(color: AppTheme.colors.primary, width: 2.5) : BorderSide.none,
          left: left ? BorderSide(color: AppTheme.colors.primary, width: 2.5) : BorderSide.none,
          right: !left ? BorderSide(color: AppTheme.colors.primary, width: 2.5) : BorderSide.none,
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
      color: AppTheme.colors.accent,
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
                      Text('Confirmar ingreso', style: AppTheme.font.h3.copyWith(fontSize: 18)),
                      Text('Revisa y corrige si es necesario',
                          style: AppTheme.font.caption.copyWith(color: AppTheme.colors.accentDark)),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                decoration: BoxDecoration(
                  color: AppTheme.colors.card,
                  borderRadius: AppTheme.radius.brMd,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(Icons.store_outlined, color: AppTheme.colors.brownMid, size: 15),
                        const SizedBox(width: 8),
                        Text(_proveedorController.text, style: AppTheme.font.label.copyWith(fontSize: 12)),
                      ],
                    ),
                    Text(_fechaController.text, style: AppTheme.font.caption),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
                decoration: BoxDecoration(
                  color: AppTheme.colors.successLight,
                  borderRadius: AppTheme.radius.brSm,
                  border: Border.all(color: AppTheme.colors.successBorder, width: 0.5),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.document_scanner_outlined, color: AppTheme.colors.statusNormal, size: 14),
                    const SizedBox(width: 8),
                    Text('OCR detectó ${_items.length} insumos en la boleta',
                        style: AppTheme.font.caption.copyWith(
                          fontWeight: FontWeight.w500, color: AppTheme.colors.statusNormal)),
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Insumos detectados', style: AppTheme.font.label.copyWith(fontSize: 13)),
                  GestureDetector(
                    onTap: _agregarItem,
                    child: Row(
                      children: [
                        Icon(Icons.add_rounded, color: AppTheme.colors.primary, size: 16),
                        const SizedBox(width: 4),
                        Text('Agregar ítem', style: AppTheme.font.label.copyWith(
                          fontSize: 12, color: AppTheme.colors.primary)),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            Expanded(
              child: ListView.separated(
                padding: const EdgeInsets.fromLTRB(14, 0, 14, 8),
                itemCount: _items.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (context, index) => _buildItemCard(index),
              ),
            ),
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              decoration: BoxDecoration(
                color: AppTheme.colors.card,
                border: Border(top: BorderSide(color: AppTheme.colors.border, width: 0.5)),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.colors.surface,
                      borderRadius: AppTheme.radius.brMd,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Total boleta', style: AppTheme.font.label.copyWith(fontSize: 13)),
                        Text('S/ ${_totalBoleta.toStringAsFixed(2)}',
                            style: AppTheme.font.h3.copyWith(fontSize: 16, color: AppTheme.colors.primary)),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () => setState(() => _mostrandoConfirmacion = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: AppTheme.radius.brMd,
                              border: Border.all(color: AppTheme.colors.border, width: 0.5),
                            ),
                            child: Text('Volver a escanear', textAlign: TextAlign.center,
                                style: AppTheme.font.label.copyWith(fontSize: 13, color: AppTheme.colors.bodyText)),
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
                              color: AppTheme.colors.primary,
                              borderRadius: AppTheme.radius.brMd,
                            ),
                            child: Text('Confirmar todo', textAlign: TextAlign.center,
                                style: AppTheme.font.label.copyWith(fontSize: 13, color: AppTheme.colors.white)),
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
        border: Border.all(color: AppTheme.colors.border, width: 0.5),
        borderRadius: AppTheme.radius.brMd,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Expanded(
                child: TextFormField(
                  initialValue: item.nombre,
                  style: AppTheme.font.label.copyWith(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Nombre del insumo',
                    hintStyle: AppTheme.font.hint.copyWith(fontSize: 12),
                    border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero,
                  ),
                  onChanged: (v) => item.nombre = v,
                ),
              ),
              GestureDetector(
                onTap: () => _eliminarItem(index),
                child: Container(
                  width: 24, height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.colors.dangerLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(Icons.delete_outline_rounded, color: AppTheme.colors.statusCritical, size: 14),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(child: _buildMiniCampo(label: 'CANTIDAD',
                  valor: item.cantidad == 0 ? '' : item.cantidad.toString(), esNumero: true,
                  onChanged: (v) => item.cantidad = double.tryParse(v) ?? 0)),
              const SizedBox(width: 6),
              Expanded(child: _buildSelectorUnidadMini(index)),
              const SizedBox(width: 6),
              Expanded(child: _buildMiniCampo(label: 'PRECIO/u',
                  valor: item.precioUnitario == 0 ? '' : item.precioUnitario.toString(),
                  esNumero: true, prefijo: 'S/',
                  onChanged: (v) => item.precioUnitario = double.tryParse(v) ?? 0)),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildMiniCampo({
    required String label, required String valor, required bool esNumero,
    String? prefijo, required Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: AppTheme.colors.primaryLight,
        borderRadius: AppTheme.radius.brSm,
        border: Border.all(color: AppTheme.colors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: AppTheme.font.caption.copyWith(
            fontSize: 8, color: AppTheme.colors.brownMid, fontWeight: FontWeight.w500)),
          const SizedBox(height: 2),
          TextFormField(
            initialValue: prefijo != null && valor.isNotEmpty ? '$prefijo$valor' : valor,
            keyboardType: esNumero ? const TextInputType.numberWithOptions(decimal: true) : TextInputType.text,
            inputFormatters: esNumero ? [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))] : null,
            style: AppTheme.font.label.copyWith(fontSize: 13),
            decoration: const InputDecoration(border: InputBorder.none, isDense: true, contentPadding: EdgeInsets.zero),
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
          color: AppTheme.colors.primaryLight,
          borderRadius: AppTheme.radius.brSm,
          border: Border.all(color: AppTheme.colors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('UNIDAD', style: AppTheme.font.caption.copyWith(
              fontSize: 8, color: AppTheme.colors.brownMid, fontWeight: FontWeight.w500)),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(_items[index].unidad, style: AppTheme.font.label.copyWith(fontSize: 13)),
                Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.colors.brownMid, size: 14),
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radius.xl)),
      ),
      builder: (_) => Padding(
        padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Seleccionar unidad', style: AppTheme.font.h3.copyWith(fontSize: 15)),
            const SizedBox(height: 16),
            Wrap(
              spacing: 8, runSpacing: 8,
              children: _unidades.map((u) {
                final activo = _items[index].unidad == u;
                return GestureDetector(
                  onTap: () {
                    setState(() => _items[index].unidad = u);
                    Navigator.pop(context);
                  },
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    decoration: BoxDecoration(
                      color: activo ? AppTheme.colors.titleText : AppTheme.colors.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radius.full),
                      border: Border.all(
                        color: activo ? AppTheme.colors.titleText : AppTheme.colors.border, width: 0.5),
                    ),
                    child: Text(u, style: AppTheme.font.bodySmall.copyWith(fontSize: 13,
                      fontWeight: activo ? FontWeight.w500 : FontWeight.normal,
                      color: activo ? AppTheme.colors.white : AppTheme.colors.hint)),
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

class _ItemOCR {
  String nombre;
  double cantidad;
  String unidad;
  double precioUnitario;
  _ItemOCR({required this.nombre, required this.cantidad, required this.unidad, required this.precioUnitario});
}
