import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../shared/widgets/gradient_button.dart';
import 'package:shared_preferences/shared_preferences.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _controller = PageController();
  int _currentPage = 0;

  List<_OnboardingPage> _pages(BuildContext context) {
    final strings = AppStrings.of(context);
    return [
      _OnboardingPage(
        emoji: '🌍',
        title: strings.onboardingTitle1,
        subtitle: strings.onboardingDesc1,
        gradient: const [Color(0xFF0D1B2A), Color(0xFF1A2E42)],
      ),
      _OnboardingPage(
        emoji: '🗺️',
        title: strings.onboardingTitle2,
        subtitle: strings.onboardingDesc2,
        gradient: const [Color(0xFF0D1B2A), Color(0xFF15263A)],
      ),
      _OnboardingPage(
        emoji: '💬',
        title: strings.onboardingTitle3,
        subtitle: strings.onboardingDesc3,
        gradient: const [Color(0xFF0D1B2A), Color(0xFF1A2E42)],
      ),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final pagesList = _pages(context);

    return Scaffold(
      backgroundColor: AppColors.adaptiveBgPrimary(context),
      body: Stack(
        children: [
          // Background glow
          Positioned.fill(
            child: DecoratedBox(
              decoration: BoxDecoration(
                gradient: RadialGradient(
                  center: Alignment.topLeft,
                  radius: 1.5,
                  colors: [
                    AppColors.accentAmber.withValues(alpha: 0.06),
                    Colors.transparent,
                  ],
                ),
              ),
            ),
          ),
          SafeArea(
            child: Column(
              children: [
                // Skip button
                Align(
                  alignment: AlignmentDirectional.topEnd,
                  child: TextButton(
                    onPressed: _onGetStarted,
                    child: Text(
                      strings.onboardingSkip,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: AppColors.adaptiveTextSecondary(context),
                      ),
                    ),
                  ),
                ),

                // Page view
                Expanded(
                  child: PageView.builder(
                    controller: _controller,
                    itemCount: pagesList.length,
                    onPageChanged: (i) => setState(() => _currentPage = i),
                    itemBuilder: (ctx, i) =>
                        _OnboardingPageWidget(page: pagesList[i]),
                  ),
                ),

                // Indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    pagesList.length,
                    (i) => AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: _currentPage == i ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(4),
                        color: _currentPage == i
                            ? AppColors.accentAmber
                            : AppColors.adaptiveTextSecondary(context).withValues(alpha: 0.3),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),

                // CTA
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: _currentPage == pagesList.length - 1
                      ? GradientButton(
                          label: strings.onboardingGetStarted,
                          icon: Icons.arrow_forward_rounded,
                          onPressed: _onGetStarted,
                        )
                      : GradientButton(
                          label: strings.onboardingNext,
                          icon: Icons.arrow_forward_ios_rounded,
                          onPressed: () => _controller.nextPage(
                            duration: const Duration(milliseconds: 400),
                            curve: Curves.easeOutCubic,
                          ),
                        ),
                ),
                const SizedBox(height: 32),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _onGetStarted() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('has_seen_onboarding', true);
    if (mounted) context.go('/auth');
  }
}

class _OnboardingPage {
  final String emoji;
  final String title;
  final String subtitle;
  final List<Color> gradient;

  const _OnboardingPage({
    required this.emoji,
    required this.title,
    required this.subtitle,
    required this.gradient,
  });
}

class _OnboardingPageWidget extends StatelessWidget {
  final _OnboardingPage page;
  const _OnboardingPageWidget({required this.page});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          // Emoji in glowing circle
          Container(
            width: 140,
            height: 140,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: AppColors.adaptiveBgCard(context),
              border: Border.all(color: AppColors.adaptiveBorder(context), width: 1),
              boxShadow: AppColors.amberGlow,
            ),
            child: Center(
              child: Text(
                page.emoji,
                style: const TextStyle(fontSize: 60),
              ),
            ),
          ).animate().scale(
                begin: const Offset(0.8, 0.8),
                duration: 500.ms,
                curve: Curves.easeOutBack,
              ),
          const SizedBox(height: 40),
          Text(
            page.title,
            textAlign: TextAlign.center,
            style: AppTextStyles.headlineLarge.copyWith(height: 1.4),
          ).animate().fadeIn(delay: 200.ms).slideY(begin: 0.2, end: 0),
          const SizedBox(height: 16),
          Text(
            page.subtitle,
            textAlign: TextAlign.center,
            style: AppTextStyles.bodyMedium.copyWith(height: 1.7),
          ).animate().fadeIn(delay: 350.ms),
        ],
      ),
    );
  }
}
