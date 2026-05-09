import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/widgets/bottom_nav_bar.dart';

class RecetarioView extends StatefulWidget {
  const RecetarioView({super.key});

  @override
  State<RecetarioView> createState() => _RecetarioViewState();
}

class _RecetarioViewState extends State<RecetarioView> {
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  final List<_Receta> _recetas = [
    _Receta(nombre: 'Pan Francés', ingredientes: 5, costoLote: 12.40, tiempoMin: 45,
        rentabilidad: _Rentabilidad.rentable, icono: Icons.breakfast_dining_outlined),
    _Receta(nombre: 'Torta Tres Leches', ingredientes: 9, costoLote: 48.20, tiempoMin: 120,
        rentabilidad: _Rentabilidad.enRiesgo, icono: Icons.cake_outlined),
    _Receta(nombre: 'Croissant', ingredientes: 7, costoLote: 28.60, tiempoMin: 90,
        rentabilidad: _Rentabilidad.rentable, icono: Icons.breakfast_dining_outlined),
    _Receta(nombre: 'Pan de Yema', ingredientes: 6, costoLote: 18.90, tiempoMin: 60,
        rentabilidad: _Rentabilidad.revisar, icono: Icons.breakfast_dining_outlined),
    _Receta(nombre: 'Bizcocho', ingredientes: 8, costoLote: 22.50, tiempoMin: 75,
        rentabilidad: _Rentabilidad.rentable, icono: Icons.cake_outlined),
    _Receta(nombre: 'Pan Ciabatta', ingredientes: 5, costoLote: 15.80, tiempoMin: 110,
        rentabilidad: _Rentabilidad.revisar, icono: Icons.breakfast_dining_outlined),
  ];

  List<_Receta> get _recetasFiltradas =>
      _recetas.where((r) => r.nombre.toLowerCase().contains(_query.toLowerCase())).toList();

