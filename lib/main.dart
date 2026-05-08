import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'core/router/app_router.dart';
import 'core/services/supabase_service.dart';
import 'core/services/local_storage_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

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

  runApp(const ProviderScope(child: HappyOvenApp()));
}

class HappyOvenApp extends ConsumerWidget {
  const HappyOvenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      locale: const Locale('es'),
      supportedLocales: const [Locale('es')],
      title: 'Happy Oven',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}

