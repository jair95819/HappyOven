import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:happy_oven/core/widgets/bottom_nav_bar.dart';
import 'package:happy_oven/core/providers.dart';
import 'package:happy_oven/features/analitica_alertas/presentation/viewmodels/dashboard_viewmodel.dart';

class AppShell extends ConsumerStatefulWidget {
  final StatefulNavigationShell navigationShell;

  const AppShell({super.key, required this.navigationShell});

  @override
  ConsumerState<AppShell> createState() => _AppShellState();
}

class _AppShellState extends ConsumerState<AppShell> {
  int _previousBranchIndex = 0;

  @override
  void initState() {
    super.initState();
    _previousBranchIndex = widget.navigationShell.currentIndex;
    // Iniciar el monitoreo de stock cuando el usuario está autenticado
    WidgetsBinding.instance.addPostFrameCallback((_) async {
      final notifService = ref.read(notificationServiceProvider);
      await notifService.requestPermissions();
      ref.read(stockMonitorServiceProvider).startMonitoring();
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final currentIndex = widget.navigationShell.currentIndex;

    if (currentIndex == 0 && currentIndex != _previousBranchIndex) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        ref.read(dashboardViewModelProvider.notifier).cargarDatos();
      });
    }

    _previousBranchIndex = currentIndex;

    return Scaffold(
      body: widget.navigationShell,
      bottomNavigationBar: BottomNavBar(navigationShell: widget.navigationShell),
    );
  }
}
