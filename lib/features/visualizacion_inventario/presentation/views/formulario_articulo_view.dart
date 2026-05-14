import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/viewmodels/catalogo_viewmodel.dart';

class FormularioArticuloView extends ConsumerStatefulWidget {
  final Articulo? articulo;
  
  const FormularioArticuloView({super.key, this.articulo});

  @override
  ConsumerState<FormularioArticuloView> createState() => _FormularioArticuloViewState();
}

class _FormularioArticuloViewState extends ConsumerState<FormularioArticuloView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _stockMinimoController = TextEditingController();
  final _stockInicialController = TextEditingController();

  _TipoArticulo _tipoSeleccionado = _TipoArticulo.insumo;
  String _unidadSeleccionada = 'kg';
  final List<String> _unidades = ['kg', 'litros', 'unidades', 'gramos', 'ml'];
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.articulo != null) {
      final a = widget.articulo!;
      _nombreController.text = a.nombre;
      _stockMinimoController.text = a.stockMinimo.toString();
      _stockInicialController.text = a.stockActual.toString();
      _tipoSeleccionado = a.tipo == 'insumo' ? _TipoArticulo.insumo : _TipoArticulo.productoFinal;
      _unidadSeleccionada = a.unidad;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _stockMinimoController.dispose();
    _stockInicialController.dispose();
    super.dispose();
  }

  void _guardar() async {
    if (_isSaving) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final nuevoArticulo = Articulo(
        id: widget.articulo?.id ?? '', // Si tiene ID, se actualiza, si no, se crea
        nombre: _nombreController.text.trim(),
        tipo: _tipoSeleccionado == _TipoArticulo.insumo ? 'insumo' : 'producto_final',
        unidad: _unidadSeleccionada,
        stockActual: double.parse(_stockInicialController.text),
        stockMinimo: double.parse(_stockMinimoController.text),
        precioUnitario: widget.articulo?.precioUnitario ?? 0.0,
        activo: widget.articulo?.activo ?? true,
        createdAt: widget.articulo?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final error = await ref.read(catalogoViewModelProvider.notifier).guardarArticulo(nuevoArticulo);

      if (error == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Artículo guardado correctamente'),
            backgroundColor: AppTheme.colorsOf(context).primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppTheme.radius.brSm),
          ),
        );
        _retroceder();
      } else if (mounted) {
        setState(() => _isSaving = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error al guardar: $error'),
            backgroundColor: AppTheme.colorsOf(context).statusCritical,
          ),
        );
      }
    }
  }

  void _retroceder() {
    if (context.canPop()) {
      context.pop();
    } else {
      context.go('/catalogo');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colors.bg,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildFormulario()),
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Row(
            children: [
              GestureDetector(
                onTap: _retroceder,
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
                  Text(widget.articulo == null ? 'Nuevo artículo' : 'Editar artículo', style: AppTheme.font.h3),
                  const SizedBox(height: 2),
                  Text(widget.articulo == null ? 'Completa los datos del artículo' : 'Actualiza los datos del artículo',
                      style: AppTheme.font.caption.copyWith(color: AppTheme.colors.accentDark)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildFormulario() {
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                _buildLabel('Tipo de artículo'),
                const SizedBox(height: 8),
                _buildSelectorTipo(),
                const SizedBox(height: 20),
                _buildLabel('Nombre'),
                const SizedBox(height: 6),
                _buildCampoTexto(
                  controller: _nombreController, hint: 'Ej. Harina de trigo',
                  icono: Icons.label_outline_rounded,
                  validator: (v) => (v == null || v.trim().isEmpty) ? 'El nombre es obligatorio' : null,
                ),
                const SizedBox(height: 20),
                _buildLabel('Unidad de medida'),
                const SizedBox(height: 8),
                _buildSelectorUnidades(),
                const SizedBox(height: 20),
                _buildLabel('Stock mínimo de seguridad'),
                const SizedBox(height: 6),
                _buildCampoNumerico(
                  controller: _stockMinimoController, hint: 'Ej. 20',
                  icono: Icons.warning_amber_rounded,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa el stock mínimo';
                    if (double.tryParse(v) == null) return 'Ingresa un número válido';
                    return null;
                  },
                ),
                const SizedBox(height: 20),
                _buildLabel('Stock inicial'),
                const SizedBox(height: 6),
                _buildCampoNumerico(
                  controller: _stockInicialController, hint: 'Ej. 50',
                  icono: Icons.inventory_2_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) return 'Ingresa el stock inicial';
                    if (double.tryParse(v) == null) return 'Ingresa un número válido';
                    return null;
                  },
                ),
                const SizedBox(height: 32),
                GestureDetector(
                  onTap: _isSaving ? null : _guardar,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _isSaving ? AppTheme.colors.hint : AppTheme.colors.primary,
                      borderRadius: AppTheme.radius.brMd,
                    ),
                    child: _isSaving
                        ? SizedBox(
                            height: 18, width: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2, color: AppTheme.colors.white,
                            ),
                          )
                        : Text('Guardar artículo',
                            textAlign: TextAlign.center, style: AppTheme.font.button),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorTipo() {
    return Row(
      children: _TipoArticulo.values.map((tipo) {
        final activo = _tipoSeleccionado == tipo;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _tipoSeleccionado = tipo),
            child: Container(
              margin: EdgeInsets.only(right: tipo == _TipoArticulo.insumo ? 8 : 0),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: activo ? AppTheme.colors.titleText : AppTheme.colors.surface,
                borderRadius: AppTheme.radius.brSm,
                border: Border.all(
                  color: activo ? AppTheme.colors.titleText : AppTheme.colors.border, width: 0.5),
              ),
              child: Column(
                children: [
                  Icon(
                    tipo == _TipoArticulo.insumo ? Icons.inventory_2_outlined : Icons.breakfast_dining_outlined,
                    color: activo ? AppTheme.colors.accent : AppTheme.colors.hint, size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tipo == _TipoArticulo.insumo ? 'Insumo' : 'Producto final',
                    style: AppTheme.font.bodySmall.copyWith(fontSize: 12,
                      fontWeight: activo ? FontWeight.w500 : FontWeight.normal,
                      color: activo ? AppTheme.colors.white : AppTheme.colors.hint),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildSelectorUnidades() {
    return Wrap(
      spacing: 8, runSpacing: 8,
      children: _unidades.map((unidad) {
        final activo = _unidadSeleccionada == unidad;
        return GestureDetector(
          onTap: () => setState(() => _unidadSeleccionada = unidad),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: activo ? AppTheme.colors.titleText : AppTheme.colors.surface,
              borderRadius: BorderRadius.circular(AppTheme.radius.full),
              border: Border.all(
                color: activo ? AppTheme.colors.titleText : AppTheme.colors.border, width: 0.5),
            ),
            child: Text(unidad, style: AppTheme.font.bodySmall.copyWith(fontSize: 12,
              fontWeight: activo ? FontWeight.w500 : FontWeight.normal,
              color: activo ? AppTheme.colors.white : AppTheme.colors.hint)),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCampoTexto({
    required TextEditingController controller, required String hint,
    required IconData icono, String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors.primaryLight,
        borderRadius: AppTheme.radius.brSm,
        border: Border.all(color: AppTheme.colors.border, width: 0.5),
      ),
      child: TextFormField(
        controller: controller, validator: validator,
        style: AppTheme.font.bodySmall.copyWith(color: AppTheme.colors.titleText),
        decoration: InputDecoration(
          hintText: hint, hintStyle: AppTheme.font.hint,
          prefixIcon: Icon(icono, color: AppTheme.colors.brownMid, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          errorStyle: TextStyle(fontSize: 11, color: AppTheme.colors.statusCritical),
        ),
      ),
    );
  }

  Widget _buildCampoNumerico({
    required TextEditingController controller, required String hint,
    required IconData icono, String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors.primaryLight,
        borderRadius: AppTheme.radius.brSm,
        border: Border.all(color: AppTheme.colors.border, width: 0.5),
      ),
      child: TextFormField(
        controller: controller, validator: validator,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*'))],
        style: AppTheme.font.bodySmall.copyWith(color: AppTheme.colors.titleText),
        decoration: InputDecoration(
          hintText: hint, hintStyle: AppTheme.font.hint,
          prefixIcon: Icon(icono, color: AppTheme.colors.brownMid, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
          errorStyle: TextStyle(fontSize: 11, color: AppTheme.colors.statusCritical),
        ),
      ),
    );
  }

  Widget _buildLabel(String texto) {
    return Text(
      texto.toUpperCase(),
      style: AppTheme.font.label.copyWith(
        fontSize: 11, color: AppTheme.colors.brownMid, letterSpacing: 0.5),
    );
  }
}

enum _TipoArticulo { insumo, productoFinal }
