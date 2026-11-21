import 'dart:convert';
import 'dart:math';
import 'package:crypto/crypto.dart';

class PasswordHashResult {
  final String hash;
  final String salt;

  const PasswordHashResult({required this.hash, required this.salt});
}

class SecurityService {
  static final Random _secureRandom = Random.secure();

  /// Generates a random cryptographic salt (hex-encoded)
  static String generateSalt([int length = 16]) {
    final values = List<int>.generate(length, (_) => _secureRandom.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Hashes a password using SHA-256 with the given salt
  static PasswordHashResult hashPassword(String password, [String? existingSalt]) {
    final salt = existingSalt ?? generateSalt();
    final bytes = utf8.encode('$salt:$password:$salt');
    final digest = sha256.convert(bytes);
    return PasswordHashResult(hash: digest.toString(), salt: salt);
  }

  /// Verifies a password against a stored hash and salt
  static bool verifyPassword({
    required String password,
    required String storedHash,
    required String storedSalt,
  }) {
    final calculated = hashPassword(password, storedSalt);
    return calculated.hash == storedHash;
  }

  /// Generates a secure, URL-safe single-use token (32 hex characters)
  static String generateSecureToken([int byteLength = 24]) {
    final values = List<int>.generate(byteLength, (_) => _secureRandom.nextInt(256));
    return values.map((b) => b.toRadixString(16).padLeft(2, '0')).join();
  }

  /// Validates password strength (0: Too weak, 1: Weak, 2: Fair, 3: Good, 4: Botanist Strong)
  static int evaluatePasswordStrength(String password) {
    if (password.isEmpty) return 0;
    int score = 0;
    if (password.length >= 6) score++;
    if (password.length >= 8 && RegExp(r'[A-Z]').hasMatch(password)) score++;
    if (RegExp(r'[0-9]').hasMatch(password)) score++;
    if (RegExp(r'[^A-Za-z0-9]').hasMatch(password)) score++;
    return score;
  }
}
