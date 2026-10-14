import 'dart:convert';
import 'dart:math';

import 'package:crypto/crypto.dart';
import 'package:flutter/foundation.dart' show compute;
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

/// Outcome of a PIN check. When [lockedFor] is non-null the PIN was NOT
/// evaluated (or the attempt just triggered a lockout) and the caller should
/// show a countdown instead of letting the user retry.
class PinCheckResult {
  final bool ok;
  final Duration? lockedFor;

  /// Wrong attempts left before the next temporary lockout starts.
  final int attemptsLeft;

  const PinCheckResult({required this.ok, this.lockedFor, this.attemptsLeft = 0});

  bool get isLocked => lockedFor != null;
}

/// "0:30", "5:00" — for lockout countdowns.
String formatLockDuration(Duration d) {
  final total = d.inSeconds < 0 ? 0 : (d.inMilliseconds / 1000).ceil();
  return '${total ~/ 60}:${(total % 60).toString().padLeft(2, '0')}';
}

class SecurityService {
  SecurityService._internal();

  static final SecurityService _instance = SecurityService._internal();

  factory SecurityService() => _instance;

  static const String _pinKey = 'user_pin_hash';
  static const String _failCountKey = 'pin_fail_count';
  static const String _lockedUntilKey = 'pin_locked_until_ms';

  /// PBKDF2-HMAC-SHA256 work factor. A 4–6 digit PIN only has 10^4–10^6
  /// possibilities, so this is about making every offline guess expensive;
  /// the lockout below is the real defence against on-device guessing.
  static const int _pbkdf2Iterations = 60000;

  /// Failures allowed before the first lockout.
  static const int _freeAttempts = 5;

  /// Lockout length for the 5th, 6th, 7th, ... failure (last one repeats).
  static const List<int> _lockSeconds = [30, 60, 120, 300, 900];

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
    final hash = await _hashPin(sanitizedPin, salt, _pbkdf2Iterations);
    await _secureStorage.write(key: _pinKey, value: 'v2:$_pbkdf2Iterations:$salt:$hash');
    await _resetFailures();
  }

  Future<void> clearPin() async {
    await _secureStorage.delete(key: _pinKey);
    await _resetFailures();
  }

  /// Remaining lockout time, or null if PIN entry is currently allowed.
  Future<Duration?> lockRemaining() async {
    final raw = await _secureStorage.read(key: _lockedUntilKey);
    final until = int.tryParse(raw ?? '');
    if (until == null) return null;
    final remaining = until - DateTime.now().millisecondsSinceEpoch;
    return remaining > 0 ? Duration(milliseconds: remaining) : null;
  }

  /// Checks [pin], enforcing the lockout and counting failures.
  Future<PinCheckResult> checkPin(String pin) async {
    final locked = await lockRemaining();
    if (locked != null) return PinCheckResult(ok: false, lockedFor: locked);

    final sanitizedPin = pin.trim();
    final stored = await _secureStorage.read(key: _pinKey);
    final parsed = _parse(stored);

    var ok = false;
    if (sanitizedPin.isNotEmpty && parsed != null) {
      final candidate = await _hashPin(sanitizedPin, parsed.salt, parsed.iterations);
      ok = _constantTimeEquals(parsed.hash, candidate);
    }

    if (ok) {
      await _resetFailures();
      // Silently upgrade a legacy single-round SHA-256 PIN to PBKDF2.
      if (parsed!.legacy) await setPin(sanitizedPin);
      return const PinCheckResult(ok: true);
    }

    final failures = (int.tryParse(await _secureStorage.read(key: _failCountKey) ?? '') ?? 0) + 1;
    await _secureStorage.write(key: _failCountKey, value: '$failures');

    if (failures >= _freeAttempts) {
      final step = failures - _freeAttempts;
      final seconds = _lockSeconds[step >= _lockSeconds.length ? _lockSeconds.length - 1 : step];
      final lock = Duration(seconds: seconds);
      await _secureStorage.write(
        key: _lockedUntilKey,
        value: '${DateTime.now().add(lock).millisecondsSinceEpoch}',
      );
      return PinCheckResult(ok: false, lockedFor: lock);
    }
    return PinCheckResult(ok: false, attemptsLeft: _freeAttempts - failures);
  }

  /// Convenience wrapper: true only for a correct PIN while not locked out.
  Future<bool> verifyPin(String pin) async => (await checkPin(pin)).ok;

  Future<void> _resetFailures() async {
    await _secureStorage.delete(key: _failCountKey);
    await _secureStorage.delete(key: _lockedUntilKey);
  }

  /// Stored formats:
  ///   v2:<iterations>:<salt>:<hash>   PBKDF2-HMAC-SHA256
  ///   <salt>:<hash>                   legacy, one round of SHA-256(salt+pin)
  _StoredPin? _parse(String? value) {
    if (value == null || value.isEmpty) return null;
    final parts = value.split(':');
    if (parts.length == 4 && parts[0] == 'v2') {
      final iterations = int.tryParse(parts[1]);
      if (iterations == null || iterations <= 0) return null;
      return _StoredPin(salt: parts[2], hash: parts[3], iterations: iterations, legacy: false);
    }
    if (parts.length == 2) {
      return _StoredPin(salt: parts[0], hash: parts[1], iterations: 0, legacy: true);
    }
    return null;
  }

  /// iterations == 0 means the legacy scheme.
  Future<String> _hashPin(String pin, String salt, int iterations) {
    if (iterations == 0) {
      return Future.value(sha256.convert(utf8.encode('$salt$pin')).toString());
    }
    // Run off the UI isolate so the unlock screen doesn't freeze.
    return compute(_pbkdf2Hex, <Object>[pin, salt, iterations]);
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

class _StoredPin {
  final String salt;
  final String hash;
  final int iterations;
  final bool legacy;
  const _StoredPin({required this.salt, required this.hash, required this.iterations, required this.legacy});
}

/// PBKDF2-HMAC-SHA256, 32-byte output (a single block, so no block loop).
/// Top-level so it can run in a background isolate via `compute`.
String _pbkdf2Hex(List<Object> args) {
  final pin = args[0] as String;
  final salt = args[1] as String;
  final iterations = args[2] as int;

  final hmac = Hmac(sha256, utf8.encode(pin));
  // U1 = HMAC(pin, salt || INT_32_BE(1))
  var u = hmac.convert([...utf8.encode(salt), 0, 0, 0, 1]).bytes;
  final t = List<int>.from(u);
  for (var i = 1; i < iterations; i++) {
    u = hmac.convert(u).bytes;
    for (var j = 0; j < t.length; j++) {
      t[j] ^= u[j];
    }
  }
  return t.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
}
