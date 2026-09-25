import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/core/demo/diseno_demo.dart';
import 'package:happy_oven/core/models/receta.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/widgets/ho_ui.dart';
import 'package:happy_oven/features/recetas_costeo/presentation/viewmodels/recetas_viewmodel.dart';
import 'package:happy_oven/features/recetas_costeo/presentation/views/widgets/receta_widgets.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/viewmodels/catalogo_viewmodel.dart';

/// Detalle de receta (diseño "Ver receta").
class VerRecetaView extends ConsumerStatefulWidget {
  final Receta receta;

  const VerRecetaView({super.key, required this.receta});

  @override
  ConsumerState<VerRecetaView> createState() => _VerRecetaViewState();
}

class _VerRecetaViewState extends ConsumerState<VerRecetaView> {
  bool _verMas = false;

  @override
  Widget build(BuildContext context) {
    final c = AppTheme.colorsOf(context);
    final receta = widget.receta;
    final articulos = ref.watch(catalogoViewModelProvider).valueOrNull ?? [];
    final ingredientes =
        ref.watch(ingredientesRecetaProvider(receta.id)).valueOrNull ?? [];
    final producto = articuloPorId(articulos, receta.productoId);
    final total = ingredientes.isEmpty
        ? receta.costoLote
        : costoLote(ingredientes, articulos);
    final unitario = receta.rendimiento > 0 ? total / receta.rendimiento : 0.0;
    final precioVenta = producto?.precioUnitario ?? 0;
    final margen = precioVenta > 0
        ? (precioVenta - unitario) / precioVenta * 100
        : null;
    final unidad = producto?.unidad.dbValue ?? 'unidades';

    return Scaffold(
      backgroundColor: c.bg,
      body: SingleChildScrollView(
        padding: const EdgeInsets.only(bottom: 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Foto principal con botones flotantes y badge de margen
            SizedBox(
              height: 280,
              child: Stack(
                fit: StackFit.expand,
                children: [
                  HoPhoto(
                    photoId: fotoReceta(receta, producto),
                    px: 600,
                  ),
                  const DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.bottomCenter,
                        end: Alignment.topCenter,
                        colors: [
                          Color(0x99000000),
                          Colors.transparent,
                          Color(0x4D000000),
                        ],
                      ),
                    ),
                  ),
                  SafeArea(
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
                      child: Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          _botonFlotante(
                            Icons.chevron_left_rounded,
                            c.titleText,
                            () => context.pop(),
                          ),
                          const Spacer(),
                          _botonFlotante(
                            Icons.edit_outlined,
                            c.primary,
                            () => context.push(
                              '/recetas/gestionar',
                              extra: receta,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  Positioned(
                    left: 16,
                    bottom: 40,
                    child: Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 14,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: c.primary,
                        borderRadius: BorderRadius.circular(999),
                        boxShadow: AppTheme.shadows.cardMd,
                      ),
                      child: Text(
                        '%  ${margen != null ? margen.toStringAsFixed(1) : '--'}% MARGEN',
                        style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.4,
                          color: Colors.white,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            // Tarjeta de detalle superpuesta
            Transform.translate(
              offset: const Offset(0, -24),
              child: Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: c.card,
                  borderRadius: const BorderRadius.vertical(
                    top: Radius.circular(30),
                  ),
                  border: Border.all(color: c.border),
                  boxShadow: AppTheme.shadows.cardMd,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                receta.nombre,
                                style: AppTheme.serif(
                                  TextStyle(
                                    fontSize: 22,
                                    height: 1.2,
                                    fontWeight: FontWeight.w800,
                                    color: c.titleText,
                                  ),
                                ),
                              ),
                              const SizedBox(height: 2),
                              Text(
                                '📍 Panadería Happy Oven · Producción artesanal',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: c.bodyText,
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(width: 8),
                        Column(
                          crossAxisAlignment: CrossAxisAlignment.end,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  TextSpan(
                                    text: '★ ',
                                    style: TextStyle(color: c.statusLow),
                                  ),
                                  const TextSpan(text: DisenoDemo.valoracion),
                                  TextSpan(
                                    text: ' ${DisenoDemo.lotes}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w400,
                                      color: c.bodyText,
                                    ),
                                  ),
                                ],
                              ),
                              style: TextStyle(
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                                color: c.titleText,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              'S/ ${unitario.toStringAsFixed(2)} / unidad',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w700,
                                color: c.statusNormal,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    // Valores nutricionales
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: c.bg,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(color: c.border),
                      ),
                      child: Row(
                        children: [
                          for (final (valor, etiqueta) in DisenoDemo.nutricion)
                            Expanded(
                              child: Column(
                                children: [
                                  Text(
                                    valor,
                                    style: TextStyle(
                                      fontSize: 15,
                                      fontWeight: FontWeight.w800,
                                      color: c.titleText,
                                    ),
                                  ),
                                  Text(
                                    etiqueta,
                                    style: TextStyle(
                                      fontSize: 10,
                                      fontWeight: FontWeight.w500,
                                      color: c.bodyText,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Descripción',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: c.titleText,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text.rich(
                      TextSpan(
                        text: (receta.instrucciones?.trim().isNotEmpty ?? false)
                            ? receta.instrucciones!.trim()
                            : DisenoDemo.descripcion,
                        children: [
                          if (_verMas)
                            const TextSpan(text: DisenoDemo.descripcionExtra),
                          WidgetSpan(
                            alignment: PlaceholderAlignment.baseline,
                            baseline: TextBaseline.alphabetic,
                            child: GestureDetector(
                              onTap: () => setState(() => _verMas = !_verMas),
                              child: Text(
                                _verMas ? ' Ver menos' : ' ...Ver más',
                                style: TextStyle(
                                  fontSize: 13,
                                  fontWeight: FontWeight.w700,
                                  color: c.primary,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ),
                      style: TextStyle(
                        fontSize: 13,
                        height: 1.5,
                        color: c.bodyText,
                      ),
                    ),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: _chip(
                            c,
                            'RENDIMIENTO',
                            '${fmtNum(receta.rendimiento)} $unidad / lote',
                            c.titleText,
                          ),
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: _chip(
                            c,
                            'COSTO TOTAL RECETA',
                            'S/ ${total.toStringAsFixed(2)}',
                            c.primary,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    IngredienteTable(
                      ingredientes: ingredientes,
                      articulos: articulos,
                    ),
                    const SizedBox(height: 20),
                    Row(
                      children: [
                        Material(
                          color: c.card,
                          shape: CircleBorder(side: BorderSide(color: c.border)),
                          child: InkWell(
                            customBorder: const CircleBorder(),
                            onTap: () =>
                                context.push('/recetas/costos', extra: receta),
                            child: SizedBox(
                              width: 48,
                              height: 48,
                              child: Icon(
                                Icons.attach_money_rounded,
                                color: c.primary,
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: HoPrimaryButton(
                            label: 'Preparar Lote / Producir',
                            pill: true,
                            onPressed: () => context.push(
                              '/produccion/nueva',
                              extra: receta,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _botonFlotante(IconData icon, Color color, VoidCallback onTap) {
    return Material(
      color: Colors.white.withValues(alpha: 0.9),
      shape: const CircleBorder(),
      elevation: 3,
      child: InkWell(
        customBorder: const CircleBorder(),
        onTap: onTap,
        child: SizedBox(
          width: 40,
          height: 40,
          child: Icon(icon, color: color, size: 20),
        ),
      ),
    );
  }

  Widget _chip(AppColors c, String label, String value, Color color) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: c.bg,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: c.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              letterSpacing: 0.6,
              fontWeight: FontWeight.w500,
              color: c.bodyText,
            ),
          ),
          const SizedBox(height: 2),
          Text(
            value,
            style: TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w800,
              color: color,
            ),
          ),
        ],
      ),
    );
  }
}
