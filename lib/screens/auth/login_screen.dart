import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../state/app_state.dart';
import 'signup_screen.dart';
import 'forgot_password_screen.dart';
import '../main_shell.dart';

class LoginScreen extends StatefulWidget {
  final AppState appState;

  const LoginScreen({super.key, required this.appState});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _emailController = TextEditingController(text: 'maria.santos@catanduanes.gov.ph');
  final _passwordController = TextEditingController(text: '••••••••••••');
  bool _obscurePassword = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final result = await widget.appState.login(
      email: _emailController.text.trim(),
      password: _passwordController.text,
    );
    if (!mounted) return; // safety after async gap
    if (result.success && result.user != null) {
      // Successful login – navigate to main app
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => MainShell(appState: widget.appState),
        ),
      );
    } else {
      // Show error feedback
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Login failed. Please check your credentials.'),
          backgroundColor: Colors.redAccent,
        ),
      );
    }
  }

  void _handleGuest() {
    widget.appState.continueAsGuest();
    Navigator.of(context).pushReplacement(
      MaterialPageRoute(
        builder: (_) => MainShell(appState: widget.appState),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const SizedBox(height: 12),

              // Herbarium Brand Seal
              Stack(
                alignment: Alignment.center,
                children: [
                  Container(
                    width: 90,
                    height: 90,
                    decoration: BoxDecoration(
                      color: AppColors.surfaceContainerLowest,
                      shape: BoxShape.circle,
                      boxShadow: const [
                        BoxShadow(
                          color: Color(0x18442B21),
                          blurRadius: 16,
                          offset: Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Container(
                        width: 72,
                        height: 72,
                        decoration: BoxDecoration(
                          color: AppColors.secondaryContainer.withValues(alpha: 0.4),
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Icons.local_florist,
                          color: AppColors.primary,
                          size: 38,
                        ),
                      ),
                    ),
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: Container(
                      width: 28,
                      height: 28,
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryFixed,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.eco,
                        color: AppColors.onSecondaryFixed,
                        size: 16,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Title & Descriptors
              Text(
                'CATANDUANES HERBAL MEDICINE SHOP',
                style: AppTypography.labelSm(color: AppColors.secondary).copyWith(
                  letterSpacing: 1.5,
                  fontWeight: FontWeight.w700,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 6),
              Text(
                'Welcome to HerbaCat',
                style: AppTypography.headlineLg(color: AppColors.secondary),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 8),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24),
                child: RichText(
                  textAlign: TextAlign.center,
                  text: TextSpan(
                    style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
                    children: const [
                      TextSpan(text: 'Order authentic Catanduanes '),
                      TextSpan(
                        text: 'halamang gamot',
                        style: TextStyle(
                          color: AppColors.primary,
                          fontStyle: FontStyle.italic,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      TextSpan(text: ', organic teas, and pure natural remedies online.'),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Island Naturalist Note Capsule
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Row(
                  children: [
                    Container(
                      width: 38,
                      height: 38,
                      decoration: const BoxDecoration(
                        color: AppColors.secondaryContainer,
                        shape: BoxShape.circle,
                      ),
                      child: const Icon(
                        Icons.spa,
                        color: AppColors.onSecondaryContainer,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Virac & Baras Highland Flora Index',
                            style: AppTypography.labelMd(color: AppColors.onSurface),
                          ),
                          Text(
                            'Verified by local abukay & folk healers',
                            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Email Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text('Email address', style: AppTypography.labelMd(color: AppColors.onSurfaceVariant)),
                      Text('Gov & Researcher Portal', style: AppTypography.labelSm(color: AppColors.secondary)),
                    ],
                  ),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _emailController,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.mail_outline, color: AppColors.secondary),
                      hintText: 'maria.santos@catanduanes.gov.ph',
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              // Password Field
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('Field Access PIN / Password', style: AppTypography.labelMd(color: AppColors.onSurfaceVariant)),
                  const SizedBox(height: 6),
                  TextField(
                    controller: _passwordController,
                    obscureText: _obscurePassword,
                    decoration: InputDecoration(
                      prefixIcon: const Icon(Icons.lock_outline, color: AppColors.secondary),
                      hintText: '••••••••••••',
                      suffixIcon: IconButton(
                        icon: Icon(
                          _obscurePassword ? Icons.visibility : Icons.visibility_off,
                          color: AppColors.outline,
                        ),
                        onPressed: () {
                          setState(() {
                            _obscurePassword = !_obscurePassword;
                          });
                        },
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),

              // Forgot Password
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => ForgotPasswordScreen(appState: widget.appState),
                      ),
                    );
                  },
                  child: Text(
                    'Forgot password?',
                    style: AppTypography.labelSm(color: AppColors.primary),
                  ),
                ),
              ),
              const SizedBox(height: 8),

              // Primary Login Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _handleLogin,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AppColors.secondary,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        'Sign In & Shop',
                        style: AppTypography.labelLg(color: AppColors.onSecondary),
                      ),
                      const SizedBox(width: 8),
                      const Icon(Icons.shopping_bag_outlined, size: 18, color: AppColors.onSecondary),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Divider
              Row(
                children: [
                  const Expanded(child: Divider(color: AppColors.surfaceContainerHighest)),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 12),
                    child: Text(
                      'OR SHOP DIRECTLY',
                      style: AppTypography.labelSm(color: AppColors.onSurfaceVariant).copyWith(
                        letterSpacing: 1.0,
                      ),
                    ),
                  ),
                  const Expanded(child: Divider(color: AppColors.surfaceContainerHighest)),
                ],
              ),
              const SizedBox(height: 18),

              // Guest Access Button
              SizedBox(
                width: double.infinity,
                child: OutlinedButton(
                  onPressed: _handleGuest,
                  style: OutlinedButton.styleFrom(
                    side: const BorderSide(color: AppColors.outlineVariant, width: 1),
                    backgroundColor: AppColors.surfaceContainerLow,
                    shape: const StadiumBorder(),
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                  child: Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      const Icon(Icons.storefront_outlined, color: AppColors.secondary, size: 20),
                      const SizedBox(width: 8),
                      Text(
                        'Continue as Guest Shopper',
                        style: AppTypography.labelMd(color: AppColors.secondary),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Specimen of the Day Card
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLowest,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                  boxShadow: const [
                    BoxShadow(
                      color: Color(0x0A442B21),
                      blurRadius: 8,
                      offset: Offset(0, 2),
                    ),
                  ],
                ),
                child: Row(
                  children: [
                    Container(
                      width: 44,
                      height: 44,
                      decoration: BoxDecoration(
                        color: AppColors.surfaceContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: const Icon(Icons.spa, color: AppColors.secondary, size: 24),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            children: [
                              Text(
                                'Specimen of the Day',
                                style: AppTypography.labelSm(color: AppColors.primary).copyWith(
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                              const SizedBox(width: 6),
                              const Text('•', style: TextStyle(color: AppColors.outline)),
                              const SizedBox(width: 6),
                              Text('Lagundi', style: AppTypography.labelSm(color: AppColors.onSurface)),
                            ],
                          ),
                          Text(
                            'Vitex negundo L. • Puraran Coastline',
                            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant).copyWith(
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(Icons.chevron_right, color: AppColors.outline, size: 20),
                  ],
                ),
              ),
              const SizedBox(height: 20),

              // Footer Sign Up link
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text("Don't have an account?", style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
                  TextButton(
                    onPressed: () {
                      Navigator.of(context).push(
                        MaterialPageRoute(
                          builder: (_) => SignUpScreen(appState: widget.appState),
                        ),
                      );
                    },
                    child: Text(
                      'Sign Up',
                      style: AppTypography.labelLg(color: AppColors.tertiary),
                    ),
                  ),
                ],
              ),
              Text(
                'Herbal records compiled with Catanduanes SUC & Barangay elders',
                style: AppTypography.labelSm(color: AppColors.outline),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 12),
            ],
          ),
        ),
      ),
    );
  }
}

