import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';

class FormularioArticuloView extends StatefulWidget {
  const FormularioArticuloView({super.key});

  @override
  State<FormularioArticuloView> createState() => _FormularioArticuloViewState();
}

class _FormularioArticuloViewState extends State<FormularioArticuloView> {
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

  final _formKey = GlobalKey<FormState>();
  final _nombreController = TextEditingController();
  final _stockMinimoController = TextEditingController();
  final _stockInicialController = TextEditingController();

  _TipoArticulo _tipoSeleccionado = _TipoArticulo.insumo;
  String _unidadSeleccionada = 'kg';

  final List<String> _unidades = ['kg', 'litros', 'unidades', 'gramos', 'ml'];

  @override
  void dispose() {
    _nombreController.dispose();
    _stockMinimoController.dispose();
    _stockInicialController.dispose();
    super.dispose();
  }

  void _guardar() {
    if (_formKey.currentState!.validate()) {
      // TODO: conectar con InventarioViewModel → guardarArticulo()
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('Artículo guardado correctamente'),
          backgroundColor: _orange,
          behavior: SnackBarBehavior.floating,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10),
          ),
        ),
      );
      context.pop();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _beige,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildFormulario()),
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
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
                    'Nuevo artículo',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Completa los datos del artículo',
                    style: TextStyle(fontSize: 12, color: _oliveDark),
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
  Widget _buildFormulario() {
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
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 32),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // Tipo de artículo
                _buildLabel('Tipo de artículo'),
                const SizedBox(height: 8),
                _buildSelectorTipo(),
                const SizedBox(height: 20),

                // Nombre
                _buildLabel('Nombre'),
                const SizedBox(height: 6),
                _buildCampoTexto(
                  controller: _nombreController,
                  hint: 'Ej. Harina de trigo',
                  icono: Icons.label_outline_rounded,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'El nombre es obligatorio';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Unidad de medida
                _buildLabel('Unidad de medida'),
                const SizedBox(height: 8),
                _buildSelectorUnidades(),
                const SizedBox(height: 20),

                // Stock mínimo
                _buildLabel('Stock mínimo de seguridad'),
                const SizedBox(height: 6),
                _buildCampoNumerico(
                  controller: _stockMinimoController,
                  hint: 'Ej. 20',
                  icono: Icons.warning_amber_rounded,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingresa el stock mínimo';
                    }
                    if (double.tryParse(v) == null) {
                      return 'Ingresa un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 20),

                // Stock inicial
                _buildLabel('Stock inicial'),
                const SizedBox(height: 6),
                _buildCampoNumerico(
                  controller: _stockInicialController,
                  hint: 'Ej. 50',
                  icono: Icons.inventory_2_outlined,
                  validator: (v) {
                    if (v == null || v.trim().isEmpty) {
                      return 'Ingresa el stock inicial';
                    }
                    if (double.tryParse(v) == null) {
                      return 'Ingresa un número válido';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 32),

                // Botón guardar
                GestureDetector(
                  onTap: _guardar,
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    decoration: BoxDecoration(
                      color: _orange,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Text(
                      'Guardar artículo',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 15,
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
      ),
    );
  }

  // ── Selector tipo
  Widget _buildSelectorTipo() {
    return Row(
      children: _TipoArticulo.values.map((tipo) {
        final activo = _tipoSeleccionado == tipo;
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => _tipoSeleccionado = tipo),
            child: Container(
              margin: EdgeInsets.only(
                right: tipo == _TipoArticulo.insumo ? 8 : 0,
              ),
              padding: const EdgeInsets.symmetric(vertical: 12),
              decoration: BoxDecoration(
                color: activo ? _textDark : _beige,
                borderRadius: BorderRadius.circular(10),
                border: Border.all(
                  color: activo ? _textDark : _beigeDeep,
                  width: 0.5,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    tipo == _TipoArticulo.insumo
                        ? Icons.inventory_2_outlined
                        : Icons.breakfast_dining_outlined,
                    color: activo ? _olive : _textMuted,
                    size: 20,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    tipo == _TipoArticulo.insumo ? 'Insumo' : 'Producto final',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: activo ? FontWeight.w500 : FontWeight.normal,
                      color: activo ? Colors.white : _textMuted,
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

  // ── Selector unidades chips
  Widget _buildSelectorUnidades() {
    return Wrap(
      spacing: 8,
      runSpacing: 8,
      children: _unidades.map((unidad) {
        final activo = _unidadSeleccionada == unidad;
        return GestureDetector(
          onTap: () => setState(() => _unidadSeleccionada = unidad),
          child: Container(
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
            decoration: BoxDecoration(
              color: activo ? _textDark : _beige,
              borderRadius: BorderRadius.circular(999),
              border: Border.all(
                color: activo ? _textDark : _beigeDeep,
                width: 0.5,
              ),
            ),
            child: Text(
              unidad,
              style: TextStyle(
                fontSize: 12,
                fontWeight: activo ? FontWeight.w500 : FontWeight.normal,
                color: activo ? Colors.white : _textMuted,
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Campo de texto
  Widget _buildCampoTexto({
    required TextEditingController controller,
    required String hint,
    required IconData icono,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _orangeLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _brownLight, width: 0.5),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        style: TextStyle(fontSize: 14, color: _textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: _textMuted, fontSize: 14),
          prefixIcon: Icon(icono, color: _brownMid, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          errorStyle: TextStyle(fontSize: 11, color: Colors.red[700]),
        ),
      ),
    );
  }

  // ── Campo numérico
  Widget _buildCampoNumerico({
    required TextEditingController controller,
    required String hint,
    required IconData icono,
    String? Function(String?)? validator,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: _orangeLight,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _brownLight, width: 0.5),
      ),
      child: TextFormField(
        controller: controller,
        validator: validator,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        inputFormatters: [
          FilteringTextInputFormatter.allow(RegExp(r'^\d*\.?\d*')),
        ],
        style: TextStyle(fontSize: 14, color: _textDark),
        decoration: InputDecoration(
          hintText: hint,
          hintStyle: TextStyle(color: _textMuted, fontSize: 14),
          prefixIcon: Icon(icono, color: _brownMid, size: 18),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 14,
            vertical: 14,
          ),
          errorStyle: TextStyle(fontSize: 11, color: Colors.red[700]),
        ),
      ),
    );
  }

  // ── Label
  Widget _buildLabel(String texto) {
    return Text(
      texto.toUpperCase(),
      style: TextStyle(
        fontSize: 11,
        fontWeight: FontWeight.w500,
        color: _brownMid,
        letterSpacing: 0.5,
      ),
    );
  }
}

// ── Enum local
enum _TipoArticulo { insumo, productoFinal }
