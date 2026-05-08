import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class CosteoDinamicoView extends StatefulWidget {
  const CosteoDinamicoView({super.key});

  @override
  State<CosteoDinamicoView> createState() => _CosteoDinamicoViewState();
}

class _CosteoDinamicoViewState extends State<CosteoDinamicoView> {
  static const _olive = Color(0xFFC8CA9E);
  static const _oliveDark = Color(0xFF4A4A38);
  static const _orange = Color(0xFFFF8C42);
  static const _orangeLight = Color(0xFFFFF3EB);
  static const _orangeBorde = Color(0xFFFFD9BE);
  static const _beige = Color(0xFFF5F0E8);
  static const _beigeDeep = Color(0xFFEDE5D6);
  static const _textDark = Color(0xFF2C2C2A);
  static const _textMuted = Color(0xFFBFB5A0);
  static const _danger = Color(0xFFA32D2D);
  static const _dangerLight = Color(0xFFFCEBEB);
  static const _success = Color(0xFF3B6D11);
  static const _successLight = Color(0xFFEAF3DE);
  static const _brownLight = Color(0xFFD4A47A);

  final TextEditingController _nombreRecetaController = TextEditingController();
  final TextEditingController _precioCostoController = TextEditingController();
  final TextEditingController _precioVentaController = TextEditingController();
  final TextEditingController _rendimientoController = TextEditingController();

  String _tiempoProduccion = '60 min';
  double _margenGanancia = 0.0;
  double _rentabilidad = 0.0;

  // Datos de ejemplo de ingredientes
  final List<_Ingrediente> _ingredientes = [
    _Ingrediente(
      nombre: 'Harina',
      cantidad: 500,
      unidad: 'gr',
      precioUnitario: 0.50,
      costo: 250,
    ),
    _Ingrediente(
      nombre: 'Azúcar',
      cantidad: 200,
      unidad: 'gr',
      precioUnitario: 0.80,
      costo: 160,
    ),
    _Ingrediente(
      nombre: 'Mantequilla',
      cantidad: 250,
      unidad: 'gr',
      precioUnitario: 1.20,
      costo: 300,
    ),
  ];

  double get _costoTotal => _ingredientes.fold(0, (sum, i) => sum + i.costo);

  void _calcularMargenYRentabilidad() {
    double precioVenta = double.tryParse(_precioVentaController.text) ?? 0;
    double precioCosto = _costoTotal;

    if (precioVenta > 0) {
      _margenGanancia = precioVenta - precioCosto;
      _rentabilidad = (_margenGanancia / precioCosto) * 100;
    } else {
      _margenGanancia = 0;
      _rentabilidad = 0;
    }

    setState(() {});
  }

  Color _getColorRentabilidad() {
    if (_rentabilidad >= 40) return _success;
    if (_rentabilidad >= 20) return _orange;
    if (_rentabilidad > 0) return _brownLight;
    return _danger;
  }

  String _getTextoRentabilidad() {
    if (_rentabilidad >= 40) return 'Muy rentable';
    if (_rentabilidad >= 20) return 'Rentable';
    if (_rentabilidad > 0) return 'Revisar';
    return 'No rentable';
  }

