import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart' show kIsWeb;
import '../state/app_state.dart';
import 'security_service.dart';
import 'email_service.dart';

class UserAccount {
  final String id;
  final String name;
  final String email;
  final String passwordHash;
  final String passwordSalt;
  final String municipality;
  final UserRole role;
  final String adminId;
  final bool isEmailVerified;
  final String? verificationToken;
  final DateTime? verificationTokenExpiresAt;
  final DateTime? verifiedAt;
  final String? resetToken;
  final DateTime? resetTokenExpiresAt;
  final DateTime createdAt;

  UserAccount({
    required this.id,
    required this.name,
    required this.email,
    required this.passwordHash,
    required this.passwordSalt,
    required this.municipality,
    required this.role,
    this.adminId = '',
    required this.isEmailVerified,
    this.verificationToken,
    this.verificationTokenExpiresAt,
    this.verifiedAt,
    this.resetToken,
    this.resetTokenExpiresAt,
    required this.createdAt,
  });

  bool get isAdmin => role == UserRole.administrator;

  UserAccount copyWith({
    String? name,
    String? email,
    String? passwordHash,
    String? passwordSalt,
    String? municipality,
    UserRole? role,
    String? adminId,
    bool? isEmailVerified,
    String? verificationToken,
    DateTime? verificationTokenExpiresAt,
    DateTime? verifiedAt,
    String? resetToken,
    DateTime? resetTokenExpiresAt,
  }) {
    return UserAccount(
      id: id,
      name: name ?? this.name,
      email: email ?? this.email,
      passwordHash: passwordHash ?? this.passwordHash,
      passwordSalt: passwordSalt ?? this.passwordSalt,
      municipality: municipality ?? this.municipality,
      role: role ?? this.role,
      adminId: adminId ?? this.adminId,
      isEmailVerified: isEmailVerified ?? this.isEmailVerified,
      verificationToken: verificationToken,
      verificationTokenExpiresAt: verificationTokenExpiresAt,
      verifiedAt: verifiedAt ?? this.verifiedAt,
      resetToken: resetToken,
      resetTokenExpiresAt: resetTokenExpiresAt,
      createdAt: createdAt,
    );
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'name': name,
        'email': email,
        'passwordHash': passwordHash,
        'passwordSalt': passwordSalt,
        'municipality': municipality,
        'role': role.name,
        'adminId': adminId,
        'isEmailVerified': isEmailVerified,
        'verificationToken': verificationToken,
        'verificationTokenExpiresAt': verificationTokenExpiresAt?.toIso8601String(),
        'verifiedAt': verifiedAt?.toIso8601String(),
        'resetToken': resetToken,
        'resetTokenExpiresAt': resetTokenExpiresAt?.toIso8601String(),
        'createdAt': createdAt.toIso8601String(),
      };

  factory UserAccount.fromJson(Map<String, dynamic> json) {
    return UserAccount(
      id: json['id'] as String,
      name: json['name'] as String,
      email: json['email'] as String,
      passwordHash: json['passwordHash'] as String,
      passwordSalt: json['passwordSalt'] as String,
      municipality: json['municipality'] as String? ?? 'Virac',
      role: UserRole.values.firstWhere(
        (r) => r.name == json['role'],
        orElse: () => UserRole.communityMember,
      ),
      adminId: json['adminId'] as String? ?? '',
      isEmailVerified: json['isEmailVerified'] as bool? ?? false,
      verificationToken: json['verificationToken'] as String?,
      verificationTokenExpiresAt: json['verificationTokenExpiresAt'] != null
          ? DateTime.tryParse(json['verificationTokenExpiresAt'] as String)
          : null,
      verifiedAt: json['verifiedAt'] != null
          ? DateTime.tryParse(json['verifiedAt'] as String)
          : null,
      resetToken: json['resetToken'] as String?,
      resetTokenExpiresAt: json['resetTokenExpiresAt'] != null
          ? DateTime.tryParse(json['resetTokenExpiresAt'] as String)
          : null,
      createdAt: json['createdAt'] != null
          ? DateTime.tryParse(json['createdAt'] as String) ?? DateTime.now()
          : DateTime.now(),
    );
  }
}

class AuthResult {
  final bool success;
  final UserAccount? user;
  final String? errorMessage;
  final bool requiresVerification;

  const AuthResult({
    required this.success,
    this.user,
    this.errorMessage,
    this.requiresVerification = false,
  });
}

