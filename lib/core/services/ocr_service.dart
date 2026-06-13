import 'dart:io';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';

/// Resultado parseado de una línea de la boleta.
///
/// Para el propósito del proyecto se reconocen cuatro campos por línea:
/// nombre del producto, cantidad, precio unitario e importe (total de la línea).
class OcrItem {
  final String nombreRaw;
  final double cantidad;
  final String unidad;
  final double precioUnitario;
  final double importe;

  OcrItem({
    required this.nombreRaw,
    required this.cantidad,
    required this.unidad,
    required this.precioUnitario,
    required this.importe,
  });
}

class OcrService {
  final TextRecognizer _textRecognizer = TextRecognizer();

  /// Procesa una imagen (foto tomada con la cámara o subida desde la galería)
  /// y devuelve el texto crudo reconocido por ML Kit.
  Future<String> reconocerTexto(File imageFile) async {
    final inputImage = InputImage.fromFile(imageFile);
    final recognizedText = await _textRecognizer.processImage(inputImage);
    return recognizedText.text;
  }

  /// Parsea el texto OCR completo de una boleta en una lista de ítems.
  /// Recorre línea por línea y conserva solo las que contienen una cantidad,
  /// un precio y un nombre legible.
  List<OcrItem> parsearBoleta(String textoOcr) {
    final items = <OcrItem>[];
    for (final linea in textoOcr.split('\n')) {
      final item = parsearLinea(linea);
      if (item != null) items.add(item);
    }
    return items;
  }

  /// Intenta interpretar una sola línea como un ítem de boleta.
  /// Devuelve `null` si la línea no contiene suficientes datos numéricos
  /// o si no se puede extraer un nombre legible.
  ///
  /// Estructura típica de una línea:
  ///   `NOMBRE  CANTIDAD [UNIDAD]  PRECIO_UNITARIO  IMPORTE`
  /// ejemplos:
  ///   `Harina de trigo  50 kg  2.80  140.00`
  ///   `Mantequilla      20     8.50  170.00`
  OcrItem? parsearLinea(String linea) {
    // Separar cantidad y unidad pegadas (`50kg` -> `50 kg`) para que la unidad
    // se reconozca y no contamine el nombre; en boletas reales es común.
    final limpia = linea.trim().replaceAllMapped(
      RegExp(r'(\d)([a-zA-ZáéíóúñÁÉÍÓÚÑ])'),
      (m) => '${m[1]} ${m[2]}',
    );
    if (limpia.isEmpty) return null;

    final numeros = _regexNumero
        .allMatches(limpia)
        .map((m) => _parsearNumero(m.group(0)!))
        .where((n) => n != null && n > 0)
        .cast<double>()
        .toList();

    final triple = _interpretarNumeros(numeros);
    if (triple == null) return null;

    final unidadMatch = _regexUnidad.firstMatch(limpia);
    final unidad = _normalizarUnidad(unidadMatch?.group(0));

    // El nombre es lo que queda tras quitar números, unidades, símbolos de
    // moneda y puntuación; esto descarta también códigos numéricos al inicio.
    String nombre = limpia
        .replaceAll(_regexUnidad, ' ')
        .replaceAll(_regexNumero, ' ')
        .replaceAll(_regexMoneda, ' ')
        .replaceAll(RegExp(r'[^\wáéíóúñÁÉÍÓÚÑ\s]'), ' ')
        .replaceAll(RegExp(r'\s+'), ' ')
        .trim();

    if (nombre.length < 2) return null;

    return OcrItem(
      nombreRaw: nombre,
      cantidad: triple.cantidad,
      unidad: unidad,
      precioUnitario: triple.precio,
      importe: triple.importe,
    );
  }

  /// Decide qué números de la línea son cantidad, precio e importe.
  ///
  /// Estrategia: una boleta cumple `cantidad × precio ≈ importe`, así que se
  /// busca la primera tripleta de números (en orden) que satisfaga esa
  /// relación — esto tolera números espurios como códigos de artículo. Si no
  /// hay tripleta válida pero hay al menos dos números, se asume
  /// `[cantidad, precio]` y el importe se calcula.
  _Triple? _interpretarNumeros(List<double> nums) {
    if (nums.length >= 3) {
      for (var i = 0; i < nums.length; i++) {
        for (var j = i + 1; j < nums.length; j++) {
          for (var k = j + 1; k < nums.length; k++) {
            final esperado = nums[i] * nums[j];
            if (_aproximado(esperado, nums[k])) {
              return _Triple(nums[i], nums[j], nums[k]);
            }
          }
        }
      }
    }
    if (nums.length >= 2) {
      final cantidad = nums[0];
      final precio = nums[1];
      return _Triple(cantidad, precio, cantidad * precio);
    }
    return null;
  }

  bool _aproximado(double a, double b) {
    final tolerancia = (b.abs() * 0.05).clamp(0.1, double.infinity);
    return (a - b).abs() <= tolerancia;
  }

