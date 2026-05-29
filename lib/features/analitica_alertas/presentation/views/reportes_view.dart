import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/models/movimiento.dart';
import 'package:happy_oven/core/repositories/movimientos_repository.dart';
import 'package:happy_oven/core/providers.dart';

final reportesDataProvider = FutureProvider.family<ReportesData, DateTimeRange>((ref, rango) async {
  final repo = ref.watch(movimientosRepositoryProvider);
  final movimientos = await repo.getMovimientosPorRango(rango.start, rango.end);
  return ReportesData._fromMovimientos(movimientos);
});

class ReportesData {
  final double totalEntradas;
  final double totalSalidas;
  final double totalMermas;
  final double valorMovido;
  final List<_InsumoConsumo> insumos;

  ReportesData._fromMovimientos(List<Movimiento> movs) :
    totalEntradas = movs.where((m) => m.tipoMovimiento == 'entrada').fold(0, (sum, m) => sum + m.cantidad),
    totalSalidas = movs.where((m) => m.tipoMovimiento == 'salida_produccion').fold(0, (sum, m) => sum + m.cantidad),
    totalMermas = movs.where((m) => m.tipoMovimiento == 'merma').fold(0, (sum, m) => sum + m.cantidad),
    valorMovido = movs.fold(0, (sum, m) => sum + (m.precioUnitario ?? 0) * m.cantidad.abs()),
    insumos = _topInsumos(movs);
}

class _InsumoConsumo {
  final String nombre;
  final double kg;
  final double porcentaje;
  _InsumoConsumo({required this.nombre, required this.kg, required this.porcentaje});
}

List<_InsumoConsumo> _topInsumos(List<Movimiento> movs) {
  final salidas = movs.where((m) => m.tipoMovimiento == 'salida_produccion').toList();
  if (salidas.isEmpty) return [];
  final agrupado = <String, double>{};
  for (final m in salidas) {
    agrupado.update(m.articuloId, (v) => v + m.cantidad, ifAbsent: () => m.cantidad);
  }
  final sorted = agrupado.entries.toList()..sort((a, b) => b.value.compareTo(a.value));
  final top5 = sorted.take(5).toList();
  final maxVal = top5.firstOrNull?.value ?? 1;
  return top5.map((e) => _InsumoConsumo(
    nombre: e.key, // we don't have the name here, but the articulo_id
    kg: e.value,
    porcentaje: e.value / maxVal,
  )).toList();
}

class ReportesView extends ConsumerStatefulWidget {
  const ReportesView({super.key});

  @override
  ConsumerState<ReportesView> createState() => _ReportesViewState();
}

