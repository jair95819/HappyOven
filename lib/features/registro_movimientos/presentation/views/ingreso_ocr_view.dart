import 'dart:io' as io;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/models/movimiento.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/services/ocr_service.dart';
import 'package:happy_oven/core/providers.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/viewmodels/catalogo_viewmodel.dart';
import 'package:happy_oven/features/registro_movimientos/presentation/viewmodels/movimientos_viewmodel.dart';

class IngresoOcrView extends ConsumerStatefulWidget {
  const IngresoOcrView({super.key});

  @override
  ConsumerState<IngresoOcrView> createState() => _IngresoOcrViewState();
}

class _IngresoOcrViewState extends ConsumerState<IngresoOcrView> {
  bool _mostrandoConfirmacion = false;
  bool _guardando = false;
  bool _procesandoOcr = false;

  final _proveedorController = TextEditingController(
    text: 'Molinos del Norte S.A.',
  );
  final _fechaController = TextEditingController(
    text:
        '${DateTime.now().day.toString().padLeft(2, '0')}/${DateTime.now().month.toString().padLeft(2, '0')}/${DateTime.now().year}',
  );

  final List<_ItemOCR> _items = [];

  final List<String> _unidades = ['kg', 'litros', 'unidades', 'gramos', 'ml'];

  double get _totalBoleta =>
      _items.fold(0, (sum, i) => sum + (i.cantidad * i.precioUnitario));

  @override
  void dispose() {
    _proveedorController.dispose();
    _fechaController.dispose();
    super.dispose();
  }