class VerificationResult {
  final bool success;
  final String message;
  final bool isExpired;
  final bool isAlreadyVerified;

  const VerificationResult({
    required this.success,
    required this.message,
    this.isExpired = false,
    this.isAlreadyVerified = false,
  });
}

class ResetTokenStatus {
  final bool isValid;
  final bool isExpired;
  final UserAccount? user;
  final String message;

  const ResetTokenStatus({
    required this.isValid,
    required this.isExpired,
    this.user,
    required this.message,
  });
}

class AuthDatabase {
  final String? dbFilePath;
  final EmailService emailService;
  final Map<String, UserAccount> _usersByEmail = {};

  AuthDatabase({
    this.dbFilePath = 'data/herbacat_auth_db.json',
    EmailService? emailService,
  }) : emailService = emailService ?? EmailService() {
    _loadOrSeedDatabase();
  }

  void _loadOrSeedDatabase() {
    if (!kIsWeb && dbFilePath != null && dbFilePath!.isNotEmpty) {
      try {
        final file = File(dbFilePath!);
        if (file.existsSync()) {
          final content = file.readAsStringSync();
          if (content.trim().isNotEmpty) {
            final List<dynamic> jsonList = jsonDecode(content);
            for (final item in jsonList) {
              final acc = UserAccount.fromJson(item as Map<String, dynamic>);
              _usersByEmail[acc.email.toLowerCase()] = acc;
            }
            return;
          }
        }
      } catch (_) {
        // In testing or fallback environments, seed defaults
      }
    }

    // Seed default baseline accounts
    _seedDefaultAccounts();
  }

  void _seedDefaultAccounts() {
    _usersByEmail.clear();

    // 1. System Administrator (Maria Santos)
    final adminHash = SecurityService.hashPassword('AdminPassword123!');
    final adminUser = UserAccount(
      id: 'usr_admin_001',
      name: 'Maria Santos',
      email: 'maria.santos@catanduanes.gov.ph',
      passwordHash: adminHash.hash,
      passwordSalt: adminHash.salt,
      municipality: 'Virac',
      role: UserRole.administrator,
      adminId: '#1042',
      isEmailVerified: true,
      verifiedAt: DateTime.now().subtract(const Duration(days: 30)),
      createdAt: DateTime.now().subtract(const Duration(days: 30)),
    );
    _usersByEmail[adminUser.email.toLowerCase()] = adminUser;

    // 2. Verified Community User (Juan Dela Cruz)
    final commHash = SecurityService.hashPassword('Community123!');
    final communityUser = UserAccount(
      id: 'usr_comm_001',
      name: 'Juan Dela Cruz',
      email: 'juan.delacruz@gmail.com',
      passwordHash: commHash.hash,
      passwordSalt: commHash.salt,
      municipality: 'San Andres',
      role: UserRole.communityMember,
      isEmailVerified: true,
      verifiedAt: DateTime.now().subtract(const Duration(days: 10)),
      createdAt: DateTime.now().subtract(const Duration(days: 10)),
    );
    _usersByEmail[communityUser.email.toLowerCase()] = communityUser;

    // 3. Unverified Community User for testing
    final unverifiedHash = SecurityService.hashPassword('Unverified123!');
    final unverifiedUser = UserAccount(
      id: 'usr_unver_001',
      name: 'New Explorer',
      email: 'new.explorer@catanduanes.org',
      passwordHash: unverifiedHash.hash,
      passwordSalt: unverifiedHash.salt,
      municipality: 'Pandan',
      role: UserRole.communityMember,
      isEmailVerified: false,
      verificationToken: 'test_unverified_token_12345',
      verificationTokenExpiresAt: DateTime.now().add(const Duration(hours: 24)),
      createdAt: DateTime.now().subtract(const Duration(minutes: 30)),
    );
    _usersByEmail[unverifiedUser.email.toLowerCase()] = unverifiedUser;

    _saveToDisk();
  }

  void _saveToDisk() {
    if (kIsWeb || dbFilePath == null || dbFilePath!.isEmpty) return;
    try {
      final file = File(dbFilePath!);
      final dir = file.parent;
      if (!dir.existsSync()) {
        dir.createSync(recursive: true);
      }
      final list = _usersByEmail.values.map((u) => u.toJson()).toList();
      file.writeAsStringSync(const JsonEncoder.withIndent('  ').convert(list));
    } catch (_) {
      // Ignored if file system is sandboxed/read-only
    }
  }

