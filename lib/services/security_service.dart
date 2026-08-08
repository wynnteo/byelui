import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';
class SecurityService {
  SecurityService._internal();

  static final SecurityService _instance = SecurityService._internal();

  factory SecurityService() => _instance;

  static const String _pinKey = 'user_pin_hash';

  final FlutterSecureStorage _secureStorage = const FlutterSecureStorage();
  final Random _random = Random.secure();

  Future<bool> hasPin() async {
    return await _secureStorage.containsKey(key: _pinKey);
  }

  Future<void> setPin(String pin) async {
    final sanitizedPin = pin.trim();
    if (sanitizedPin.isEmpty) {
      throw ArgumentError('PIN cannot be empty');
    }

    final salt = _generateSalt();
    final hash = _hashPin(sanitizedPin, salt);
    await _secureStorage.write(key: _pinKey, value: '$salt:$hash');
  }

  Future<void> clearPin() async {
    await _secureStorage.delete(key: _pinKey);
  }

  Future<bool> verifyPin(String pin) async {
    final sanitizedPin = pin.trim();
    if (sanitizedPin.isEmpty) {
      return false;
    }

    final storedValue = await _secureStorage.read(key: _pinKey);
    if (storedValue == null || storedValue.isEmpty) {
      return false;
    }

    final parts = storedValue.split(':');
    if (parts.length != 2) {
      return false;
    }

    final salt = parts.first;
    final expectedHash = parts.last;
    final candidateHash = _hashPin(sanitizedPin, salt);

    return _constantTimeEquals(expectedHash, candidateHash);
  }

  String _hashPin(String pin, String salt) {
    final bytes = utf8.encode('$salt$pin');
    final digest = sha256.convert(bytes);
    return digest.toString();
  }

  String _generateSalt() {
    final values = List<int>.generate(16, (_) => _random.nextInt(256));
    return base64Url.encode(values);
  }

  bool _constantTimeEquals(String a, String b) {
    if (a.length != b.length) {
      return false;
    }

    var result = 0;
    for (var i = 0; i < a.length; i++) {
      result |= a.codeUnitAt(i) ^ b.codeUnitAt(i);
    }
    return result == 0;
  }
}
