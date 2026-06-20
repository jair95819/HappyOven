import 'dart:convert';
import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/intl.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/models/movimiento.dart';
import 'package:happy_oven/core/models/enums.dart';
import 'package:happy_oven/core/providers.dart';

// ───────────────────────────── Lógica pura (testeable) ─────────────────────────────

/// Valida un rango de fechas. Devuelve el mensaje de error si la fecha de inicio
/// es posterior a la de fin (RF-016), o null si el rango es válido.
String? validarRangoFechas(DateTime inicio, DateTime fin) {
  if (inicio.isAfter(fin)) return 'Rango de fechas inválido.';
  return null;
}

/// Consumo agregado de un insumo en el período, con su nombre legible.
class InsumoConsumo {
  final String id;
  final String nombre;
  final double cantidad;
  InsumoConsumo({required this.id, required this.nombre, required this.cantidad});
}

/// Consumo total agregado por día (para la serie temporal del gráfico de línea).
class ConsumoDia {
  final DateTime fecha;
  final double cantidad;
  ConsumoDia({required this.fecha, required this.cantidad});
}

class ReportesData {
  final double totalEntradas;
  final double totalSalidas;
  final double totalMermas;
  final double valorMovido;
  final List<InsumoConsumo> insumos; // top consumidos, con nombre real
  final List<ConsumoDia> serieDiaria; // consumo por día dentro del rango

  ReportesData({
    required this.totalEntradas,
    required this.totalSalidas,
    required this.totalMermas,
    required this.valorMovido,
    required this.insumos,
    required this.serieDiaria,
  });

  bool get sinDatos => totalEntradas == 0 && totalSalidas == 0 && totalMermas == 0;

  /// Calcula los indicadores del reporte a partir de los [movimientos], usando
  /// el mapa [nombres] (articulo_id -> nombre) para mostrar nombres legibles.
  static ReportesData calcular(
    List<Movimiento> movimientos,
    Map<String, String> nombres,
    DateTimeRange rango,
  ) {
    double entradas = 0, salidas = 0, mermas = 0, valor = 0;
    final porInsumo = <String, double>{};

    // Inicializa todos los días del rango en 0 para una serie continua.
    final porDia = <DateTime, double>{};
    final dInicio = DateTime(rango.start.year, rango.start.month, rango.start.day);
    final dFin = DateTime(rango.end.year, rango.end.month, rango.end.day);
    for (var d = dInicio; !d.isAfter(dFin); d = d.add(const Duration(days: 1))) {
      porDia[d] = 0;
    }

    for (final m in movimientos) {
      valor += (m.precioUnitario ?? 0) * m.cantidad.abs();
      switch (m.tipoMovimiento) {
        case TipoMovimiento.entrada:
          entradas += m.cantidad;
          break;
        case TipoMovimiento.salidaProduccion:
          salidas += m.cantidad;
          porInsumo.update(m.articuloId, (v) => v + m.cantidad,
              ifAbsent: () => m.cantidad);
          final dia = DateTime(m.fecha.year, m.fecha.month, m.fecha.day);
          if (porDia.containsKey(dia)) porDia[dia] = porDia[dia]! + m.cantidad;
          break;
        case TipoMovimiento.merma:
          mermas += m.cantidad;
          break;
        case TipoMovimiento.ajuste:
          break;
      }
    }

    final insumos = porInsumo.entries
        .map((e) => InsumoConsumo(
              id: e.key,
              nombre: nombres[e.key] ?? 'Insumo',
              cantidad: e.value,
            ))
        .toList()
      ..sort((a, b) => b.cantidad.compareTo(a.cantidad));

    final serie = porDia.entries
        .map((e) => ConsumoDia(fecha: e.key, cantidad: e.value))
        .toList()
      ..sort((a, b) => a.fecha.compareTo(b.fecha));

    return ReportesData(
      totalEntradas: entradas,
      totalSalidas: salidas,
      totalMermas: mermas,
      valorMovido: valor,
      insumos: insumos.take(5).toList(),
      serieDiaria: serie,
    );
  }
}

