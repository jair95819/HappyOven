import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

class ReportesView extends StatefulWidget {
  const ReportesView({super.key});

  @override
  State<ReportesView> createState() => _ReportesViewState();
}

class _ReportesViewState extends State<ReportesView> {
  static const _olive = Color(0xFFC8CA9E);
  static const _oliveDark = Color(0xFF4A4A38);
  static const _orange = Color(0xFFFF8C42);
  static const _orangeLight = Color(0xFFFFF3EB);
  static const _orangeBorde = Color(0xFFFFD9BE);
  static const _beige = Color(0xFFF5F0E8);
  static const _beigeDeep = Color(0xFFEDE5D6);
  static const _textDark = Color(0xFF2C2C2A);
  static const _textGray = Color(0xFF5F5E5A);
  static const _textMuted = Color(0xFFBFB5A0);
  static const _danger = Color(0xFFA32D2D);
  static const _dangerLight = Color(0xFFFCEBEB);
  static const _dangerBorde = Color(0xFFF5C6C6);
  static const _success = Color(0xFF3B6D11);
  static const _successLight = Color(0xFFEAF3DE);
  static const _successBorde = Color(0xFFC2DFA8);
  static const _warningLight = Color(0xFFFAEEDA);
  static const _warningBorde = Color(0xFFFFD9BE);
  static const _warning = Color(0xFF633806);

  DateTimeRange _rango = DateTimeRange(
    start: DateTime.now().subtract(const Duration(days: 6)),
    end: DateTime.now(),
  );

