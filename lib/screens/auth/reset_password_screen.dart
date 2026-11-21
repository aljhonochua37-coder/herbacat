import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../state/app_state.dart';
import '../../services/auth_database.dart';
import '../../services/security_service.dart';
import 'login_screen.dart';
import 'forgot_password_screen.dart';

class ResetPasswordScreen extends StatefulWidget {
  final AppState appState;
  final String? initialToken;

  const ResetPasswordScreen({
    super.key,
    required this.appState,
    this.initialToken,
  });

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  late final TextEditingController _tokenController;
  final _newPasswordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;
  String? _errorMessage;
  bool _isSuccess = false;

  ResetTokenStatus? _tokenStatus;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.initialToken ?? '');
    _validateCurrentToken();
  }

  @override
  void dispose() {
    _tokenController.dispose();
    _newPasswordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  void _validateCurrentToken() {
    final token = _tokenController.text.trim();
    if (token.isNotEmpty) {
      final status = widget.appState.validateResetToken(token);
      setState(() {
        _tokenStatus = status;
        _errorMessage = status.isValid ? null : status.message;
      });
    }
  }

  int get _passwordStrength => SecurityService.evaluatePasswordStrength(_newPasswordController.text);

  String get _strengthText {
    final s = _passwordStrength;
    if (_newPasswordController.text.isEmpty) return 'Too weak';
    switch (s) {
      case 1:
        return 'Weak';
      case 2:
        return 'Fair';
      case 3:
        return 'Good';
      case 4:
        return 'Botanist Strong';
      default:
        return 'Too weak';
    }
  }

  Color get _strengthColor {
    final s = _passwordStrength;
    if (_newPasswordController.text.isEmpty) return AppColors.outline;
    switch (s) {
      case 1:
        return AppColors.primary;
      case 2:
        return AppColors.primaryContainer;
      case 3:
        return AppColors.secondary;
      case 4:
        return AppColors.tertiary;
      default:
        return AppColors.outline;
    }
  }

  bool get _passwordsMatch =>
      _confirmPasswordController.text.isNotEmpty &&
      _confirmPasswordController.text == _newPasswordController.text;

  Future<void> _handleResetPassword() async {
    final token = _tokenController.text.trim();
    final newPass = _newPasswordController.text;
    final confirmPass = _confirmPasswordController.text;

    if (token.isEmpty) {
      setState(() => _errorMessage = 'Reset token is required.');
      return;
    }

    if (newPass.length < 8) {
      setState(() => _errorMessage = 'Password must be at least 8 characters long.');
      return;
    }

    if (newPass != confirmPass) {
      setState(() => _errorMessage = 'Passwords do not match. Please verify both fields.');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final result = await widget.appState.resetPassword(
      token: token,
      newPassword: newPass,
    );

    setState(() {
      _isLoading = false;
      if (result.success) {
        _isSuccess = true;
        _errorMessage = null;
      } else {
        _errorMessage = result.errorMessage ?? 'Unable to reset password.';
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Reset Password', style: AppTypography.headlineSm(color: AppColors.secondary)),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _isSuccess ? AppColors.secondaryContainer : AppColors.primaryFixed,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    _isSuccess ? Icons.check_circle : Icons.lock_reset,
                    color: _isSuccess ? AppColors.tertiary : AppColors.primary,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Text(
                _isSuccess ? 'Password Reset Successful!' : 'Create New Password',
                style: AppTypography.headlineLg(color: AppColors.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                _isSuccess
                    ? 'Your password has been securely updated using salted cryptographic hashing. You can now log in with your new password.'
                    : 'Choose a strong password to protect your Catanduanes field ethnobotanical journal.',
                style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 20),

              // Error or Token Status Banner
              if (_errorMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: AppColors.errorContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.error),
                  ),
                  child: Row(
                    children: [
                      const Icon(Icons.error_outline, color: AppColors.error, size: 20),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _errorMessage!,
                          style: AppTypography.bodySm(color: AppColors.onErrorContainer),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
              ],

              // Success View
              if (_isSuccess) ...[
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => LoginScreen(appState: widget.appState),
                        ),
                        (route) => false,
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.secondary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text('Proceed to Log In', style: AppTypography.labelLg(color: Colors.white)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ] else if (_tokenStatus != null && !_tokenStatus!.isValid) ...[
                // Token Expired or Invalid View
                const SizedBox(height: 10),
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => ForgotPasswordScreen(appState: widget.appState),
                        ),
                      );
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: Text('Request a New Reset Link', style: AppTypography.labelLg(color: Colors.white)),
                  ),
                ),
                const SizedBox(height: 12),
                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => LoginScreen(appState: widget.appState),
                      ),
                      (route) => false,
                    );
                  },
                  child: Text('Return to Login', style: AppTypography.labelMd(color: AppColors.outline)),
                ),
              ] else ...[
                // Token Field (Editable if needed)
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Reset Token', style: AppTypography.labelMd(color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _tokenController,
                      onChanged: (_) => _validateCurrentToken(),
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.key, color: AppColors.secondary),
                        hintText: 'Enter or paste single-use reset token',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // New Password Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('New Password', style: AppTypography.labelMd(color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _newPasswordController,
                      obscureText: _obscurePassword,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_outline, color: AppColors.secondary),
                        hintText: 'Minimum 8 characters',
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility : Icons.visibility_off,
                            color: AppColors.outline,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                      ),
                    ),
                    const SizedBox(height: 8),

                    // Password Strength Indicator
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text('Password strength', style: AppTypography.labelSm()),
                        Text(
                          _strengthText,
                          style: AppTypography.labelSm(color: _strengthColor).copyWith(fontWeight: FontWeight.w600),
                        ),
                      ],
                    ),
                    const SizedBox(height: 6),
                    Row(
                      children: List.generate(4, (index) {
                        final active = _passwordStrength > index;
                        return Expanded(
                          child: Container(
                            height: 6,
                            margin: EdgeInsets.only(right: index < 3 ? 6 : 0),
                            decoration: BoxDecoration(
                              color: active ? _strengthColor : AppColors.surfaceVariant,
                              borderRadius: BorderRadius.circular(9999),
                            ),
                          ),
                        );
                      }),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Confirm Password Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Confirm New Password', style: AppTypography.labelMd(color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _confirmPasswordController,
                      obscureText: _obscureConfirm,
                      onChanged: (_) => setState(() {}),
                      decoration: InputDecoration(
                        prefixIcon: const Icon(Icons.lock_reset, color: AppColors.secondary),
                        hintText: 'Re-enter your new password',
                        suffixIcon: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            if (_passwordsMatch)
                              const Padding(
                                padding: EdgeInsets.only(right: 8),
                                child: Icon(Icons.check_circle, color: AppColors.tertiary, size: 20),
                              ),
                            IconButton(
                              icon: Icon(
                                _obscureConfirm ? Icons.visibility : Icons.visibility_off,
                                color: AppColors.outline,
                              ),
                              onPressed: () => setState(() => _obscureConfirm = !_obscureConfirm),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 24),

                // Submit Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleResetPassword,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Save New Password',
                            style: AppTypography.labelLg(color: AppColors.onPrimary),
                          ),
                  ),
                ),
                const SizedBox(height: 16),

                TextButton(
                  onPressed: () {
                    Navigator.of(context).pushAndRemoveUntil(
                      MaterialPageRoute(
                        builder: (_) => LoginScreen(appState: widget.appState),
                      ),
                      (route) => false,
                    );
                  },
                  child: Text('Cancel and Return to Login', style: AppTypography.labelMd(color: AppColors.outline)),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
