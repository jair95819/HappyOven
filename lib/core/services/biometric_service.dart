import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

/// Envoltura de `local_auth` para el ingreso por huella / Face ID.
/// Nunca lanza excepciones: cualquier fallo de la plataforma se traduce
/// en `false`, para que la UI pueda caer al login con contraseña.
class BiometricService {
  final LocalAuthentication _auth;

  BiometricService({LocalAuthentication? auth})
    : _auth = auth ?? LocalAuthentication();

  /// Verdadero si el dispositivo tiene biometría y al menos una huella/rostro
  /// registrado.
  Future<bool> disponible() async {
    try {
      if (!await _auth.isDeviceSupported()) return false;
      final registradas = await _auth.getAvailableBiometrics();
      return registradas.isNotEmpty;
    } catch (e) {
      debugPrint('Biometría no disponible: $e');
      return false;
    }
  }

  /// Muestra el diálogo biométrico del sistema. Devuelve `true` solo si el
  /// usuario se autenticó correctamente.
  Future<bool> autenticar(String motivo) async {
    try {
      return await _auth.authenticate(
        localizedReason: motivo,
        biometricOnly: true,
        persistAcrossBackgrounding: true,
      );
    } catch (e) {
      debugPrint('Autenticación biométrica fallida: $e');
      return false;
    }
  }
}