  // Datos de ejemplo — luego vendrán del ViewModel
  final List<_InsumoConsumo> _insumos = [
    _InsumoConsumo(nombre: 'Harina', kg: 48, porcentaje: 0.90),
    _InsumoConsumo(nombre: 'Azúcar', kg: 32, porcentaje: 0.60),
    _InsumoConsumo(nombre: 'Mantequilla', kg: 20, porcentaje: 0.38),
    _InsumoConsumo(nombre: 'Levadura', kg: 12, porcentaje: 0.22),
  ];

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
            colorScheme: const ColorScheme.light(
              primary: _orange,
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: _textDark,
            ),
          ),
          child: child!,
        );
      },
    );
    if (resultado != null) {
      setState(() => _rango = resultado);
    }
  }

  Future<void> _exportarPDF() async {
    final pdf = pw.Document();
    pdf.addPage(
      pw.Page(
        pageFormat: PdfPageFormat.a4,
        build: (pw.Context context) {
          return pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(
                'Happy Oven — Reporte de Inventario',
                style: pw.TextStyle(
                  fontSize: 20,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 8),
              pw.Text(
                'Período: $_rangoFormateado',
                style: const pw.TextStyle(fontSize: 12),
              ),
              pw.SizedBox(height: 24),
              pw.Row(
                mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                children: [
                  _pdfKpi('Total entradas', '148 kg'),
                  _pdfKpi('Total salidas', '112 kg'),
                  _pdfKpi('Valor movido', 'S/ 3,420'),
                  _pdfKpi('Mermas', '18 kg'),
                ],
              ),
              pw.SizedBox(height: 24),
              pw.Text(
                'Insumos más consumidos',
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.SizedBox(height: 12),
              ..._insumos.map(
                (i) => pw.Padding(
                  padding: const pw.EdgeInsets.only(bottom: 8),
                  child: pw.Row(
                    mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
                    children: [
                      pw.Text(
                        i.nombre,
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                      pw.Text(
                        '${i.kg} kg',
                        style: const pw.TextStyle(fontSize: 12),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          );
        },
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
      name: 'reporte_happy_oven.pdf',
    );
  }

  pw.Widget _pdfKpi(String label, String valor) {
    return pw.Column(
      crossAxisAlignment: pw.CrossAxisAlignment.start,
      children: [
        pw.Text(
          valor,
          style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold),
        ),
        pw.Text(label, style: const pw.TextStyle(fontSize: 10)),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _beige,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildBody()),
          _buildBottomNav(),
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
          padding: const EdgeInsets.fromLTRB(20, 16, 20, 20),
          child: Column(
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Reportes',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Genera y exporta tu resumen',
                        style: TextStyle(fontSize: 12, color: _oliveDark),
                      ),
                    ],
                  ),
                  // Botón exportar PDF
                  GestureDetector(
                    onTap: _exportarPDF,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: _orange,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          const Icon(
                            Icons.picture_as_pdf_outlined,
                            color: Colors.white,
                            size: 16,
                          ),
                          const SizedBox(width: 6),
                          const Text(
                            'Exportar',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: Colors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),
              // Selector de rango
              GestureDetector(
                onTap: _seleccionarRango,
                child: Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 12,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            color: _brownMid,
                            size: 16,
                          ),
                          const SizedBox(width: 10),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Rango seleccionado',
                                style: TextStyle(
                                  fontSize: 10,
                                  color: _textMuted,
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                _rangoFormateado,
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                  color: _textDark,
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      Icon(
                        Icons.keyboard_arrow_down_rounded,
                        color: _brownMid,
                        size: 20,
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

  // ── Cuerpo
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
          padding: const EdgeInsets.fromLTRB(14, 20, 14, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildKpiGrid(),
              const SizedBox(height: 16),
              _buildInsumosConsumo(),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  // ── KPI grid
  Widget _buildKpiGrid() {
    return GridView.count(
      crossAxisCount: 2,
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      crossAxisSpacing: 10,
      mainAxisSpacing: 10,
      childAspectRatio: 1.4,
      children: [
        _buildKpiCard(
          icono: Icons.arrow_circle_down_outlined,
          valor: '148 kg',
          etiqueta: 'Total entradas',
          colorFondo: _successLight,
          colorBorde: _successBorde,
          colorIcono: _success,
        ),
        _buildKpiCard(
          icono: Icons.arrow_circle_up_outlined,
          valor: '112 kg',
          etiqueta: 'Total salidas',
          colorFondo: _dangerLight,
          colorBorde: _dangerBorde,
          colorIcono: _danger,
        ),
        _buildKpiCard(
          icono: Icons.monetization_on_outlined,
          valor: 'S/ 3,420',
          etiqueta: 'Valor movido',
          colorFondo: _orangeLight,
          colorBorde: _orangeBorde,
          colorIcono: _orange,
        ),
        _buildKpiCard(
          icono: Icons.delete_outline_rounded,
          valor: '18 kg',
          etiqueta: 'Mermas del período',
          colorFondo: _dangerLight,
          colorBorde: _dangerBorde,
          colorIcono: _danger,
        ),
      ],
    );
  }

  Widget _buildKpiCard({
    required IconData icono,
    required String valor,
    required String etiqueta,
    required Color colorFondo,
    required Color colorBorde,
    required Color colorIcono,
  }) {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: colorFondo,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: colorBorde, width: 0.5),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icono, color: colorIcono, size: 20),
          const SizedBox(height: 8),
          Text(
            valor,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w500,
              color: colorIcono,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            etiqueta,
            style: TextStyle(
              fontSize: 11,
              color: colorIcono.withOpacity(0.8),
              height: 1.3,
            ),
          ),
        ],
      ),
    );
  }

  // ── Insumos más consumidos
  Widget _buildInsumosConsumo() {
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
          Text(
            'Insumos más consumidos',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w500,
              color: _textDark,
            ),
          ),
          const SizedBox(height: 16),
          ..._insumos.map((i) => _buildBarraInsumo(i)),
        ],
      ),
    );
  }

  Widget _buildBarraInsumo(_InsumoConsumo insumo) {
    final color = insumo.porcentaje >= 0.7 ? _orange : const Color(0xFFFFD9BE);
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
                '${insumo.kg} kg',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w500,
                  color: _textDark,
                ),
              ),
            ],
          ),
          const SizedBox(height: 6),
          ClipRRect(
            borderRadius: BorderRadius.circular(999),
            child: LinearProgressIndicator(
              value: insumo.porcentaje,
              minHeight: 6,
              backgroundColor: _beige,
              valueColor: AlwaysStoppedAnimation<Color>(color),
            ),
          ),
        ],
      ),
    );
  }

  // ── Bottom navigation
  Widget _buildBottomNav() {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        border: Border(top: BorderSide(color: _beigeDeep, width: 0.5)),
      ),
      child: SafeArea(
        top: false,
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: [
              _buildNavItem(Icons.bar_chart_rounded, 'Dashboard', false),
              _buildNavItem(Icons.inventory_2_outlined, 'Inventario', false),
              _buildNavItem(Icons.menu_book_outlined, 'Recetas', false),
              _buildNavItem(Icons.swap_horiz_rounded, 'Movimientos', false),
              _buildNavItem(Icons.notifications_outlined, 'Alertas', false),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildNavItem(IconData icono, String etiqueta, bool activo) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        activo
            ? Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: _orange,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(icono, color: Colors.white, size: 18),
              )
            : Icon(icono, color: _textMuted, size: 24),
        const SizedBox(height: 3),
        Text(
          etiqueta,
          style: TextStyle(
            fontSize: 10,
            fontWeight: activo ? FontWeight.w500 : FontWeight.normal,
            color: activo ? _orange : _textMuted,
          ),
        ),
      ],
    );
  }

  // Color extra para el ícono del calendario
  static const _brownMid = Color(0xFFA8714A);
}

// ── Modelos locales temporales
class _InsumoConsumo {
  final String nombre;
  final int kg;
  final double porcentaje;

  const _InsumoConsumo({
    required this.nombre,
    required this.kg,
    required this.porcentaje,
  });
}