  void _simularEscaneo() {
    // Mostrar opciones: cámara o galería
    showModalBottomSheet(
      context: context,
      builder: (BuildContext context) {
        return SafeArea(
          child: Wrap(
            children: [
              ListTile(
                leading: const Icon(Icons.camera_alt),
                title: const Text('Capturar foto'),
                onTap: () {
                  Navigator.pop(context);
                  _capturarYProcesarOcr(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const Icon(Icons.image),
                title: const Text('Seleccionar de galería'),
                onTap: () {
                  Navigator.pop(context);
                  _capturarYProcesarOcr(ImageSource.gallery);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _capturarYProcesarOcr(ImageSource source) async {
    try {
      final picker = ImagePicker();
      final pickedFile = await picker.pickImage(source: source);

      if (pickedFile == null) return;

      setState(() => _procesandoOcr = true);

      final ocrService = OcrService();
      final recognizedText = await ocrService.reconocerTexto(
        io.File(pickedFile.path),
      );

      _procesarTextoOcr(recognizedText);

      if (mounted) {
        setState(() {
          _procesandoOcr = false;
          _mostrandoConfirmacion = true;
        });
      }
    } catch (e) {
      setState(() => _procesandoOcr = false);
      if (mounted) {
        _mostrarError('Error al procesar la imagen: $e');
      }
    }
  }

  void _procesarTextoOcr(String texto) {
    _items.clear();

    final lineas = texto.split('\n');

    for (final linea in lineas) {
      final limpia = linea.trim();
      if (limpia.isEmpty) continue;

      // Buscar patrones: nombre + cantidad + precio
      // Ejemplo: "Harina 50 kg 2.80" o "Mantequilla 20 kg 8.50"

      final item = _extraerItemDeLinea(limpia);
      if (item != null) {
        _items.add(item);
      }
    }

    // Si no encontró nada, mostrar el texto completo para que el usuario lo edite
    if (_items.isEmpty) {
      _mostrarError('No se encontraron ítems. Por favor, edita manualmente.');
      // Agregar un ítem vacío para que el usuario comience a editar
      _items.add(
        _ItemOCR(nombre: '', cantidad: 0, unidad: 'kg', precioUnitario: 0),
      );
    }
  }

  _ItemOCR? _extraerItemDeLinea(String linea) {
    // Intentar extraer: nombre (letras/espacios) + números (cantidad) + números (precio)
    // Patrón: palabras, seguidas de números, seguidas de más números

    final pattern = RegExp(
      r'([a-zA-ZáéíóúñÁÉÍÓÚÑ\s]+?)\s+(\d+(?:[.,]\d+)?)\s+([a-z]+)?\s*(\d+(?:[.,]\d+)?)',
      caseSensitive: false,
    );

    final match = pattern.firstMatch(linea);
    if (match == null) return null;

    String nombre = match.group(1)?.trim() ?? '';
    String cantidadStr = match.group(2) ?? '0';
    String? unidadStr = match.group(3)?.trim().toLowerCase();
    String precioStr = match.group(4) ?? '0';

    if (nombre.isEmpty) return null;

    double cantidad = double.tryParse(cantidadStr.replaceAll(',', '.')) ?? 0;
    double precio = double.tryParse(precioStr.replaceAll(',', '.')) ?? 0;

    String unidad = 'kg'; // default
    if (unidadStr != null) {
      if (unidadStr.startsWith('l')) {
        unidad = 'litros';
      } else if (unidadStr.startsWith('u')) {
        unidad = 'unidades';
      } else if (unidadStr.startsWith('g')) {
        unidad = 'gramos';
      } else if (unidadStr.startsWith('m')) {
        unidad = 'ml';
      }
    }

    if (cantidad <= 0 || precio <= 0) return null;

    return _ItemOCR(
      nombre: nombre,
      cantidad: cantidad,
      unidad: unidad,
      precioUnitario: precio,
    );
  }

  Future<void> _confirmarTodo() async {
    if (_guardando) return;

    // Validar que todos los ítems tienen nombre y cantidad
    final itemsInvalidos = _items
        .where((i) => i.nombre.trim().isEmpty || i.cantidad <= 0)
        .toList();
    if (itemsInvalidos.isNotEmpty) {
      _mostrarError('Todos los ítems deben tener nombre y cantidad válida');
      return;
    }

    setState(() => _guardando = true);

    final supabaseService = ref.read(supabaseServiceProvider);
    final usuarioId = supabaseService.getCurrentUser()?.id ?? '';

    // Buscar artículos en catálogo por nombre para obtener su ID
    final catalogoState = ref.read(catalogoViewModelProvider);
    final articulos = catalogoState.maybeWhen(
      data: (lista) => lista,
      orElse: () => <Articulo>[],
    );

    int exitosos = 0;
    int fallidos = 0;

    for (final item in _items) {
      // Buscar artículo por nombre (case-insensitive)
      final articuloMatch = articulos
          .where(
            (a) =>
                a.nombre.toLowerCase().trim() ==
                item.nombre.toLowerCase().trim(),
          )
          .toList();

      if (articuloMatch.isEmpty) {
        fallidos++;
        continue;
      }

      final articulo = articuloMatch.first;
      final nuevoStock = articulo.stockActual + item.cantidad;

      final movimiento = Movimiento(
        id: '',
        articuloId: articulo.id,
        usuarioId: usuarioId,
        tipoMovimiento: 'entrada',
        cantidad: item.cantidad,
        precioUnitario: item.precioUnitario,
        proveedor: _proveedorController.text.trim().isEmpty
            ? null
            : _proveedorController.text.trim(),
        porOcr: true,
        fecha: DateTime.now(),
      );

      final exito = await ref
          .read(movimientosViewModelProvider.notifier)
          .registrarMovimiento(movimiento, articulo, nuevoStock);

      if (exito) {
        exitosos++;
      } else {
        fallidos++;
      }
    }

    setState(() => _guardando = false);

    if (!mounted) return;

    if (fallidos == 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('$exitosos insumos registrados correctamente'),
          backgroundColor: AppTheme.colorsOf(context).statusNormal,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.radius.brSm),
        ),
      );
      context.pop();
    } else if (exitosos > 0) {
      // Algunos fallaron — probablemente el nombre no coincide con el catálogo
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            '$exitosos registrados. $fallidos no encontrados en catálogo — '
            'verifica que el nombre coincida exactamente.',
          ),
          backgroundColor: AppTheme.colorsOf(context).statusLow,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(borderRadius: AppTheme.radius.brSm),
          duration: const Duration(seconds: 5),
        ),
      );
    } else {
      _mostrarError(
        'No se encontraron los insumos en el catálogo. '
        'Verifica que los nombres coincidan exactamente.',
      );
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
    final colors = AppTheme.colorsOf(context);
    return Scaffold(
      backgroundColor: _mostrandoConfirmacion
          ? colors.bg
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
    if (_procesandoOcr) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const CircularProgressIndicator(),
            const SizedBox(height: 16),
            const Text(
              'Procesando imagen...',
              style: TextStyle(color: Colors.white),
            ),
          ],
        ),
      );
    }

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
              borderRadius: AppTheme.radius.brLg,
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
        Container(
          color: const Color(0xFF1A1A1A),
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 40),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: AppTheme.radius.brSm,
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
              GestureDetector(
                onTap: _simularEscaneo,
                child: Container(
                  width: 64,
                  height: 64,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    border: Border.all(
                      color: AppTheme.colors.primary,
                      width: 3,
                    ),
                  ),
                  child: Center(
                    child: Container(
                      width: 50,
                      height: 50,
                      decoration: BoxDecoration(
                        color: AppTheme.colors.primary,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ),
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  borderRadius: AppTheme.radius.brSm,
                  border: Border.all(
                    color: const Color(0xFF444444),
                    width: 0.5,
                  ),
                ),
                child: Icon(
                  Icons.bolt_outlined,
                  color: Colors.white.withValues(alpha: 0.6),
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
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);
    return Column(
      children: [
        _buildHeaderConfirmacion(context, colors, font),
        Expanded(child: _buildListaItems(context, colors, font)),
      ],
    );
  }

  Widget _buildHeaderConfirmacion(
    BuildContext context,
    AppColors colors,
    AppFont font,
  ) {
    return Container(
      color: colors.accent,
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
                          color: colors.accentDark,
                          width: 0.5,
                        ),
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
                      Text('Confirmar ingreso', style: font.h3),
                      Text(
                        'Revisa y corrige si es necesario',
                        style: font.caption.copyWith(color: colors.accentDark),
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
                  color: colors.card,
                  borderRadius: AppTheme.radius.brSm,
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Row(
                      children: [
                        Icon(
                          Icons.store_outlined,
                          color: colors.brownMid,
                          size: 15,
                        ),
                        const SizedBox(width: 8),
                        Text(
                          _proveedorController.text,
                          style: font.label.copyWith(fontSize: 12),
                        ),
                      ],
                    ),
                    Text(_fechaController.text, style: font.caption),
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
                  color: _items.isNotEmpty
                      ? colors.successLight
                      : colors.dangerLight,
                  borderRadius: AppTheme.radius.brSm,
                  border: Border.all(
                    color: _items.isNotEmpty
                        ? colors.successBorder
                        : colors.dangerBorder,
                    width: 0.5,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      _items.isNotEmpty
                          ? Icons.check_circle_outline
                          : Icons.warning_amber_rounded,
                      color: _items.isNotEmpty
                          ? colors.statusNormal
                          : colors.statusCritical,
                      size: 14,
                    ),
                    const SizedBox(width: 8),
                    Text(
                      _items.isEmpty
                          ? 'Edita manualmente los ítems'
                          : 'OCR detectó ${_items.length} insumo${_items.length != 1 ? 's' : ''}',
                      style: font.caption.copyWith(
                        fontWeight: FontWeight.w500,
                        color: _items.isNotEmpty
                            ? colors.statusNormal
                            : colors.statusCritical,
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

  Widget _buildListaItems(
    BuildContext context,
    AppColors colors,
    AppFont font,
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
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 20, 16, 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Insumos detectados',
                    style: font.label.copyWith(fontSize: 13),
                  ),
                  GestureDetector(
                    onTap: _agregarItem,
                    child: Row(
                      children: [
                        Icon(
                          Icons.add_rounded,
                          color: colors.primary,
                          size: 16,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Agregar ítem',
                          style: font.label.copyWith(
                            fontSize: 12,
                            color: colors.primary,
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
                itemBuilder: (context, index) =>
                    _buildItemCard(index, colors, font),
              ),
            ),
            // Total y botones
            Container(
              padding: const EdgeInsets.fromLTRB(14, 12, 14, 24),
              decoration: BoxDecoration(
                color: colors.card,
                border: Border(
                  top: BorderSide(color: colors.border, width: 0.5),
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
                      color: colors.surface,
                      borderRadius: AppTheme.radius.brSm,
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Total boleta',
                          style: font.label.copyWith(fontSize: 13),
                        ),
                        Text(
                          'S/ ${_totalBoleta.toStringAsFixed(2)}',
                          style: font.h3.copyWith(
                            fontSize: 16,
                            color: colors.primary,
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
                              borderRadius: AppTheme.radius.brSm,
                              border: Border.all(
                                color: colors.border,
                                width: 0.5,
                              ),
                            ),
                            child: Text(
                              'Volver a escanear',
                              textAlign: TextAlign.center,
                              style: font.label.copyWith(
                                fontSize: 13,
                                color: colors.bodyText,
                              ),
                            ),
                          ),
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: GestureDetector(
                          onTap: _guardando ? null : _confirmarTodo,
                          child: Container(
                            padding: const EdgeInsets.symmetric(vertical: 14),
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
                                    'Confirmar todo',
                                    textAlign: TextAlign.center,
                                    style: font.label.copyWith(
                                      fontSize: 13,
                                      color: colors.white,
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

  Widget _buildItemCard(int index, AppColors colors, AppFont font) {
    final item = _items[index];
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        border: Border.all(color: colors.border, width: 0.5),
        borderRadius: AppTheme.radius.brSm,
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
                  style: font.label.copyWith(fontSize: 12),
                  decoration: InputDecoration(
                    hintText: 'Nombre del insumo',
                    hintStyle: font.hint.copyWith(fontSize: 12),
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
                    color: colors.dangerLight,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Icon(
                    Icons.delete_outline_rounded,
                    color: colors.statusCritical,
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
                  colors: colors,
                  font: font,
                  onChanged: (v) => item.cantidad = double.tryParse(v) ?? 0,
                ),
              ),
              const SizedBox(width: 6),
              Expanded(child: _buildSelectorUnidadMini(index, colors, font)),
              const SizedBox(width: 6),
              Expanded(
                child: _buildMiniCampo(
                  label: 'PRECIO/u',
                  valor: item.precioUnitario == 0
                      ? ''
                      : item.precioUnitario.toString(),
                  colors: colors,
                  font: font,
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
    required AppColors colors,
    required AppFont font,
    String? prefijo,
    required Function(String) onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
      decoration: BoxDecoration(
        color: colors.primaryLight,
        borderRadius: AppTheme.radius.brSm,
        border: Border.all(color: colors.primaryBorder, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: font.caption.copyWith(
              fontSize: 8,
              color: colors.brownMid,
              fontWeight: FontWeight.w500,
            ),
          ),
          const SizedBox(height: 2),
          TextFormField(
            initialValue: prefijo != null && valor.isNotEmpty
                ? '$prefijo$valor'
                : valor,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            inputFormatters: [
              FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
            ],
            style: font.label.copyWith(fontSize: 13),
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

  Widget _buildSelectorUnidadMini(int index, AppColors colors, AppFont font) {
    return GestureDetector(
      onTap: () => _mostrarSelectorUnidad(index, colors, font),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
        decoration: BoxDecoration(
          color: colors.primaryLight,
          borderRadius: AppTheme.radius.brSm,
          border: Border.all(color: colors.primaryBorder, width: 0.5),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'UNIDAD',
              style: font.caption.copyWith(
                fontSize: 8,
                color: colors.brownMid,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 4),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  _items[index].unidad,
                  style: font.label.copyWith(fontSize: 13),
                ),
                Icon(
                  Icons.keyboard_arrow_down_rounded,
                  color: colors.brownMid,
                  size: 14,
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  void _mostrarSelectorUnidad(int index, AppColors colors, AppFont font) {
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
            Text('Seleccionar unidad', style: font.h3.copyWith(fontSize: 15)),
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
                      color: activo ? colors.titleText : colors.surface,
                      borderRadius: BorderRadius.circular(AppTheme.radius.full),
                      border: Border.all(
                        color: activo ? colors.titleText : colors.border,
                        width: 0.5,
                      ),
                    ),
                    child: Text(
                      u,
                      style: font.label.copyWith(
                        fontSize: 13,
                        fontWeight: activo
                            ? FontWeight.w500
                            : FontWeight.normal,
                        color: activo ? colors.white : colors.hint,
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
