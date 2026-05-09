import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Resultado parseado de una línea de la boleta
class OcrItem {
  final String nombreRaw;
  final double cantidad;
  final String unidad;
  final double precioUnitario;

  OcrItem({
    required this.nombreRaw,
    required this.cantidad,
    required this.unidad,
    required this.precioUnitario,
  });
}

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer(script: TextRecognitionScript.latin);

  /// Procesa una imagen y devuelve el texto crudo reconocido
  Future<String> reconocerTexto(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  /// Intenta parsear el texto OCR en items de boleta
  /// Estrategia: buscar líneas que contengan cantidades y precios
  List<OcrItem> parsearBoleta(String textoOcr) {
    final items = <OcrItem>[];
    final lineas = textoOcr.split('\n').where((l) => l.trim().isNotEmpty).toList();

    // Patrón: buscar líneas con números que puedan ser cantidad y precio
    // Ejemplo típico de boleta:
    //   "Harina de trigo  50 kg  2.80"
    //   "Mantequilla      20 kg  8.50"
    final regexNumero = RegExp(r'(\d+\.?\d*)');
    final regexUnidad = RegExp(r'\b(kg|gr|g|lt|l|litros?|unid\.?|unidades?|ml|pzas?)\b', caseSensitive: false);

    for (final linea in lineas) {
      final numeros = regexNumero.allMatches(linea).map((m) => double.tryParse(m.group(0) ?? '') ?? 0).where((n) => n > 0).toList();
      final unidadMatch = regexUnidad.firstMatch(linea);

      if (numeros.length >= 2) {
        // Limpiar el nombre: remover números y unidades
        String nombre = linea
            .replaceAll(regexNumero, '')
            .replaceAll(regexUnidad, '')
            .replaceAll(RegExp(r'[^\w\sáéíóúñÁÉÍÓÚÑ]'), '')
            .trim();

        // Limpiar espacios multiples
        nombre = nombre.replaceAll(RegExp(r'\s+'), ' ').trim();

        if (nombre.length < 2) continue; // Ignorar líneas sin nombre legible

        String unidad = _normalizarUnidad(unidadMatch?.group(0) ?? 'unid.');
        double cantidad = numeros.first;
        double precio = numeros.last;

        // Si hay 3+ números, el primero es cantidad, el último es precio
        // A veces el segundo podría ser subtotal
        if (numeros.length >= 3) {
          cantidad = numeros[0];
          precio = numeros[numeros.length - 1];
        }

        items.add(OcrItem(
          nombreRaw: nombre,
          cantidad: cantidad,
          unidad: unidad,
          precioUnitario: precio,
        ));
      }
    }

    return items;
  }

  String _normalizarUnidad(String raw) {
    final lower = raw.toLowerCase().replaceAll('.', '');
    if (lower.startsWith('kg')) return 'kg';
    if (lower.startsWith('gr') || lower == 'g') return 'gr';
    if (lower.startsWith('lt') || lower.startsWith('l') || lower.startsWith('litro')) return 'litros';
    if (lower.startsWith('ml')) return 'ml';
    if (lower.startsWith('unid') || lower.startsWith('pza')) return 'unid.';
    return raw;
  }

  void dispose() {
    _textRecognizer.close();
  }
}
