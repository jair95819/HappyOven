import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/router/app_router.dart';
import 'package:happy_oven/core/services/supabase_service.dart';
import 'package:happy_oven/core/services/local_storage_service.dart';
import 'package:happy_oven/core/services/notification_service.dart';
import 'package:happy_oven/core/theme/theme_notifier.dart';
import 'package:happy_oven/core/theme/theme.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  try {
    // ── Inicializar LocalStorage
    await LocalStorageService().initialize();

    // ── Inicializar Supabase
    await SupabaseService().initialize(
      url: 'https://rfzsqcgiuroncdnnhpmp.supabase.co',
      anonKey:
          'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJmenNxY2dpdXJvbmNkbm5ocG1wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxMTcyMzUsImV4cCI6MjA5MzY5MzIzNX0._cAZIkuGVFb0EryM1rTvTUSkZpb0SfoLA72xl7Y6kUM',
    );

    // ── Inicializar localizaciones
    await initializeDateFormatting('es', null);

    // ── Inicializar notificaciones locales
    await NotificationService().initialize();
  } catch (e) {
    // Si falla la inicialización, la app mostrará una pantalla de error
    print('Error en inicialización: $e');
  }

  runApp(const ProviderScope(child: HappyOvenApp()));
}

class HappyOvenApp extends ConsumerWidget {
  const HappyOvenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final themeMode = ref.watch(themeProvider);

    return MaterialApp.router(
      locale: const Locale('es', 'ES'),
      supportedLocales: const [Locale('es', 'ES'), Locale('es'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      title: 'Happy Oven',
      debugShowCheckedModeBanner: false,
      themeMode: themeMode,
      theme: ThemeData(
        brightness: Brightness.light,
        scaffoldBackgroundColor: AppTheme.colors.bg,
        colorScheme: ColorScheme.light(
          primary: AppTheme.colors.primary,
          secondary: AppTheme.colors.accent,
          surface: AppTheme.colors.surface,
        ),
      ),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        scaffoldBackgroundColor: const Color(0xFF121212),
        colorScheme: const ColorScheme.dark(
          primary: Color(0xFFFF8C42),
          secondary: Color(0xFFC8CA9E),
          surface: Color(0xFF2C2C2C),
        ),
      ),
      routerConfig: router,
    );
  }
}
