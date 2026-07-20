import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:firebase_core/firebase_core.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../domain/repositories/auth_repository.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  @override
  void initState() {
    super.initState();
    _navigate();
  }

  Future<void> _navigate() async {
    await Future.delayed(const Duration(milliseconds: 1500));
    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    if (!mounted) return;
    
    // Check if Firebase was initialized successfully
    bool isFirebaseAvailable = true;
    try {
      isFirebaseAvailable = Firebase.apps.isNotEmpty;
    } catch (_) {
      isFirebaseAvailable = false;
    }

    if (!isFirebaseAvailable && mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'تعذّر الاتصال بالخدمات السحابية. التطبيق يعمل في وضع محلي.',
            style: TextStyle(color: Colors.white),
          ),
          backgroundColor: Colors.orange,
          duration: Duration(seconds: 4),
        ),
      );
    }

    final hasSeenOnboarding = prefs.getBool('has_seen_onboarding') ?? false;
    final authRepo = sl<AuthRepository>();

    if (!hasSeenOnboarding) {
      context.go('/onboarding');
    } else if (!isFirebaseAvailable) {
      context.go('/home');
    } else if (authRepo.isAuthenticated) {
      context.go('/home');
    } else {
      context.go('/auth');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.adaptiveBgPrimary(context),
      body: Stack(
        children: [
          // Radial ambient glow
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topCenter,
                  radius: 1.2,
                  colors: [
                    AppColors.accentAmber.withValues(alpha: 0.08),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          // Animated particles
          ..._buildParticles(),
          // Main content
          Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Logo
                _buildLogo(),
                const SizedBox(height: 24),
                // App name
                Text(
                  'رحّال AI',
                  style: AppTextStyles.displayLarge.copyWith(
                    fontSize: 40,
                    letterSpacing: 2,
                    color: AppColors.adaptiveTextPrimary(context),
                  ),
                )
                    .animate()
                    .fadeIn(delay: 400.ms, duration: 600.ms)
                    .slideY(begin: 0.3, end: 0),
                const SizedBox(height: 8),
                Text(
                  'مساعدك الذكي للسفر',
                  style: AppTextStyles.bodyMedium.copyWith(
                    color: AppColors.adaptiveTextSecondary(context),
                    letterSpacing: 1,
                  ),
                ).animate().fadeIn(delay: 700.ms, duration: 600.ms),
                const SizedBox(height: 48),
                // Loading dots
                _buildLoadingDots(),
              ],
            ),
          ),
          // Version at bottom
          Positioned(
            bottom: 40,
            left: 0,
            right: 0,
            child: Text(
              'v1.0.0',
              textAlign: TextAlign.center,
              style: AppTextStyles.labelSmall.copyWith(
                color: AppColors.adaptiveTextSecondary(context).withValues(alpha: 0.4),
              ),
            ).animate().fadeIn(delay: 1000.ms),
          ),
        ],
      ),
    );
  }


  Widget _buildLogo() {
    return Container(
      width: 100,
      height: 100,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        gradient: AppColors.amberGradient,
        boxShadow: AppColors.amberGlowStrong,
      ),
      child: const Center(
        child: Text(
          '✈️',
          style: TextStyle(fontSize: 44),
        ),
      ),
    )
        .animate()
        .scale(
          begin: const Offset(0.5, 0.5),
          end: const Offset(1, 1),
          duration: 700.ms,
          curve: Curves.easeOutBack,
        )
        .fadeIn(duration: 500.ms);
  }

  Widget _buildLoadingDots() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.center,
      children: List.generate(
        3,
        (i) => Container(
          margin: const EdgeInsets.symmetric(horizontal: 4),
          width: 8,
          height: 8,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: i == 0
                ? AppColors.accentAmber
                : AppColors.adaptiveTextSecondary(context).withValues(alpha: 0.3),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .fadeIn(delay: Duration(milliseconds: 800 + i * 200))
            .then()
            .shimmer(
              duration: 1200.ms,
              delay: Duration(milliseconds: i * 200),
            ),
      ),
    );
  }

  List<Widget> _buildParticles() {
    final positions = [
      (0.15, 0.2),
      (0.8, 0.15),
      (0.1, 0.7),
      (0.85, 0.65),
      (0.5, 0.1),
      (0.45, 0.85),
    ];
    return positions.asMap().entries.map((entry) {
      final i = entry.key;
      final (x, y) = entry.value;
      return Positioned(
        left: MediaQuery.sizeOf(context).width * x,
        top: MediaQuery.sizeOf(context).height * y,
        child: Container(
          width: 4,
          height: 4,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentAmber.withValues(alpha: 0.4),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .fadeIn(
              delay: Duration(milliseconds: 300 * i),
              duration: 600.ms,
            )
            .then()
            .moveY(
              end: -30,
              duration: 3000.ms,
              curve: Curves.easeInOut,
            )
            .fadeOut(duration: 600.ms),
      );
    }).toList();
  }
}
