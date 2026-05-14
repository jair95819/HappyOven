import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/models/movimiento.dart';
import 'package:happy_oven/core/services/ocr_service.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/viewmodels/catalogo_viewmodel.dart';
import 'package:happy_oven/features/registro_movimientos/presentation/viewmodels/movimientos_viewmodel.dart';
import 'package:happy_oven/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:image_picker/image_picker.dart';
import 'package:intl/intl.dart';
import 'dart:io';

class IngresoOcrView extends ConsumerStatefulWidget {
  const IngresoOcrView({super.key});

  @override
  ConsumerState<IngresoOcrView> createState() => _IngresoOcrViewState();
}

class _IngresoOcrViewState extends ConsumerState<IngresoOcrView> {
  bool _mostrandoConfirmacion = false;
  bool _procesando = false;

  final _proveedorController = TextEditingController(text: '');
  final _fechaController = TextEditingController(
    text: DateFormat('dd/MM/yyyy').format(DateTime.now()),
  );
  final _ocrService = OcrService();
  final _imagePicker = ImagePicker();

  List<_ItemOCR> _items = [];
  List<Articulo> _articulosDisponibles = [];

  double get _totalBoleta =>
      _items.fold(0, (sum, i) => sum + (i.cantidad * i.precioUnitario));
  final List<String> _unidades = ['kg', 'litros', 'unidades', 'gramos', 'ml'];

  @override
  void dispose() {
    _proveedorController.dispose();
    _fechaController.dispose();
    _ocrService.dispose();
    super.dispose();
  }

