import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/core/demo/diseno_demo.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/widgets/ho_ui.dart';
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

    final c = AppTheme.colorsOf(context);
    final productos = state.inventarioTop;
    final maxStock = productos.isEmpty
        ? 1.0
        : productos
              .map((p) => p.stockActual)
              .reduce((a, b) => a > b ? a : b)
              .clamp(1.0, double.infinity);
    final barColors = [
      c.primary,
      c.accent,
      const Color(0xFF2B4C70),
      c.statusNormal,
      const Color(0xFF8EA2B0),
    ];

    return Scaffold(
      backgroundColor: c.bg,
      body: SafeArea(
        bottom: false,
        child: RefreshIndicator(
          onRefresh: () =>
              ref.read(dashboardViewModelProvider.notifier).cargarDatos(),
          child: ListView(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
            children: [
              // Encabezado: saludo + campana
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  children: [
                    GestureDetector(
                      onTap: () => context.go('/perfil'),
                      child: Container(
                        width: 40,
                        height: 40,
                        decoration: BoxDecoration(
                          color: const Color(0xFF611130),
                          shape: BoxShape.circle,
                          border: Border.all(color: c.border, width: 2),
                        ),
                        child: Icon(
                          Icons.person_outline_rounded,
                          color: c.white,
                          size: 20,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            _saludo().toUpperCase(),
                            style: AppTheme.fontOf(context).section,
                          ),
                          Text(
                            nombre,
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                            style: TextStyle(
                              fontSize: 14,
                              fontWeight: FontWeight.w700,
                              color: c.titleText,
                            ),
                          ),
                        ],
                      ),
                    ),
                    HoIconButton(
                      icon: Icons.notifications_none_rounded,
                      round: true,
                      tooltip: 'Alertas',
                      onTap: () => context.go('/alertas'),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.baseline,
                  textBaseline: TextBaseline.alphabetic,
                  children: [
                    Text(
                      'Dashboard',
                      style: AppTheme.serif(
                        TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.w800,
                          letterSpacing: -0.4,
                          color: c.titleText,
                        ),
                      ),
                    ),
                    const Spacer(),
                    Text(
                      _capitalizar(fecha),
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.bodyText,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Accesos directos
              const HoSectionLabel('Accesos directos'),
              const SizedBox(height: 8),
              IntrinsicHeight(
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Expanded(
                      child: _buildQuickAccessCard(
                        label: 'Nuevo Ingreso',
                        tag: '+Entrada',
                        icon: Icons.download_rounded,
                        color: c.primary,
                        onTap: () => context.push('/movimientos/entrada'),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: _buildQuickAccessCard(
                        label: 'Nueva Salida',
                        tag: '-Salida',
                        icon: Icons.upload_rounded,
                        color: c.accent,
                        onTap: () => context.push('/movimientos/salida'),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 10),
              _buildInventoryTile(c),
              const SizedBox(height: 16),

              _buildDistribucionCategorias(c),
              const SizedBox(height: 16),

              // Productos con más stock
              HoCard(
                radius: 24,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const HoSectionLabel('Almacén general'),
                              Text(
                                'Productos con más stock',
                                style: AppTheme.serif(
                                  TextStyle(
                                    fontSize: 18,
                                    fontWeight: FontWeight.w700,
                                    color: c.titleText,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        GestureDetector(
                          onTap: () => context.go('/catalogo'),
                          child: Row(
                            children: [
                              Text(
                                'Ver todo',
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w700,
                                  color: c.primary,
                                ),
                              ),
                              Icon(
                                Icons.chevron_right_rounded,
                                size: 16,
                                color: c.primary,
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 14),
                    if (productos.isEmpty)
                      Text(
                        'No hay productos con información disponible.',
                        style: TextStyle(fontSize: 13, color: c.bodyText),
                      )
                    else
                      for (var i = 0; i < productos.length; i++) ...[
                        if (i > 0) const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: Text(
                                productos[i].nombre,
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: c.titleText,
                                ),
                              ),
                            ),
                            Text.rich(
                              TextSpan(
                                text: _formatNumero(productos[i].stockActual),
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                  color: c.titleText,
                                ),
                                children: [
                                  TextSpan(
                                    text: ' ${productos[i].unidad.dbValue}',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.w400,
                                      color: c.bodyText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 4),
                        HoProgressBar(
                          value: productos[i].stockActual / maxStock,
                          color: barColors[i % barColors.length],
                          height: 8,
                          background: c.bg,
                        ),
                      ],
                    if (state.insumosConStockBajo > 0) ...[
                      const SizedBox(height: 14),
                      _buildLowStockBanner(c, state),
                    ],
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Resumen semanal
              _buildWeeklySummary(c, state),
              const SizedBox(height: 16),

              // Operaciones
              const HoSectionLabel('Operaciones'),
              const SizedBox(height: 8),
              _buildOperationCard(
                label: 'Registro de Entrada (OCR / Voz)',
                subtitle: 'Boletas, fotos de remisión e ingreso por voz',
                icon: Icons.description_outlined,
                color: c.primary,
                onTap: () => context.push('/movimientos/ingreso-ocr'),
              ),
              const SizedBox(height: 10),
              _buildOperationCard(
                label: 'Registro de Salida & Merma',
                subtitle: 'Despacho de productos y descarte de merma',
                icon: Icons.inventory_2_outlined,
                color: c.accent,
                onTap: () => context.push('/movimientos/salida'),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // TODO: calcular la distribución real por categoría (hoy es dato demo).
  Widget _buildDistribucionCategorias(AppColors c) {
    const colores = [Color(0xFF0B2137), Color(0xFF1A385C), Color(0xFFD3DEEA)];
    final datos = DisenoDemo.distribucionCategorias;
    return HoCard(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Distribución por categoría',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: c.titleText,
                  ),
                ),
              ),
              Text(
                '100% verificado',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: c.bodyText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: SizedBox(
              height: 14,
              child: Row(
                children: [
                  for (var i = 0; i < datos.length; i++)
                    Expanded(
                      flex: datos[i].$2,
                      child: Container(color: colores[i % colores.length]),
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 16,
            runSpacing: 4,
            children: [
              for (var i = 0; i < datos.length; i++)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 10,
                      height: 10,
                      decoration: BoxDecoration(
                        color: colores[i % colores.length],
                        shape: BoxShape.circle,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '${datos[i].$1} (${datos[i].$2}%)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w600,
                        color: c.bodyText,
                      ),
                    ),
                  ],
                ),
            ],
          ),
        ],
      ),
    );
  }

  String _saludo() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Buenos días,';
    if (h < 19) return 'Buenas tardes,';
    return 'Buenas noches,';
  }

  String _capitalizar(String s) =>
      s.isEmpty ? s : s[0].toUpperCase() + s.substring(1);

  String _formatNumero(double v) =>
      v % 1 == 0 ? v.toInt().toString() : v.toStringAsFixed(1);

  Widget _buildQuickAccessCard({
    required String label,
    required String tag,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: color,
      borderRadius: BorderRadius.circular(24),
      child: InkWell(
        borderRadius: BorderRadius.circular(24),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Icon(icon, color: Colors.white, size: 20),
                  ),
                  const Spacer(),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withValues(alpha: 0.25),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: Text(
                      tag,
                      style: const TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Spacer(),
              Text(
                'ACCESO DIRECTO',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 0.8,
                  fontWeight: FontWeight.w700,
                  color: Colors.white.withValues(alpha: 0.8),
                ),
              ),
              Text(
                label,
                style: AppTheme.serif(
                  const TextStyle(
                    fontSize: 20,
                    height: 1.25,
                    fontWeight: FontWeight.w700,
                    color: Colors.white,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInventoryTile(AppColors c) {
    return Material(
      color: c.slate,
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        borderRadius: BorderRadius.circular(22),
        onTap: () => context.go('/catalogo'),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Row(
            children: [
              Container(
                width: 40,
                height: 40,
                decoration: BoxDecoration(
                  color: c.primary,
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.pie_chart_outline_rounded,
                  color: c.white,
                  size: 20,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Ver Inventario completo',
                      style: AppTheme.serif(
                        TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.w700,
                          color: c.primary,
                        ),
                      ),
                    ),
                    Text(
                      'Control de stock & insumos',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.w500,
                        color: c.primary.withValues(alpha: 0.8),
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_rounded,
                color: c.primary.withValues(alpha: 0.7),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLowStockBanner(AppColors c, DashboardState state) {
    return GestureDetector(
      onTap: () => setState(() => _showLowStockDetails = !_showLowStockDetails),
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
        decoration: BoxDecoration(
          color: c.dangerLight,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: c.statusCritical,
                  size: 16,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    '${state.insumosConStockBajo} insumos con stock por debajo del mínimo',
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                      color: c.statusCritical,
                    ),
                  ),
                ),
                Icon(
                  _showLowStockDetails
                      ? Icons.keyboard_arrow_up_rounded
                      : Icons.keyboard_arrow_down_rounded,
                  color: c.statusCritical,
                  size: 18,
                ),
              ],
            ),
            if (_showLowStockDetails)
              for (final insumo in state.listaInsumosConStockBajo)
                Padding(
                  padding: const EdgeInsets.only(top: 6, left: 24),
                  child: Row(
                    children: [
                      Expanded(
                        child: Text(
                          insumo.nombre,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: c.statusCritical,
                          ),
                        ),
                      ),
                      Text(
                        '${_formatNumero(insumo.stockActual)} / ${_formatNumero(insumo.stockMinimo)}',
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w700,
                          color: c.statusCritical,
                        ),
                      ),
                    ],
                  ),
                ),
          ],
        ),
      ),
    );
  }

  Widget _buildWeeklySummary(AppColors c, DashboardState state) {
    return HoCard(
      radius: 22,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  'Resumen semanal',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w700,
                    color: c.titleText,
                  ),
                ),
              ),
              Text(
                'Últimos 7 días',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: c.bodyText,
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMetricTile(
                  c,
                  label: 'Valor inventario',
                  value: _formatCurrency(state.valorTotalInventario),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: _buildMetricTile(
                  c,
                  label: 'Consumo',
                  value: '${state.totalConsumoSemanal.toStringAsFixed(1)} kg',
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          if (state.consumoSemanal.isEmpty)
            Container(
              height: 80,
              alignment: Alignment.center,
              child: Text(
                'Sin datos del último período',
                style: TextStyle(fontSize: 12, color: c.bodyText),
              ),
            )
          else
            _buildConsumoChart(c, state.consumoSemanal),
        ],
      ),
    );
  }

  Widget _buildConsumoChart(AppColors c, List<ConsumoDiaData> dias) {
    final maxValue = dias
        .map((e) => e.cantidad)
        .reduce((a, b) => a > b ? a : b);
    final safeMax = maxValue <= 0 ? 1.0 : maxValue;
    return SizedBox(
      height: 100,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          for (final dia in dias)
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 3),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    Container(
                      height: 8 + (dia.cantidad / safeMax) * 64,
                      decoration: BoxDecoration(
                        color: dia.cantidad > 0 ? c.primary : c.border,
                        borderRadius: BorderRadius.circular(6),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      DateFormat('E', 'es').format(dia.fecha).substring(0, 2),
                      style: TextStyle(fontSize: 10, color: c.bodyText),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildMetricTile(
    AppColors c, {
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w500,
              color: c.bodyText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
              color: c.titleText,
            ),
          ),
        ],
      ),
    );
  }

  String _formatCurrency(double value) =>
      'S/ ${NumberFormat('#,##0', 'es').format(value)}';

  Widget _buildOperationCard({
    required String label,
    required String subtitle,
    required IconData icon,
    required Color color,
    required VoidCallback onTap,
  }) {
    final c = AppTheme.colorsOf(context);
    return HoCard(
      padding: const EdgeInsets.all(14),
      onTap: onTap,
      child: Row(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color, size: 20),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: c.titleText,
                  ),
                ),
                Text(
                  subtitle,
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(fontSize: 11, color: c.bodyText),
                ),
              ],
            ),
          ),
          Icon(Icons.chevron_right_rounded, size: 18, color: c.bodyText),
        ],
      ),
    );
  }
}
