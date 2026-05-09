import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/core/theme/theme.dart';

class CosteoDinamicoView extends StatefulWidget {
  const CosteoDinamicoView({super.key});

  @override
  State<CosteoDinamicoView> createState() => _CosteoDinamicoViewState();
}

class _CosteoDinamicoViewState extends State<CosteoDinamicoView> {
  final TextEditingController _nombreRecetaController = TextEditingController();
  final TextEditingController _precioCostoController = TextEditingController();
  final TextEditingController _precioVentaController = TextEditingController();
  final TextEditingController _rendimientoController = TextEditingController();

  String _tiempoProduccion = '60 min';
  double _margenGanancia = 0.0;
  double _rentabilidad = 0.0;

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
    if (_rentabilidad >= 40) return AppTheme.colors.statusNormal;
    if (_rentabilidad >= 20) return AppTheme.colors.primary;
    if (_rentabilidad > 0) return AppTheme.colors.brownLight;
    return AppTheme.colors.statusCritical;
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
      backgroundColor: AppTheme.colors.bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppTheme.colors.accent,
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
                  Text('Costeo Dinámico', style: AppTheme.font.h3),
                  const SizedBox(height: 2),
                  Text(
                    'Calcula costos y rentabilidad',
                    style: AppTheme.font.caption.copyWith(
                      color: AppTheme.colors.accentDark,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: AppTheme.colors.titleText,
                    borderRadius: AppTheme.radius.brSm,
                  ),
                  child: Icon(
                    Icons.close_rounded,
                    color: AppTheme.colors.accent,
                    size: 18,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors.bg,
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
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
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

              _buildSectionTitle('Ingredientes'),
              const SizedBox(height: 12),
              _buildIngredientesList(),
              const SizedBox(height: 12),
              _buildAgregarIngredienteBtn(),
              const SizedBox(height: 20),

              _buildSectionTitle('Análisis de Costos'),
              const SizedBox(height: 12),
              _buildCostoResumen(),
              const SizedBox(height: 16),

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

              _buildBotonGuardar(),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String titulo) {
    return Text(
      titulo,
      style: AppTheme.font.label.copyWith(
        fontSize: 14,
        fontWeight: FontWeight.w600,
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    VoidCallback? onChanged,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors.card,
        borderRadius: AppTheme.radius.brSm,
        border: Border.all(color: AppTheme.colors.border, width: 1),
      ),
      child: TextField(
        controller: controller,
        onChanged: (_) => onChanged?.call(),
        style: AppTheme.font.bodySmall.copyWith(
          fontSize: 13,
          color: AppTheme.colors.titleText,
        ),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: AppTheme.font.hint.copyWith(fontSize: 13),
          prefixIcon: Icon(icon, color: AppTheme.colors.primary, size: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(
            horizontal: 12,
            vertical: 12,
          ),
        ),
      ),
    );
  }

  Widget _buildTimeSelector() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors.card,
        borderRadius: AppTheme.radius.brSm,
        border: Border.all(color: AppTheme.colors.border, width: 1),
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        child: Row(
          children: [
            Icon(
              Icons.schedule_outlined,
              color: AppTheme.colors.primary,
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _tiempoProduccion,
                style: AppTheme.font.bodySmall.copyWith(fontSize: 13),
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
                color: AppTheme.colors.hint,
                size: 18,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildIngredientesList() {
    return Column(
      children: _ingredientes.asMap().entries.map((entry) {
        int idx = entry.key;
        _Ingrediente ing = entry.value;
        return Padding(
          padding: const EdgeInsets.only(bottom: 8),
          child: Container(
            decoration: BoxDecoration(
              color: AppTheme.colors.card,
              borderRadius: AppTheme.radius.brSm,
              border: Border.all(color: AppTheme.colors.border, width: 1),
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
                          style: AppTheme.font.label.copyWith(fontSize: 13),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${ing.cantidad} ${ing.unidad} × \$${ing.precioUnitario.toStringAsFixed(2)}',
                          style: AppTheme.font.caption,
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '\$${ing.costo.toStringAsFixed(2)}',
                        style: AppTheme.font.h3.copyWith(
                          fontSize: 13,
                          color: AppTheme.colors.primary,
                        ),
                      ),
                      GestureDetector(
                        onTap: () =>
                            setState(() => _ingredientes.removeAt(idx)),
                        child: Icon(
                          Icons.close_rounded,
                          color: AppTheme.colors.statusCritical,
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

  Widget _buildAgregarIngredienteBtn() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: AppTheme.colors.primaryLight,
          borderRadius: AppTheme.radius.brSm,
          border: Border.all(color: AppTheme.colors.primaryBorder, width: 1),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.add_rounded, color: AppTheme.colors.primary, size: 16),
            const SizedBox(width: 6),
            Text(
              'Agregar Ingrediente',
              style: AppTheme.font.label.copyWith(
                fontSize: 13,
                color: AppTheme.colors.primary,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCostoResumen() {
    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors.card,
        borderRadius: AppTheme.radius.brSm,
        border: Border.all(color: AppTheme.colors.border, width: 1),
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
                  style: AppTheme.font.caption.copyWith(fontSize: 12),
                ),
                Text(
                  '\$${_costoTotal.toStringAsFixed(2)}',
                  style: AppTheme.font.label.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: AppTheme.colors.border, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Costo por Unidad:',
                  style: AppTheme.font.caption.copyWith(fontSize: 12),
                ),
                Text(
                  '\$${(_costoTotal / (double.tryParse(_rendimientoController.text) ?? 1)).toStringAsFixed(2)}',
                  style: AppTheme.font.label.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: AppTheme.colors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRentabilidadCard() {
    Color colorRent = _getColorRentabilidad();
    String textoRent = _getTextoRentabilidad();

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colors.card,
        borderRadius: AppTheme.radius.brSm,
        border: Border.all(color: AppTheme.colors.border, width: 1),
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
                  style: AppTheme.font.caption.copyWith(fontSize: 12),
                ),
                Text(
                  '\$${_margenGanancia.toStringAsFixed(2)}',
                  style: AppTheme.font.label.copyWith(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: colorRent,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Divider(color: AppTheme.colors.border, height: 1),
            const SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  'Rentabilidad:',
                  style: AppTheme.font.caption.copyWith(fontSize: 12),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 4,
                  ),
                  decoration: BoxDecoration(
                    color: colorRent.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    '${_rentabilidad.toStringAsFixed(1)}% - $textoRent',
                    style: AppTheme.font.label.copyWith(
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

  Widget _buildBotonGuardar() {
    return GestureDetector(
      onTap: () {},
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppTheme.colors.accent,
          borderRadius: AppTheme.radius.brSm,
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.save_outlined,
              color: AppTheme.colors.titleText,
              size: 16,
            ),
            const SizedBox(width: 8),
            Text(
              'Guardar Receta',
              style: AppTheme.font.label.copyWith(
                fontSize: 14,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

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
