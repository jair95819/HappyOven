import 'package:flutter/material.dart';

/// Datos de ejemplo tomados del prototipo de diseño (Diseño Happy Oven).
///
/// TODO: reemplazar cada uno por datos reales. Todo lo que se lee de aquí es
/// provisional y solo sirve para que la UI quede igual al diseño.
class DisenoDemo {
  DisenoDemo._();

  // ── Fotos (Unsplash) usadas en el prototipo ──
  static String foto(String id, {int w = 200, int h = 200}) =>
      'https://images.unsplash.com/photo-$id?w=$w&h=$h&fit=crop&auto=format';

  static const _fotos = {
    'alfajor': '1757522744922-1708afba3917',
    'brownie': '1606313564200-e75d5e30476c',
    'cheesecake': '1622621746668-59fb299bc4d7',
    'calzone': '1753656681797-3234c89d6d4d',
    'calzzone': '1753656681797-3234c89d6d4d',
    'pan': '1549413468-cd78edb7e75c',
    'harina': '1509440159596-0249088772ff',
    'azúcar': '1581441363689-1f3c3c414635',
    'azucar': '1581441363689-1f3c3c414635',
    'levadura': '1586444248902-2f64eddc13df',
    'aceite': '1474979266404-7eaacbcd87c5',
    'almendra': '1508061253366-f7da158b6d46',
    'ajonjol': '1508061253366-f7da158b6d46',
    'anís': '1509358211525-c9da108034d6',
    'colorante': '1563170351-be82bc888aa4',
  };

  /// ID de foto por palabra clave del nombre; `null` si no hay coincidencia.
  static String? fotoPara(String nombre) {
    final n = nombre.toLowerCase();
    for (final e in _fotos.entries) {
      if (n.contains(e.key)) return e.value;
    }
    return null;
  }

  static const fotoPorDefecto = '1509440159596-0249088772ff';
  static const fotoPerfil = '1595152772835-219674b2a8a6';

  // ── Receta: valores nutricionales, valoración y descripción ──
  static const nutricion = [
    ('189', 'Kcal'),
    ('28g', 'Proteínas'),
    ('18g', 'Grasas'),
    ('24g', 'Carbos'),
  ];
  static const valoracion = '4.9';
  static const lotes = '(120+ lotes)';
  static const descripcion =
      'Receta artesanal tradicional con ingredientes seleccionados y un delicado '
      'toque casero. Textura suave que se deshace en el paladar.';
  static const descripcionExtra =
      ' Se hornea a temperatura controlada para preservar la suavidad. '
      'Costo de producción optimizado por lote.';
  static const etiquetas = ['Básica', 'Alta rotación'];

  // ── Dashboard: distribución por categoría ──
  static const distribucionCategorias = [
    ('Harinas', 45),
    ('Lácteos', 35),
    ('Otros', 20),
  ];

  // ── Reportes ──
  static const kpis = [
    (Icons.attach_money_rounded, 'Ventas (recetas)', '128', '+18.2%', true),
    (Icons.shopping_cart_outlined, 'Costo de producción', 'S/ 1,245.60', '-5.6%', false),
    (Icons.trending_up_rounded, 'Margen bruto', 'S/ 754.40', '+22.8%', true),
    (Icons.inventory_2_outlined, 'Recetas producidas', '245', '+14.1%', true),
  ];

  static const ventasPorDia = [
    ('01/05', 22.0),
    ('02/05', 41.0),
    ('03/05', 30.0),
    ('04/05', 20.0),
    ('05/05', 34.0),
    ('06/05', 28.0),
    ('07/05', 46.0),
  ];

  static const costosCategoria = [
    ('Harinas', 42.0),
    ('Lácteos', 23.0),
    ('Azúcares', 15.0),
    ('Otros', 20.0),
  ];
  static const costosCategoriaTotal = 'S/ 1,245';

  static const productosUsados = [
    ('Harina de trigo', '120.5 kg', '+12.5%', true),
    ('Azúcar', '45.2 kg', '-3.2%', false),
    ('Mantequilla', '28.1 kg', '+8.7%', true),
    ('Levadura seca', '2.1 kg', '-1.1%', false),
  ];

  static const oportunidades = [
    (Icons.factory_outlined, 'Control de merma', 'La merma aumentó 2.3%. Revisa procesos y almacenamiento.'),
    (Icons.menu_book_outlined, 'Optimizar recetas', 'Algunas recetas tienen margen bajo. Ajusta costos o porciones.'),
    (Icons.shopping_cart_outlined, 'Planificación de compras', 'Harina y azúcar con alta rotación. Planifica con anticipación.'),
  ];
}
