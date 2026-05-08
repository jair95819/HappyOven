import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/core/widgets/bottom_nav_bar.dart';

class CatalogoGeneralView extends StatefulWidget {
  const CatalogoGeneralView({super.key});

  @override
  State<CatalogoGeneralView> createState() => _CatalogoGeneralViewState();
}

class _CatalogoGeneralViewState extends State<CatalogoGeneralView>
    with SingleTickerProviderStateMixin {
  static const _olive = Color(0xFFC8CA9E);
  static const _oliveDark = Color(0xFF4A4A38);
  static const _orange = Color(0xFFFF8C42);
  static const _beige = Color(0xFFF5F0E8);
  static const _beigeDeep = Color(0xFFEDE5D6);
  static const _textDark = Color(0xFF2C2C2A);
  static const _textMuted = Color(0xFFBFB5A0);
  static const _danger = Color(0xFFA32D2D);
  static const _dangerLight = Color(0xFFFCEBEB);
  static const _success = Color(0xFF3B6D11);
  static const _successLight = Color(0xFFEAF3DE);
  static const _orangeLight = Color(0xFFFFF3EB);

  late TabController _tabController;
  final TextEditingController _searchController = TextEditingController();
  String _query = '';

  // Datos de ejemplo — luego vendrán del ViewModel
  final List<_Articulo> _insumos = [
    _Articulo(
      nombre: 'Harina',
      stockActual: 8,
      stockMinimo: 20,
      unidad: 'kg',
      icono: Icons.grain_rounded,
    ),
    _Articulo(
      nombre: 'Azúcar',
      stockActual: 15,
      stockMinimo: 25,
      unidad: 'kg',
      icono: Icons.store_outlined,
    ),
    _Articulo(
      nombre: 'Aceite',
      stockActual: 12,
      stockMinimo: 5,
      unidad: 'litros',
      icono: Icons.water_drop_outlined,
    ),
    _Articulo(
      nombre: 'Mantequilla',
      stockActual: 30,
      stockMinimo: 10,
      unidad: 'kg',
      icono: Icons.egg_outlined,
    ),
    _Articulo(
      nombre: 'Levadura',
      stockActual: 2,
      stockMinimo: 8,
      unidad: 'kg',
      icono: Icons.bubble_chart_outlined,
    ),
  ];

  final List<_Articulo> _productosFinal = [
    _Articulo(
      nombre: 'Pan Francés',
      stockActual: 120,
      stockMinimo: 50,
      unidad: 'unid.',
      icono: Icons.breakfast_dining_outlined,
    ),
    _Articulo(
      nombre: 'Torta Tres Leches',
      stockActual: 4,
      stockMinimo: 5,
      unidad: 'unid.',
      icono: Icons.cake_outlined,
    ),
    _Articulo(
      nombre: 'Croissant',
      stockActual: 35,
      stockMinimo: 20,
      unidad: 'unid.',
      icono: Icons.breakfast_dining_outlined,
    ),
    _Articulo(
      nombre: 'Pan de Yema',
      stockActual: 8,
      stockMinimo: 30,
      unidad: 'unid.',
      icono: Icons.breakfast_dining_outlined,
    ),
  ];

  List<_Articulo> get _insumosFiltrados => _insumos
      .where((a) => a.nombre.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  List<_Articulo> get _productosFiltrados => _productosFinal
      .where((a) => a.nombre.toLowerCase().contains(_query.toLowerCase()))
      .toList();

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _searchController.addListener(
      () => setState(() => _query = _searchController.text),
    );
  }

  @override
  void dispose() {
    _tabController.dispose();
    _searchController.dispose();
    super.dispose();
  }

  _EstadoStock _estadoDeArticulo(_Articulo a) {
    final ratio = a.stockActual / a.stockMinimo;
    if (ratio <= 0.5) return _EstadoStock.critico;
    if (ratio <= 1.0) return _EstadoStock.bajo;
    return _EstadoStock.normal;
  }

  @override
  Widget build(BuildContext context) {
    final rutaActual = GoRouterState.of(context).uri.path;
    return Scaffold(
      backgroundColor: _beige,
      body: Column(
        children: [
          _buildHeader(context),
          Expanded(child: _buildBody()),
          BottomNavBar(rutaActual: rutaActual),
        ],
      ),
    );
  }

  // ── Header oliva
  Widget _buildHeader(BuildContext context) {
    return Container(
      color: _olive,
      child: SafeArea(
        bottom: false,
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Catálogo',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.w500,
                          color: _textDark,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Maestro de artículos',
                        style: TextStyle(fontSize: 12, color: _oliveDark),
                      ),
                    ],
                  ),
                  // Botón nuevo
                  GestureDetector(
                    onTap: () => context.go('/catalogo/nuevo'),
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
                            'Nuevo',
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
                    hintText: 'Buscar artículo...',
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

            // Tabs
            TabBar(
              controller: _tabController,
              labelColor: _textDark,
              unselectedLabelColor: _textMuted,
              labelStyle: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
              ),
              unselectedLabelStyle: const TextStyle(fontSize: 13),
              indicatorColor: _textDark,
              indicatorWeight: 2.5,
              dividerColor: _textMuted.withOpacity(0.3),
              tabs: const [
                Tab(text: 'Insumos'),
                Tab(text: 'Productos finales'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ── Cuerpo con tabs
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
        child: TabBarView(
          controller: _tabController,
          children: [
            _buildLista(_insumosFiltrados),
            _buildLista(_productosFiltrados),
          ],
        ),
      ),
    );
  }

  Widget _buildLista(List<_Articulo> articulos) {
    if (articulos.isEmpty) {
      return Center(
        child: Text(
          'Sin resultados',
          style: TextStyle(fontSize: 13, color: _textMuted),
        ),
      );
    }
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(14, 20, 14, 8),
      itemCount: articulos.length,
      separatorBuilder: (_, __) => const SizedBox(height: 10),
      itemBuilder: (context, index) => _buildTarjetaArticulo(articulos[index]),
    );
  }

  Widget _buildTarjetaArticulo(_Articulo articulo) {
    final estado = _estadoDeArticulo(articulo);
    final config = _configPorEstado(estado);
    final ratio = (articulo.stockActual / articulo.stockMinimo).clamp(0.0, 1.0);

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _beigeDeep, width: 0.5),
      ),
      child: Row(
        children: [
          // Ícono
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: config.colorFondo,
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(articulo.icono, color: config.colorPrincipal, size: 22),
          ),
          const SizedBox(width: 12),
          // Info
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      articulo.nombre,
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w500,
                        color: _textDark,
                      ),
                    ),
                    // Badge estado
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 3,
                      ),
                      decoration: BoxDecoration(
                        color: config.colorFondo,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Text(
                        config.etiqueta,
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w500,
                          color: config.colorPrincipal,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    RichText(
                      text: TextSpan(
                        style: TextStyle(fontSize: 11, color: _textMuted),
                        children: [
                          const TextSpan(text: 'Stock: '),
                          TextSpan(
                            text: '${articulo.stockActual} ${articulo.unidad}',
                            style: TextStyle(
                              color: config.colorPrincipal,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                          TextSpan(
                            text:
                                ' / mín. ${articulo.stockMinimo} ${articulo.unidad}',
                          ),
                        ],
                      ),
                    ),
                    Text(
                      articulo.unidad,
                      style: TextStyle(fontSize: 11, color: _textMuted),
                    ),
                  ],
                ),
                const SizedBox(height: 6),
                // Barra de progreso
                ClipRRect(
                  borderRadius: BorderRadius.circular(999),
                  child: LinearProgressIndicator(
                    value: ratio,
                    minHeight: 4,
                    backgroundColor: _beige,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      config.colorPrincipal,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  _ConfigEstado _configPorEstado(_EstadoStock estado) {
    switch (estado) {
      case _EstadoStock.critico:
        return _ConfigEstado(
          etiqueta: 'Crítico',
          colorPrincipal: _danger,
          colorFondo: _dangerLight,
        );
      case _EstadoStock.bajo:
        return _ConfigEstado(
          etiqueta: 'Bajo',
          colorPrincipal: _orange,
          colorFondo: _orangeLight,
        );
      case _EstadoStock.normal:
        return _ConfigEstado(
          etiqueta: 'Normal',
          colorPrincipal: _success,
          colorFondo: _successLight,
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
              _buildNavItem(Icons.inventory_2_outlined, 'Inventario', true),
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
}

// ── Modelos locales temporales
enum _EstadoStock { critico, bajo, normal }

class _Articulo {
  final String nombre;
  final double stockActual;
  final double stockMinimo;
  final String unidad;
  final IconData icono;

  const _Articulo({
    required this.nombre,
    required this.stockActual,
    required this.stockMinimo,
    required this.unidad,
    required this.icono,
  });
}

class _ConfigEstado {
  final String etiqueta;
  final Color colorPrincipal;
  final Color colorFondo;

  const _ConfigEstado({
    required this.etiqueta,
    required this.colorPrincipal,
    required this.colorFondo,
  });
}
