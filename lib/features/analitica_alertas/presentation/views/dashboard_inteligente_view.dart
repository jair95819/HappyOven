import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/widgets/bottom_nav_bar.dart';

class DashboardInteligenteView extends StatelessWidget {
  const DashboardInteligenteView({super.key});

  @override
  Widget build(BuildContext context) {
    final rutaActual = GoRouterState.of(context).uri.path;
    return Scaffold(
      backgroundColor: AppTheme.colors.bg,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildBody()),
          BottomNavBar(rutaActual: rutaActual),
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
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Buenos días,',
                    style: AppTheme.font.bodySmall.copyWith(
                      color: AppTheme.colors.accentDark,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text('Administrador', style: AppTheme.font.h3),
                  const SizedBox(height: 6),
                  Text(
                    'Jueves, 07 de mayo 2026',
                    style: AppTheme.font.caption.copyWith(
                      color: AppTheme.colors.accentDark,
                    ),
                  ),
                ],
              ),
              GestureDetector(
                onTap: () => context.push('/perfil'),
                child: Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppTheme.colors.titleText,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.person_outline_rounded,
                    color: AppTheme.colors.accent,
                    size: 22,
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
          padding: EdgeInsets.fromLTRB(
            AppTheme.spacing.md,
            20,
            AppTheme.spacing.md,
            8,
          ),
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

  Widget _buildKpiRow() {
    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            valor: '4',
            etiqueta: 'Insumos con\nstock bajo',
            icono: Icons.warning_amber_rounded,
            colorFondo: AppTheme.colors.dangerLight,
            colorBorde: AppTheme.colors.dangerBorder,
            colorIcono: AppTheme.colors.statusCritical,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildKpiCard(
            valor: 'S/ 2,840',
            etiqueta: 'Valor total\ninventario',
            icono: Icons.monetization_on_outlined,
            colorFondo: AppTheme.colors.successLight,
            colorBorde: AppTheme.colors.successBorder,
            colorIcono: AppTheme.colors.statusNormal,
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
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(AppTheme.radius.lg),
        border: Border.all(color: colorBorde, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: colorIcono.withValues(alpha: 0.12),
              borderRadius: AppTheme.radius.brSm,
            ),
            child: Icon(icono, color: colorIcono, size: 18),
          ),
          const SizedBox(height: 10),
          Text(valor, style: AppTheme.font.h2.copyWith(color: colorIcono)),
          const SizedBox(height: 2),
          Text(
            etiqueta,
            style: AppTheme.font.caption.copyWith(
              color: colorIcono.withValues(alpha: 0.8),
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildConsumoSemanal() {
    final barGroups = [
      _barGroup(0, 40),
      _barGroup(1, 55),
      _barGroup(2, 65),
      _barGroup(3, 45),
      _barGroup(4, 30),
      _barGroup(5, 20),
      _barGroup(6, 10),
    ];
    final dias = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppTheme.colors.card,
        borderRadius: BorderRadius.circular(AppTheme.radius.lg),
        border: Border.all(color: AppTheme.colors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Consumo semanal',
                style: AppTheme.font.label.copyWith(fontSize: 13),
              ),
              Text('Esta semana', style: AppTheme.font.caption),
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
                              color: esHoy
                                  ? AppTheme.colors.titleText
                                  : AppTheme.colors.hint,
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
          color: esHoy
              ? AppTheme.colors.primary
              : AppTheme.colors.primaryBorder,
          width: 18,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildProyeccionIA() {
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
        color: AppTheme.colors.card,
        borderRadius: BorderRadius.circular(AppTheme.radius.lg),
        border: Border.all(color: AppTheme.colors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                'Proyección IA',
                style: AppTheme.font.label.copyWith(fontSize: 13),
              ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: AppTheme.colors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Series de tiempo',
                  style: AppTheme.font.caption.copyWith(
                    color: AppTheme.colors.primary,
                    fontWeight: FontWeight.w500,
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
    String etiqueta = 'Se agota en ${insumo.diasRestantes} días';

    if (insumo.diasRestantes <= 5) {
      colorBarra = AppTheme.colors.statusCritical;
    } else if (insumo.diasRestantes <= 10) {
      colorBarra = AppTheme.colors.primary;
    } else {
      colorBarra = AppTheme.colors.statusNormal;
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
                style: AppTheme.font.bodySmall.copyWith(fontSize: 12),
              ),
              Text(
                etiqueta,
                style: AppTheme.font.label.copyWith(
                  fontSize: 12,
                  color: colorBarra,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radius.full),
            child: LinearProgressIndicator(
              value: insumo.stockPorcentaje,
              minHeight: 6,
              backgroundColor: AppTheme.colors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(colorBarra),
            ),
          ),
        ],
      ),
    );
  }
}

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
