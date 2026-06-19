import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/models/categoria.dart';
import 'package:happy_oven/core/models/enums.dart';
import 'package:happy_oven/core/repositories/categorias_repository.dart';
import 'package:happy_oven/core/providers.dart';

final categoriasViewModelProvider =
    StateNotifierProvider<CategoriasViewModel, AsyncValue<List<Categoria>>>((ref) {
      return CategoriasViewModel(ref.watch(categoriasRepositoryProvider));
    });

class CategoriasViewModel extends StateNotifier<AsyncValue<List<Categoria>>> {
  final CategoriasRepository _repository;

  CategoriasViewModel(this._repository) : super(const AsyncLoading()) {
    cargar();
  }

  Future<void> cargar() async {
    try {
      state = const AsyncLoading();
      final cats = await _repository.getCategorias();
      state = AsyncData(cats);
    } catch (e, st) {
      state = AsyncError(e, st);
    }
  }

  Future<String?> crear(String nombre, TipoArticulo tipo) async {
    try {
      final cat = Categoria(
        id: '',
        nombre: nombre,
        tipo: tipo,
        orden: 0,
        createdAt: DateTime.now(),
      );
      await _repository.createCategoria(cat);
      await cargar();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<String?> actualizar(Categoria cat) async {
    try {
      await _repository.updateCategoria(cat);
      await cargar();
      return null;
    } catch (e) {
      return e.toString();
    }
  }

  Future<bool> eliminar(String id) async {
    try {
      await _repository.deleteCategoria(id);
      await cargar();
      return true;
    } catch (e) {
      return false;
    }
  }
}

class GestionCategoriasView extends ConsumerStatefulWidget {
  const GestionCategoriasView({super.key});

  @override
  ConsumerState<GestionCategoriasView> createState() => _GestionCategoriasViewState();
}

class _GestionCategoriasViewState extends ConsumerState<GestionCategoriasView> {
  TipoArticulo _tab = TipoArticulo.insumo;

  void _mostrarDialogo({Categoria? existente}) {
    final controller = TextEditingController(text: existente?.nombre ?? '');
    final font = AppTheme.fontOf(context);
    final colors = AppTheme.colorsOf(context);

    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: colors.card,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        title: Text(existente != null ? 'Editar categoría' : 'Nueva categoría', style: font.label),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: font.bodySmall,
          decoration: InputDecoration(
            hintText: 'Nombre de la categoría',
            hintStyle: font.hint,
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text('Cancelar', style: font.label.copyWith(color: colors.hint)),
          ),
          TextButton(
            onPressed: () async {
              final nombre = controller.text.trim();
              if (nombre.isEmpty) return;
              if (existente != null) {
                await ref.read(categoriasViewModelProvider.notifier).actualizar(
                  Categoria(id: existente.id, nombre: nombre, tipo: existente.tipo, orden: existente.orden, createdAt: existente.createdAt),
                );
              } else {
                await ref.read(categoriasViewModelProvider.notifier).crear(nombre, _tab);
              }
              if (ctx.mounted) Navigator.pop(ctx);
            },
            child: Text('Guardar', style: font.label.copyWith(color: colors.primary)),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final catsAsync = ref.watch(categoriasViewModelProvider);
    final colors = AppTheme.colorsOf(context);
    final font = AppTheme.fontOf(context);

    final cats = catsAsync.valueOrNull ?? [];
    final filtradas = cats.where((c) => c.tipo == _tab).toList();
    return Scaffold(
      backgroundColor: colors.bg,
      body: Column(
        children: [
          Container(
            color: colors.accent,
            child: SafeArea(
              bottom: false,
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 14),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text('Categorías', style: font.h3),
                        const SizedBox(height: 2),
                        Text('${cats.length} categorías', style: font.caption.copyWith(color: colors.accentDark)),
                      ],
                    ),
                    GestureDetector(
                      onTap: () => _mostrarDialogo(),
                      child: Container(
                        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                        decoration: BoxDecoration(
                          color: colors.titleText,
                          borderRadius: AppTheme.radius.brSm,
                        ),
                        child: Row(
                          children: [
                            Icon(Icons.add_rounded, color: colors.accent, size: 16),
                            const SizedBox(width: 6),
                            Text('Nueva', style: font.label.copyWith(color: colors.accent, fontSize: 13)),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
          Container(
            color: colors.accent,
            child: Row(
              children: [
                _buildTab(TipoArticulo.insumo, 'Insumos'),
                _buildTab(TipoArticulo.productoFinal, 'Productos'),
              ],
            ),
          ),
          Expanded(
            child: catsAsync.when(
              loading: () => const Center(child: CircularProgressIndicator()),
              error: (e, _) => Center(child: Text('Error: $e', style: font.body)),
              data: (_) => filtradas.isEmpty
                  ? Center(
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.category_outlined, color: colors.hint, size: 48),
                          const SizedBox(height: 12),
                          Text('Sin categorías', style: font.label),
                          const SizedBox(height: 4),
                          Text('Agrega una categoría nueva', style: font.caption),
                        ],
                      ),
                    )
                  : Container(
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
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(14, 20, 14, 8),
                          itemCount: filtradas.length,
                          itemBuilder: (_, i) => Padding(
                            padding: const EdgeInsets.only(bottom: 8),
                            child: Container(
                              padding: const EdgeInsets.all(14),
                              decoration: BoxDecoration(
                                color: colors.card,
                                borderRadius: BorderRadius.circular(AppTheme.radius.lg),
                                border: Border.all(color: colors.border, width: 0.5),
                              ),
                              child: Row(
                                children: [
                                  Container(
                                    width: 40, height: 40,
                                    decoration: BoxDecoration(
                                      color: colors.primaryLight,
                                      borderRadius: AppTheme.radius.brMd,
                                    ),
                                    child: Icon(Icons.category_outlined, color: colors.primary, size: 20),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment: CrossAxisAlignment.start,
                                      children: [
                                        Text(filtradas[i].nombre, style: font.label.copyWith(fontSize: 13)),
                                        const SizedBox(height: 2),
                                        Text('Orden: ${filtradas[i].orden}', style: font.caption),
                                      ],
                                    ),
                                  ),
                                  PopupMenuButton<String>(
                                    icon: Icon(Icons.more_vert_rounded, color: colors.hint, size: 18),
                                    padding: EdgeInsets.zero,
                                    onSelected: (val) {
                                      if (val == 'editar') {
                                        _mostrarDialogo(existente: filtradas[i]);
                                      } else if (val == 'eliminar') {
                                        ref.read(categoriasViewModelProvider.notifier).eliminar(filtradas[i].id);
                                      }
                                    },
                                    itemBuilder: (_) => [
                                      PopupMenuItem(value: 'editar', child: Row(children: [
                                        Icon(Icons.edit_outlined, size: 18, color: colors.primary),
                                        const SizedBox(width: 8),
                                        Text('Editar', style: font.bodySmall),
                                      ])),
                                      PopupMenuItem(value: 'eliminar', child: Row(children: [
                                        Icon(Icons.delete_outline, size: 18, color: colors.statusCritical),
                                        const SizedBox(width: 8),
                                        Text('Eliminar', style: font.bodySmall.copyWith(color: colors.statusCritical)),
                                      ])),
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTab(TipoArticulo tipo, String etiqueta) {
    final colors = AppTheme.colorsOf(context);
    final activo = _tab == tipo;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => _tab = tipo),
        child: Container(
          padding: const EdgeInsets.symmetric(vertical: 10),
          decoration: BoxDecoration(
            border: Border(
              bottom: BorderSide(
                color: activo ? colors.titleText : Colors.transparent,
                width: 2,
              ),
            ),
          ),
          child: Text(
            etiqueta,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 13,
              fontWeight: activo ? FontWeight.w600 : FontWeight.normal,
              color: activo ? colors.titleText : colors.hint,
            ),
          ),
        ),
      ),
    );
  }
}