  Future<void> _escanear(ImageSource source) async {
    final picked = await _imagePicker.pickImage(
      source: source,
      imageQuality: 85,
    );
    if (picked == null) return;

    setState(() => _procesando = true);

    try {
      final file = File(picked.path);
      final textoRaw = await _ocrService.reconocerTexto(file);

      final ocrItems = _ocrService.parsearBoleta(textoRaw);

      final listaItems = ocrItems.map((o) {
        final item = _ItemOCR(
          nombreRaw: o.nombreRaw,
          cantidad: o.cantidad,
          unidad: o.unidad,
          precioUnitario: o.precioUnitario,
        );
        // Auto-enlazar por nombre parcial
        try {
          item.articulo = _articulosDisponibles.firstWhere(
            (a) => a.nombre.toLowerCase().contains(
              o.nombreRaw.toLowerCase().split(' ').first,
            ),
          );
          item.unidad = item.articulo!.unidad;
        } catch (_) {}
        return item;
      }).toList();

      setState(() {
        _items = listaItems;
        _mostrandoConfirmacion = true;
        _procesando = false;
      });

      if (listaItems.isEmpty && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'No se detectaron items. Agrégalos manualmente.',
            ),
            backgroundColor: AppTheme.colorsOf(context).primary,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } catch (e) {
      setState(() => _procesando = false);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al procesar imagen: $e'),
            backgroundColor: AppTheme.colorsOf(context).statusCritical,
          ),
        );
      }
    }
  }

  void _confirmarTodo() async {
    final user = ref.read(authViewModelProvider).usuario;
    if (user == null) return;

    if (_items.any((i) => i.articulo == null)) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Todos los ítems deben estar enlazados a un artículo'),
          backgroundColor: AppTheme.colorsOf(context).statusCritical,
        ),
      );
      return;
    }

    for (final item in _items) {
      final articulo = item.articulo!;
      final mov = Movimiento(
        id: '',
        articuloId: articulo.id,
        usuarioId: user.id,
        tipoMovimiento: 'entrada',
        cantidad: item.cantidad,
        precioUnitario: item.precioUnitario,
        proveedor: _proveedorController.text.trim(),
        porOcr: true,
        fecha: DateTime.now(),
      );
      final nuevoStock = articulo.stockActual + item.cantidad;
      await ref
          .read(movimientosViewModelProvider.notifier)
          .registrarMovimiento(mov, articulo, nuevoStock);
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('${_items.length} insumos registrados correctamente'),
          backgroundColor: AppTheme.colorsOf(context).statusNormal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.radius.brSm),
        ),
      );
      context.pop();
    }
  }

  void _agregarItem() {
    setState(
      () => _items.add(
        _ItemOCR(
          nombreRaw: 'Nuevo insumo',
          cantidad: 0,
          unidad: 'kg',
          precioUnitario: 0,
        ),
      ),
    );
  }

  void _eliminarItem(int index) {
    setState(() => _items.removeAt(index));
  }

  @override
  Widget build(BuildContext context) {
    final catalogoState = ref.watch(catalogoViewModelProvider);
    _articulosDisponibles = catalogoState.value ?? [];

    return Scaffold(
      backgroundColor: _mostrandoConfirmacion
          ? AppTheme.colorsOf(context).bg
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
                        borderRadius: AppTheme.radius.brSm,
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
                      Text(
                        'Escanear boleta',
                        style: AppTheme.font.label.copyWith(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Apunta la cámara a la boleta',
                        style: AppTheme.font.caption.copyWith(
                          color: Colors.white.withValues(alpha: 0.5),
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
        Expanded(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(AppTheme.radius.lg),
              child: Stack(
                children: [
                  Container(color: const Color(0xFF2A2A2A)),
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
                            AppTheme.colors.primary,
                            Colors.transparent,
                          ],
                        ),
                      ),
                    ),
                  ),
                  Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          color: Colors.white.withValues(alpha: 0.3),
                          size: 48,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          'Encuadra la boleta completa',
                          style: TextStyle(
                            fontSize: 13,
                            color: Colors.white.withValues(alpha: 0.4),
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
        if (_procesando)
          Container(
            color: const Color(0xFF1A1A1A),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Column(
              children: [
                const CircularProgressIndicator(color: Colors.white),
                const SizedBox(height: 12),
                Text(
                  'Procesando OCR...',
                  style: TextStyle(
                    color: Colors.white.withValues(alpha: 0.6),
                    fontSize: 13,
                  ),
                ),
              ],
            ),
          )
        else
          Container(
            color: const Color(0xFF1A1A1A),
            padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: [
                GestureDetector(
                  onTap: () => _escanear(ImageSource.gallery),
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: AppTheme.radius.brMd,
                      border: Border.all(
                        color: const Color(0xFF444444),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      Icons.photo_library_outlined,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 20,
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () => _escanear(ImageSource.camera),
                  child: Container(
                    width: 64,
                    height: 64,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: AppTheme.colorsOf(context).primary,
                        width: 3,
                      ),
                    ),
                    child: Center(
                      child: Container(
                        width: 50,
                        height: 50,
                        decoration: BoxDecoration(
                          color: AppTheme.colorsOf(context).primary,
                          shape: BoxShape.circle,
                        ),
                      ),
                    ),
                  ),
                ),
                GestureDetector(
                  onTap: () {
                    // Ingreso manual sin escaneo
                    setState(() {
                      _items = [];
                      _mostrandoConfirmacion = true;
                    });
                  },
                  child: Container(
                    width: 42,
                    height: 42,
                    decoration: BoxDecoration(
                      borderRadius: AppTheme.radius.brMd,
                      border: Border.all(
                        color: const Color(0xFF444444),
                        width: 0.5,
                      ),
                    ),
                    child: Icon(
                      Icons.edit_note_outlined,
                      color: Colors.white.withValues(alpha: 0.6),
                      size: 20,
                    ),
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
          top: top
              ? BorderSide(color: AppTheme.colors.primary, width: 2.5)
              : BorderSide.none,
          bottom: !top
              ? BorderSide(color: AppTheme.colors.primary, width: 2.5)
              : BorderSide.none,
          left: left
              ? BorderSide(color: AppTheme.colors.primary, width: 2.5)
              : BorderSide.none,
          right: !left
              ? BorderSide(color: AppTheme.colors.primary, width: 2.5)
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
                      width: 36,
                      height: 36,
                      decoration: BoxDecoration(
                        borderRadius: AppTheme.radius.brSm,
                        border: Border.all(
                          color: AppTheme.colors.accentDark,
                          width: 0.5,
                        ),
                      ),
                      child: Icon(
                        Icons.arrow_back_rounded,
                        color: AppTheme.colors.titleText,
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
                        style: AppTheme.font.h3.copyWith(fontSize: 18),
                      ),
                      Text(
                        'Revisa y corrige si es necesario',
                        style: AppTheme.font.caption.copyWith(
                          color: AppTheme.colors.accentDark,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 14,
                  vertical: 10,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.colors.card,
                  borderRadius: AppTheme.radius.brMd,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.store_outlined,
                          color: AppTheme.colors.brownMid,
                          size: 15,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _proveedorController.text,
                          style: AppTheme.font.label.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                    Text(_fechaController.text, style: AppTheme.font.caption),
                  ],
                ),
              ),
              const SizedBox(height: 8),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 7,
                ),
                decoration: BoxDecoration(
                  color: AppTheme.colors.successLight,
                  borderRadius: AppTheme.radius.brSm,
                  border: Border.all(
                    color: AppTheme.colors.successBorder,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.document_scanner_outlined,
                      color: AppTheme.colors.statusNormal,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'OCR detectó ${_items.length} insumos en la boleta',
                      style: AppTheme.font.caption.copyWith(
                        fontWeight: FontWeight.w500,
                        color: AppTheme.colors.statusNormal,
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
                  Text(
                    'Insumos detectados',
                    style: AppTheme.font.label.copyWith(fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: _agregarItem,
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_rounded,
                          color: AppTheme.colors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Agregar ítem',
                          style: AppTheme.font.label.copyWith(
                            fontSize: 12,
                            color: AppTheme.colors.primary,
                          ),
                        ),
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
                border: Border(
                  top: BorderSide(color: AppTheme.colors.border, width: 0.5),
                ),
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.colors.surface,
                      borderRadius: AppTheme.radius.brMd,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total boleta',
                          style: AppTheme.font.label.copyWith(fontSize: 13),
                        ),
                        Text(
                          'S/ ${_totalBoleta.toStringAsFixed(2)}',
                          style: AppTheme.font.h3.copyWith(
                            fontSize: 16,
                            color: AppTheme.colors.primary,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: GestureDetector(
                          onTap: () =>
                              setState(() => _mostrandoConfirmacion = false),
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            decoration: BoxDecoration(
                              borderRadius: AppTheme.radius.brMd,
                              border: Border.all(
                                color: AppTheme.colors.border,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              'Volver a escanear',
                              textAlign: TextAlign.center,
                              style: AppTheme.font.label.copyWith(
                                fontSize: 13,
                                color: AppTheme.colors.bodyText,
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
                              color: AppTheme.colors.primary,
                              borderRadius: AppTheme.radius.brMd,
                            ),
                            child: Text(
                              'Confirmar todo',
                              textAlign: TextAlign.center,
                              style: AppTheme.font.label.copyWith(
                                fontSize: 13,
                                color: AppTheme.colors.white,
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
                child: GestureDetector(
                  onTap: () => _mostrarSelectorArticulo(index),
                  child: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 8,
                    ),
                    decoration: BoxDecoration(
                      color: AppTheme.colorsOf(context).surface,
                      borderRadius: AppTheme.radius.brSm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          item.articulo?.nombre ?? 'Seleccionar artículo...',
                          style: AppTheme.fontOf(context).label.copyWith(
                            fontSize: 13,
                            color: item.articulo == null
                                ? AppTheme.colorsOf(context).statusCritical
                                : AppTheme.colorsOf(context).titleText,
                          ),
                        ),
                        Icon(
                          Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.colorsOf(context).hint,
                          size: 16,
                        ),
                      ],
                    ),
                  ),
                ),
              ),
              const SizedBox(width: 8),
              GestureDetector(
                onTap: () => _eliminarItem(index),
                child: Container(
                  width: 24,
                  height: 24,
                  decoration: BoxDecoration(
                    color: AppTheme.colors.dangerLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: AppTheme.colors.statusCritical,
                    size: 14,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
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
        color: AppTheme.colors.primaryLight,
        borderRadius: AppTheme.radius.brSm,
        border: Border.all(color: AppTheme.colors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.font.caption.copyWith(
              fontSize: 8,
              color: AppTheme.colors.brownMid,
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
            style: AppTheme.font.label.copyWith(fontSize: 13),
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
          color: AppTheme.colors.primaryLight,
          borderRadius: AppTheme.radius.brSm,
          border: Border.all(color: AppTheme.colors.border, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UNIDAD',
              style: AppTheme.font.caption.copyWith(
                fontSize: 8,
                color: AppTheme.colors.brownMid,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _items[index].unidad,
                  style: AppTheme.font.label.copyWith(fontSize: 13),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: AppTheme.colors.brownMid,
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
            Text(
              'Seleccionar unidad',
              style: AppTheme.fontOf(context).h3.copyWith(fontSize: 15),
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
                      color: activo
                          ? AppTheme.colorsOf(context).titleText
                          : AppTheme.colorsOf(context).surface,
                      borderRadius: BorderRadius.circular(AppTheme.radius.full),
                      border: Border.all(
                        color: activo
                            ? AppTheme.colorsOf(context).titleText
                            : AppTheme.colorsOf(context).border,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      u,
                      style: AppTheme.fontOf(context).bodySmall.copyWith(
                        fontSize: 13,
                        fontWeight: activo
                            ? FontWeight.w500
                            : FontWeight.normal,
                        color: activo
                            ? AppTheme.colorsOf(context).white
                            : AppTheme.colorsOf(context).hint,
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

  void _mostrarSelectorArticulo(int index) {
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Enlazar con artículo',
              style: AppTheme.fontOf(context).h3.copyWith(fontSize: 15),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: ListView.builder(
                itemCount: _articulosDisponibles.length,
                itemBuilder: (context, i) {
                  final a = _articulosDisponibles[i];
                  return ListTile(
                    title: Text(
                      a.nombre,
                      style: AppTheme.fontOf(context).bodySmall,
                    ),
                    subtitle: Text(
                      'Stock actual: ${a.stockActual} ${a.unidad}',
                      style: AppTheme.fontOf(context).caption,
                    ),
                    onTap: () {
                      setState(() {
                        _items[index].articulo = a;
                        _items[index].unidad = a.unidad;
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
    );
  }
}

class _ItemOCR {
  Articulo? articulo;
  String nombreRaw;
  double cantidad;
  String unidad;
  double precioUnitario;
  _ItemOCR({
    required this.nombreRaw,
    required this.cantidad,
    required this.unidad,
    required this.precioUnitario,
  });
}