  /// Convierte un token numérico de la boleta a `double`, tolerando
  /// separadores de miles y decimales con coma o punto (`1,234.50`, `2,80`).
  double? _parsearNumero(String raw) {
    var token = raw.trim();
    final tienePunto = token.contains('.');
    final tieneComa = token.contains(',');

    if (tienePunto && tieneComa) {
      // El separador que aparece más a la derecha es el decimal.
      if (token.lastIndexOf(',') > token.lastIndexOf('.')) {
        token = token.replaceAll('.', '').replaceAll(',', '.');
      } else {
        token = token.replaceAll(',', '');
      }
    } else if (tieneComa) {
      // Coma como decimal solo si hay un único separador con <=2 dígitos detrás.
      if (RegExp(r'^\d+,\d{1,2}$').hasMatch(token)) {
        token = token.replaceAll(',', '.');
      } else {
        token = token.replaceAll(',', '');
      }
    } else if (tienePunto) {
      // Múltiples puntos => todos menos el último son separadores de miles.
      final partes = token.split('.');
      if (partes.length > 2) {
        final decimal = partes.removeLast();
        token = '${partes.join()}.$decimal';
      }
    }
    return double.tryParse(token);
  }

  String _normalizarUnidad(String? raw) {
    if (raw == null) return 'unidades';
    final lower = raw.toLowerCase().replaceAll('.', '');
    if (lower.startsWith('kg') || lower.startsWith('kilo')) return 'kg';
    if (lower.startsWith('ml')) return 'ml';
    if (lower == 'g' || lower.startsWith('gr')) return 'gramos';
    if (lower.startsWith('l')) return 'litros';
    return 'unidades';
  }

  /// Busca, dentro de [candidatos] (nombres del catálogo), el que mejor
  /// corresponde a [nombre] detectado por OCR, tolerando acentos, mayúsculas,
  /// palabras de relleno ("de", "la"…) y nombres parciales
  /// (p. ej. "Harina trigo" → "Harina de trigo", "Levadura" → "Levadura seca").
  ///
  /// Devuelve el índice del mejor candidato, o `null` si ninguno supera el
  /// umbral mínimo de similitud.
  static int? indiceMejorCoincidencia(String nombre, List<String> candidatos) {
    final objetivo = _tokens(nombre);
    if (objetivo.isEmpty) return null;

    int? mejor;
    double mejorScore = 0;
    for (var i = 0; i < candidatos.length; i++) {
      final cand = _tokens(candidatos[i]);
      if (cand.isEmpty) continue;

      final interseccion = objetivo.where(cand.contains).length;
      if (interseccion == 0) continue;

      final union = {...objetivo, ...cand}.length;
      final jaccard = interseccion / union;
      // Si todos los tokens detectados están en el candidato (nombre parcial),
      // se prioriza fuertemente sobre coincidencias parciales sueltas.
      final subconjunto = objetivo.every(cand.contains);
      final score = subconjunto ? 1 + jaccard : jaccard;

      if (score > mejorScore) {
        mejorScore = score;
        mejor = i;
      }
    }

    // Umbral: aceptar subconjunto (score > 1) o un Jaccard de al menos 0.5.
    return mejorScore >= 0.5 ? mejor : null;
  }

  /// Normaliza un nombre a tokens comparables: minúsculas, sin acentos, sin
  /// puntuación ni palabras de relleno.
  static List<String> _tokens(String s) {
    var t = s.toLowerCase();
    const acentos = {
      'á': 'a',
      'é': 'e',
      'í': 'i',
      'ó': 'o',
      'ú': 'u',
      'ü': 'u',
      'ñ': 'n',
    };
    acentos.forEach((k, v) => t = t.replaceAll(k, v));
    t = t.replaceAll(RegExp(r'[^a-z0-9\s]'), ' ');
    return t
        .split(RegExp(r'\s+'))
        .where((w) => w.length > 1 && !_relleno.contains(w))
        .toList();
  }

  static const _relleno = {'de', 'del', 'la', 'el', 'los', 'las', 'con', 'sin', 'al', 'y'};

  void dispose() {
    _textRecognizer.close();
  }

  // Acepta enteros y decimales con punto o coma, incluyendo separadores de
  // miles: `50`, `2.80`, `2,80`, `1,234.50`.
  static final RegExp _regexNumero = RegExp(r'\d[\d.,]*\d|\d');
  static final RegExp _regexUnidad = RegExp(
    r'\b(kg|kilos?|gr|g|gramos?|lt|l|litros?|ml|unid\.?|unidades?|pzas?|pza)\b',
    caseSensitive: false,
  );
  static final RegExp _regexMoneda = RegExp(
    r'(S/\.?|\$|soles?)',
    caseSensitive: false,
  );
}

class _Triple {
  final double cantidad;
  final double precio;
  final double importe;
  _Triple(this.cantidad, this.precio, this.importe);
}
