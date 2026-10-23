import 'package:flutter/foundation.dart';
import 'package:local_auth/local_auth.dart';

class BiometricService {
  final LocalAuthentication auth = LocalAuthentication();

  Future<bool> authenticate() async {
    try {
      final canCheck = await auth.canCheckBiometrics;
      final supported = await auth.isDeviceSupported();
      final available = await auth.getAvailableBiometrics();

      debugPrint("canCheckBiometrics = $canCheck");
      debugPrint("isDeviceSupported = $supported");
      debugPrint("availableBiometrics = $available");

      final authenticated = await auth.authenticate(
        localizedReason: "Unlock Smart AI Expense Tracker",
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      debugPrint("authenticated = $authenticated");

      return authenticated;
    } catch (e) {
      debugPrint("Biometric Error: $e");
      return false;
    }
  }
}