class _ReportesViewState extends ConsumerState<ReportesView> {
  DateTimeRange _rango = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 6)),
    end: DateTime.now(),
  );

  String get _rangoFormateado {
    final fmt = DateFormat('dd MMM yyyy', 'es');
    return '${fmt.format(_rango.start)} — ${fmt.format(_rango.end)}';
  }

  Future<void> _seleccionarRango() async {
    final resultado = await showDateRangePicker(
      context: context,
      firstDate: DateTime(2024),
      lastDate: DateTime.now(),
      initialDateRange: _rango,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: ColorScheme.light(
              primary: AppTheme.colors.primary,
              onPrimary: AppTheme.colors.white,
              surface: AppTheme.colors.white,
              onSurface: AppTheme.colors.titleText,
            ),
          ),
          child: child!,
        );
      },
    );
    if (resultado != null) setState(() => _rango = resultado);
  }

  Future<void> _exportarPDF(ReportesData data) async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text('Happy Oven — Reporte de Inventario',
                  style: pw.TextStyle(fontSize: 20, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 8),
              pw.Text('Período: $_rangoFormateado', style: const pw.TextStyle(fontSize: 12)),
              pw.SizedBox(height: 24),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _pdfKpi('Total entradas', '${data.totalEntradas.toStringAsFixed(1)} kg'),
                  _pdfKpi('Total salidas', '${data.totalSalidas.toStringAsFixed(1)} kg'),
                  _pdfKpi('Valor movido', 'S/ ${data.valorMovido.toStringAsFixed(2)}'),
                  _pdfKpi('Mermas', '${data.totalMermas.toStringAsFixed(1)} kg'),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Text('Insumos más consumidos',
                  style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
              pw.SizedBox(height: 12),
              ...data.insumos.map((i) => pw.Padding(
                    padding: const pw.EdgeInsets.only(bottom: 8),
                    child: pw.Row(
                      mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                      children: [
                        pw.Text(i.nombre, style: const pw.TextStyle(fontSize: 12)),
                        pw.Text('${i.kg.toStringAsFixed(1)} kg', style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                  )),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(onLayout: (format) async => pdf.save(), name: 'reporte_happy_oven.pdf');
  }

  pw.Widget _pdfKpi(String label, String valor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(valor, style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final dataAsync = ref.watch(reportesDataProvider(_rango));
    return Scaffold(
      backgroundColor: AppTheme.colors.bg,
      body: Column(
        children: [
          _buildHeader(dataAsync),
          Expanded(child: _buildBody(dataAsync)),
        ],
      ),
    );
  }

  Widget _buildHeader(AsyncValue<ReportesData> dataAsync) {
    return Container(
      color: AppTheme.colors.accent,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Reportes', style: AppTheme.font.h3),
                      const SizedBox(height: 2),
                      Text('Genera y exporta tu resumen',
                          style: AppTheme.font.caption.copyWith(color: AppTheme.colors.accentDark)),
                    ],
                  ),
                  GestureDetector(
                    onTap: dataAsync.hasValue ? () => _exportarPDF(dataAsync.value!) : null,
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppTheme.colors.primary,
                        borderRadius: AppTheme.radius.brSm,
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.picture_as_pdf_outlined, color: AppTheme.colors.white, size: 16),
                          const SizedBox(width: 6),
                          Text('Exportar', style: AppTheme.font.label.copyWith(
                            color: AppTheme.colors.white, fontSize: 13)),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _seleccionarRango,
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  decoration: BoxDecoration(
                    color: AppTheme.colors.card,
                    borderRadius: AppTheme.radius.brMd,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined, color: AppTheme.colors.brownMid, size: 16),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text('Rango seleccionado', style: AppTheme.font.caption),
                              const SizedBox(height: 2),
                              Text(_rangoFormateado, style: AppTheme.font.label.copyWith(fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                      Icon(Icons.keyboard_arrow_down_rounded, color: AppTheme.colors.brownMid, size: 20),
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

  Widget _buildBody(AsyncValue<ReportesData> dataAsync) {
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
        child: dataAsync.when(
          loading: () => const Center(child: CircularProgressIndicator()),
          error: (e, _) => Center(
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Text('Error al cargar datos: $e', style: AppTheme.font.body),
            ),
          ),
          data: (data) => SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(14, 20, 14, 8),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKpiGrid(data),
                const SizedBox(height: 16),
                _buildInsumosConsumo(data),
                const SizedBox(height: 16),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildKpiGrid(ReportesData data) {
    return GridView.count(
      crossAxisCount: 2, shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 1.4,
      children: [
        _buildKpiCard(icono: Icons.arrow_circle_down_outlined,
            valor: '${data.totalEntradas.toStringAsFixed(1)} kg',
            etiqueta: 'Total entradas', colorFondo: AppTheme.colors.successLight,
            colorBorde: AppTheme.colors.successBorder, colorIcono: AppTheme.colors.statusNormal),
        _buildKpiCard(icono: Icons.arrow_circle_up_outlined,
            valor: '${data.totalSalidas.toStringAsFixed(1)} kg',
            etiqueta: 'Total salidas', colorFondo: AppTheme.colors.dangerLight,
            colorBorde: AppTheme.colors.dangerBorder, colorIcono: AppTheme.colors.statusCritical),
        _buildKpiCard(icono: Icons.monetization_on_outlined,
            valor: 'S/ ${data.valorMovido.toStringAsFixed(2)}',
            etiqueta: 'Valor movido', colorFondo: AppTheme.colors.primaryLight,
            colorBorde: AppTheme.colors.primaryBorder, colorIcono: AppTheme.colors.primary),
        _buildKpiCard(icono: Icons.delete_outline_rounded,
            valor: '${data.totalMermas.toStringAsFixed(1)} kg',
            etiqueta: 'Mermas del período', colorFondo: AppTheme.colors.dangerLight,
            colorBorde: AppTheme.colors.dangerBorder, colorIcono: AppTheme.colors.statusCritical),
      ],
    );
  }

  Widget _buildKpiCard({
    required IconData icono, required String valor, required String etiqueta,
    required Color colorFondo, required Color colorBorde, required Color colorIcono,
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
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, color: colorIcono, size: 20),
          const SizedBox(height: 8),
          Text(valor, style: AppTheme.font.h3.copyWith(fontSize: 18, color: colorIcono)),
          const SizedBox(height: 2),
          Text(etiqueta, style: AppTheme.font.caption.copyWith(
            color: colorIcono.withValues(alpha: 0.8), height: 1.3)),
        ],
      ),
    );
  }

  Widget _buildInsumosConsumo(ReportesData data) {
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
          Text('Insumos más consumidos', style: AppTheme.font.label.copyWith(fontSize: 13)),
          const SizedBox(height: 16),
          if (data.insumos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No hay datos de consumo en este período',
                    style: AppTheme.font.caption),
              ),
            )
          else
            ...data.insumos.map((i) => _buildBarraInsumo(i)),
        ],
      ),
    );
  }

  Widget _buildBarraInsumo(_InsumoConsumo insumo) {
    final color = insumo.porcentaje >= 0.7 ? AppTheme.colors.primary : AppTheme.colors.primaryBorder;
    return Padding(
      padding: const EdgeInsets.only(bottom: 14),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(insumo.nombre, style: AppTheme.font.bodySmall.copyWith(fontSize: 12)),
              Text('${insumo.kg.toStringAsFixed(1)} kg', style: AppTheme.font.label.copyWith(fontSize: 12)),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(AppTheme.radius.full),
            child: LinearProgressIndicator(
              value: insumo.porcentaje, minHeight: 6,
              backgroundColor: AppTheme.colors.surface,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }
}