/// Genera el contenido CSV del reporte (RF-015). Función pura, testeable.
String generarCsvReporte(ReportesData data, DateTimeRange rango) {
  final fmt = DateFormat('yyyy-MM-dd');
  String esc(String s) => '"${s.replaceAll('"', '""')}"';
  final b = StringBuffer();
  b.writeln('Reporte Happy Oven');
  b.writeln('Periodo,${fmt.format(rango.start)},${fmt.format(rango.end)}');
  b.writeln('');
  b.writeln('Indicador,Valor');
  b.writeln('Total entradas (kg),${data.totalEntradas.toStringAsFixed(2)}');
  b.writeln('Total salidas (kg),${data.totalSalidas.toStringAsFixed(2)}');
  b.writeln('Mermas (kg),${data.totalMermas.toStringAsFixed(2)}');
  b.writeln('Valor movido (S/),${data.valorMovido.toStringAsFixed(2)}');
  b.writeln('');
  b.writeln('Insumo,Consumo (kg)');
  for (final i in data.insumos) {
    b.writeln('${esc(i.nombre)},${i.cantidad.toStringAsFixed(2)}');
  }
  b.writeln('');
  b.writeln('Fecha,Consumo (kg)');
  for (final d in data.serieDiaria) {
    b.writeln('${fmt.format(d.fecha)},${d.cantidad.toStringAsFixed(2)}');
  }
  return b.toString();
}

// ───────────────────────────── Provider ─────────────────────────────

final reportesDataProvider =
    FutureProvider.family<ReportesData, DateTimeRange>((ref, rango) async {
  final movRepo = ref.watch(movimientosRepositoryProvider);
  final artRepo = ref.watch(articulosRepositoryProvider);
  final movimientos = await movRepo.getMovimientosPorRango(rango.start, rango.end);
  final articulos = await artRepo.getArticulos();
  final nombres = {for (final a in articulos) a.id: a.nombre};
  return ReportesData.calcular(movimientos, nombres, rango);
});

