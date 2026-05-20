# Happy Oven

Aplicación Flutter multiplataforma para **gestión de inventario de panadería/repostería**: insumos, productos finales, recetas con costeo, movimientos tipo kardex, alertas y reportes PDF. Backend con [Supabase](https://supabase.com); estado con Riverpod.

## Requisitos

- Flutter SDK `^3.10.0`
- Proyecto Supabase con el schema de [`database/schema.sql`](database/schema.sql) y Auth habilitado

## Inicio rápido

```bash
cd d:\Happy_Oven\HappyOven
flutter pub get
flutter run
```

Configura URL y clave anónima de Supabase antes de ejecutar (ver `lib/main.dart` o variables de entorno del proyecto).

## Documentación

| Recurso | Contenido |
|---------|-----------|
| [**Guía completa del proyecto**](docs/GUIA_PROYECTO.md) | Arquitectura, features, rutas, modelos, base de datos y flujos |
| [`database/schema.sql`](database/schema.sql) | Esquema Postgres (tablas e índices) |

## Módulos principales

- **Auth** — Login, registro y recuperación de contraseña
- **Inventario** — Catálogo de insumos y productos finales
- **Recetas** — Recetario y costeo dinámico de lote
- **Movimientos** — Kardex, ingreso OCR y salidas de almacén
- **Analítica** — Dashboard, alertas y reportes PDF
- **Configuración** — Perfil y ajustes (tema, sesión)

## Stack

Flutter · Riverpod · go_router · Supabase · fl_chart · ML Kit (OCR) · pdf/printing

## Estructura del código

```
lib/
├── main.dart
├── core/           # Router, tema, modelos, repositorios, servicios, widgets
└── features/       # auth, visualizacion_inventario, recetas_costeo,
                    # registro_movimientos, analitica_alertas, configuracion
```

Detalle de cada carpeta y pantalla en la [guía del proyecto](docs/GUIA_PROYECTO.md).
