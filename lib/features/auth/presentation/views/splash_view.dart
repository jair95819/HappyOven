import 'package:flutter/material.dart';
import 'package:happy_oven/core/theme/theme.dart';
import 'package:happy_oven/core/widgets/ho_ui.dart';

class SplashView extends StatelessWidget {
  const SplashView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.colors.bg,
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: EdgeInsets.symmetric(horizontal: AppTheme.spacing.xl),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const HoLogo(size: 140),
                SizedBox(height: AppTheme.spacing.xl),
                Text(
                  'Happy Oven',
                  style: AppTheme.font.h2,
                ),
                SizedBox(height: AppTheme.spacing.sm),
                Text(
                  'Cargando tu entorno...',
                  style: AppTheme.font.bodySmall.copyWith(
                    color: AppTheme.colors.hint,
                  ),
                ),
                SizedBox(height: AppTheme.spacing.xl),
                SizedBox(
                  width: 32,
                  height: 32,
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    valueColor: AlwaysStoppedAnimation<Color>(
                      AppTheme.colors.primary,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
