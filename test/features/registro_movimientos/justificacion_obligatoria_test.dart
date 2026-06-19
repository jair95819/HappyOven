import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:mockito/mockito.dart';

import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/models/enums.dart';
import 'package:happy_oven/core/providers.dart';
import 'package:happy_oven/features/registro_movimientos/presentation/views/salida_almacen_view.dart';
import 'package:happy_oven/features/registro_movimientos/presentation/views/ingreso_almacen_view.dart';
import 'package:happy_oven/features/visualizacion_inventario/presentation/viewmodels/catalogo_viewmodel.dart';

import '../../helpers/test_helpers.mocks.dart';

Articulo _articulo({required TipoArticulo tipo}) => Articulo(
      id: 'art-1',
      nombre: 'Harina',
      tipo: tipo,
      unidad: UnidadMedida.kg,
      stockActual: 10,
      stockMinimo: 0,
      precioUnitario: 2,
      activo: true,
      createdAt: DateTime(2026, 1, 1),
      updatedAt: DateTime(2026, 1, 1),
    );

Widget _wrap(Widget child, MockArticulosRepository repo) {
  return ProviderScope(
    overrides: [articulosRepositoryProvider.overrideWithValue(repo)],
    child: MaterialApp(home: child),
  );
}

void main() {
  late MockArticulosRepository repo;

  setUp(() {
    repo = MockArticulosRepository();
  });

  // Superficie alta para que el formulario completo quepa en pantalla.
  void usarPantallaAlta(WidgetTester tester) {
    tester.view.physicalSize = const Size(1080, 2600);
    tester.view.devicePixelRatio = 1.0;
    addTearDown(tester.view.resetPhysicalSize);
    addTearDown(tester.view.resetDevicePixelRatio);
  }

  group('CP-04 / RF-012 - Justificación obligatoria', () {
    testWidgets(
        'CA035 - SALIDA: bloquea el registro y exige justificación cuando está vacía',
        (tester) async {
      usarPantallaAlta(tester);
      when(repo.getArticulos())
          .thenAnswer((_) async => [_articulo(tipo: TipoArticulo.productoFinal)]);

      await tester.pumpWidget(_wrap(const SalidaAlmacenView(), repo));
      await tester.pumpAndSettle(); // carga catálogo + auto-selección de producto

      // Pulsar "Registrar salida" con la justificación vacía.
      final boton = find.text('Registrar salida').last;
      await tester.ensureVisible(boton);
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pump(); // mostrar SnackBar

      expect(
        find.text('La justificación es obligatoria para registrar la salida'),
        findsOneWidget,
      );
    });

    testWidgets(
        'CA036 - INGRESO: bloquea el registro y exige justificación cuando está vacía',
        (tester) async {
      usarPantallaAlta(tester);
      when(repo.getArticulos()).thenAnswer((_) async => [_articulo(tipo: TipoArticulo.insumo)]);

      await tester.pumpWidget(_wrap(const IngresoAlmacenView(), repo));
      await tester.pumpAndSettle();

      // Pre-cargar el catálogo (la vista lo lee de forma diferida al abrir el selector).
      ProviderScope.containerOf(tester.element(find.byType(IngresoAlmacenView)))
          .read(catalogoViewModelProvider);
      await tester.pumpAndSettle();

      // Seleccionar el artículo desde el bottom sheet.
      await tester.tap(find.text('Seleccionar artículo...'));
      await tester.pumpAndSettle();
      await tester.tap(find.text('Harina').last);
      await tester.pumpAndSettle();

      // Ingresar una cantidad válida (primer TextField del formulario).
      await tester.enterText(find.byType(TextField).first, '5');

      // Pulsar "Registrar Entrada" con la justificación vacía.
      final boton = find.text('Registrar Entrada');
      await tester.ensureVisible(boton);
      await tester.pumpAndSettle();
      await tester.tap(boton);
      await tester.pump();

      expect(
        find.text('La justificación es obligatoria para registrar el ingreso'),
        findsOneWidget,
      );
    });
  });
}
