import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/core/widgets/bottom_nav_bar.dart';

class DashboardInteligenteView extends StatelessWidget {
  const DashboardInteligenteView({super.key});

  static const _olive = Color(0xFFC8CA9E);
  static const _oliveDark = Color(0xFF4A4A38);
  static const _orange = Color(0xFFFF8C42);
  static const _orangeLight = Color(0xFFFFF3EB);
  static const _beige = Color(0xFFF5F0E8);
  static const _beigeDeep = Color(0xFFEDE5D6);
  static const _textDark = Color(0xFF2C2C2A);
  static const _textGray = Color(0xFF5F5E5A);
  static const _textMuted = Color(0xFFBFB5A0);
  static const _danger = Color(0xFFA32D2D);
  static const _dangerLight = Color(0xFFFCEBEB);
  static const _success = Color(0xFF3B6D11);
  static const _successLight = Color(0xFFEAF3DE);

  @override
  Widget build(BuildContext context) {
    final rutaActual = GoRouterState.of(context).uri.path;
    return Scaffold(
      backgroundColor: _beige,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
          BottomNavBar(rutaActual: rutaActual),
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 28),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buenos días,',
                    style: TextStyle(fontSize: 13, color: _oliveDark),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Administrador',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w500,
                      color: _textDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Jueves, 07 de mayo 2026',
                    style: TextStyle(fontSize: 12, color: _oliveDark),
                  ),
                ],
              ),
              Container(
                width: 42,
                height: 42,
                decoration: BoxDecoration(
                  color: _textDark,
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.person_outline_rounded,
                  color: _olive,
                  size: 22,
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
          padding: const EdgeInsets.fromLTRB(16, 20, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKpiRow(),
              const SizedBox(height: 16),
              _buildConsumoSemanal(),
              const SizedBox(height: 14),
              _buildProyeccionIA(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── KPI cards
  Widget _buildKpiRow() {
    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            valor: '4',
            etiqueta: 'Insumos con\nstock bajo',
            icono: Icons.warning_amber_rounded,
            colorFondo: _dangerLight,
            colorBorde: const Color(0xFFF5C6C6),
            colorIcono: _danger,
            colorValor: _danger,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildKpiCard(
            valor: 'S/ 2,840',
            etiqueta: 'Valor total\ninventario',
            icono: Icons.monetization_on_outlined,
            colorFondo: _successLight,
            colorBorde: const Color(0xFFC2DFA8),
            colorIcono: _success,
            colorValor: _success,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required String valor,
    required String etiqueta,
    required IconData icono,
    required Color colorFondo,
    required Color colorBorde,
    required Color colorIcono,
    required Color colorValor,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: colorBorde, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colorIcono.withOpacity(0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Icon(icono, color: colorIcono, size: 18),
          ),
          const SizedBox(height: 10),
          Text(
            valor,
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.w500,
              color: colorValor,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            etiqueta,
            style: TextStyle(
              fontSize: 11,
              color: colorIcono.withOpacity(0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  // ── Gráfica consumo semanal
  Widget _buildConsumoSemanal() {
    // Datos de ejemplo — luego vendrán del ViewModel
    final barGroups = [
      _barGroup(0, 40),
      _barGroup(1, 55),
      _barGroup(2, 65), // hoy (resaltado)
      _barGroup(3, 45),
      _barGroup(4, 30),
      _barGroup(5, 20),
      _barGroup(6, 10),
    ];

    final dias = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _beigeDeep, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Consumo semanal',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textDark,
                ),
              ),
              Text(
                'Esta semana',
                style: TextStyle(fontSize: 11, color: _textMuted),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 120,
            child: BarChart(
              BarChartData(
                alignment: BarChartAlignment.spaceAround,
                maxY: 80,
                barTouchData: BarTouchData(enabled: false),
                titlesData: FlTitlesData(
                  leftTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  rightTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  topTitles: AxisTitles(
                    sideTitles: SideTitles(showTitles: false),
                  ),
                  bottomTitles: AxisTitles(
                    sideTitles: SideTitles(
                      showTitles: true,
                      getTitlesWidget: (value, meta) {
                        final index = value.toInt();
                        final esHoy = index == 2;
                        return Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            dias[index],
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: esHoy
                                  ? FontWeight.w500
                                  : FontWeight.normal,
                              color: esHoy ? _textDark : _textMuted,
                            ),
                          ),
                        );
                      },
                    ),
                  ),
                ),
                gridData: FlGridData(show: false),
                borderData: FlBorderData(show: false),
                barGroups: barGroups,
              ),
            ),
          ),
        ],
      ),
    );
  }

  BarChartGroupData _barGroup(int x, double y) {
    final esHoy = x == 2;
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: esHoy ? _orange : const Color(0xFFFFD9BE),
          width: 18,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }

  // ── Proyección IA
  Widget _buildProyeccionIA() {
    // Datos de ejemplo — luego vendrán del ViewModel
    final insumos = [
      _InsumoProyeccion(
        nombre: 'Harina',
        diasRestantes: 3,
        stockPorcentaje: 0.20,
      ),
      _InsumoProyeccion(
        nombre: 'Azúcar',
        diasRestantes: 7,
        stockPorcentaje: 0.45,
      ),
      _InsumoProyeccion(
        nombre: 'Mantequilla',
        diasRestantes: 14,
        stockPorcentaje: 0.75,
      ),
    ];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: _beigeDeep, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Proyección IA',
                style: TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w500,
                  color: _textDark,
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: _orangeLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Series de tiempo',
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w500,
                    color: _orange,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          ...insumos.map((i) => _buildInsumoProyeccion(i)),
        ],
      ),
    );
  }

  Widget _buildInsumoProyeccion(_InsumoProyeccion insumo) {
    Color colorBarra;
    Color colorTexto;
    String etiqueta;

    if (insumo.diasRestantes <= 5) {
      colorBarra = _danger;
      colorTexto = _danger;
      etiqueta = 'Se agota en ${insumo.diasRestantes} días';
    } else if (insumo.diasRestantes <= 10) {
      colorBarra = _orange;
      colorTexto = _orange;
      etiqueta = 'Se agota en ${insumo.diasRestantes} días';
    } else {
      colorBarra = _success;
      colorTexto = _success;
      etiqueta = 'Se agota en ${insumo.diasRestantes} días';
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                insumo.nombre,
                style: TextStyle(fontSize: 12, color: _textDark),
              ),
              Text(
                etiqueta,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: colorTexto,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: insumo.stockPorcentaje,
              minHeight: 6,
              backgroundColor: _beige,
              valueColor: AlwaysStoppedAnimation<Color>(colorBarra),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom navigation
}

// Modelo local temporal — luego viene del ViewModel
class _InsumoProyeccion {
  final String nombre;
  final int diasRestantes;
  final double stockPorcentaje;

  const _InsumoProyeccion({
    required this.nombre,
    required this.diasRestantes,
    required this.stockPorcentaje,
  });
}
