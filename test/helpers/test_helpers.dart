import 'package:mockito/annotations.dart';
import 'package:happy_oven/core/repositories/i_articulos_repository.dart';
import 'package:happy_oven/core/repositories/i_recetas_repository.dart';
import 'package:happy_oven/core/repositories/i_movimientos_repository.dart';
import 'package:happy_oven/core/repositories/i_alertas_repository.dart';
import 'package:happy_oven/core/repositories/i_ordenes_produccion_repository.dart';
import 'package:happy_oven/core/repositories/articulos_repository.dart';
import 'package:happy_oven/core/repositories/alertas_repository.dart';

@GenerateMocks([
  IArticulosRepository,
  IRecetasRepository,
  IMovimientosRepository,
  IAlertasRepository,
  IOrdenesProduccionRepository,
  ArticulosRepository,
  AlertasRepository,
])
void main() {}
