import 'package:flutter_test/flutter_test.dart';
import 'package:happy_oven/core/services/ocr_service.dart';

void main() {
  late OcrService ocr;

  setUp(() => ocr = OcrService());

  // ═══════════════════════════════════════════════════════
  // parsearLinea() — extrae nombre, cantidad, precio e importe
  // ═══════════════════════════════════════════════════════
  group('OcrService.parsearLinea()', () {
    test('línea completa: nombre + cantidad + unidad + precio + importe', () {
      final item = ocr.parsearLinea('Harina de trigo  50 kg  2.80  140.00');

      expect(item, isNotNull);
      expect(item!.nombreRaw, 'Harina de trigo');
      expect(item.cantidad, 50);
      expect(item.unidad, 'kg');
      expect(item.precioUnitario, 2.80);
      expect(item.importe, closeTo(140.00, 0.001));
    });

    test('sin importe explícito: lo calcula como cantidad × precio', () {
      final item = ocr.parsearLinea('Mantequilla 20 kg 8.50');

      expect(item, isNotNull);
      expect(item!.cantidad, 20);
      expect(item.precioUnitario, 8.50);
      expect(item.importe, closeTo(170.00, 0.001));
    });

    test('elige la tripleta correcta ignorando un código de artículo inicial',
        () {
      // "001" es un código espurio; 12 × 3.50 = 42.00 debe ganar.
      final item = ocr.parsearLinea('001 Azucar rubia 12 3.50 42.00');

      expect(item, isNotNull);
      expect(item!.nombreRaw.toLowerCase(), contains('azucar'));
      expect(item.cantidad, 12);
      expect(item.precioUnitario, 3.50);
      expect(item.importe, closeTo(42.00, 0.001));
    });

    test('detecta la unidad pegada a la cantidad sin contaminar el nombre', () {
      final item = ocr.parsearLinea('Harina trigo 50kg 2.80 140.00');

      expect(item, isNotNull);
      expect(item!.nombreRaw, 'Harina trigo');
      expect(item.unidad, 'kg');
      expect(item.cantidad, 50);
      expect(item.precioUnitario, 2.80);
      expect(item.importe, closeTo(140.00, 0.001));
    });

    test('acepta decimales con coma', () {
      final item = ocr.parsearLinea('Leche 10 lt 4,20 42,00');

      expect(item, isNotNull);
      expect(item!.unidad, 'litros');
      expect(item.precioUnitario, closeTo(4.20, 0.001));
      expect(item.importe, closeTo(42.00, 0.001));
    });

    test('maneja separador de miles en el importe', () {
      final item = ocr.parsearLinea('Cacao premium 500 25.50 12,750.00');

      expect(item, isNotNull);
      expect(item!.cantidad, 500);
      expect(item.precioUnitario, closeTo(25.50, 0.001));
      expect(item.importe, closeTo(12750.00, 0.01));
    });

    test('descarta líneas sin nombre legible', () {
      expect(ocr.parsearLinea('50 2.80 140.00'), isNull);
    });

    test('descarta líneas sin suficientes números', () {
      expect(ocr.parsearLinea('Subtotal 140.00'), isNull);
      expect(ocr.parsearLinea(''), isNull);
    });

    test('normaliza variantes de unidades', () {
      expect(ocr.parsearLinea('Sal 5 kilos 1.0 5.0')!.unidad, 'kg');
      expect(ocr.parsearLinea('Esencia 3 ml 2.0 6.0')!.unidad, 'ml');
      expect(ocr.parsearLinea('Polvo 8 gramos 1.5 12.0')!.unidad, 'gramos');
      expect(ocr.parsearLinea('Cajas 4 unidades 3.0 12.0')!.unidad, 'unidades');
      // sin unidad explícita -> 'unidades' por defecto
      expect(ocr.parsearLinea('Tornillos 4 3.0 12.0')!.unidad, 'unidades');
    });
  });

  // ═══════════════════════════════════════════════════════
  // parsearBoleta() — recorre el texto completo
  // ═══════════════════════════════════════════════════════
  group('OcrService.parsearBoleta()', () {
    test('extrae solo las líneas de ítems válidas', () {
      const texto = '''
PANADERIA EL SOL
RUC 20123456789
Harina de trigo  50 kg  2.80  140.00
Mantequilla      20 kg  8.50  170.00
Azucar           30 kg  3.20  96.00
TOTAL                          406.00
Gracias por su compra
''';

      final items = ocr.parsearBoleta(texto);

      expect(items.length, 3);
      expect(items[0].nombreRaw, 'Harina de trigo');
      expect(items[1].cantidad, 20);
      expect(items[2].importe, closeTo(96.00, 0.001));
    });

    test('devuelve lista vacía cuando no hay ítems', () {
      expect(ocr.parsearBoleta('PANADERIA\nGRACIAS\n'), isEmpty);
    });
  });

  // ═══════════════════════════════════════════════════════
  // indiceMejorCoincidencia() — asocia nombre OCR al catálogo
  // ═══════════════════════════════════════════════════════
  group('OcrService.indiceMejorCoincidencia()', () {
    const catalogo = [
      'Harina de trigo',
      'Mantequilla',
      'Azúcar Rubia',
      'Levadura seca',
      'Aceite vegetal',
    ];

    int? match(String nombre) =>
        OcrService.indiceMejorCoincidencia(nombre, catalogo);

    test('coincidencia exacta', () {
      expect(match('Mantequilla'), 1);
    });

    test('ignora palabra de relleno faltante ("de")', () {
      expect(match('Harina trigo'), 0);
    });

    test('ignora acentos y mayúsculas', () {
      expect(match('Azucar rubia'), 2);
    });

    test('asocia nombre parcial al más parecido', () {
      expect(match('Levadura'), 3);
    });

    test('devuelve null cuando no hay candidato parecido', () {
      expect(match('Chocolate amargo'), isNull);
      expect(match(''), isNull);
    });
  });
}
