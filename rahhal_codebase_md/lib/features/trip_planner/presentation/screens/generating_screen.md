# ملف كود Dart: lib\features\trip_planner\presentation\screens\generating_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection.dart';
import '../cubit/trip_planner_cubit.dart';

class GeneratingScreen extends StatelessWidget {
  final Map<String, dynamic> params;

  const GeneratingScreen({super.key, required this.params});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => sl<TripPlannerCubit>(),
      child: _GeneratingScreenBody(params: params),
    );
  }
}

class _GeneratingScreenBody extends StatefulWidget {
  final Map<String, dynamic> params;
  const _GeneratingScreenBody({required this.params});

  @override
  State<_GeneratingScreenBody> createState() => _GeneratingScreenBodyState();
}

class _GeneratingScreenBodyState extends State<_GeneratingScreenBody>
    with SingleTickerProviderStateMixin {
  late final AnimationController _rotationCtrl;
  int _currentStep = 0;

  List<String> get _steps => [
    '🔍 ${AppStrings.generatingStep1}',
    '💰 ${AppStrings.generatingStep2}',
    '📅 ${AppStrings.generatingStep3}',
    '🍽️ ${AppStrings.generatingStep4}',
    '✨ ${AppStrings.generatingStep5}',
  ];

  @override
  void initState() {
    super.initState();
    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _animateSteps();
    // Trigger generation after the frame is built so BlocProvider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _startGeneration());
  }

  @override
  void dispose() {
    _rotationCtrl.dispose();
    super.dispose();
  }

  void _animateSteps() {
    for (var i = 1; i < _steps.length; i++) {
      Future.delayed(Duration(milliseconds: 1500 * i), () {
        if (mounted) setState(() => _currentStep = i);
      });
    }
  }

  void _startGeneration() {
    if (!mounted) return;
    context.read<TripPlannerCubit>().generateTripPlan(
      destination: widget.params['destination'] as String,
      durationDays: widget.params['durationDays'] as int,
      budgetTier: widget.params['budgetTier'] as String,
      travelStyles: (widget.params['travelStyles'] as List).cast<String>(),
      travelersCount: widget.params['travelersCount'] as int,
      startDate: widget.params['startDate'] as DateTime?,
    );
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TripPlannerCubit, TripPlannerState>(
      listener: (context, state) {
        if (state is TripPlannerSuccess) {
          context.go('/trip/${state.trip.id}', extra: state.trip);
        } else if (state is TripPlannerError) {
          showDialog(
            context: context,
            builder: (ctx) => AlertDialog(
              backgroundColor: AppColors.bgCard,
              title: Text(AppStrings.errorTitle, style: AppTextStyles.headlineMedium),
              content: Text(state.message, style: AppTextStyles.bodyMedium),
              actions: [
                TextButton(
                  onPressed: () {
                    Navigator.pop(ctx);
                    context.go('/plan');
                  },
                  child: Text(AppStrings.errorRetry),
                ),
              ],
            ),
          );
        }
      },
      child: Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Stack(
          children: [
            // Radial background animation
            Positioned.fill(
              child: AnimatedContainer(
                duration: const Duration(seconds: 3),
                decoration: BoxDecoration(
                  gradient: RadialGradient(
                    center: Alignment.center,
                    radius: 1.5,
                    colors: [
                      AppColors.accentAmber.withValues(alpha: 0.06),
                      AppColors.bgPrimary,
                    ],
                  ),
                ),
              ),
            ),

            // Floating particles
            ..._buildParticles(),

            Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  // Spinning logo
                  _buildSpinningLogo(),
                  const SizedBox(height: 40),

                  // Title
                  Text(
                    AppStrings.generatingTitle,
                    style: AppTextStyles.headlineLarge,
                    textAlign: TextAlign.center,
                  )
                      .animate(onPlay: (c) => c.repeat(reverse: true))
                      .fadeIn(duration: 600.ms),

                  const SizedBox(height: 8),
                  Text(
                    AppStrings.generatingSubtitle,
                    style: AppTextStyles.bodyMedium,
                    textAlign: TextAlign.center,
                  ),

                  const SizedBox(height: 48),

                  // Steps
                  _buildSteps(),

                  const SizedBox(height: 48),

                  // Progress dots
                  _buildProgressDots(),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSpinningLogo() {
    return Stack(
      alignment: Alignment.center,
      children: [
        // Outer ring
        RotationTransition(
          turns: _rotationCtrl,
          child: Container(
            width: 120,
            height: 120,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: AppColors.accentAmber.withValues(alpha: 0.3),
                width: 2,
              ),
            ),
          ),
        ),
        // Inner glow
        Container(
          width: 90,
          height: 90,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            gradient: AppColors.amberGradient,
            boxShadow: AppColors.amberGlowStrong,
          ),
          child: const Center(
            child: Text('✈️', style: TextStyle(fontSize: 36)),
          ),
        )
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scaleXY(begin: 1.0, end: 1.08, duration: 1500.ms),
      ],
    );
  }

  Widget _buildSteps() {
    return SizedBox(
      width: 280,
      child: Column(
        children: _steps.asMap().entries.map((entry) {
          final i = entry.key;
          final step = entry.value;
          final isDone = i < _currentStep;
          final isActive = i == _currentStep;

          return AnimatedOpacity(
            opacity: i <= _currentStep ? 1.0 : 0.3,
            duration: const Duration(milliseconds: 400),
            child: Padding(
              padding: const EdgeInsets.symmetric(vertical: 6),
              child: Row(
                children: [
                  AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isDone
                          ? AppColors.success
                          : isActive
                              ? AppColors.accentAmber
                              : AppColors.glass,
                      border: Border.all(
                        color: isDone
                            ? AppColors.success
                            : isActive
                                ? AppColors.accentAmber
                                : AppColors.border,
                      ),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check_rounded,
                              size: 14, color: Colors.white)
                          : isActive
                              ? const SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.bgPrimary,
                                  ),
                                )
                              : null,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      step,
                      style: AppTextStyles.bodyMedium.copyWith(
                        color: isActive || isDone
                            ? AppColors.textPrimary
                            : AppColors.textSecondary,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildProgressDots() {
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
            color: AppColors.accentAmber,
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .scaleXY(
              begin: 0.5,
              end: 1.0,
              delay: Duration(milliseconds: i * 200),
              duration: 600.ms,
            )
            .then()
            .scaleXY(begin: 1.0, end: 0.5, duration: 600.ms),
      ),
    );
  }

  List<Widget> _buildParticles() {
    return List.generate(8, (i) {
      final x = (i * 137.5) % 100 / 100;
      final y = (i * 89.3) % 100 / 100;
      return Positioned(
        left: MediaQuery.sizeOf(context).width * x,
        top: MediaQuery.sizeOf(context).height * y,
        child: Container(
          width: 3,
          height: 3,
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: AppColors.accentAmber.withValues(alpha: 0.5),
          ),
        )
            .animate(onPlay: (c) => c.repeat())
            .fadeIn(delay: Duration(milliseconds: i * 300), duration: 600.ms)
            .then()
            .moveY(end: -40, duration: 3000.ms)
            .fadeOut(duration: 500.ms),
      );
    });
  }
}

```