  @override
  void dispose() {
    _nombreRecetaController.dispose();
    _precioCostoController.dispose();
    _precioVentaController.dispose();
    _rendimientoController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _beige,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  // ── Header oliva
  Widget _buildHeader() {
    return Container(
      color: _olive,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Costeo Dinámico',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Calcula costos y rentabilidad',
                    style: TextStyle(fontSize: 12, color: _oliveDark),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: _textDark,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Icon(Icons.close_rounded, color: _olive, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Cuerpo scrollable
  Widget _buildBody() {
    return Container(
      decoration: const BoxDecoration(
        color: _beige,
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
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Datos básicos
              _buildSectionTitle('Información Básica'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _nombreRecetaController,
                label: 'Nombre de la Receta',
                icon: Icons.edit_outlined,
              ),
              const SizedBox(height: 10),
              _buildTextField(
                controller: _rendimientoController,
                label: 'Rendimiento (unidades)',
                icon: Icons.production_quantity_limits_outlined,
              ),
              const SizedBox(height: 10),
              _buildTimeSelector(),
              const SizedBox(height: 20),

              // Ingredientes
              _buildSectionTitle('Ingredientes'),
              const SizedBox(height: 12),
              _buildIngredientesList(),
              const SizedBox(height: 12),
              _buildAgregarIngredienteBtn(),
              const SizedBox(height: 20),

              // Cálculo de costos
              _buildSectionTitle('Análisis de Costos'),
              const SizedBox(height: 12),
              _buildCostoResumen(),
              const SizedBox(height: 16),

              // Precios y rentabilidad
              _buildSectionTitle('Precios y Rentabilidad'),
              const SizedBox(height: 12),
              _buildTextField(
                controller: _precioVentaController,
                label: 'Precio de Venta (\$)',
                icon: Icons.attach_money_rounded,
                onChanged: _calcularMargenYRentabilidad,
              ),
              const SizedBox(height: 12),
              _buildRentabilidadCard(),
              const SizedBox(height: 24),

              // Botones de acción
              _buildBotonGuardar(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  // ── Título de sección
  Widget _buildSectionTitle(String titulo) {
    return Text(
      titulo,
      style: TextStyle(
        fontSize: 14,
        fontWeight: FontWeight.w600,
        color: _textDark,
      ),
    );
  }

  // ── TextField personalizado
  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    VoidCallback? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _beigeDeep, width: 1),
      ),
      child: TextField(
        controller: controller,
        onChanged: (_) {
          onChanged?.call();
        },
        style: TextStyle(fontSize: 13, color: _textDark),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: TextStyle(fontSize: 13, color: _textMuted),
          prefixIcon: Icon(icon, color: _orange, size: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  // ── Selector de tiempo
  Widget _buildTimeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _beigeDeep, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(Icons.schedule_outlined, color: _orange, size: 16),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _tiempoProduccion,
                style: TextStyle(fontSize: 13, color: _textDark),
              ),
            ),
            PopupMenuButton<String>(
              onSelected: (value) => setState(() => _tiempoProduccion = value),
              itemBuilder: (BuildContext context) => [
                const PopupMenuItem(value: '30 min', child: Text('30 min')),
                const PopupMenuItem(value: '60 min', child: Text('60 min')),
                const PopupMenuItem(value: '90 min', child: Text('90 min')),
                const PopupMenuItem(value: '2 hrs', child: Text('2 hrs')),
                const PopupMenuItem(value: '3 hrs', child: Text('3 hrs')),
              ],
              child: Icon(
                Icons.expand_more_rounded,
                color: _textMuted,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Lista de ingredientes
  Widget _buildIngredientesList() {
    return Column(
      children: _ingredientes.asMap().entries.map((entry) {
        int idx = entry.key;
        _Ingrediente ing = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: _beigeDeep, width: 1),
            ),
            child: Padding(
              padding: const EdgeInsets.all(10),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          ing.nombre,
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                            color: _textDark,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${ing.cantidad} ${ing.unidad} × \$${ing.precioUnitario.toStringAsFixed(2)}',
                          style: TextStyle(fontSize: 11, color: _textMuted),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${ing.costo.toStringAsFixed(2)}',
                        style: TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w600,
                          color: _orange,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _ingredientes.removeAt(idx)),
                        child: Icon(
                          Icons.close_rounded,
                          color: _danger,
                          size: 16,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  // ── Botón agregar ingrediente
  Widget _buildAgregarIngredienteBtn() {
    return GestureDetector(
      onTap: () {
        // TODO: Implementar modal para agregar ingrediente
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: _orangeLight,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: _orangeBorde, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: _orange, size: 16),
            const SizedBox(width: 6),
            Text(
              'Agregar Ingrediente',
              style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _orange,
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Resumen de costo
  Widget _buildCostoResumen() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _beigeDeep, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Costo Total Ingredientes:',
                  style: TextStyle(fontSize: 12, color: _textMuted),
                ),
                Text(
                  '\$${_costoTotal.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _textDark,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: _beigeDeep, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Costo por Unidad:',
                  style: TextStyle(fontSize: 12, color: _textMuted),
                ),
                Text(
                  '\$${(_costoTotal / (double.tryParse(_rendimientoController.text) ?? 1)).toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: _orange,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Card de rentabilidad
  Widget _buildRentabilidadCard() {
    Color colorRent = _getColorRentabilidad();
    String textoRent = _getTextoRentabilidad();

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: _beigeDeep, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Margen de Ganancia:',
                  style: TextStyle(fontSize: 12, color: _textMuted),
                ),
                Text(
                  '\$${_margenGanancia.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorRent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: _beigeDeep, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rentabilidad:',
                  style: TextStyle(fontSize: 12, color: _textMuted),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorRent.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_rentabilidad.toStringAsFixed(1)}% - $textoRent',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: colorRent,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Botón guardar
  Widget _buildBotonGuardar() {
    return GestureDetector(
      onTap: () {
        // TODO: Guardar receta con costos
      },
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: _olive,
          borderRadius: BorderRadius.circular(10),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.save_outlined, color: _textDark, size: 16),
            const SizedBox(width: 8),
            Text(
              'Guardar Receta',
              style: TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: _textDark,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ── Modelo de Ingrediente
class _Ingrediente {
  final String nombre;
  final double cantidad;
  final String unidad;
  final double precioUnitario;
  final double costo;

  _Ingrediente({
    required this.nombre,
    required this.cantidad,
    required this.unidad,
    required this.precioUnitario,
    required this.costo,
  });
}
