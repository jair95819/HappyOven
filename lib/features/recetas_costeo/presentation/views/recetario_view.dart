import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/core/widgets/bottom_nav_bar.dart';

class RecetarioView extends StatefulWidget {
  const RecetarioView({super.key});

  @override
  State<RecetarioView> createState() => _RecetarioViewState();
}

class _RecetarioViewState extends State<RecetarioView> {
  static const _olive = Color(0xFFC8CA9E);
  static const _oliveDark = Color(0xFF4A4A38);
  static const _orange = Color(0xFFFF8C42);
  static const _orangeLight = Color(0xFFFFF3EB);
  static const _orangeBorde = Color(0xFFFFD9BE);
  static const _beige = Color(0xFFF5F0E8);
  static const _beigeDeep = Color(0xFFEDE5D6);
  static const _textDark = Color(0xFF2C2C2A);
  static const _textMuted = Color(0xFFBFB5A0);
  static const _danger = Color(0xFFA32D2D);
  static const _dangerLight = Color(0xFFFCEBEB);
  static const _success = Color(0xFF3B6D11);
  static const _successLight = Color(0xFFEAF3DE);
  static const _brownLight = Color(0xFFD4A47A);

  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // Datos de ejemplo — luego vendrán del ViewModel
  final List<_Receta> _recetas = [
    _Receta(
      nombre: 'Pan Francés',
      ingredientes: 5,
      costoLote: 12.40,
      tiempoMin: 45,
      rentabilidad: _Rentabilidad.rentable,
      icono: Icons.breakfast_dining_outlined,
    ),
    _Receta(
      nombre: 'Torta Tres Leches',
      ingredientes: 9,
      costoLote: 48.20,
      tiempoMin: 120,
      rentabilidad: _Rentabilidad.enRiesgo,
      icono: Icons.cake_outlined,
    ),
    _Receta(
      nombre: 'Croissant',
      ingredientes: 7,
      costoLote: 28.60,
      tiempoMin: 90,
      rentabilidad: _Rentabilidad.rentable,
      icono: Icons.breakfast_dining_outlined,
    ),
    _Receta(
      nombre: 'Pan de Yema',
      ingredientes: 6,
      costoLote: 18.90,
      tiempoMin: 60,
      rentabilidad: _Rentabilidad.revisar,
      icono: Icons.breakfast_dining_outlined,
    ),
    _Receta(
      nombre: 'Bizcocho',
      ingredientes: 8,
      costoLote: 22.50,
      tiempoMin: 75,
      rentabilidad: _Rentabilidad.rentable,
      icono: Icons.cake_outlined,
    ),
    _Receta(
      nombre: 'Pan Ciabatta',
      ingredientes: 5,
      costoLote: 15.80,
      tiempoMin: 110,
      rentabilidad: _Rentabilidad.revisar,
      icono: Icons.breakfast_dining_outlined,
    ),
  ];