  /// Reset in-memory and saved database back to default accounts (ideal for automated test isolation)
  void resetDatabaseToDefaults() {
    _seedDefaultAccounts();
  }

  List<UserAccount> getAllUsers() => List.unmodifiable(_usersByEmail.values);

  UserAccount? getUserByEmail(String email) => _usersByEmail[email.trim().toLowerCase()];

  /// User Registration with Password Hashing & Verification Email
  Future<AuthResult> registerUser({
    required String name,
    required String email,
    required String password,
    required String municipality,
    required UserRole role,
  }) async {
    final normalizedEmail = email.trim().toLowerCase();

    // 1. Input validations
    if (name.trim().isEmpty) {
      return const AuthResult(success: false, errorMessage: 'Full name is required.');
    }
    if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(normalizedEmail)) {
      return const AuthResult(success: false, errorMessage: 'Please enter a valid email address.');
    }
    if (password.length < 8) {
      return const AuthResult(success: false, errorMessage: 'Password must be at least 8 characters long.');
    }

    // 2. Security rule: Community users cannot register as administrator
    final safeRole = role == UserRole.administrator ? UserRole.communityMember : role;

    // 3. Duplicate check
    if (_usersByEmail.containsKey(normalizedEmail)) {
      return const AuthResult(
        success: false,
        errorMessage: 'An account with this email address already exists. Please log in.',
      );
    }

    // 4. Secure Password Hashing
    final hashResult = SecurityService.hashPassword(password);

    // 5. Secure Verification Token
    final verificationToken = SecurityService.generateSecureToken();
    final tokenExpiration = DateTime.now().add(const Duration(hours: 24));

    final newUser = UserAccount(
      id: 'usr_${DateTime.now().millisecondsSinceEpoch}',
      name: name.trim(),
      email: normalizedEmail,
      passwordHash: hashResult.hash,
      passwordSalt: hashResult.salt,
      municipality: municipality.trim().isEmpty ? 'Virac' : municipality.trim(),
      role: safeRole,
      isEmailVerified: false,
      verificationToken: verificationToken,
      verificationTokenExpiresAt: tokenExpiration,
      createdAt: DateTime.now(),
    );

    _usersByEmail[normalizedEmail] = newUser;
    _saveToDisk();

    // 6. Send verification email
    await emailService.sendVerificationEmail(
      email: normalizedEmail,
      name: newUser.name,
      token: verificationToken,
    );

