import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/core/widgets/bottom_nav_bar.dart';
import 'package:happy_oven/core/providers.dart';

class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  @override
  void initState() {
    super.initState();
    // Iniciar el monitoreo de stock cuando el usuario está autenticado
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifService = ref.read(notificationServiceProvider);
      await notifService.requestPermissions();
      ref.read(stockMonitorServiceProvider).startMonitoring();
    });
  }

  @override
  void dispose() {
    // No podemos acceder a ref en dispose, pero el servicio se limpiará
    // al destruirse el provider scope
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: BottomNavBar(navigationShell: widget.navigationShell),
    );
  }
}
