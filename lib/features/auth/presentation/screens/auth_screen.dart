import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../cubit/auth_cubit.dart';

class AuthScreen extends StatefulWidget {
  final bool isLogin;
  const AuthScreen({super.key, this.isLogin = true});

  @override
  State<AuthScreen> createState() => _AuthScreenState();
}

class _AuthScreenState extends State<AuthScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameCtrl = TextEditingController();
  final _emailCtrl = TextEditingController();
  final _passwordCtrl = TextEditingController();
  final _confirmPasswordCtrl = TextEditingController();
  late bool _isLogin;
  bool _obscurePassword = true;

  @override
  void initState() {
    super.initState();
    _isLogin = widget.isLogin;
  }

  @override
  void dispose() {
    _nameCtrl.dispose();
    _emailCtrl.dispose();
    _passwordCtrl.dispose();
    _confirmPasswordCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return BlocListener<AuthCubit, AuthState>(
      listener: (context, state) {
        if (state is AuthAuthenticated) {
          context.go('/home');
        } else if (state is AuthError) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(strings.authErrorMessage(state.message)),
              backgroundColor: AppColors.error,
            ),
          );
        }
      },
      child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(),
          child: Scaffold(
            backgroundColor: AppColors.adaptiveBgPrimary(context),
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
              Positioned(
                bottom: -50,
                right: -50,
                child: Container(
                  width: 300,
                  height: 300,
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: const Color(0xFF9B7FD4).withValues(alpha: 0.05),
                  ),
                ),
              ),

              SafeArea(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 40),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const SizedBox(height: 20),
                      // Logo
                      Row(
                        children: [
                          Container(
                            width: 44,
                            height: 44,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              gradient: AppColors.amberGradient,
                              boxShadow: AppColors.amberGlow,
                            ),
                            child: const Center(
                              child: Text('✈️', style: TextStyle(fontSize: 22)),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Text(strings.appName, style: AppTextStyles.headlineLarge),
                        ],
                      ).animate().fadeIn(duration: 400.ms).slideX(begin: -0.2),
                      const SizedBox(height: 32),
                      Text(
                        _isLogin ? strings.authLogin : strings.authRegister,
                        style: AppTextStyles.displaySmall,
                      ).animate().fadeIn(delay: 100.ms),
                      const SizedBox(height: 8),
                      Text(
                        _isLogin
                            ? strings.authWelcomeBack
                            : strings.authCreateAccount,
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
                                    label: strings.authName,
                                    icon: Icons.person_outline_rounded,
                                    maxLength: 50,
                                    validator: (v) => (v == null || v.isEmpty)
                                        ? strings.authEnterName
                                        : null,
                                  ),
                                  const SizedBox(height: 16),
                                ],
                                _buildField(
                                  controller: _emailCtrl,
                                  label: strings.authEmail,
                                  icon: Icons.email_outlined,
                                  maxLength: 100,
                                  keyboardType: TextInputType.emailAddress,
                                  validator: (v) =>
                                      (v == null || !v.contains('@'))
                                          ? strings.authInvalidEmail
                                          : null,
                                ),
                                const SizedBox(height: 16),
                                _buildField(
                                  controller: _passwordCtrl,
                                  label: strings.authPassword,
                                  icon: Icons.lock_outline_rounded,
                                  maxLength: 64,
                                  obscureText: _obscurePassword,
                                  suffix: IconButton(
                                    icon: Icon(
                                      _obscurePassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: AppColors.adaptiveTextSecondary(context),
                                      size: 20,
                                    ),
                                    onPressed: () => setState(() =>
                                        _obscurePassword = !_obscurePassword),
                                  ),
                                  validator: (v) => (v == null || v.length < 6)
                                      ? strings.authWeakPassword
                                      : null,
                                ),
                                if (!_isLogin) ...[
                                  const SizedBox(height: 16),
                                  _buildField(
                                    controller: _confirmPasswordCtrl,
                                    label: strings.authConfirmPassword,
                                    icon: Icons.lock_outline_rounded,
                                    maxLength: 64,
                                    obscureText: _obscurePassword,
                                    validator: (v) {
                                      if (v == null || v.isEmpty) return strings.authWeakPassword;
                                      if (v != _passwordCtrl.text) return strings.authPasswordMismatch;
                                      return null;
                                    },
                                  ),
                                ],
                                if (_isLogin)
                                  Align(
                                    alignment: AlignmentDirectional.centerEnd,
                                    child: TextButton(
                                      onPressed: () async {
                                        if (_emailCtrl.text.trim().isEmpty || !_emailCtrl.text.contains('@')) {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(strings.authInvalidEmail)),
                                          );
                                          return;
                                        }
                                        await firebase_auth.FirebaseAuth.instance
                                            .sendPasswordResetEmail(email: _emailCtrl.text.trim());
                                        if (!context.mounted) return;
                                        ScaffoldMessenger.of(context).showSnackBar(
                                          SnackBar(content: Text('تم إرسال رابط إعادة تعيين كلمة المرور إلى ${_emailCtrl.text.trim()}')),
                                        );
                                      },
                                      child: Text(
                                        strings.authForgotPassword,
                                        style: AppTextStyles.bodySmall.copyWith(color: AppColors.accentAmber),
                                      ),
                                    ),
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
                            label: _isLogin ? strings.authLogin : strings.authRegister,
                            icon: Icons.arrow_forward_rounded,
                            isLoading: state is AuthLoading,
                            onPressed: _submit,
                          );
                        },
                      ).animate().fadeIn(delay: 400.ms),

                      const SizedBox(height: 16),

                      // Divider
                      Row(children: [
                        Expanded(child: Divider(color: AppColors.adaptiveBorder(context))),
                        Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 16),
                          child: Text(strings.authOr, style: AppTextStyles.labelSmall),
                        ),
                        Expanded(child: Divider(color: AppColors.adaptiveBorder(context))),
                      ]),

                      const SizedBox(height: 16),

                      // Google Sign In
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton(
                          onPressed: () =>
                              context.read<AuthCubit>().signInWithGoogle(),
                          style: OutlinedButton.styleFrom(
                            foregroundColor: AppColors.adaptiveTextPrimary(context),
                            side: BorderSide(color: AppColors.adaptiveBorder(context)),
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(50),
                            ),
                          ),
                          child: Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Container(
                                width: 22,
                                height: 22,
                                decoration: BoxDecoration(
                                  shape: BoxShape.circle,
                                  color: Colors.white,
                                  boxShadow: [
                                    BoxShadow(
                                      color: Colors.black12,
                                      blurRadius: 2,
                                    )
                                  ],
                                ),
                                child: const Center(
                                  child: Text(
                                    'G',
                                    style: TextStyle(
                                      color: Color(0xFF4285F4),
                                      fontWeight: FontWeight.bold,
                                      fontSize: 14,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(width: 12),
                              Text(strings.authGoogleSignIn),
                            ],
                          ),
                        ),
                      ),

                      const SizedBox(height: 12),

                      // Guest mode
                      BlocBuilder<AuthCubit, AuthState>(
                        builder: (context, state) {
                          final isLoading = state is AuthLoading;
                          return SizedBox(
                            width: double.infinity,
                            child: OutlinedButton.icon(
                              onPressed: isLoading
                                  ? null
                                  : () => context
                                      .read<AuthCubit>()
                                      .signInAnonymously(),
                              icon: isLoading
                                  ? SizedBox(
                                      width: 18,
                                      height: 18,
                                      child: CircularProgressIndicator(
                                        strokeWidth: 2,
                                        color: AppColors.adaptiveTextSecondary(context),
                                      ),
                                    )
                                  : const Icon(Icons.person_outline_rounded,
                                      size: 18),
                              label: Text(isLoading
                                  ? strings.loading
                                  : strings.authGuestMode),
                              style: OutlinedButton.styleFrom(
                                foregroundColor: AppColors.adaptiveTextSecondary(context),
                                side: BorderSide(color: AppColors.adaptiveBorder(context)),
                                padding:
                                    const EdgeInsets.symmetric(vertical: 14),
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(50),
                                ),
                              ),
                            ),
                          );
                        },
                      ),

                      const SizedBox(height: 24),

                      // Toggle
                      Center(
                        child: TextButton(
                          onPressed: () => setState(() => _isLogin = !_isLogin),
                          child: Text(
                            _isLogin
                                ? strings.authNoAccount
                                : strings.authHaveAccount,
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
    int? maxLength,
  }) {
    return TextFormField(
      controller: controller,
      validator: validator,
      keyboardType: keyboardType,
      obscureText: obscureText,
      maxLength: maxLength,
      maxLengthEnforcement: MaxLengthEnforcement.enforced,
      buildCounter: (_, {required currentLength, required isFocused, maxLength}) =>
          null, // إخفاء عداد الأحرف
      style: AppTextStyles.bodyLarge,
      decoration: InputDecoration(
        labelText: label,
        prefixIcon: Icon(icon, color: AppColors.adaptiveTextSecondary(context), size: 20),
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
