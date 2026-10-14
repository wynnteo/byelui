import 'package:flutter/services.dart';
import 'package:local_auth/local_auth.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../i18n/s.dart';

enum BiometricAuthResult {
  success,
  userCanceled,
  authenticationFailed,
  error,
  notAvailable,
  notEnrolled
}

class BiometricAuthResponse {
  final BiometricAuthResult result;
  final String? errorMessage;

  BiometricAuthResponse({required this.result, this.errorMessage});

  bool get isSuccess => result == BiometricAuthResult.success;
  bool get isUserCanceled => result == BiometricAuthResult.userCanceled;
}

class BiometricService {
  static final LocalAuthentication _localAuth = LocalAuthentication();
  static const String _biometricEnabledKey = 'biometric_enabled';

  // Check if biometric authentication is available on the device
  static Future<bool> isBiometricAvailable() async {
    try {
      final bool isAvailable = await _localAuth.canCheckBiometrics;
      final bool isDeviceSupported = await _localAuth.isDeviceSupported();
      return isAvailable && isDeviceSupported;
    } catch (e) {
      print('Biometric availability check error: $e');
      return false;
    }
  }

  // Get available biometric types
  static Future<List<BiometricType>> getAvailableBiometrics() async {
    try {
      return await _localAuth.getAvailableBiometrics();
    } catch (e) {
      print('Get available biometrics error: $e');
      return [];
    }
  }

  // Improved authenticate method with better error handling
  static Future<BiometricAuthResponse> authenticate() async {
    try {
      // Check if biometric is available first
      final bool canUse = await canUseBiometric();
      if (!canUse) {
        return BiometricAuthResponse(
            result: BiometricAuthResult.notAvailable,
            errorMessage: S.t.bioNotAvailableOrSetup
        );
      }

      final bool isAuthenticated = await _localAuth.authenticate(
        localizedReason: S.t.bioReason,
        options: const AuthenticationOptions(
          biometricOnly: false,
          stickyAuth: true,
        ),
      );

      if (isAuthenticated) {
        return BiometricAuthResponse(result: BiometricAuthResult.success);
      } else {
        // Authentication returned false - this could be user cancellation
        return BiometricAuthResponse(
            result: BiometricAuthResult.userCanceled,
            errorMessage: S.t.bioCanceled
        );
      }
    } on PlatformException catch (e) {
      print('Platform exception during authentication: $e');

      // Handle specific platform exceptions
      switch (e.code) {
        case 'NotAvailable':
          return BiometricAuthResponse(
              result: BiometricAuthResult.notAvailable,
              errorMessage: S.t.bioNotAvailableDevice
          );
        case 'NotEnrolled':
          return BiometricAuthResponse(
              result: BiometricAuthResult.notEnrolled,
              errorMessage: S.t.bioNotEnrolled
          );
        case 'UserCancel':
        case 'UserFallback':
          return BiometricAuthResponse(
              result: BiometricAuthResult.userCanceled,
              errorMessage: S.t.bioCanceledByUser
          );
        case 'AuthenticationFailed':
        case 'BiometricAuthenticationFailed':
          return BiometricAuthResponse(
              result: BiometricAuthResult.authenticationFailed,
              errorMessage: S.t.bioFailed
          );
        default:
          return BiometricAuthResponse(
              result: BiometricAuthResult.error,
              errorMessage: e.message ?? S.t.bioUnknown
          );
      }
    } catch (e) {
      print('General error during authentication: $e');
      return BiometricAuthResponse(
          result: BiometricAuthResult.error,
          errorMessage: 'Authentication error: ${e.toString()}'
      );
    }
  }

  // Backward compatibility - returns simple boolean
  static Future<bool> authenticateSimple() async {
    final response = await authenticate();
    return response.isSuccess;
  }

  // Check if biometric setting is enabled in app settings
  static Future<bool> isBiometricEnabled() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool(_biometricEnabledKey) ?? false;
    } catch (e) {
      print('Get biometric enabled error: $e');
      return false;
    }
  }

  // Enable/disable biometric setting
  static Future<void> setBiometricEnabled(bool enabled) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setBool(_biometricEnabledKey, enabled);
    } catch (e) {
      print('Set biometric enabled error: $e');
      throw Exception(S.t.bioSaveFailed);
    }
  }

  static String getBiometricDescription(List<BiometricType> biometrics) {
    if (biometrics.isEmpty) return S.t.bioNone;

    final List<String> types = [];

    if (biometrics.contains(BiometricType.fingerprint)) {
      types.add(S.t.fingerprint);
    }
    if (biometrics.contains(BiometricType.face)) {
      types.add(S.t.faceId);
    }
    if (biometrics.contains(BiometricType.iris)) {
      types.add(S.t.iris);
    }
    if (biometrics.contains(BiometricType.strong)) {
      types.add(S.t.strongBiometric);
    }
    if (biometrics.contains(BiometricType.weak)) {
      types.add(S.t.weakBiometric);
    }

    if (types.isEmpty) {
      return S.t.bioAvailable;
    }

    return S.t.typesAvailable(types.join(S.isChinese ? '、' : ', '));
  }

  static Future<bool> canUseBiometric() async {
    try {
      final LocalAuthentication auth = LocalAuthentication();

      // Check if device supports biometric
      final bool isDeviceSupported = await auth.isDeviceSupported();
      if (!isDeviceSupported) return false;

      // Check if user can check biometrics (hardware available)
      final bool canCheckBiometrics = await auth.canCheckBiometrics;
      if (!canCheckBiometrics) return false;

      // Check if biometrics are enrolled
      final List<BiometricType> availableBiometrics = await auth.getAvailableBiometrics();
      return availableBiometrics.isNotEmpty;

    } catch (e) {
      return false;
    }
  }
}