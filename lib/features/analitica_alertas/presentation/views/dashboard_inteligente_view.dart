import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/features/analitica_alertas/presentation/viewmodels/dashboard_viewmodel.dart';
import 'package:happy_oven/features/auth/presentation/viewmodels/auth_viewmodel.dart';
import 'package:intl/intl.dart';

class DashboardInteligenteView extends ConsumerStatefulWidget {
  const DashboardInteligenteView({super.key});

  @override
  ConsumerState<DashboardInteligenteView> createState() =>
      _DashboardInteligenteViewState();
}

class _DashboardInteligenteViewState
    extends ConsumerState<DashboardInteligenteView> {
  bool _showLowStockDetails = false;

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(dashboardViewModelProvider);
    final usuario = ref.watch(authViewModelProvider).usuario;
    final nombre = usuario?.nombre ?? 'Usuario';
    final fecha = DateFormat("EEEE, dd 'de' MMMM", 'es').format(DateTime.now());

    if (state.isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    if (state.error != null) {
      return Scaffold(
        body: Center(
          child: Text(
            'Error: ${state.error}',
            style: AppTheme.fontOf(context).body,
          ),
        ),
      );
    }

    final productos = state.inventarioTop.isNotEmpty
        ? state.inventarioTop
              .map(
                (p) => {
                  'nombre': p.nombre,
                  'cantidad': _formatStockValue(p.stockActual, p.unidad),
                  'color': p.stockActual <= p.stockMinimo
                      ? AppTheme.colors.statusCritical
                      : p.stockActual <= p.stockMinimo * 1.5
                      ? AppTheme.colors.primary
                      : AppTheme.colors.statusNormal,
                },
              )
              .toList()
        : const <Map<String, dynamic>>[];

    return Scaffold(
      backgroundColor: const Color(0xFFF5F3F0),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 14),
          child: Column(
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  GestureDetector(
                    onTap: () => context.push('/perfil'),
                    child: Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: const Color(0xFF9B4D69),
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.person_outline_rounded,
                        color: Colors.white,
                        size: 24,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'BUENOS DÍAS,',
                          style: AppTheme.font.caption.copyWith(
                            fontSize: 12,
                            letterSpacing: 0.4,
                            color: AppTheme.colors.bodyText,
                          ),
                        ),
                        Text(
                          nombre,
                          style: AppTheme.font.h3.copyWith(
                            fontSize: 18,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text(
                    'Accesos directos',
                    style: AppTheme.font.h1.copyWith(
                      fontSize: 32,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                  const Spacer(),
                  Text(
                    fecha,
                    style: AppTheme.font.caption.copyWith(
                      fontSize: 12,
                      color: AppTheme.colors.bodyText,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Row(
                children: [
                  Expanded(
                    child: _buildQuickAccessCard(
                      label: 'Entrada',
                      icon: Icons.arrow_downward_rounded,
                      color: const Color(0xFF1B3E5F),
                      onTap: () => context.push('/movimientos/entrada'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _buildQuickAccessCard(
                      label: 'Salida',
                      icon: Icons.arrow_upward_rounded,
                      color: const Color(0xFF1E3F5F),
                      onTap: () => context.push('/movimientos/salida'),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 18),
              Expanded(
                child: SingleChildScrollView(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 18),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EFEF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.center,
                              children: [
                                Expanded(
                                  child: Text(
                                    'Almacén general',
                                    style: AppTheme.font.h3.copyWith(
                                      fontSize: 22,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                TextButton(
                                  onPressed: () => context.push('/catalogo'),
                                  style: TextButton.styleFrom(
                                    padding: EdgeInsets.zero,
                                    minimumSize: const Size(0, 0),
                                    tapTargetSize:
                                        MaterialTapTargetSize.shrinkWrap,
                                  ),
                                  child: Text(
                                    'Ver todo >',
                                    style: AppTheme.font.body.copyWith(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w700,
                                      color: AppTheme.colors.primary,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            if (productos.isEmpty)
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.all(18),
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  'No hay productos con información disponible.',
                                  style: AppTheme.font.bodySmall,
                                ),
                              )
                            else
                              ...List.generate(productos.length, (index) {
                                final item = productos[index];
                                final color = item['color'] as Color;
                                return Container(
                                  margin: EdgeInsets.only(
                                    bottom: index == productos.length - 1
                                        ? 0
                                        : 12,
                                  ),
                                  child: Column(
                                    children: [
                                      Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              item['nombre'] as String,
                                              style: AppTheme.font.body
                                                  .copyWith(
                                                    fontSize: 15,
                                                    fontWeight: FontWeight.w600,
                                                    color: AppTheme
                                                        .colors
                                                        .titleText,
                                                  ),
                                            ),
                                          ),
                                          Text(
                                            item['cantidad'] as String,
                                            style: AppTheme.font.bodySmall
                                                .copyWith(
                                                  fontWeight: FontWeight.w600,
                                                  color:
                                                      AppTheme.colors.bodyText,
                                                ),
                                          ),
                                        ],
                                      ),
                                      const SizedBox(height: 6),
                                      ClipRRect(
                                        borderRadius: BorderRadius.circular(
                                          999,
                                        ),
                                        child: LinearProgressIndicator(
                                          value: 0.72,
                                          minHeight: 5,
                                          backgroundColor: const Color(
                                            0xFFE7E0DA,
                                          ),
                                          valueColor:
                                              AlwaysStoppedAnimation<Color>(
                                                color,
                                              ),
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              }),
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'OPERACIONES',
                        style: AppTheme.font.label.copyWith(
                          fontSize: 13,
                          letterSpacing: 0.7,
                          color: AppTheme.colors.bodyText,
                        ),
                      ),
                      const SizedBox(height: 12),
                      _buildOperationCard(
                        label: 'Registro de Entrada (OCR / Documento)',
                        subtitle: 'Boletas, fotos y remisión',
                        icon: Icons.input_rounded,
                        onTap: () => context.push('/movimientos/entrada'),
                      ),
                      const SizedBox(height: 10),
                      _buildOperationCard(
                        label: 'Registro de Salida & Merma',
                        subtitle:
                            'Despacho de productos y descarte de material',
                        icon: Icons.output_rounded,
                        onTap: () => context.push('/movimientos/salida'),
                      ),
                      const SizedBox(height: 18),
                      Text(
                        'Dashboard',
                        style: AppTheme.font.h3.copyWith(
                          fontSize: 24,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Container(
                        width: double.infinity,
                        padding: const EdgeInsets.all(14),
                        decoration: BoxDecoration(
                          color: const Color(0xFFF0EFEF),
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    'Resumen semanal',
                                    style: AppTheme.font.h3.copyWith(
                                      fontSize: 18,
                                      fontWeight: FontWeight.w800,
                                    ),
                                  ),
                                ),
                                Text(
                                  '7 días',
                                  style: AppTheme.font.caption.copyWith(
                                    color: AppTheme.colors.bodyText,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 14),
                            Row(
                              children: [
                                Expanded(
                                  child: _buildMetricTile(
                                    label: 'Inventario',
                                    value: _formatCurrency(
                                      state.valorTotalInventario,
                                    ),
                                    accent: const Color(0xFF3A6EA5),
                                  ),
                                ),
                                const SizedBox(width: 10),
                                Expanded(
                                  child: _buildMetricTile(
                                    label: 'Consumo',
                                    value: state.totalConsumoSemanal > 0
                                        ? '${state.totalConsumoSemanal.toStringAsFixed(1)} kg'
                                        : '0 kg',
                                    accent: const Color(0xFFB86A45),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Consumo por día',
                              style: AppTheme.font.body.copyWith(
                                fontSize: 13,
                                fontWeight: FontWeight.w700,
                                color: AppTheme.colors.bodyText,
                              ),
                            ),
                            const SizedBox(height: 10),
                            if (state.consumoSemanal.isEmpty)
                              Container(
                                height: 96,
                                width: double.infinity,
                                decoration: BoxDecoration(
                                  color: Colors.white,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                alignment: Alignment.center,
                                child: Text(
                                  'Sin datos del último período',
                                  style: AppTheme.font.bodySmall,
                                ),
                              )
                            else ...[
                              LayoutBuilder(
                                builder: (context, constraints) {
                                  final maxValue = state.consumoSemanal
                                      .map((e) => e.cantidad)
                                      .reduce((a, b) => a > b ? a : b);
                                  final safeMax = maxValue <= 0
                                      ? 1.0
                                      : maxValue;

                                  return SizedBox(
                                    height: 110,
                                    child: Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.end,
                                      children: state.consumoSemanal.map((dia) {
                                        final height =
                                            52 + (dia.cantidad / safeMax) * 48;
                                        return Expanded(
                                          child: Padding(
                                            padding: const EdgeInsets.symmetric(
                                              horizontal: 3,
                                            ),
                                            child: Column(
                                              mainAxisAlignment:
                                                  MainAxisAlignment.end,
                                              children: [
                                                Container(
                                                  height: height,
                                                  width: double.infinity,
                                                  decoration: BoxDecoration(
                                                    color: dia.cantidad > 0
                                                        ? const Color(
                                                            0xFF9B4D69,
                                                          )
                                                        : const Color(
                                                            0xFFE5DDD8,
                                                          ),
                                                    borderRadius:
                                                        BorderRadius.circular(
                                                          8,
                                                        ),
                                                  ),
                                                ),
                                                const SizedBox(height: 6),
                                                Text(
                                                  DateFormat('E', 'es')
                                                      .format(dia.fecha)
                                                      .substring(0, 2),
                                                  style: AppTheme.font.caption
                                                      .copyWith(
                                                        fontSize: 10,
                                                        color: AppTheme
                                                            .colors
                                                            .bodyText,
                                                      ),
                                                ),
                                              ],
                                            ),
                                          ),
                                        );
                                      }).toList(),
                                    ),
                                  );
                                },
                              ),
                            ],
                          ],
                        ),
                      ),
                      const SizedBox(height: 18),
                      if (state.insumosConStockBajo > 0)
                        GestureDetector(
                          onTap: () {
                            setState(() {
                              _showLowStockDetails = !_showLowStockDetails;
                            });
                          },
                          child: Container(
                            width: double.infinity,
                            padding: const EdgeInsets.symmetric(
                              horizontal: 14,
                              vertical: 10,
                            ),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFDE7E7),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(
                                      Icons.warning_amber_rounded,
                                      color: Color(0xFFE15757),
                                    ),
                                    const SizedBox(width: 10),
                                    Expanded(
                                      child: Text(
                                        '${state.insumosConStockBajo} insumos con stock por debajo del mínimo',
                                        style: AppTheme.font.bodySmall.copyWith(
                                          color: const Color(0xFFB63A3A),
                                          fontWeight: FontWeight.w600,
                                        ),
                                      ),
                                    ),
                                    Icon(
                                      _showLowStockDetails
                                          ? Icons.keyboard_arrow_up_rounded
                                          : Icons.keyboard_arrow_down_rounded,
                                      color: const Color(0xFFE15757),
                                    ),
                                  ],
                                ),
                                if (_showLowStockDetails &&
                                    state
                                        .listaInsumosConStockBajo
                                        .isNotEmpty) ...[
                                  const SizedBox(height: 12),
                                  ...state.listaInsumosConStockBajo.map((
                                    insumo,
                                  ) {
                                    return Padding(
                                      padding: const EdgeInsets.only(bottom: 6),
                                      child: Row(
                                        children: [
                                          Expanded(
                                            child: Text(
                                              insumo.nombre,
                                              style: AppTheme.font.bodySmall
                                                  .copyWith(
                                                    color: const Color(
                                                      0xFFB63A3A,
                                                    ),
                                                    fontWeight: FontWeight.w600,
                                                  ),
                                            ),
                                          ),
                                          Text(
                                            '${insumo.stockActual} / ${insumo.stockMinimo}',
                                            style: AppTheme.font.bodySmall
                                                .copyWith(
                                                  color: const Color(
                                                    0xFFB63A3A,
                                                  ),
                                                  fontWeight: FontWeight.w700,
                                                ),
                                          ),
                                        ],
                                      ),
                                    );
                                  }),
                                ],
                              ],
                            ),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  String _formatStockValue(double stock, dynamic unidad) {
    final value = stock % 1 == 0
        ? stock.toInt().toString()
        : stock.toStringAsFixed(1);
    return '$value ${unidad.toString().split('.').last}';
  }

  Widget _buildQuickAccessCard({
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        height: 152,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: color,
          borderRadius: BorderRadius.circular(18),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Align(
              alignment: Alignment.topLeft,
              child: Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(icon, color: Colors.white, size: 22),
              ),
            ),
            const Spacer(),
            Text(
              'ACCESO DIRECTO',
              style: AppTheme.font.caption.copyWith(
                fontSize: 10,
                letterSpacing: 0.7,
                fontWeight: FontWeight.w700,
                color: Colors.white.withOpacity(0.8),
              ),
            ),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTheme.font.h3.copyWith(
                fontSize: 26,
                fontWeight: FontWeight.w800,
                color: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildMetricTile({
    required String label,
    required String value,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: AppTheme.font.caption.copyWith(
              fontSize: 11,
              color: AppTheme.colors.bodyText,
              letterSpacing: 0.5,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            value,
            style: AppTheme.font.h3.copyWith(
              fontSize: 18,
              fontWeight: FontWeight.w800,
              color: accent,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) {
    final formatted = value.toStringAsFixed(0);
    return 'S/ $formatted';
  }

  Widget _buildOperationCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.all(14),
        decoration: BoxDecoration(
          color: const Color(0xFFF0EFEF),
          borderRadius: BorderRadius.circular(16),
        ),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: const Color(0xFFE6E0DC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(icon, color: AppTheme.colors.titleText, size: 22),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    label,
                    style: AppTheme.font.body.copyWith(
                      fontSize: 16,
                      fontWeight: FontWeight.w700,
                      color: AppTheme.colors.titleText,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: AppTheme.font.bodySmall.copyWith(
                      fontSize: 12,
                      color: AppTheme.colors.bodyText,
                    ),
                  ),
                ],
              ),
            ),
            const Icon(Icons.chevron_right_rounded, size: 26),
          ],
        ),
      ),
    );
  }
}