  String _formatTiempo(int minutos) {
    if (minutos < 60) return '$minutos min';
    final h = minutos ~/ 60;
    final m = minutos % 60;
    return m == 0 ? '$h hr' : '$h hr $m min';
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(() => setState(() => _query = _searchController.text));
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final rutaActual = GoRouterState.of(context).uri.path;
    return Scaffold(
      backgroundColor: AppTheme.colors.bg,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildGrid()),
          BottomNavBar(rutaActual: rutaActual),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      color: AppTheme.colors.accent,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Recetario', style: AppTheme.font.h3),
                      const SizedBox(height: 2),
                      Text('${_recetas.length} recetas registradas',
                          style: AppTheme.font.caption.copyWith(color: AppTheme.colors.accentDark)),
                    ],
                  ),
                  GestureDetector(
                    onTap: () {
                      // TODO: navegar a costeo_dinamico_view (nueva receta)
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                      decoration: BoxDecoration(
                        color: AppTheme.colors.titleText,
                        borderRadius: AppTheme.radius.brSm,
                      ),
                      child: Row(children: [
                        Icon(Icons.add_rounded, color: AppTheme.colors.accent, size: 16),
                        const SizedBox(width: 6),
                        Text('Nueva', style: AppTheme.font.label.copyWith(
                          color: AppTheme.colors.accent, fontSize: 13)),
                      ]),
                    ),
                  ),
                ],
              ),
            ),
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: AppTheme.colors.card,
                  borderRadius: AppTheme.radius.brSm,
                ),
                child: TextField(
                  controller: _searchController,
                  style: AppTheme.font.bodySmall.copyWith(fontSize: 13, color: AppTheme.colors.titleText),
                  decoration: InputDecoration(
                    hintText: 'Buscar receta...',
                    hintStyle: AppTheme.font.hint.copyWith(fontSize: 13),
                    prefixIcon: Icon(Icons.search_rounded, color: AppTheme.colors.hint, size: 18),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildGrid() {
    final recetas = _recetasFiltradas;
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
        child: recetas.isEmpty
            ? Center(child: Text('Sin resultados', style: AppTheme.font.hint.copyWith(fontSize: 13)))
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2, crossAxisSpacing: 10, mainAxisSpacing: 10, childAspectRatio: 0.82),
                itemCount: recetas.length,
                itemBuilder: (context, index) => _buildTarjeta(recetas[index]),
              ),
      ),
    );
  }

  Widget _buildTarjeta(_Receta receta) {
    final config = _configPorRentabilidad(receta.rentabilidad);
    return GestureDetector(
      onTap: () {
        // TODO: navegar a costeo_dinamico_view con receta seleccionada
      },
      child: Container(
        decoration: BoxDecoration(
          color: AppTheme.colors.card,
          borderRadius: BorderRadius.circular(AppTheme.radius.lg),
          border: Border.all(color: AppTheme.colors.border, width: 0.5),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              height: 90, width: double.infinity,
              color: AppTheme.colors.primaryLight,
              child: Stack(children: [
                Center(child: Icon(receta.icono, color: AppTheme.colors.brownLight, size: 42)),
                Positioned(top: 8, right: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 3),
                    decoration: BoxDecoration(
                      color: config.colorFondo,
                      borderRadius: BorderRadius.circular(6),
                      border: Border.all(color: config.colorBorde, width: 0.5),
                    ),
                    child: Text(config.etiqueta, style: AppTheme.font.caption.copyWith(
                      fontSize: 9, fontWeight: FontWeight.w500, color: config.colorTexto)),
                  ),
                ),
              ]),
            ),
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(receta.nombre, style: AppTheme.font.label.copyWith(fontSize: 12),
                      maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 6),
                  _buildInfoRow(Icons.format_list_bulleted_rounded, '${receta.ingredientes} ingredientes'),
                  const SizedBox(height: 3),
                  _buildInfoRow(Icons.monetization_on_outlined, 'S/ ${receta.costoLote.toStringAsFixed(2)} / lote'),
                  const SizedBox(height: 3),
                  _buildInfoRow(Icons.schedule_outlined, _formatTiempo(receta.tiempoMin)),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icono, String texto) {
    return Row(children: [
      Icon(icono, color: AppTheme.colors.hint, size: 11),
      const SizedBox(width: 4),
      Expanded(child: Text(texto, style: AppTheme.font.caption,
          maxLines: 1, overflow: TextOverflow.ellipsis)),
    ]);
  }

  _ConfigRentabilidad _configPorRentabilidad(_Rentabilidad r) {
    switch (r) {
      case _Rentabilidad.rentable:
        return _ConfigRentabilidad(etiqueta: 'Rentable', colorFondo: AppTheme.colors.successLight,
            colorBorde: AppTheme.colors.successBorder, colorTexto: AppTheme.colors.statusNormal);
      case _Rentabilidad.enRiesgo:
        return _ConfigRentabilidad(etiqueta: 'En riesgo', colorFondo: AppTheme.colors.dangerLight,
            colorBorde: AppTheme.colors.dangerBorder, colorTexto: AppTheme.colors.statusCritical);
      case _Rentabilidad.revisar:
        return _ConfigRentabilidad(etiqueta: 'Revisar', colorFondo: AppTheme.colors.primaryLight,
            colorBorde: AppTheme.colors.primaryBorder, colorTexto: AppTheme.colors.primary);
    }
  }
}

enum _Rentabilidad { rentable, enRiesgo, revisar }

class _Receta {
  final String nombre; final int ingredientes; final double costoLote;
  final int tiempoMin; final _Rentabilidad rentabilidad; final IconData icono;
  const _Receta({required this.nombre, required this.ingredientes, required this.costoLote,
    required this.tiempoMin, required this.rentabilidad, required this.icono});
}

class _ConfigRentabilidad {
  final String etiqueta; final Color colorFondo; final Color colorBorde; final Color colorTexto;
  const _ConfigRentabilidad({required this.etiqueta, required this.colorFondo,
    required this.colorBorde, required this.colorTexto});
}
