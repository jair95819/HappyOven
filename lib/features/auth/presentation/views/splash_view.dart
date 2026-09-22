import 'package:flutter/material.dart';
import 'package:happy_oven/core/theme/theme.dart';

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
                Container(
                  width: 140,
                  height: 140,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppTheme.colors.card,
                    border: Border.all(
                      color: AppTheme.colors.border,
                      width: 1.5,
                    ),
                    boxShadow: AppTheme.shadows.cardMd,
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(20),
                    child: Image.asset(
                      'assets/images/logo.png',
                      fit: BoxFit.contain,
                    ),
                  ),
                ),
                SizedBox(height: AppTheme.spacing.xl),
                Text(
                  'Happy Oven',
                  style: AppTheme.font.h2.copyWith(
                    color: AppTheme.colors.titleText,
                  ),
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
