import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../state/app_state.dart';
import 'reset_password_screen.dart';
import 'login_screen.dart';

class ForgotPasswordScreen extends StatefulWidget {
  final AppState appState;

  const ForgotPasswordScreen({super.key, required this.appState});

  @override
  State<ForgotPasswordScreen> createState() => _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState extends State<ForgotPasswordScreen> {
  final _emailController = TextEditingController();
  final _manualTokenController = TextEditingController();
  bool _isLoading = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void dispose() {
    _emailController.dispose();
    _manualTokenController.dispose();
    super.dispose();
  }

  Future<void> _handleSendResetLink() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter your registered email address.';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isLoading = true;
      _statusMessage = null;
    });

    final result = await widget.appState.requestPasswordReset(email);

    setState(() {
      _isLoading = false;
      if (result.success) {
        _isSuccess = true;
        _statusMessage =
            'A secure password reset link and single-use code have been sent to $email. It expires in 1 hour.';
      } else {
        _isSuccess = false;
        _statusMessage = result.errorMessage ?? 'Unable to send password reset request.';
      }
    });
  }

  void _showLocalOutboxSheet() {
    final outbox = widget.appState.authDatabase.emailService.outbox;
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (ctx) {
        return Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Local Email Outbox', style: AppTypography.headlineSm()),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.of(ctx).pop(),
                  ),
                ],
              ),
              const Divider(),
              if (outbox.isEmpty)
                Padding(
                  padding: const EdgeInsets.symmetric(vertical: 24),
                  child: Center(
                    child: Text('No emails in outbox yet.', style: AppTypography.bodyMd()),
                  ),
                )
              else
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: outbox.length,
                    itemBuilder: (context, idx) {
                      final item = outbox[idx];
                      return Container(
                        margin: const EdgeInsets.only(bottom: 10),
                        padding: const EdgeInsets.all(12),
                        decoration: BoxDecoration(
                          color: AppColors.surfaceContainerLowest,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.4)),
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text(item.recipient, style: AppTypography.labelMd(color: AppColors.primary)),
                                Text(
                                  item.deliveredViaSmtp ? 'Delivered (SMTP)' : 'Local Outbox',
                                  style: AppTypography.labelSm(
                                    color: item.deliveredViaSmtp ? AppColors.tertiary : AppColors.secondary,
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(item.subject, style: AppTypography.bodySm()),
                            const SizedBox(height: 6),
                            SelectableText('Token: ${item.token}', style: const TextStyle(fontFamily: 'monospace', fontSize: 12)),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                Navigator.of(ctx).pop();
                                Navigator.of(context).push(
                                  MaterialPageRoute(
                                    builder: (_) => ResetPasswordScreen(
                                      appState: widget.appState,
                                      initialToken: item.token,
                                    ),
                                  ),
                                );
                              },
                              style: ElevatedButton.styleFrom(
                                backgroundColor: AppColors.primary,
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                              ),
                              child: const Text('Open Reset Page with Token', style: TextStyle(fontSize: 12)),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: Text('Forgot Password', style: AppTypography.headlineSm(color: AppColors.secondary)),
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
                decoration: const BoxDecoration(
                  color: AppColors.primaryFixed,
                  shape: BoxShape.circle,
                ),
                child: const Center(
                  child: Icon(
                    Icons.lock_reset,
                    color: AppColors.primary,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Text(
                'Reset Field Password',
                style: AppTypography.headlineLg(color: AppColors.onSurface),
              ),
              const SizedBox(height: 8),
              Text(
                'Enter your registered HerbaCat email address. We will send you a secure link to create a new password.',
                style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),

              if (_statusMessage != null) ...[
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: _isSuccess
                        ? AppColors.secondaryContainer.withValues(alpha: 0.6)
                        : AppColors.errorContainer.withValues(alpha: 0.7),
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: _isSuccess ? AppColors.tertiary : AppColors.error,
                      width: 1,
                    ),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        _isSuccess ? Icons.check_circle : Icons.error_outline,
                        color: _isSuccess ? AppColors.tertiary : AppColors.error,
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          _statusMessage!,
                          style: AppTypography.bodySm(
                            color: _isSuccess ? AppColors.onSecondaryContainer : AppColors.onErrorContainer,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
              ],

              // Email Input Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Registered Email Address', style: AppTypography.labelMd(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailController,
                    keyboardType: TextInputType.emailAddress,
                    decoration: const InputDecoration(
                      prefixIcon: Icon(Icons.mail_outline, color: AppColors.secondary),
                      hintText: 'e.g. maria.santos@catanduanes.gov.ph',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleSendResetLink,
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
                          'Send Password Reset Link',
                          style: AppTypography.labelLg(color: AppColors.onPrimary),
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Option to enter token directly
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Already have a reset code?', style: AppTypography.labelMd(color: AppColors.onSurface)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _manualTokenController,
                      decoration: const InputDecoration(
                        hintText: 'Paste single-use reset token',
                        prefixIcon: Icon(Icons.key, color: AppColors.secondary),
                      ),
                    ),
                    const SizedBox(height: 10),
                    SizedBox(
                      width: double.infinity,
                      child: OutlinedButton(
                        onPressed: () {
                          final tok = _manualTokenController.text.trim();
                          if (tok.isEmpty) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(content: Text('Please enter your reset code')),
                            );
                            return;
                          }
                          Navigator.of(context).push(
                            MaterialPageRoute(
                              builder: (_) => ResetPasswordScreen(
                                appState: widget.appState,
                                initialToken: tok,
                              ),
                            ),
                          );
                        },
                        style: OutlinedButton.styleFrom(
                          side: const BorderSide(color: AppColors.secondary),
                          shape: const StadiumBorder(),
                        ),
                        child: Text('Proceed to Reset Password', style: AppTypography.labelMd(color: AppColors.secondary)),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              // Developer helper
              OutlinedButton.icon(
                onPressed: _showLocalOutboxSheet,
                icon: const Icon(Icons.mark_email_unread_outlined, size: 16),
                label: const Text('View Outbox / Reset Link (Local Test)'),
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: AppColors.outlineVariant),
                  shape: const StadiumBorder(),
                ),
              ),

              const SizedBox(height: 24),
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
            ],
          ),
        ),
      ),
    );
  }
}
