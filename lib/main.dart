import 'dart:async';

import 'package:app_links/app_links.dart';
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
  runApp(const ProviderScope(child: AppLoader()));
}

class AppLoader extends StatefulWidget {
  const AppLoader({super.key});

  @override
  State<AppLoader> createState() => _AppLoaderState();
}

class _AppLoaderState extends State<AppLoader> {
  bool _initialized = false;

  @override
  void initState() {
    super.initState();
    _init();
  }

  Future<void> _init() async {
    try {
      debugPrint('⌛ 1. Iniciando LocalStorage...');
      await LocalStorageService().initialize();
      debugPrint('✅ LocalStorage OK');

      debugPrint('⌛ 2. Iniciando Supabase...');
      await SupabaseService().initialize(
        url: 'https://rfzsqcgiuroncdnnhpmp.supabase.co',
        anonKey:
            'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJmenNxY2dpdXJvbmNkbm5ocG1wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxMTcyMzUsImV4cCI6MjA5MzY5MzIzNX0._cAZIkuGVFb0EryM1rTvTUSkZpb0SfoLA72xl7Y6kUM',
      );
      debugPrint('✅ Supabase OK');

      debugPrint('⌛ 3. Iniciando localizaciones...');
      await initializeDateFormatting('es');
      debugPrint('✅ Localizaciones OK');

      debugPrint('⌛ 4. Iniciando Notificaciones...');
      await NotificationService().initialize();
      debugPrint('✅ Notificaciones OK');
    } catch (e) {
      debugPrint('❌ Error en inicialización: $e');
    }

    if (mounted) {
      setState(() {
        _initialized = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    if (!_initialized) {
      return const MaterialApp(
        debugShowCheckedModeBanner: false,
        home: Scaffold(body: Center(child: CircularProgressIndicator())),
      );
    }
    return const HappyOvenApp();
  }
}

class HappyOvenApp extends ConsumerStatefulWidget {
  const HappyOvenApp({super.key});

  @override
  ConsumerState<HappyOvenApp> createState() => _HappyOvenAppState();
}

class _HappyOvenAppState extends ConsumerState<HappyOvenApp> {
  StreamSubscription<Uri?>? _linkSubscription;

  @override
  void initState() {
    super.initState();
    _listenForDeepLinks();
  }

  Future<void> _listenForDeepLinks() async {
    final appLinks = AppLinks();
    final initialLink = await appLinks.getInitialLink();
    _handleDeepLink(initialLink);

    _linkSubscription = appLinks.uriLinkStream.listen((uri) {
      _handleDeepLink(uri);
    });
  }

  void _handleDeepLink(Uri? uri) {
    if (uri == null) return;

    final isResetLink =
        uri.scheme == 'happyoven' &&
        (uri.host == 'reset-password' ||
            uri.path == '/reset-password' ||
            uri.path == 'reset-password');

    if (!isResetLink) return;

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      ref.read(appRouterProvider).go('/reset-password');
    });
  }

  @override
  void dispose() {
    _linkSubscription?.cancel();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
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
      theme: AppTheme.themeData(Brightness.light),
      darkTheme: AppTheme.themeData(Brightness.dark),
      routerConfig: router,
    );
  }
}