  List<_Receta> get _recetasFiltradas => _recetas
      .where((r) => r.nombre.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  String _formatTiempo(int minutos) {
    if (minutos < 60) return '$minutos min';
    final h = minutos ~/ 60;
    final m = minutos % 60;
    return m == 0 ? '$h hr' : '$h hr $m min';
  }

  @override
  void initState() {
    super.initState();
    _searchController.addListener(
      () => setState(() => _query = _searchController.text),
    );
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
      backgroundColor: _beige,
      body: Column(
        children: [
          _buildHeader(),
          Expanded(child: _buildGrid()),
          BottomNavBar(rutaActual: rutaActual),
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
                      Text(
                        'Recetario',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${_recetas.length} recetas registradas',
                        style: TextStyle(fontSize: 12, color: _oliveDark),
                      ),
                    ],
                  ),
                  // Botón nueva receta
                  GestureDetector(
                    onTap: () {
                      // TODO: navegar a costeo_dinamico_view (nueva receta)
                    },
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 9,
                      ),
                      decoration: BoxDecoration(
                        color: _textDark,
                        borderRadius: BorderRadius.circular(10),
                      ),
                      child: Row(
                        children: [
                          Icon(Icons.add_rounded, color: _olive, size: 16),
                          const SizedBox(width: 6),
                          Text(
                            'Nueva',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w500,
                              color: _olive,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Buscador
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 0, 20, 16),
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: TextField(
                  controller: _searchController,
                  style: TextStyle(fontSize: 13, color: _textDark),
                  decoration: InputDecoration(
                    hintText: 'Buscar receta...',
                    hintStyle: TextStyle(fontSize: 13, color: _textMuted),
                    prefixIcon: Icon(
                      Icons.search_rounded,
                      color: _textMuted,
                      size: 18,
                    ),
                    border: InputBorder.none,
                    contentPadding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 12,
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Grid
  Widget _buildGrid() {
    final recetas = _recetasFiltradas;
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
        child: recetas.isEmpty
            ? Center(
                child: Text(
                  'Sin resultados',
                  style: TextStyle(fontSize: 13, color: _textMuted),
                ),
              )
            : GridView.builder(
                padding: const EdgeInsets.fromLTRB(12, 20, 12, 8),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 2,
                  crossAxisSpacing: 10,
                  mainAxisSpacing: 10,
                  childAspectRatio: 0.82,
                ),
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
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: _beigeDeep, width: 0.5),
        ),
        clipBehavior: Clip.hardEdge,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Imagen / ícono
            Container(
              height: 90,
              width: double.infinity,
              color: _orangeLight,
              child: Stack(
                children: [
                  Center(
                    child: Icon(receta.icono, color: _brownLight, size: 42),
                  ),
                  // Badge rentabilidad
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 7,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: config.colorFondo,
                        borderRadius: BorderRadius.circular(6),
                        border: Border.all(
                          color: config.colorBorde,
                          width: 0.5,
                        ),
                      ),
                      child: Text(
                        config.etiqueta,
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w500,
                          color: config.colorTexto,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Info
            Padding(
              padding: const EdgeInsets.all(10),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    receta.nombre,
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w500,
                      color: _textDark,
                    ),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 6),
                  _buildInfoRow(
                    Icons.format_list_bulleted_rounded,
                    '${receta.ingredientes} ingredientes',
                  ),
                  const SizedBox(height: 3),
                  _buildInfoRow(
                    Icons.monetization_on_outlined,
                    'S/ ${receta.costoLote.toStringAsFixed(2)} / lote',
                  ),
                  const SizedBox(height: 3),
                  _buildInfoRow(
                    Icons.schedule_outlined,
                    _formatTiempo(receta.tiempoMin),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icono, String texto) {
    return Row(
      children: [
        Icon(icono, color: _textMuted, size: 11),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            texto,
            style: TextStyle(fontSize: 10, color: _textMuted),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }

  _ConfigRentabilidad _configPorRentabilidad(_Rentabilidad r) {
    switch (r) {
      case _Rentabilidad.rentable:
        return _ConfigRentabilidad(
          etiqueta: 'Rentable',
          colorFondo: _successLight,
          colorBorde: const Color(0xFFC2DFA8),
          colorTexto: _success,
        );
      case _Rentabilidad.enRiesgo:
        return _ConfigRentabilidad(
          etiqueta: 'En riesgo',
          colorFondo: _dangerLight,
          colorBorde: const Color(0xFFF5C6C6),
          colorTexto: _danger,
        );
      case _Rentabilidad.revisar:
        return _ConfigRentabilidad(
          etiqueta: 'Revisar',
          colorFondo: _orangeLight,
          colorBorde: _orangeBorde,
          colorTexto: _orange,
        );
    }
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
              _buildNavItem(Icons.menu_book_outlined, 'Recetas', true),
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
}

// ── Modelos locales temporales
enum _Rentabilidad { rentable, enRiesgo, revisar }

class _Receta {
  final String nombre;
  final int ingredientes;
  final double costoLote;
  final int tiempoMin;
  final _Rentabilidad rentabilidad;
  final IconData icono;

  const _Receta({
    required this.nombre,
    required this.ingredientes,
    required this.costoLote,
    required this.tiempoMin,
    required this.rentabilidad,
    required this.icono,
  });
}

class _ConfigRentabilidad {
  final String etiqueta;
  final Color colorFondo;
  final Color colorBorde;
  final Color colorTexto;

  const _ConfigRentabilidad({
    required this.etiqueta,
    required this.colorFondo,
    required this.colorBorde,
    required this.colorTexto,
  });
}
