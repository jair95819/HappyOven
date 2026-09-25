import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/features/analitica_alertas/presentation/viewmodels/sugerencias_viewmodel.dart';

const _umbralUrgente = 14; // días para considerar "reabastecer pronto"

class SugerenciasCompraView extends ConsumerWidget {
  const SugerenciasCompraView({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final colors = AppTheme.colorsOf(context);
    final async = ref.watch(sugerenciasCompraProvider);

    return Scaffold(
      backgroundColor: colors.bg,
      body: Column(
        children: [
          _buildHeader(context, colors),
          Expanded(
            child: async.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(20),
                  child: Text('Error al cargar sugerencias: $e',
                      style: AppTheme.fontOf(context).body),
                ),
              ),
              data: (lista) => _buildBody(context, colors, lista),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(BuildContext context, AppColors colors) {
    final font = AppTheme.fontOf(context);
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [colors.khaki, colors.khakiSoft],
        ),
      ),
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
          child: Row(
            children: [
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: colors.primary,
                    borderRadius: AppTheme.radius.brSm,
                  ),
                  child: Icon(Icons.arrow_back_rounded,
                      color: colors.white, size: 18),
                ),
              ),
              const SizedBox(width: 12),
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Sugerencias de Compra', style: font.h3),
                  const SizedBox(height: 2),
                  Text('Reabastecimiento proyectado por IA',
                      style: font.caption.copyWith(color: colors.accentDark)),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildBody(
    BuildContext context,
    AppColors colors,
    List<SugerenciaCompra> lista,
  ) {
    final font = AppTheme.fontOf(context);
    final conProyeccion = lista.where((s) => !s.dataInsuficiente).toList();
    final sinDatos = lista.where((s) => s.dataInsuficiente).toList();

    return Container(
      decoration: BoxDecoration(
        color: colors.bg,
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
        child: lista.isEmpty
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Text('No hay insumos registrados todavía.',
                      style: font.hint, textAlign: TextAlign.center),
                ),
              )
            : ListView(
                padding: const EdgeInsets.fromLTRB(16, 20, 16, 24),
                children: [
                  Text(
                    'El motor de IA estima la tasa de consumo diario, proyecta '
                    'el agotamiento y sugiere cuánto reabastecer (cobertura de 30 días).',
                    style: font.caption.copyWith(color: colors.hint),
                  ),
                  SizedBox(height: AppTheme.spacing.lg),
                  if (conProyeccion.isEmpty)
                    _infoBox(
                      colors,
                      font,
                      'Aún no hay insumos con suficiente historial para sugerir compras.',
                    )
                  else ...[
                    _sectionTitle(font, 'Reabastecimiento sugerido',
                        '${conProyeccion.length}'),
                    SizedBox(height: AppTheme.spacing.md),
                    ...conProyeccion
                        .map((s) => _buildSugerenciaCard(colors, font, s)),
                  ],
                  if (sinDatos.isNotEmpty) ...[
                    SizedBox(height: AppTheme.spacing.lg),
                    _sectionTitle(
                        font, 'Sin datos suficientes', '${sinDatos.length}'),
                    const SizedBox(height: 6),
                    Text(
                      'No tienen historial confiable; la predicción se omite (RF-021).',
                      style: font.caption.copyWith(fontSize: 10, color: colors.hint),
                    ),
                    SizedBox(height: AppTheme.spacing.md),
                    ...sinDatos.map((s) => _buildSinDatosCard(colors, font, s)),
                  ],
                ],
              ),
      ),
    );
  }

  Widget _sectionTitle(AppFont font, String titulo, String contador) {
    return Row(
      children: [
        Text(titulo, style: font.label.copyWith(fontWeight: FontWeight.w600)),
        const SizedBox(width: 8),
        Text('($contador)', style: font.caption),
      ],
    );
  }

  Widget _infoBox(AppColors colors, AppFont font, String texto) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: colors.surface,
        borderRadius: AppTheme.radius.brMd,
      ),
      child: Text(texto, style: font.caption, textAlign: TextAlign.center),
    );
  }

  Widget _buildSugerenciaCard(
      AppColors colors, AppFont font, SugerenciaCompra s) {
    final esUrgente = s.urgente(_umbralUrgente);
    final color = esUrgente
        ? colors.statusCritical
        : (s.diasRestantes <= 30 ? colors.statusLow : colors.statusNormal);

    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacing.md),
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacing.md),
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
              children: [
                Expanded(
                  child: Text(s.nombre,
                      style: font.label.copyWith(fontSize: 14)),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                  decoration: BoxDecoration(
                    color: color.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    esUrgente
                        ? 'Urgente'
                        : 'Se agota en ${s.diasRestantes} días',
                    style: font.caption.copyWith(
                        color: color, fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              children: [
                _metric(colors, font, 'Stock actual',
                    '${s.stockActual.toStringAsFixed(1)} ${s.unidad}'),
                _metric(colors, font, 'Tasa consumo',
                    '${s.consumoDiario.toStringAsFixed(2)} ${s.unidad}/día'),
                _metric(colors, font, 'Se agota en', '${s.diasRestantes} días'),
              ],
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              decoration: BoxDecoration(
                color: colors.primaryLight,
                borderRadius: AppTheme.radius.brSm,
              ),
              child: Row(
                children: [
                  Icon(Icons.shopping_cart_outlined,
                      size: 16, color: colors.primary),
                  const SizedBox(width: 8),
                  Text('Cantidad sugerida:',
                      style: font.caption.copyWith(color: colors.primaryDark)),
                  const Spacer(),
                  Text(
                    '${s.cantidadSugerida.toStringAsFixed(0)} ${s.unidad}',
                    style: font.label
                        .copyWith(fontSize: 14, color: colors.primary),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _metric(AppColors colors, AppFont font, String label, String valor) {
    return Expanded(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: font.caption.copyWith(fontSize: 10)),
          const SizedBox(height: 2),
          Text(valor, style: font.label.copyWith(fontSize: 12)),
        ],
      ),
    );
  }

  Widget _buildSinDatosCard(
      AppColors colors, AppFont font, SugerenciaCompra s) {
    return Padding(
      padding: EdgeInsets.only(bottom: AppTheme.spacing.sm),
      child: Container(
        padding: EdgeInsets.all(AppTheme.spacing.md),
        decoration: BoxDecoration(
          color: colors.surface,
          borderRadius: BorderRadius.circular(AppTheme.radius.md),
          border: Border.all(color: colors.border, width: 0.5),
          boxShadow: AppTheme.shadows.cardSm,
        ),
        child: Row(
          children: [
            Icon(Icons.help_outline_rounded, size: 18, color: colors.hint),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(s.nombre, style: font.bodySmall.copyWith(fontSize: 13)),
                  const SizedBox(height: 2),
                  Text(
                    'Stock: ${s.stockActual.toStringAsFixed(1)} ${s.unidad} · '
                    '${s.muestras} movimiento(s) de consumo',
                    style: font.caption.copyWith(fontSize: 10),
                  ),
                ],
              ),
            ),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
              decoration: BoxDecoration(
                color: colors.hint.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(6),
              ),
              child: Text('Data insuficiente',
                  style: font.caption
                      .copyWith(color: colors.hint, fontWeight: FontWeight.w600)),
            ),
          ],
        ),
      ),
    );
  }
}
