import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:happy_oven/core/models/articulo.dart';
import 'package:happy_oven/core/models/alerta.dart';
import 'package:happy_oven/core/models/enums.dart';
import 'package:happy_oven/core/services/stock_monitor_service.dart';
import 'package:happy_oven/core/services/notification_service.dart';

import '../helpers/test_helpers.mocks.dart';

// ── Fake de NotificationService (porque es singleton con constructor privado) ──
class FakeNotificationService extends Fake implements NotificationService {
  int showResumenCalls = 0;
  int lastTotalBajo = 0;
  int lastTotalCritico = 0;

  @override
  Future<void> showResumenAlert({
    required int totalBajo,
    required int totalCritico,
  }) async {
    showResumenCalls++;
    lastTotalBajo = totalBajo;
    lastTotalCritico = totalCritico;
  }
}

Articulo _art({
  String id = 'a1',
  String nombre = 'Harina',
  double stockActual = 100,
  double stockMinimo = 10,
}) {
  return Articulo(
    id: id, nombre: nombre, categoriaId: null,
    tipo: TipoArticulo.insumo, unidad: UnidadMedida.kg, stockActual: stockActual,
    stockMinimo: stockMinimo, precioUnitario: 5.0, activo: true,
    createdAt: DateTime(2025, 1), updatedAt: DateTime(2025, 1),
  );
}

void main() {
  late MockIArticulosRepository mockArticulosRepo;
  late MockIAlertasRepository mockAlertasRepo;
  late FakeNotificationService fakeNotificationService;
  late StockMonitorService service;

  setUp(() {
    mockArticulosRepo = MockIArticulosRepository();
    mockAlertasRepo = MockIAlertasRepository();
    fakeNotificationService = FakeNotificationService();

    service = StockMonitorService(
      articulosRepo: mockArticulosRepo,
      alertasRepo: mockAlertasRepo,
      notificationService: fakeNotificationService,
    );
  });

  // ═══════════════════════════════════════════════════════
  // CA020 — startMonitoring()
  // ═══════════════════════════════════════════════════════
  group('CA020 - startMonitoring()', () {
    test('inicia monitoreo y ejecuta chequeo inmediato', () async {
      when(mockArticulosRepo.getArticulos())
          .thenAnswer((_) async => [_art(stockMinimo: 10)]);
      when(mockAlertasRepo.getAlertasPendientes())
          .thenAnswer((_) async => []);

      service.startMonitoring();

      await Future.delayed(const Duration(milliseconds: 100));

      expect(service.isRunning, true);
      verify(mockArticulosRepo.getArticulos()).called(1);

      service.stopMonitoring();
    });

    test('no inicia doble monitoreo si ya está corriendo', () async {
      when(mockArticulosRepo.getArticulos())
          .thenAnswer((_) async => []);
      when(mockAlertasRepo.getAlertasPendientes())
          .thenAnswer((_) async => []);

      service.startMonitoring();
      service.startMonitoring();

      await Future.delayed(const Duration(milliseconds: 100));

      verify(mockArticulosRepo.getArticulos()).called(1);

      service.stopMonitoring();
    });
  });

  // ═══════════════════════════════════════════════════════
  // CA021 — checkNow()
  // ═══════════════════════════════════════════════════════
  group('CA021 - checkNow()', () {
    test('no crea alertas cuando todo el stock es normal', () async {
      when(mockArticulosRepo.getArticulos()).thenAnswer((_) async => [
        _art(stockActual: 100),
        _art(id: 'a2', stockActual: 50, stockMinimo: 5),
      ]);
      when(mockAlertasRepo.getAlertasPendientes())
          .thenAnswer((_) async => []);

      await service.checkNow();

      verifyNever(mockAlertasRepo.createAlerta(any));
      expect(fakeNotificationService.showResumenCalls, 0);
    });

    test('crea alerta de stock BAJO cuando stock <= stockMinimo', () async {
      when(mockArticulosRepo.getArticulos()).thenAnswer((_) async => [
        _art(nombre: 'Harina', stockActual: 8),
      ]);
      when(mockAlertasRepo.getAlertasPendientes())
          .thenAnswer((_) async => []);
      when(mockAlertasRepo.createAlerta(any)).thenAnswer((_) async =>
        Alerta(id: 'al1', tipo: TipoAlerta.stockBajo, titulo: 'Stock bajo',
               mensaje: 'test', leida: false, createdAt: DateTime.now()),
      );

      await service.checkNow();

      verify(mockAlertasRepo.createAlerta(any)).called(1);
      expect(fakeNotificationService.showResumenCalls, 1);
      expect(fakeNotificationService.lastTotalBajo, 1);
      expect(fakeNotificationService.lastTotalCritico, 0);
    });

    test('crea alerta CRÍTICA cuando stock <= stockMinimo * 0.5', () async {
      when(mockArticulosRepo.getArticulos()).thenAnswer((_) async => [
        _art(nombre: 'Azúcar', stockActual: 3),
      ]);
      when(mockAlertasRepo.getAlertasPendientes())
          .thenAnswer((_) async => []);
      when(mockAlertasRepo.createAlerta(any)).thenAnswer((_) async =>
        Alerta(id: 'al1', tipo: TipoAlerta.stockBajo, titulo: 'Stock crítico',
               mensaje: 'test', leida: false, createdAt: DateTime.now()),
      );

      await service.checkNow();

      verify(mockAlertasRepo.createAlerta(any)).called(1);
      expect(fakeNotificationService.lastTotalCritico, 1);
    });

    test('NO duplica alerta si ya existe una pendiente para el artículo', () async {
      when(mockArticulosRepo.getArticulos()).thenAnswer((_) async => [
        _art(stockActual: 3),
      ]);
      when(mockAlertasRepo.getAlertasPendientes()).thenAnswer((_) async => [
        Alerta(id: 'al-existente', articuloId: 'a1', tipo: TipoAlerta.stockBajo,
               titulo: 'Stock bajo', mensaje: 'ya existe',
               leida: false, createdAt: DateTime.now()),
      ]);

      await service.checkNow();

      verifyNever(mockAlertasRepo.createAlerta(any));
    });

    test('ignora artículos con stockMinimo = 0', () async {
      when(mockArticulosRepo.getArticulos()).thenAnswer((_) async => [
        _art(stockActual: 0, stockMinimo: 0),
      ]);
      when(mockAlertasRepo.getAlertasPendientes())
          .thenAnswer((_) async => []);

      await service.checkNow();

      verifyNever(mockAlertasRepo.createAlerta(any));
    });
  });
}
