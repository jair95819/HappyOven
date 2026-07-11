import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/models/receta.dart';
import 'package:happy_oven/core/models/orden_produccion.dart';
import 'package:happy_oven/features/produccion/presentation/viewmodels/produccion_viewmodel.dart';
import 'package:happy_oven/features/recetas_costeo/presentation/viewmodels/recetas_viewmodel.dart';
import 'package:happy_oven/features/auth/presentation/viewmodels/auth_viewmodel.dart';

class NuevaOrdenProduccionView extends ConsumerStatefulWidget {
  final Receta? receta;

  const NuevaOrdenProduccionView({super.key, this.receta});

  @override
  ConsumerState<NuevaOrdenProduccionView> createState() => _NuevaOrdenProduccionViewState();
}

class _NuevaOrdenProduccionViewState extends ConsumerState<NuevaOrdenProduccionView> {
  Receta? _recetaSeleccionada;
  final _lotesController = TextEditingController(text: '1');
  final _notasController = TextEditingController();
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    if (widget.receta != null) {
      _recetaSeleccionada = widget.receta;
    }
  }

  @override
  void dispose() {
    _lotesController.dispose();
    _notasController.dispose();
    super.dispose();
  }

  Future<void> _guardar() async {
    if (_isSaving) return;
    if (_recetaSeleccionada == null) {
      _mostrarError('Selecciona una receta');
      return;
    }

    final lotes = int.tryParse(_lotesController.text);
    if (lotes == null || lotes <= 0) {
      _mostrarError('Ingresa una cantidad de lotes válida');
      return;
    }

    final authState = ref.read(authViewModelProvider);
    final usuarioId = authState.usuario?.id;
    if (usuarioId == null || usuarioId.isEmpty) {
      _mostrarError('No se detectó usuario autenticado. Inicia sesión nuevamente.');
      return;
    }

    setState(() => _isSaving = true);

    final orden = OrdenProduccion(
      id: '',
      recetaId: _recetaSeleccionada!.id,
      usuarioId: usuarioId,
      cantidadLotes: lotes,
      notas: _notasController.text.trim().isEmpty ? null : _notasController.text.trim(),
      createdAt: DateTime.now(),
      updatedAt: DateTime.now(),
    );

    final error = await ref.read(ordenesProduccionProvider.notifier).crearOrden(orden);

    if (error == null && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: const Text('Orden de producción creada'),
        backgroundColor: AppTheme.colorsOf(context).statusNormal,
        behavior: SnackBarBehavior.floating,
      ));
      context.pop();
    } else if (mounted) {
      _isSaving = false;
      _mostrarError(error ?? 'Error al crear orden');
    }
  }

  void _mostrarError(String msg) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(msg),
      backgroundColor: AppTheme.colorsOf(context).statusCritical,
    ));
  }

  void _seleccionarReceta() {
    final recetas = ref.read(recetasViewModelProvider).valueOrNull ?? [];
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(AppTheme.radius.xl))),
      builder: (_) => DraggableScrollableSheet(
        maxChildSize: 0.8,
        minChildSize: 0.3,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.fromLTRB(20, 20, 20, 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text('Seleccionar receta', style: font.h3.copyWith(fontSize: 15)),
              const SizedBox(height: 16),
              Expanded(
                child: ListView.builder(
                  controller: scrollController,
                  itemCount: recetas.length,
                  itemBuilder: (_, i) {
                    final r = recetas[i];
                    final seleccionada = _recetaSeleccionada?.id == r.id;
                    return ListTile(
                      leading: Icon(
                        Icons.menu_book_outlined,
                        color: seleccionada ? colors.primary : colors.hint,
                        size: 18,
                      ),
                      title: Text(r.nombre, style: font.bodySmall.copyWith(color: colors.titleText)),
                      subtitle: Text('Rinde: ${r.rendimiento.toInt()} unid.', style: font.caption),
                      trailing: seleccionada
                          ? Icon(Icons.check_circle_rounded, color: colors.statusNormal, size: 20)
                          : null,
                      onTap: () {
                        setState(() => _recetaSeleccionada = r);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);

    return Scaffold(
      backgroundColor: colors.bg,
      body: Column(
        children: [
          _buildHeader(colors, font),
          Expanded(
            child: Container(
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
                child: SingleChildScrollView(
                  padding: EdgeInsets.fromLTRB(AppTheme.spacing.md, 20, AppTheme.spacing.md, 20),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      _buildSectionTitle('Receta a producir', font),
                      SizedBox(height: AppTheme.spacing.md),
                      _buildSelectorReceta(colors, font),
                      SizedBox(height: AppTheme.spacing.lg),
                      _buildSectionTitle('Cantidad de lotes', font),
                      SizedBox(height: AppTheme.spacing.md),
                      _buildTextField(
                        controller: _lotesController,
                        label: 'Número de lotes',
                        icon: Icons.production_quantity_limits_outlined,
                        colors: colors,
                        font: font,
                      ),
                      if (_recetaSeleccionada != null) ...[
                        SizedBox(height: AppTheme.spacing.md),
                        Container(
                          padding: EdgeInsets.all(AppTheme.spacing.md),
                          decoration: BoxDecoration(
                            color: colors.primaryLight,
                            borderRadius: AppTheme.radius.brSm,
                            boxShadow: AppTheme.shadows.cardSm,
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.info_outline, size: 14, color: colors.primary),
                              SizedBox(width: AppTheme.spacing.sm),
                              Expanded(
                                child: Text(
                                  'Cada lote rinde ${_recetaSeleccionada!.rendimiento.toInt()} unidades. '
                                  'Total estimado: ${(_recetaSeleccionada!.rendimiento.toInt() * int.tryParse(_lotesController.text)!).toInt()} unidades.',
                                  style: font.caption.copyWith(fontSize: 11, color: colors.primaryDark),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],
                      SizedBox(height: AppTheme.spacing.lg),
                      _buildSectionTitle('Notas (opcional)', font),
                      SizedBox(height: AppTheme.spacing.md),
                      _buildTextField(
                        controller: _notasController,
                        label: 'Notas para la orden',
                        icon: Icons.description_outlined,
                        colors: colors,
                        font: font,
                        maxLines: 3,
                      ),
                      SizedBox(height: AppTheme.spacing.lg),
                      _buildBotonGuardar(colors, font),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildHeader(AppColors colors, AppFont font) {
    return Container(
      color: colors.accent,
      child: SafeArea(
        bottom: false,
        child: Padding(
          padding: EdgeInsets.fromLTRB(20, AppTheme.spacing.md, 20, AppTheme.spacing.md),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Nueva Orden', style: font.h3),
                  const SizedBox(height: 2),
                  Text('Programar producción', style: font.caption.copyWith(color: colors.accentDark)),
                ],
              ),
              GestureDetector(
                onTap: () => context.pop(),
                child: Container(
                  padding: EdgeInsets.all(AppTheme.spacing.sm),
                  decoration: BoxDecoration(
                    color: colors.titleText,
                    borderRadius: AppTheme.radius.brSm,
                    boxShadow: AppTheme.shadows.cardSm,
                  ),
                  child: Icon(Icons.close_rounded, color: colors.accent, size: 18),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String titulo, AppFont font) {
    return Text(titulo, style: font.label.copyWith(fontSize: 14, fontWeight: FontWeight.w600));
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    required AppColors colors,
    required AppFont font,
    int maxLines = 1,
  }) {
    return Container(
      decoration: BoxDecoration(
        color: colors.card,
        borderRadius: AppTheme.radius.brSm,
        border: Border.all(color: colors.border),
        boxShadow: AppTheme.shadows.cardSm,
      ),
      child: TextField(
        controller: controller,
        maxLines: maxLines,
        keyboardType: maxLines == 1 ? TextInputType.number : TextInputType.text,
        style: font.bodySmall.copyWith(fontSize: 13, color: colors.titleText),
        decoration: InputDecoration(
          hintText: label,
          hintStyle: font.hint.copyWith(fontSize: 13),
          prefixIcon: Icon(icon, color: colors.primary, size: 16),
          border: InputBorder.none,
          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        ),
      ),
    );
  }

  Widget _buildSelectorReceta(AppColors colors, AppFont font) {
    return GestureDetector(
      onTap: _seleccionarReceta,
      child: Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
        decoration: BoxDecoration(
          color: colors.card,
          borderRadius: AppTheme.radius.brSm,
          border: Border.all(color: colors.border),
          boxShadow: AppTheme.shadows.cardSm,
        ),
        child: Row(
          children: [
            Icon(
              _recetaSeleccionada != null ? Icons.menu_book_outlined : Icons.add_circle_outline,
              color: _recetaSeleccionada != null ? colors.primary : colors.hint,
              size: 16,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                _recetaSeleccionada?.nombre ?? 'Seleccionar receta...',
                style: font.bodySmall.copyWith(
                  fontSize: 12,
                  color: _recetaSeleccionada != null ? colors.titleText : colors.hint,
                ),
              ),
            ),
            if (_recetaSeleccionada != null)
              GestureDetector(
                onTap: () => setState(() => _recetaSeleccionada = null),
                child: Icon(Icons.close_rounded, color: colors.hint, size: 16),
              )
            else
              Icon(Icons.keyboard_arrow_down_rounded, color: colors.hint, size: 16),
          ],
        ),
      ),
    );
  }

  Widget _buildBotonGuardar(AppColors colors, AppFont font) {
    return GestureDetector(
      onTap: _isSaving ? null : _guardar,
      child: Container(
        width: double.infinity,
        padding: EdgeInsets.symmetric(vertical: AppTheme.spacing.md),
        decoration: BoxDecoration(
          color: _isSaving ? colors.hint : colors.accent,
          borderRadius: AppTheme.radius.brSm,
          boxShadow: AppTheme.shadows.cardSm,
        ),
        child: _isSaving
            ? SizedBox(
                height: 18,
                width: 18,
                child: CircularProgressIndicator(strokeWidth: 2, color: colors.titleText),
              )
            : Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.save_outlined, color: colors.titleText, size: 16),
                  const SizedBox(width: 8),
                  Text('Crear Orden de Producción', style: font.label.copyWith(fontSize: 14, fontWeight: FontWeight.w600)),
                ],
              ),
      ),
    );
  }
}
