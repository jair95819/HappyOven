import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/widgets/ho_ui.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/models/enums.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/viewmodels/catalogo_viewmodel.dart';

class FormularioArticuloView extends ConsumerStatefulWidget {
  final Articulo? articulo;

  const FormularioArticuloView({super.key, this.articulo});

  @override
  ConsumerState<FormularioArticuloView> createState() =>
      _FormularioArticuloViewState();
}

class _FormularioArticuloViewState
    extends ConsumerState<FormularioArticuloView> {
  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _stockMinimoController = TextEditingController();
  final _stockInicialController = TextEditingController();
  final _precioController = TextEditingController();

  TipoArticulo _tipoSeleccionado = TipoArticulo.insumo;
  UnidadMedida _unidadSeleccionada = UnidadMedida.kg;
  final List<UnidadMedida> _unidades = UnidadMedida.values;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.articulo != null) {
      final a = widget.articulo!;
      _nombreController.text = a.nombre;
      _stockMinimoController.text = a.stockMinimo.toString();
      _stockInicialController.text = a.stockActual.toString();
      _precioController.text = a.precioUnitario.toString();
      _tipoSeleccionado = a.tipo;
      _unidadSeleccionada = a.unidad;
    }
  }

  @override
  void dispose() {
    _nombreController.dispose();
    _stockMinimoController.dispose();
    _stockInicialController.dispose();
    _precioController.dispose();
    super.dispose();
  }

  void _guardar() async {
    if (_isSaving) return;
    if (_formKey.currentState!.validate()) {
      setState(() => _isSaving = true);
      final nuevoArticulo = Articulo(
        id:
            widget.articulo?.id ??
            '', // Si tiene ID, se actualiza, si no, se crea
        nombre: _nombreController.text.trim(),
        tipo: _tipoSeleccionado,
        unidad: _unidadSeleccionada,
        stockActual: double.parse(_stockInicialController.text),
        stockMinimo: double.parse(_stockMinimoController.text),
        precioUnitario:
            double.tryParse(_precioController.text) ??
            widget.articulo?.precioUnitario ??
            0.0,
        activo: widget.articulo?.activo ?? true,
        createdAt: widget.articulo?.createdAt ?? DateTime.now(),
        updatedAt: DateTime.now(),
      );

      final error = await ref
          .read(catalogoViewModelProvider.notifier)
          .guardarArticulo(nuevoArticulo);

      if (error == null && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('Artículo guardado correctamente'),
            backgroundColor: AppTheme.colorsOf(context).primary,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(borderRadius: AppTheme.radius.brSm),
          ),
        );
        // Si la vista fue abierta con Navigator.push, devolver el artículo editado como resultado
        if (Navigator.of(context).canPop()) {
          Navigator.of(context).pop(nuevoArticulo);
        } else {
          _retroceder();
        }
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
    final editando = widget.articulo != null;
    return Scaffold(
      backgroundColor: AppTheme.colorsOf(context).bg,
      appBar: HoTopBar(
        title: editando ? 'Editar insumo' : 'Nuevo insumo',
        subtitle: editando
            ? 'Actualiza los datos del insumo'
            : 'Completa los datos del insumo',
        onBack: _retroceder,
      ),
      body: _buildFormulario(),
    );
  }

  Widget _buildFormulario() {
    return Container(
      decoration: BoxDecoration(color: AppTheme.colorsOf(context).bg),
      child: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 32),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildLabel('NOMBRE DEL INSUMO'),
              const SizedBox(height: 6),
              _buildCampoTexto(
                controller: _nombreController,
                hint: 'Ej. Harina de trigo especial',
                icono: Icons.label_outline_rounded,
                validator: (v) => (v == null || v.trim().isEmpty)
                    ? 'El nombre es obligatorio'
                    : null,
              ),
              const SizedBox(height: 20),
              _buildLabel('UNIDAD DE MEDIDA'),
              const SizedBox(height: 6),
              _buildSelectorUnidades(),
              const SizedBox(height: 20),
              _buildLabel('STOCK MÍNIMO DE SEGURIDAD'),
              const SizedBox(height: 6),
              _buildCampoNumerico(
                controller: _stockMinimoController,
                hint: 'Ej. 20',
                icono: Icons.warning_amber_rounded,
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Ingresa el stock mínimo';
                  if (double.tryParse(v) == null)
                    return 'Ingresa un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildLabel('STOCK INICIAL'),
              const SizedBox(height: 6),
              _buildCampoNumerico(
                controller: _stockInicialController,
                hint: 'Ej. 50',
                icono: Icons.inventory_2_outlined,
                validator: (v) {
                  if (v == null || v.trim().isEmpty)
                    return 'Ingresa el stock inicial';
                  if (double.tryParse(v) == null)
                    return 'Ingresa un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 20),
              _buildLabel('PRECIO UNITARIO ESTIM. (S/)'),
              const SizedBox(height: 6),
              _buildCampoNumerico(
                controller: _precioController,
                hint: 'Ej. 12.50',
                icono: Icons.attach_money_rounded,
                validator: (v) {
                  if (v == null || v.trim().isEmpty) return null;
                  if (double.tryParse(v) == null)
                    return 'Ingresa un número válido';
                  return null;
                },
              ),
              const SizedBox(height: 28),
              HoPrimaryButton(
                label: 'Guardar insumo',
                loading: _isSaving,
                onPressed: _guardar,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSelectorTipo() {
    return Row(
      children: TipoArticulo.values.map((tipo) {
        final activo = _tipoSeleccionado == tipo;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _tipoSeleccionado = tipo),
            child: Container(
              margin: EdgeInsets.only(
                right: tipo == TipoArticulo.insumo ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: activo
                    ? AppTheme.colors.titleText
                    : AppTheme.colors.surface,
                borderRadius: AppTheme.radius.brSm,
                border: Border.all(
                  color: activo
                      ? AppTheme.colors.titleText
                      : AppTheme.colors.border,
                  width: 0.5,
                ),
                boxShadow: AppTheme.shadows.cardSm,
              ),
              child: Column(
                children: [
                  Icon(
                    tipo == TipoArticulo.insumo
                        ? Icons.inventory_2_outlined
                        : Icons.breakfast_dining_outlined,
                    color: activo
                        ? AppTheme.colors.accent
                        : AppTheme.colors.hint,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tipo == TipoArticulo.insumo ? 'Insumo' : 'Producto final',
                    style: AppTheme.font.bodySmall.copyWith(
                      fontSize: 12,
                      fontWeight: activo ? FontWeight.w500 : FontWeight.normal,
                      color: activo
                          ? AppTheme.colors.white
                          : AppTheme.colors.hint,
                    ),
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
    final c = AppTheme.colorsOf(context);
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _unidades.map((unidad) {
        final activo = _unidadSeleccionada == unidad;
        return Material(
          color: activo ? c.primary : c.primaryLight,
          borderRadius: BorderRadius.circular(999),
          child: InkWell(
            borderRadius: BorderRadius.circular(999),
            onTap: () => setState(() => _unidadSeleccionada = unidad),
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              child: Text(
                unidad.dbValue,
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w600,
                  color: activo ? c.white : c.bodyText,
                ),
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildCampoTexto({
    required TextEditingController controller,
    required String hint,
    required IconData icono,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      style: TextStyle(fontSize: 15, color: AppTheme.colorsOf(context).titleText),
      decoration: hoInputDecoration(context, hint: hint, icon: icono),
    );
  }

  Widget _buildCampoNumerico({
    required TextEditingController controller,
    required String hint,
    required IconData icono,
    String? Function(String?)? validator,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: const TextInputType.numberWithOptions(decimal: true),
      inputFormatters: [
        FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
      ],
      style: TextStyle(fontSize: 15, color: AppTheme.colorsOf(context).titleText),
      decoration: hoInputDecoration(context, hint: hint, icon: icono),
    );
  }

  Widget _buildLabel(String texto) {
    return Text(texto.toUpperCase(), style: AppTheme.fontOf(context).section);
  }
}
