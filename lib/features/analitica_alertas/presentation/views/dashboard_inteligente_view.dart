import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/widgets/bottom_nav_bar.dart';
import 'package:happy_oven/features/analitica_alertas/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:intl/intl.dart';

class DashboardInteligenteView extends ConsumerWidget {
  const DashboardInteligenteView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final rutaActual = GoRouterState.of(context).uri.path;
    final state = ref.watch(dashboardViewModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.colorsOf(context).bg,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildBody(context, state)),
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

  Widget _buildBody(BuildContext context, DashboardState state) {
    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    if (state.error != null) {
      return Center(
        child: Text(
          'Error: ${state.error}',
          style: AppTheme.fontOf(context).body,
        ),
      );
    }

    return Container(
      decoration: BoxDecoration(
        color: AppTheme.colorsOf(context).bg,
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
              _buildKpiRow(context, state),
              const SizedBox(height: 16),
              _buildConsumoSemanal(context),
              const SizedBox(height: 14),
              _buildProyeccionIA(context, state),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildKpiRow(BuildContext context, DashboardState state) {
    final colors = AppTheme.colorsOf(context);

    // Formatear el valor monetario
    final formatter = NumberFormat.currency(symbol: 'S/ ', decimalDigits: 2);
    final valorFormateado = formatter.format(state.valorTotalInventario);

    return Row(
      children: [
        Expanded(
          child: _buildKpiCard(
            context: context,
            valor: state.insumosConStockBajo.toString(),
            etiqueta: 'Insumos con\nstock bajo',
            icono: Icons.warning_amber_rounded,
            colorFondo: colors.dangerLight,
            colorBorde: colors.dangerBorder,
            colorIcono: colors.statusCritical,
          ),
        ),
        const SizedBox(width: 10),
        Expanded(
          child: _buildKpiCard(
            context: context,
            valor: valorFormateado,
            etiqueta: 'Valor total\ninventario',
            icono: Icons.monetization_on_outlined,
            colorFondo: colors.successLight,
            colorBorde: colors.successBorder,
            colorIcono: colors.statusNormal,
          ),
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required BuildContext context,
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

  Widget _buildConsumoSemanal(BuildContext context) {
    final barGroups = [
      _barGroup(context, 0, 40),
      _barGroup(context, 1, 55),
      _barGroup(context, 2, 65),
      _barGroup(context, 3, 45),
      _barGroup(context, 4, 30),
      _barGroup(context, 5, 20),
      _barGroup(context, 6, 10),
    ];
    final dias = ['Lun', 'Mar', 'Mie', 'Jue', 'Vie', 'Sab', 'Dom'];
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppTheme.radius.lg),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Consumo semanal', style: font.label.copyWith(fontSize: 13)),
              Text('Esta semana', style: font.caption),
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
                              color: esHoy ? colors.titleText : colors.hint,
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

  BarChartGroupData _barGroup(BuildContext context, int x, double y) {
    final colors = AppTheme.colorsOf(context);
    final esHoy = x == 2;
    return BarChartGroupData(
      x: x,
      barRods: [
        BarChartRodData(
          toY: y,
          color: esHoy ? colors.primary : colors.primaryBorder,
          width: 18,
          borderRadius: const BorderRadius.only(
            topLeft: Radius.circular(4),
            topRight: Radius.circular(4),
          ),
        ),
      ],
    );
  }

  Widget _buildProyeccionIA(BuildContext context, DashboardState state) {
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppTheme.radius.lg),
        border: Border.all(color: colors.border, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Proyección IA', style: font.label.copyWith(fontSize: 13)),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                decoration: BoxDecoration(
                  color: colors.primaryLight,
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Text(
                  'Kardex ML',
                  style: font.caption.copyWith(
                    color: colors.primary,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          if (state.proyecciones.isEmpty)
            Center(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: Text(
                  'No hay suficientes datos de movimientos para proyectar el consumo.',
                  style: font.hint,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            ...state.proyecciones.map(
              (i) => _buildInsumoProyeccion(context, i),
            ),
        ],
      ),
    );
  }

  Widget _buildInsumoProyeccion(
    BuildContext context,
    InsumoProyeccionData insumo,
  ) {
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);

    Color colorBarra;
    String etiqueta = 'Se agota en ${insumo.diasRestantes} días';

    if (insumo.diasRestantes <= 5) {
      colorBarra = colors.statusCritical;
    } else if (insumo.diasRestantes <= 10) {
      colorBarra = colors.primary;
    } else {
      colorBarra = colors.statusNormal;
    }

    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(insumo.nombre, style: font.bodySmall.copyWith(fontSize: 12)),
              Text(
                etiqueta,
                style: font.label.copyWith(fontSize: 12, color: colorBarra),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radius.full),
            child: LinearProgressIndicator(
              value: insumo.stockPorcentaje,
              minHeight: 6,
              backgroundColor: colors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(colorBarra),
            ),
          ),
        ],
      ),
    );
  }
}
