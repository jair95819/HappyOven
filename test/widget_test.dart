import 'package:flutter_test/flutter_test.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:happy_oven/core/providers.dart';
import 'package:happy_oven/core/services/biometric_service.dart';
import 'package:happy_oven/core/services/local_storage_service.dart';
import 'package:happy_oven/main.dart';
import 'package:happy_oven/features/auth/presentation/views/login_view.dart';
import 'package:shared_preferences/shared_preferences.dart';

class _SinBiometria extends BiometricService {
  @override
  Future<bool> disponible() async => false;
}

void main() {
  testWidgets('App loads correctly', (WidgetTester tester) async {
    SharedPreferences.setMockInitialValues({});
    await LocalStorageService().initialize();

    await tester.pumpWidget(
      ProviderScope(
        overrides: [
          biometricServiceProvider.overrideWithValue(_SinBiometria()),
        ],
        child: const HappyOvenApp(),
      ),
    );
    // Sin sesión guardada, la restauración termina y el router lleva a /login.
    for (var i = 0; i < 5; i++) {
      await tester.pump();
    }
    expect(find.byType(LoginView), findsOneWidget);
  });
}
