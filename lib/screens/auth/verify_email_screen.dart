import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../state/app_state.dart';
import '../main_shell.dart';
import 'login_screen.dart';

class VerifyEmailScreen extends StatefulWidget {
  final AppState appState;
  final String? initialEmail;
  final String? initialToken;

  const VerifyEmailScreen({
    super.key,
    required this.appState,
    this.initialEmail,
    this.initialToken,
  });

  @override
  State<VerifyEmailScreen> createState() => _VerifyEmailScreenState();
}

class _VerifyEmailScreenState extends State<VerifyEmailScreen> {
  late final TextEditingController _tokenController;
  bool _isVerifying = false;
  bool _isResending = false;
  String? _statusMessage;
  bool _isSuccess = false;

  @override
  void initState() {
    super.initState();
    _tokenController = TextEditingController(text: widget.initialToken ?? '');
    if (widget.initialToken != null && widget.initialToken!.isNotEmpty) {
      // Auto-verify if token is provided via deep-link
      WidgetsBinding.instance.addPostFrameCallback((_) {
        _handleVerify();
      });
    }
  }

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  String get _targetEmail {
    if (widget.initialEmail != null && widget.initialEmail!.isNotEmpty) {
      return widget.initialEmail!;
    }
    return widget.appState.currentUser.email;
  }

  Future<void> _handleVerify() async {
    final token = _tokenController.text.trim();
    if (token.isEmpty) {
      setState(() {
        _statusMessage = 'Please enter or paste your verification code.';
        _isSuccess = false;
      });
      return;
    }

    setState(() {
      _isVerifying = true;
      _statusMessage = null;
    });

    final result = widget.appState.verifyEmail(token);

    setState(() {
      _isVerifying = false;
      _statusMessage = result.message;
      _isSuccess = result.success;
    });
  }

  Future<void> _handleResend() async {
    setState(() {
      _isResending = true;
      _statusMessage = null;
    });

    final result = await widget.appState.resendVerificationEmail(_targetEmail);

    setState(() {
      _isResending = false;
      _statusMessage = result.message;
      _isSuccess = false;
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
                            Text(item.subject, style: AppTypography.bodySm(color: AppColors.onSurface)),
                            const SizedBox(height: 6),
                            SelectableText(
                              'Token: ${item.token}',
                              style: const TextStyle(fontFamily: 'monospace', fontSize: 12),
                            ),
                            const SizedBox(height: 8),
                            ElevatedButton(
                              onPressed: () {
                                _tokenController.text = item.token;
                                Navigator.of(ctx).pop();
                                _handleVerify();
                              },
                              style: ElevatedButton.styleFrom(
                                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                                backgroundColor: AppColors.tertiary,
                              ),
                              child: const Text('Auto-fill & Verify', style: TextStyle(fontSize: 12)),
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
        title: Text('Email Verification', style: AppTypography.headlineSm(color: AppColors.secondary)),
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
              // Icon Header
              Container(
                width: 80,
                height: 80,
                decoration: BoxDecoration(
                  color: _isSuccess ? AppColors.secondaryContainer : AppColors.primaryFixed,
                  shape: BoxShape.circle,
                ),
                child: Center(
                  child: Icon(
                    _isSuccess ? Icons.mark_email_read : Icons.mail_outline,
                    color: _isSuccess ? AppColors.tertiary : AppColors.primary,
                    size: 40,
                  ),
                ),
              ),
              const SizedBox(height: 18),

              Text(
                _isSuccess ? 'Account Verified!' : 'Verify Your Email',
                style: AppTypography.headlineLg(color: AppColors.onSurface),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),

              Text(
                _isSuccess
                    ? 'Your email address has been successfully confirmed. You now have full access to HerbaCat features.'
                    : 'We sent a single-use verification code and link to:',
                style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 4),

              Container(
                padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(9999),
                ),
                child: Text(
                  _targetEmail,
                  style: AppTypography.labelMd(color: AppColors.primary).copyWith(
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Status message banner
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

              if (!_isSuccess) ...[
                // Token Input Field
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text('Verification Code / Token', style: AppTypography.labelMd(color: AppColors.onSurfaceVariant)),
                    const SizedBox(height: 6),
                    TextField(
                      controller: _tokenController,
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.key, color: AppColors.secondary),
                        hintText: 'Paste single-use token from email',
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 18),

                // Verify Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: _isVerifying ? null : _handleVerify,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: AppColors.tertiary,
                      padding: const EdgeInsets.symmetric(vertical: 14),
                    ),
                    child: _isVerifying
                        ? const SizedBox(
                            width: 20,
                            height: 20,
                            child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                          )
                        : Text(
                            'Verify Account',
                            style: AppTypography.labelLg(color: AppColors.onTertiary),
                          ),
                  ),
                ),
                const SizedBox(height: 14),

                // Resend verification
                TextButton.icon(
                  onPressed: _isResending ? null : _handleResend,
                  icon: const Icon(Icons.refresh, size: 18, color: AppColors.secondary),
                  label: Text(
                    _isResending ? 'Sending fresh email...' : 'Resend Verification Email',
                    style: AppTypography.labelMd(color: AppColors.secondary),
                  ),
                ),

                const SizedBox(height: 8),

                // Developer / Local Outbox Inspection button
                OutlinedButton.icon(
                  onPressed: _showLocalOutboxSheet,
                  icon: const Icon(Icons.mark_email_unread_outlined, size: 16),
                  label: const Text('View Outbox / Verification Link (Local Test)'),
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.outlineVariant),
                    shape: const StadiumBorder(),
                  ),
                ),
              ] else ...[
                // Success Action Button
                SizedBox(
                  width: double.infinity,
                  child: ElevatedButton(
                    onPressed: () {
                      Navigator.of(context).pushAndRemoveUntil(
                        MaterialPageRoute(
                          builder: (_) => MainShell(appState: widget.appState),
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
                        Text('Enter HerbaCat Field Guide', style: AppTypography.labelLg(color: Colors.white)),
                        const SizedBox(width: 8),
                        const Icon(Icons.arrow_forward, size: 18, color: Colors.white),
                      ],
                    ),
                  ),
                ),
              ],

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
