import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/router/app_router.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://rfzsqcgiuroncdnnhpmp.supabase.co/rest/v1/',
    anonKey:
        'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJmenNxY2dpdXJvbmNkbm5ocG1wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NzgxMTcyMzUsImV4cCI6MjA5MzY5MzIzNX0._cAZIkuGVFb0EryM1rTvTUSkZpb0SfoLA72xl7Y6kUM',
  );

  runApp(const ProviderScope(child: HappyOvenApp()));
}

class HappyOvenApp extends ConsumerWidget {
  const HappyOvenApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    return MaterialApp.router(
      title: 'Happy Oven',
      debugShowCheckedModeBanner: false,
      routerConfig: router,
    );
  }
}
