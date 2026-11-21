import 'package:flutter/material.dart';
import '../../theme/app_colors.dart';
import '../../theme/app_typography.dart';
import '../../state/app_state.dart';
import '../../services/security_service.dart';
import 'verify_email_screen.dart';
import 'login_screen.dart';

class SignUpScreen extends StatefulWidget {
  final AppState appState;

  const SignUpScreen({super.key, required this.appState});

  @override
  State<SignUpScreen> createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _municipalityController = TextEditingController(text: 'Virac');
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  UserRole _selectedRole = UserRole.communityMember;
  bool _agreedToTerms = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _nameController.dispose();
    _emailController.dispose();
    _municipalityController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  int get _passwordStrength => SecurityService.evaluatePasswordStrength(_passwordController.text);

  String get _strengthText {
    if (_passwordController.text.isEmpty) return 'Too weak';
    switch (_passwordStrength) {
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
    if (_passwordController.text.isEmpty) return AppColors.outline;
    switch (_passwordStrength) {
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
      _confirmPasswordController.text == _passwordController.text;

  Future<void> _handleRegister() async {
    final name = _nameController.text.trim();
    final email = _emailController.text.trim();
    final municipality = _municipalityController.text.trim();
    final password = _passwordController.text;
    final confirmPassword = _confirmPasswordController.text;

    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter your full name')),
      );
      return;
    }
    if (email.isEmpty || !RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(email)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please enter a valid email address')),
      );
      return;
    }
    if (password.length < 8) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Password must be at least 8 characters long')),
      );
      return;
    }
    if (password != confirmPassword) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Passwords do not match')),
      );
      return;
    }
    if (!_agreedToTerms) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Please accept the herbal precautions agreement')),
      );
      return;
    }

    setState(() => _isLoading = true);

    final result = await widget.appState.register(
      name: name,
      email: email,
      password: password,
      municipality: municipality,
      role: _selectedRole, // Community Member, Health Worker, or Researcher
    );

    setState(() => _isLoading = false);

    if (!mounted) return;

    if (result.success) {
      // Navigate to Verification screen
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(
          builder: (_) => VerifyEmailScreen(
            appState: widget.appState,
            initialEmail: email,
            initialToken: result.user?.verificationToken,
          ),
        ),
      );
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(result.errorMessage ?? 'Registration failed'),
          backgroundColor: AppColors.error,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: AppColors.onSurface),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(
          'Register Account',
          style: AppTypography.headlineSm(color: AppColors.secondary),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Join HerbaCat Registry',
                style: AppTypography.headlineLg(color: AppColors.secondary),
              ),
              const SizedBox(height: 6),
              Text(
                'Contribute to the Catanduanes ethnobotanical documentation & field preservation.',
                style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant),
              ),
              const SizedBox(height: 24),

              // Full Name
              Text('Full Name', style: AppTypography.labelMd(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 6),
              TextField(
                controller: _nameController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.person_outline, color: AppColors.secondary),
                  hintText: 'Maria Elena Santos',
                ),
              ),
              const SizedBox(height: 16),

              // Email
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Field Email', style: AppTypography.labelMd(color: AppColors.onSurfaceVariant)),
                  Text('Field Identification Sync', style: AppTypography.bodySm(color: AppColors.secondary)),
                ],
              ),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.mail_outline, color: AppColors.secondary),
                  hintText: 'elena.santos@gmail.com',
                ),
              ),
              const SizedBox(height: 16),

              // Municipality
              Text('Municipality in Catanduanes', style: AppTypography.labelMd(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 6),
              TextField(
                controller: _municipalityController,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.location_on_outlined, color: AppColors.secondary),
                  hintText: 'Virac, Bato, San Andres, Pandan...',
                ),
              ),
              const SizedBox(height: 16),

              // Password
              Text('Create Password', style: AppTypography.labelMd(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
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
                    onPressed: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                  ),
                ),
              ),
              const SizedBox(height: 6),

              // Live Password Strength Indicator
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 4),
                child: Column(
                  children: [
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
                    const SizedBox(height: 4),
                    Row(
                      children: List.generate(4, (index) {
                        final active = _passwordStrength > index;
                        return Expanded(
                          child: Container(
                            height: 5,
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
              ),
              const SizedBox(height: 16),

              // Confirm Password
              Text('Confirm Password', style: AppTypography.labelMd(color: AppColors.onSurfaceVariant)),
              const SizedBox(height: 6),
              TextField(
                controller: _confirmPasswordController,
                obscureText: _obscureConfirm,
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  prefixIcon: const Icon(Icons.lock_reset, color: AppColors.secondary),
                  hintText: 'Re-enter your password',
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
                        onPressed: () {
                          setState(() {
                            _obscureConfirm = !_obscureConfirm;
                          });
                        },
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 20),

              // Role Selection (NO Administrator option)
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text('Botanical Registry Role', style: AppTypography.labelMd(color: AppColors.onSurfaceVariant)),
                  Text('Select one', style: AppTypography.labelSm(color: AppColors.outline)),
                ],
              ),
              const SizedBox(height: 10),
              Row(
                children: [
                  _roleCard(
                    title: 'Community Member',
                    icon: Icons.nature_people,
                    role: UserRole.communityMember,
                  ),
                  const SizedBox(width: 8),
                  _roleCard(
                    title: 'Health Worker',
                    icon: Icons.healing,
                    role: UserRole.healthWorker,
                  ),
                  const SizedBox(width: 8),
                  _roleCard(
                    title: 'Researcher',
                    icon: Icons.biotech,
                    role: UserRole.researcher,
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Terms Agreement Checkbox
              InkWell(
                onTap: () {
                  setState(() {
                    _agreedToTerms = !_agreedToTerms;
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 6),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Checkbox(
                        value: _agreedToTerms,
                        activeColor: AppColors.tertiary,
                        onChanged: (val) {
                          setState(() {
                            _agreedToTerms = val ?? false;
                          });
                        },
                      ),
                      Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(top: 10),
                          child: Text(
                            'I agree to verify local herbal preparation precautions, contraindications, and dosage guidelines before administering traditional folk remedies.',
                            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(height: 24),

              // Submit Button
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: _isLoading ? null : _handleRegister,
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
                      : Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Create Explorer Account',
                              style: AppTypography.labelLg(color: AppColors.onPrimary),
                            ),
                            const SizedBox(width: 8),
                            const Icon(Icons.arrow_forward, size: 18, color: AppColors.onPrimary),
                          ],
                        ),
                ),
              ),
              const SizedBox(height: 20),

              // Already have an account? Log In
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text('Already have an account?', style: AppTypography.bodyMd(color: AppColors.onSurfaceVariant)),
                  const SizedBox(width: 6),
                  InkWell(
                    onTap: () {
                      Navigator.of(context).pushReplacement(
                        MaterialPageRoute(
                          builder: (_) => LoginScreen(appState: widget.appState),
                        ),
                      );
                    },
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text(
                          'Log In',
                          style: AppTypography.labelLg(color: AppColors.primary).copyWith(fontWeight: FontWeight.bold),
                        ),
                        const Icon(Icons.chevron_right, size: 16, color: AppColors.primary),
                      ],
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),

              // Preserving Folk Ethnomedicine Note Banner
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.surfaceContainerLow,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.outlineVariant.withValues(alpha: 0.3)),
                ),
                child: Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Icon(Icons.local_florist, color: AppColors.primary, size: 22),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Preserving Folk Ethnomedicine',
                            style: AppTypography.labelMd(color: AppColors.onSurface),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            'Every account helps catalog biodiversity across Virac, San Andres, Pandan, and remote Catanduanes highlands.',
                            style: AppTypography.bodySm(color: AppColors.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _roleCard({
    required String title,
    required IconData icon,
    required UserRole role,
  }) {
    final isSelected = _selectedRole == role;
    return Expanded(
      child: InkWell(
        onTap: () {
          setState(() {
            _selectedRole = role;
          });
        },
        borderRadius: BorderRadius.circular(16),
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 200),
          padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
          decoration: BoxDecoration(
            color: isSelected ? AppColors.secondaryContainer : AppColors.surfaceContainerLow,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: isSelected ? AppColors.secondary : AppColors.outlineVariant.withValues(alpha: 0.3),
              width: isSelected ? 1.5 : 1,
            ),
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                icon,
                color: isSelected ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
                size: 24,
              ),
              const SizedBox(height: 6),
              Text(
                title,
                style: AppTypography.labelSm(
                  color: isSelected ? AppColors.onSecondaryContainer : AppColors.onSurfaceVariant,
                ).copyWith(fontWeight: FontWeight.w600),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