// ───────────────────────────── Vista ─────────────────────────────

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
    if (resultado == null) return;

    // Validación de congruencia del rango (RF-016).
    final error = validarRangoFechas(resultado.start, resultado.end);
    if (error != null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(error),
        backgroundColor: AppTheme.colors.statusCritical,
        behavior: SnackBarBehavior.floating,
      ));
      return;
    }
    setState(() => _rango = resultado);
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
              pw.Text('Período: $_rangoFormateado',
                  style: const pw.TextStyle(fontSize: 12)),
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
                        pw.Text('${i.cantidad.toStringAsFixed(1)} kg',
                            style: const pw.TextStyle(fontSize: 12)),
                      ],
                    ),
                  )),
            ],
          );
        },
      ),
    );
    await Printing.layoutPdf(
        onLayout: (format) async => pdf.save(), name: 'reporte_happy_oven.pdf');
  }

  Future<void> _exportarCSV(ReportesData data) async {
    final csv = generarCsvReporte(data, _rango);
    final bytes = Uint8List.fromList(utf8.encode(csv));
    try {
      await Printing.sharePdf(bytes: bytes, filename: 'reporte_happy_oven.csv');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('No se pudo exportar el CSV: $e'),
        backgroundColor: AppTheme.colors.statusCritical,
        behavior: SnackBarBehavior.floating,
      ));
    }
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
    final data = dataAsync.valueOrNull;
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
                      SizedBox(height: AppTheme.spacing.sm),
                      Text('Genera y exporta tu resumen',
                          style: AppTheme.font.caption
                              .copyWith(color: AppTheme.colors.accentDark)),
                    ],
                  ),
                  Row(
                    children: [
                      _botonExportar(
                        icono: Icons.picture_as_pdf_outlined,
                        etiqueta: 'PDF',
                        onTap: data != null ? () => _exportarPDF(data) : null,
                      ),
                      const SizedBox(width: 8),
                      _botonExportar(
                        icono: Icons.grid_on_outlined,
                        etiqueta: 'CSV',
                        onTap: data != null ? () => _exportarCSV(data) : null,
                      ),
                    ],
                  ),
                ],
              ),
              const SizedBox(height: 16),
              GestureDetector(
                onTap: _seleccionarRango,
                child: Container(
                  padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.md, vertical: AppTheme.spacing.sm),
                  decoration: BoxDecoration(
                    color: AppTheme.colors.card,
                    borderRadius: AppTheme.radius.brMd,
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(Icons.calendar_today_outlined,
                              color: AppTheme.colors.brownMid, size: 16),
                          const SizedBox(width: 10),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('Rango seleccionado',
                              style: AppTheme.font.caption),
                          SizedBox(height: AppTheme.spacing.sm),
                          Text(_rangoFormateado,
                                  style: AppTheme.font.label.copyWith(fontSize: 13)),
                            ],
                          ),
                        ],
                      ),
                      Icon(Icons.keyboard_arrow_down_rounded,
                          color: AppTheme.colors.brownMid, size: 20),
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

  Widget _botonExportar({
    required IconData icono,
    required String etiqueta,
    required VoidCallback? onTap,
  }) {
    final habilitado = onTap != null;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 9),
        decoration: BoxDecoration(
          color: habilitado
              ? AppTheme.colors.primary
              : AppTheme.colors.primary.withValues(alpha: 0.4),
          borderRadius: AppTheme.radius.brSm,
        ),
        child: Row(
          children: [
            Icon(icono, color: AppTheme.colors.white, size: 16),
            const SizedBox(width: 6),
            Text(etiqueta,
                style: AppTheme.font.label
                    .copyWith(color: AppTheme.colors.white, fontSize: 13)),
          ],
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
            padding: EdgeInsets.fromLTRB(AppTheme.spacing.md, AppTheme.spacing.lg, AppTheme.spacing.md, AppTheme.spacing.sm),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildKpiGrid(data),
                SizedBox(height: AppTheme.spacing.lg),
                _buildTendenciaConsumo(data),
                SizedBox(height: AppTheme.spacing.lg),
                _buildInsumosConsumo(data),
                SizedBox(height: AppTheme.spacing.lg),
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
      padding: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(AppTheme.radius.lg),
        border: Border.all(color: colorBorde, width: 0.5),
        boxShadow: AppTheme.shadows.cardSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, color: colorIcono, size: 20),
          SizedBox(height: AppTheme.spacing.md),
          Text(valor, style: AppTheme.font.h3.copyWith(fontSize: 18, color: colorIcono)),
          SizedBox(height: AppTheme.spacing.sm),
          Text(etiqueta, style: AppTheme.font.caption.copyWith(
            color: colorIcono.withValues(alpha: 0.8), height: 1.3)),
        ],
      ),
    );
  }

  /// Gráfico de línea interactivo con la tendencia diaria de consumo (RF-014).
  Widget _buildTendenciaConsumo(ReportesData data) {
    final serie = data.serieDiaria;
    final hayConsumo = serie.any((d) => d.cantidad > 0);
    final maxY = hayConsumo
        ? serie.map((d) => d.cantidad).reduce((a, b) => a > b ? a : b) * 1.25
        : 10.0;
    final fmtDia = DateFormat('d MMM', 'es');

    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: AppTheme.colors.card,
        borderRadius: BorderRadius.circular(AppTheme.radius.lg),
        border: Border.all(color: AppTheme.colors.border, width: 0.5),
        boxShadow: AppTheme.shadows.cardSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Tendencia de consumo', style: AppTheme.font.label.copyWith(fontSize: 13)),
          SizedBox(height: AppTheme.spacing.sm),
          Text('Consumo de insumos por día. Toca un punto para ver el valor.',
              style: AppTheme.font.caption.copyWith(fontSize: 10, color: AppTheme.colors.hint)),
          SizedBox(height: AppTheme.spacing.md),
          if (!hayConsumo)
            SizedBox(
              height: 140,
              child: Center(
                child: Text('No hay consumo registrado en este período',
                    style: AppTheme.font.caption, textAlign: TextAlign.center),
              ),
            )
          else
            SizedBox(
              height: 140,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY,
                  lineTouchData: LineTouchData(
                    enabled: true,
                    touchTooltipData: LineTouchTooltipData(
                      getTooltipItems: (spots) => spots.map((s) {
                        final dia = serie[s.x.toInt()];
                        return LineTooltipItem(
                          '${fmtDia.format(dia.fecha)}\n${dia.cantidad.toStringAsFixed(1)} kg',
                          TextStyle(
                            color: AppTheme.colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  gridData: FlGridData(
                    show: true,
                    drawVerticalLine: false,
                    getDrawingHorizontalLine: (v) =>
                        FlLine(color: AppTheme.colors.border, strokeWidth: 0.5),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles()),
                    rightTitles: const AxisTitles(sideTitles: SideTitles()),
                    topTitles: const AxisTitles(sideTitles: SideTitles()),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        interval: 1,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          // Mostrar solo primera, intermedia y última etiqueta.
                          final mostrar = i == 0 ||
                              i == serie.length - 1 ||
                              i == (serie.length ~/ 2);
                          if (i < 0 || i >= serie.length || !mostrar) {
                            return const SizedBox.shrink();
                          }
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(
                              fmtDia.format(serie[i].fecha),
                              style: TextStyle(
                                  fontSize: 9, color: AppTheme.colors.hint),
                            ),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: serie
                          .asMap()
                          .entries
                          .map((e) => FlSpot(e.key.toDouble(), e.value.cantidad))
                          .toList(),
                      isCurved: true,
                      color: AppTheme.colors.primary,
                      barWidth: 2.5,
                      dotData: const FlDotData(show: true),
                      belowBarData: BarAreaData(
                        show: true,
                        color: AppTheme.colors.primary.withValues(alpha: 0.12),
                      ),
                    ),
                  ],
                ),
              ),
            ),
        ],
      ),
    );
  }

  /// Gráfico de barras interactivo de los insumos más consumidos (RF-014),
  /// con nombres reales y tooltip al tocar cada barra.
  Widget _buildInsumosConsumo(ReportesData data) {
    final insumos = data.insumos;
    final maxY = insumos.isNotEmpty
        ? insumos.map((i) => i.cantidad).reduce((a, b) => a > b ? a : b) * 1.25
        : 10.0;

    return Container(
      padding: EdgeInsets.all(AppTheme.spacing.md),
      decoration: BoxDecoration(
        color: AppTheme.colors.card,
        borderRadius: BorderRadius.circular(AppTheme.radius.lg),
        border: Border.all(color: AppTheme.colors.border, width: 0.5),
        boxShadow: AppTheme.shadows.cardSm,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Insumos más consumidos', style: AppTheme.font.label.copyWith(fontSize: 13)),
          SizedBox(height: AppTheme.spacing.sm),
          Text('Toca una barra para ver el insumo y su consumo.',
              style: AppTheme.font.caption.copyWith(fontSize: 10, color: AppTheme.colors.hint)),
          SizedBox(height: AppTheme.spacing.md),
          if (insumos.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 20),
              child: Center(
                child: Text('No hay datos de consumo en este período',
                    style: AppTheme.font.caption),
              ),
            )
          else ...[
            SizedBox(
              height: 160,
              child: BarChart(
                BarChartData(
                  alignment: BarChartAlignment.spaceAround,
                  maxY: maxY,
                  barTouchData: BarTouchData(
                    enabled: true,
                    touchTooltipData: BarTouchTooltipData(
                      getTooltipItem: (group, gi, rod, ri) {
                        final insumo = insumos[group.x];
                        return BarTooltipItem(
                          '${insumo.nombre}\n${insumo.cantidad.toStringAsFixed(1)} kg',
                          TextStyle(
                            color: AppTheme.colors.white,
                            fontWeight: FontWeight.w600,
                            fontSize: 11,
                          ),
                        );
                      },
                    ),
                  ),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(sideTitles: SideTitles()),
                    rightTitles: const AxisTitles(sideTitles: SideTitles()),
                    topTitles: const AxisTitles(sideTitles: SideTitles()),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final i = value.toInt();
                          if (i < 0 || i >= insumos.length) {
                            return const SizedBox.shrink();
                          }
                          final nombre = insumos[i].nombre;
                          final corto =
                              nombre.length > 7 ? '${nombre.substring(0, 7)}…' : nombre;
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(corto,
                                style: TextStyle(fontSize: 9, color: AppTheme.colors.hint)),
                          );
                        },
                      ),
                    ),
                  ),
                  gridData: const FlGridData(show: false),
                  borderData: FlBorderData(show: false),
                  barGroups: insumos
                      .asMap()
                      .entries
                      .map((e) => BarChartGroupData(
                            x: e.key,
                            barRods: [
                              BarChartRodData(
                                toY: e.value.cantidad,
                                color: AppTheme.colors.primary,
                                width: 20,
                                borderRadius: const BorderRadius.only(
                                  topLeft: Radius.circular(4),
                                  topRight: Radius.circular(4),
                                ),
                              ),
                            ],
                          ))
                      .toList(),
                ),
              ),
            ),
            SizedBox(height: AppTheme.spacing.sm),
            // Leyenda con valores exactos (refuerza qué datos se muestran).
            ...insumos.map((i) => Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Container(
                            width: 8, height: 8,
                            decoration: BoxDecoration(
                              color: AppTheme.colors.primary,
                              borderRadius: BorderRadius.circular(2),
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(i.nombre,
                              style: AppTheme.font.bodySmall.copyWith(fontSize: 12)),
                        ],
                      ),
                      Text('${i.cantidad.toStringAsFixed(1)} kg',
                          style: AppTheme.font.label.copyWith(fontSize: 12)),
                    ],
                  ),
                )),
          ],
        ],
      ),
    );
  }
}