    return AuthResult(
      success: true,
      user: newUser,
      requiresVerification: true,
    );
  }

  /// Authenticate with email and password
  AuthResult authenticate({
    required String email,
    required String password,
  }) {
    final normalizedEmail = email.trim().toLowerCase();
    final user = _usersByEmail[normalizedEmail];

    if (user == null) {
      return const AuthResult(
        success: false,
        errorMessage: 'Invalid email or password. Please verify your credentials.',
      );
    }

    final isValid = SecurityService.verifyPassword(
      password: password,
      storedHash: user.passwordHash,
      storedSalt: user.passwordSalt,
    );

    if (!isValid) {
      return const AuthResult(
        success: false,
        errorMessage: 'Invalid email or password. Please verify your credentials.',
      );
    }

    return AuthResult(
      success: true,
      user: user,
      requiresVerification: !user.isEmailVerified,
    );
  }

  /// Verify email with single-use token
  VerificationResult verifyEmail(String token) {
    final trimmedToken = token.trim();
    if (trimmedToken.isEmpty) {
      return const VerificationResult(
        success: false,
        message: 'Verification token cannot be empty.',
      );
    }

    UserAccount? matchedUser;
    for (final u in _usersByEmail.values) {
      if (u.verificationToken == trimmedToken) {
        matchedUser = u;
        break;
      }
    }

    if (matchedUser == null) {
      // Check if this token was already used or account already verified
      return const VerificationResult(
        success: false,
        message: 'Invalid verification token or link. Please check the code or request a new one.',
      );
    }

    if (matchedUser.isEmailVerified) {
      return const VerificationResult(
        success: true,
        message: 'This account is already verified! You can proceed to explore.',
        isAlreadyVerified: true,
      );
    }

    // Check expiration
    if (matchedUser.verificationTokenExpiresAt != null &&
        DateTime.now().isAfter(matchedUser.verificationTokenExpiresAt!)) {
      return const VerificationResult(
        success: false,
        message: 'This verification link has expired (24 hours exceeded). Please request a new verification email.',
        isExpired: true,
      );
    }

    // Mark as verified & invalidate single-use token
    final updated = matchedUser.copyWith(
      isEmailVerified: true,
      verifiedAt: DateTime.now(),
      verificationToken: null,
      verificationTokenExpiresAt: null,
    );

    _usersByEmail[updated.email.toLowerCase()] = updated;
    _saveToDisk();

    return const VerificationResult(
      success: true,
      message: 'Email verified successfully! Your HerbaCat account is now fully active.',
    );
  }

  /// Resend verification email
  Future<VerificationResult> resendVerificationEmail(String email) async {
    final normalized = email.trim().toLowerCase();
    final user = _usersByEmail[normalized];

    if (user == null) {
      return const VerificationResult(
        success: false,
        message: 'No account found with this email address.',
      );
    }

    if (user.isEmailVerified) {
      return const VerificationResult(
        success: true,
        message: 'Your account is already verified.',
        isAlreadyVerified: true,
      );
    }

    final newToken = SecurityService.generateSecureToken();
    final newExpiry = DateTime.now().add(const Duration(hours: 24));

    final updated = user.copyWith(
      verificationToken: newToken,
      verificationTokenExpiresAt: newExpiry,
    );

    _usersByEmail[normalized] = updated;
    _saveToDisk();

    await emailService.sendVerificationEmail(
      email: normalized,
      name: user.name,
      token: newToken,
    );

    return const VerificationResult(
      success: true,
      message: 'A fresh verification email has been sent. Please check your inbox.',
    );
  }

  /// Request Password Reset
  Future<AuthResult> requestPasswordReset(String email) async {
    final normalized = email.trim().toLowerCase();
    if (normalized.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(normalized)) {
      return const AuthResult(
        success: false,
        errorMessage: 'Please enter a valid email address.',
      );
    }

    final user = _usersByEmail[normalized];
    if (user == null) {
      return const AuthResult(
        success: false,
        errorMessage: 'No account registered with this email address. Please verify your email or register.',
      );
    }

    final resetToken = SecurityService.generateSecureToken();
    final resetExpiry = DateTime.now().add(const Duration(hours: 1)); // 1 hour expiration

    final updated = user.copyWith(
      resetToken: resetToken,
      resetTokenExpiresAt: resetExpiry,
    );

    _usersByEmail[normalized] = updated;
    _saveToDisk();

    await emailService.sendPasswordResetEmail(
      email: normalized,
      name: user.name,
      token: resetToken,
    );

    return AuthResult(
      success: true,
      user: updated,
    );
  }

  /// Validate Reset Token
  ResetTokenStatus validateResetToken(String token) {
    final trimmed = token.trim();
    if (trimmed.isEmpty) {
      return const ResetTokenStatus(
        isValid: false,
        isExpired: false,
        message: 'Reset token cannot be empty.',
      );
    }

    UserAccount? matchedUser;
    for (final u in _usersByEmail.values) {
      if (u.resetToken == trimmed) {
        matchedUser = u;
        break;
      }
    }

    if (matchedUser == null) {
      return const ResetTokenStatus(
        isValid: false,
        isExpired: false,
        message: 'This password reset link is invalid or has already been used.',
      );
    }

    if (matchedUser.resetTokenExpiresAt != null &&
        DateTime.now().isAfter(matchedUser.resetTokenExpiresAt!)) {
      return ResetTokenStatus(
        isValid: false,
        isExpired: true,
        user: matchedUser,
        message: 'This password reset link has expired. Please request a new one.',
      );
    }

    return ResetTokenStatus(
      isValid: true,
      isExpired: false,
      user: matchedUser,
      message: 'Token is valid.',
    );
  }

  /// Complete Password Reset
  Future<AuthResult> resetPassword({
    required String token,
    required String newPassword,
  }) async {
    final status = validateResetToken(token);
    if (!status.isValid) {
      return AuthResult(success: false, errorMessage: status.message);
    }

    if (newPassword.length < 8) {
      return const AuthResult(
        success: false,
        errorMessage: 'Password must be at least 8 characters long.',
      );
    }

    final user = status.user!;
    final newHash = SecurityService.hashPassword(newPassword);

    // Invalidate reset token upon successful use (single-use token requirement)
    final updated = user.copyWith(
      passwordHash: newHash.hash,
      passwordSalt: newHash.salt,
      resetToken: null,
      resetTokenExpiresAt: null,
    );

    _usersByEmail[updated.email.toLowerCase()] = updated;
    _saveToDisk();

    return AuthResult(
      success: true,
      user: updated,
    );
  }
}
