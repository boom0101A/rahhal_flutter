# ملف كود Dart: lib\features\auth\presentation\screens\auth_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../cubit/auth_cubit.dart';

class AuthScreen extends StatefulWidget {
  final bool isLogin;

  const AuthScreen({super.key, this.isLogin = true});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  late bool _isLogin;
  final _formKey = GlobalKey<FormState>();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _nameCtrl = TextEditingController();
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.isLogin;
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _nameCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<AuthCubit>(),
      child: BlocListener<AuthCubit, AuthState>(
        listener: (context, state) {
          if (state is AuthAuthenticated) {
            context.go('/home');
          } else if (state is AuthError) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(state.message),
                backgroundColor: AppColors.error,
              ),
            );
          }
        },
        child: Scaffold(
          backgroundColor: AppColors.bgPrimary,
          body: Stack(
            children: [
              // Background glow
              Positioned(
                top: -100,
                left: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: AppColors.accentAmber.withValues(alpha: 0.05),
                  ),
                ),
              ),
              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 16),
                      // Logo + Title
                      Row(
                        children: [
                          Container(
                            width: 48,
                            height: 48,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.amberGradient,
                            ),
                            child: const Center(
                              child: Text('✈️', style: TextStyle(fontSize: 22)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(AppStrings.appName, style: AppTextStyles.headlineLarge),
                        ],
                      ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2),
                      const SizedBox(height: 32),
                      Text(
                        _isLogin ? AppStrings.authLogin : AppStrings.authRegister,
                        style: AppTextStyles.displaySmall,
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin
                            ? AppStrings.authWelcomeBack
                            : AppStrings.authCreateAccount,
                        style: AppTextStyles.bodyMedium,
                      ).animate().fadeIn(delay: 200.ms),
                      const SizedBox(height: 32),

                      // Form
                      GlassCard(
                        child: Padding(
                          padding: const EdgeInsets.all(20),
                          child: Form(
                            key: _formKey,
                            child: Column(
                              children: [
                                if (!_isLogin) ...[
                                  _buildField(
                                    controller: _nameCtrl,
                                    label: AppStrings.authName,
                                    icon: Icons.person_outline_rounded,
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? AppStrings.authEnterName
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                _buildField(
                                  controller: _emailCtrl,
                                  label: AppStrings.authEmail,
                                  icon: Icons.email_outlined,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) =>
                                      (v == null || !v.contains('@'))
                                          ? AppStrings.authInvalidEmail
                                          : null,
                                ),
                                const SizedBox(height: 16),
                                _buildField(
                                  controller: _passwordCtrl,
                                  label: AppStrings.authPassword,
                                  icon: Icons.lock_outline_rounded,
                                  obscureText: _obscurePassword,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppColors.textSecondary,
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                  validator: (v) => (v == null || v.length < 6)
                                      ? AppStrings.authWeakPassword
                                      : null,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ).animate().fadeIn(delay: 300.ms),

                      const SizedBox(height: 24),

                      // Submit button
                      BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) {
                          return GradientButton(
                            label: _isLogin ? AppStrings.authLogin : AppStrings.authRegister,
                            icon: Icons.arrow_forward_rounded,
                            isLoading: state is AuthLoading,
                            onPressed: _submit,
                          );
                        },
                      ).animate().fadeIn(delay: 400.ms),

                      const SizedBox(height: 16),

                      // Divider
                      Row(children: [
                        const Expanded(child: Divider(color: AppColors.border)),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(AppStrings.authOr, style: AppTextStyles.labelSmall),
                        ),
                        const Expanded(child: Divider(color: AppColors.border)),
                      ]),

                      const SizedBox(height: 16),

                      // Guest mode
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: () =>
                              context.read<AuthCubit>().signInAnonymously(),
                          icon: const Icon(Icons.person_outline_rounded,
                              size: 18),
                          label: Text(AppStrings.authGuestMode),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.textSecondary,
                            side: const BorderSide(color: AppColors.border),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 24),

                      // Toggle
                      Center(
                        child: TextButton(
                          onPressed: () => setState(() => _isLogin = !_isLogin),
                          child: Text(
                            _isLogin
                                ? AppStrings.authNoAccount
                                : AppStrings.authHaveAccount,
                            style: AppTextStyles.bodyMedium
                                .copyWith(color: AppColors.accentAmber),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField({
    required TextEditingController controller,
    required String label,
    required IconData icon,
    String? Function(String?)? validator,
    TextInputType? keyboardType,
    bool obscureText = false,
    Widget? suffix,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.textSecondary, size: 20),
        suffixIcon: suffix,
      ),
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) return;
    final cubit = context.read<AuthCubit>();
    if (_isLogin) {
      cubit.signInWithEmail(_emailCtrl.text.trim(), _passwordCtrl.text);
    } else {
      cubit.register(
        _emailCtrl.text.trim(),
        _passwordCtrl.text,
        _nameCtrl.text.trim(),
      );
    }
  }
}

```
