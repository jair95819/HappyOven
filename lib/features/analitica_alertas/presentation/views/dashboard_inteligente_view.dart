import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/features/analitica_alertas/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:happy_oven/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:intl/intl.dart';

class DashboardInteligenteView extends ConsumerWidget {
  const DashboardInteligenteView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(dashboardViewModelProvider);

    return Scaffold(
      backgroundColor: AppTheme.colorsOf(context).bg,
      body: Column(
        children: [
          _buildHeader(context, ref),
          Expanded(child: _buildBody(context, state)),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, WidgetRef ref) {
    final usuario = ref.watch(authViewModelProvider).usuario;
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
                  Text(usuario?.nombre ?? usuario?.rolLabel ?? 'Usuario',
                      style: AppTheme.font.h3),
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
              SizedBox(height: AppTheme.spacing.lg),
              _buildConsumoSemanal(context, state),
              SizedBox(height: AppTheme.spacing.lg),
              _buildProyeccionIA(context, state),
              SizedBox(height: AppTheme.spacing.lg),
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
            onTap: () {
              if (state.listaInsumosConStockBajo.isNotEmpty) {
                _mostrarDetalleStockBajo(context, state.listaInsumosConStockBajo);
              }
            },
          ),
        ),
        SizedBox(width: AppTheme.spacing.md),
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
    VoidCallback? onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: colorFondo,
          borderRadius: BorderRadius.circular(AppTheme.radius.lg),
          border: Border.all(color: colorBorde, width: 0.5),
          boxShadow: AppTheme.shadows.cardSm,
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
      ),
    );
  }

  void _mostrarDetalleStockBajo(BuildContext context, List<Articulo> items) {
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);

    showModalBottomSheet(
      context: context,
      backgroundColor: colors.bg,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radius.xl))),
      builder: (_) => DraggableScrollableSheet(
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Insumos con stock bajo', style: font.h3.copyWith(fontSize: 18)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: items.length,
                  itemBuilder: (_, i) {
                    final a = items[i];
                    final esCritico = (a.stockActual / a.stockMinimo) <= 0.5;
                    return ListTile(
                      leading: Icon(
                        Icons.warning_amber_rounded,
                        color: esCritico ? colors.statusCritical : colors.primary,
                        size: 24,
                      ),
                      title: Text(a.nombre, style: font.bodySmall),
                      subtitle: Text(
                        'Stock actual: ${a.stockActual.toStringAsFixed(0)} ${a.unidad.dbValue}\nMínimo: ${a.stockMinimo.toStringAsFixed(0)} ${a.unidad.dbValue}',
                        style: font.caption,
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildConsumoSemanal(BuildContext context, DashboardState state) {
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);
    final serie = state.consumoSemanal;
    final hayDatos = state.totalConsumoSemanal > 0;
    final maxY = hayDatos
        ? serie.map((d) => d.cantidad).reduce((a, b) => a > b ? a : b) * 1.25
        : 10.0;

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: BorderRadius.circular(AppTheme.radius.lg),
        border: Border.all(color: colors.border, width: 0.5),
        boxShadow: AppTheme.shadows.cardSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text('Consumo semanal', style: font.label.copyWith(fontSize: 13)),
              Text(
                '${state.totalConsumoSemanal.toStringAsFixed(1)} kg · 7 días',
                style: font.caption,
              ),
            ],
          ),
          const SizedBox(height: 4),
          Text(
            'Salidas y mermas por día. Toca una barra para ver el detalle.',
            style: font.caption.copyWith(fontSize: 10, color: colors.hint),
          ),
          SizedBox(height: AppTheme.spacing.md),
          if (!hayDatos)
            SizedBox(
              height: 120,
              child: Center(
                child: Text(
                  'Sin consumo registrado en los últimos 7 días.',
                  style: font.hint,
                  textAlign: TextAlign.center,
                ),
              ),
            )
          else
            SizedBox(
              height: 120,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, groupIndex, rod, rodIndex) {
                        final dia = serie[group.x];
                        final fechaTxt =
                            DateFormat('EEE d MMM', 'es').format(dia.fecha);
                        return BarTooltipItem(
                          '$fechaTxt\n${dia.cantidad.toStringAsFixed(1)} kg',
                          TextStyle(
                            color: colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final index = value.toInt();
                          if (index < 0 || index >= serie.length) {
                            return const SizedBox.shrink();
                          }
                          final esHoy = index == serie.length - 1;
                          final etiqueta = DateFormat(
                            'EEE',
                            'es',
                          ).format(serie[index].fecha);
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              etiqueta,
                              style: TextStyle(
                                fontSize: 10,
                                fontWeight: esHoy
                                    ? FontWeight.w600
                                    : FontWeight.normal,
                                color: esHoy ? colors.titleText : colors.hint,
                              ),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: serie
                      .asMap()
                      .entries
                      .map(
                        (e) => _barGroup(
                          context,
                          e.key,
                          e.value.cantidad,
                          esHoy: e.key == serie.length - 1,
                        ),
                      )
                      .toList(),
                ),
              ),
            ),
        ],
      ),
    );
  }

  BarChartGroupData _barGroup(
    BuildContext context,
    int x,
    double y, {
    required bool esHoy,
  }) {
    final colors = AppTheme.colorsOf(context);
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
        boxShadow: AppTheme.shadows.cardSm,
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
          SizedBox(height: AppTheme.spacing.md),
          GestureDetector(
            onTap: () => context.push('/dashboard/sugerencias'),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 11),
              decoration: BoxDecoration(
                color: colors.primaryLight,
                borderRadius: AppTheme.radius.brSm,
                border: Border.all(color: colors.primaryBorder),
                boxShadow: AppTheme.shadows.cardSm,
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 16, color: colors.primary),
                  const SizedBox(width: 6),
                  Text(
                    'Ver sugerencias de compra',
                    style: font.label.copyWith(fontSize: 13, color: colors.primary),
                  ),
                ],
              ),
            ),
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
      padding: EdgeInsets.only(bottom: AppTheme.spacing.md),
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
          const SizedBox(height: 2),
          Align(
            alignment: Alignment.centerLeft,
            child: Text(
              'Tasa: ${insumo.consumoDiario.toStringAsFixed(2)}/día',
              style: font.caption.copyWith(fontSize: 10, color: colors.hint),
            ),
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
