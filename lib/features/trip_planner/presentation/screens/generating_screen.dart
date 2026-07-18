import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/config/app_config.dart';
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
  bool _aiCompleted = false;
  bool _showSlowWarning = false;
  Timer? _slowWarningTimer;
  TripPlannerState? _pendingSuccessState; // hold success state until animation done

  List<String> _steps(BuildContext context) {
    final strings = AppStrings.of(context);
    return [
      '🔍 ${strings.generatingStep1}',
      '💰 ${strings.generatingStep2}',
      '📅 ${strings.generatingStep3}',
      '🍽️ ${strings.generatingStep4}',
      '✨ ${strings.generatingStep5}',
    ];
  }

  @override
  void initState() {
    super.initState();
    _rotationCtrl = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 8),
    )..repeat();
    _animateSteps();
    _startSlowTimer();
    // Trigger generation after the frame is built so BlocProvider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _startGeneration());
  }

  void _startSlowTimer() {
    _slowWarningTimer?.cancel();
    _slowWarningTimer = Timer(const Duration(seconds: 20), () {
      if (mounted && !_aiCompleted) {
        setState(() => _showSlowWarning = true);
      }
    });
  }

  @override
  void dispose() {
    _slowWarningTimer?.cancel();
    _rotationCtrl.dispose();
    super.dispose();
  }

  void _animateSteps() {
    const totalSteps = 5;
    for (var i = 1; i < totalSteps; i++) {
      Future.delayed(Duration(milliseconds: 1500 * i), () {
        if (mounted) {
          setState(() => _currentStep = i);
          // If AI already completed, navigate after last step
          if (i == totalSteps - 1 && _aiCompleted && _pendingSuccessState != null) {
            _navigateToSuccess(_pendingSuccessState!);
          }
        }
      });
    }
  }

  void _startGeneration() {
    if (!mounted) return;
    setState(() => _showSlowWarning = false);
    _startSlowTimer();
    context.read<TripPlannerCubit>().generateTripPlan(
      destination: widget.params['destination'] as String,
      durationDays: widget.params['durationDays'] as int,
      budgetTier: widget.params['budgetTier'] as String,
      travelStyles: (widget.params['travelStyles'] as List).cast<String>(),
      travelersCount: widget.params['travelersCount'] as int,
      startDate: widget.params['startDate'] as DateTime?,
    );
  }

  void _handleState(TripPlannerState state) {
    if (state is TripPlannerSuccess) {
      _aiCompleted = true;
      _slowWarningTimer?.cancel();
      final allStepsShown = _currentStep >= 4;
      if (allStepsShown) {
        _navigateToSuccess(state);
      } else {
        _pendingSuccessState = state; // wait for animation
      }
    } else if (state is TripPlannerError) {
      _slowWarningTimer?.cancel();
      // show error dialog immediately regardless of animation
      _showErrorDialog(state.message);
    }
  }

  void _navigateToSuccess(TripPlannerState state) {
    if (state is TripPlannerSuccess && mounted) {
      context.go('/trip/${state.trip.id}', extra: state.trip);
    }
  }

  void _showErrorDialog(String message) {
    // Map technical error codes to user-friendly Arabic messages
    final String userMessage = _localizeError(message);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        backgroundColor: AppColors.adaptiveBgCard(context),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: Row(
          children: [
            const Text('⚠️', style: TextStyle(fontSize: 22)),
            const SizedBox(width: 8),
            Text(AppStrings.of(context).errorTitle, style: AppTextStyles.headlineMedium),
          ],
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(userMessage, style: AppTextStyles.bodyMedium),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              context.go('/plan');
            },
            child: Text(AppStrings.of(context).errorRetry,
                style: TextStyle(color: AppColors.accentAmber)),
          ),
        ],
      ),
    );
  }

  /// Converts technical error codes from AIException into user-friendly Arabic strings.
  String _localizeError(String code) {
    if (code.contains('server-warmup-timeout') || code.contains('network-exception') || code.contains('connectionTimeout')) {
      return '⏳ السيرفر كان في وضع السكون.\n'  
             'يرجى الانتظار 30-60 ثانية ثم إعادة المحاولة.';
    }
    if (code.contains('invalid-api-key')) {
      return '🔑 مفتاح API غير صالح أو منتهي.\n'
             'تحقق من إعدادات الخادم.';
    }
    if (code.contains('rate-limit')) {
      return '⏱ تجاوزت الحد المسموح من الطلبات.\n'
             'انتظر دقيقة ثم أعد المحاولة.';
    }
    if (code.contains('server-error')) {
      return '🛠 خطأ في الخادم.\n'
             'يرجى المحاولة مجدداً بعد قليل.';
    }
    return '❌ حدث خطأ أثناء توليد الرحلة.\n'
           'تحقق من اتصالك بالإنترنت وأعد المحاولة.';
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TripPlannerCubit, TripPlannerState>(
      listener: (context, state) => _handleState(state),
      child: Scaffold(
        backgroundColor: AppColors.adaptiveBgPrimary(context),
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
                      AppColors.adaptiveBgPrimary(context),
                    ],
                  ),
                ),
              ),
            ),

            // Floating particles
            ..._buildParticles(),

            SafeArea(
              child: Center(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      // Spinning logo
                      _buildSpinningLogo(),
                      const SizedBox(height: 24),

                      // Title
                      Text(
                        AppStrings.of(context).generatingTitle,
                        style: AppTextStyles.headlineLarge,
                        textAlign: TextAlign.center,
                      )
                          .animate(onPlay: (c) => c.repeat(reverse: true))
                          .fadeIn(duration: 600.ms),

                      const SizedBox(height: 6),
                      Text(
                        AppStrings.of(context).generatingSubtitle,
                        style: AppTextStyles.bodyMedium,
                        textAlign: TextAlign.center,
                      ),

                      // Warmup hint — shown when Render free-tier server may be asleep
                      if (AppConfig.kServerMayNeedWarmup) ...[
                        const SizedBox(height: 8),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 24),
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
                          decoration: BoxDecoration(
                            color: AppColors.accentAmber.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(10),
                            border: Border.all(
                              color: AppColors.accentAmber.withValues(alpha: 0.25),
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              const Text('⏳', style: TextStyle(fontSize: 14)),
                              const SizedBox(width: 6),
                              Flexible(
                                child: Text(
                                  'قد يستغرق الأمر حتى دقيقة عند أول استخدام',
                                  style: AppTextStyles.bodySmall.copyWith(
                                    color: AppColors.accentAmber,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                              ),
                            ],
                          ),
                        ),
                      ],

                      // 20s Timeout slow warning with Retry button
                      if (_showSlowWarning) ...[
                        const SizedBox(height: 12),
                        Container(
                          margin: const EdgeInsets.symmetric(horizontal: 20),
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(14),
                            border: Border.all(color: Colors.amber.withValues(alpha: 0.4)),
                          ),
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  const Icon(Icons.speed_rounded, color: Colors.amber, size: 18),
                                  const SizedBox(width: 8),
                                  Flexible(
                                    child: Text(
                                      'الخادم يستغرق وقتاً أطول من المعتاد...',
                                      style: AppTextStyles.bodyMedium.copyWith(
                                        color: Colors.amber,
                                        fontWeight: FontWeight.w600,
                                      ),
                                      textAlign: TextAlign.center,
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              ElevatedButton.icon(
                                onPressed: _startGeneration,
                                icon: const Icon(Icons.refresh_rounded, size: 16),
                                label: const Text('إعادة المحاولة الأن'),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: AppColors.accentAmber,
                                  foregroundColor: AppColors.bgPrimary,
                                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                                  textStyle: AppTextStyles.labelMedium,
                                ),
                              ),
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms).shake(hz: 2, curve: Curves.easeInOut),
                      ],

                      const SizedBox(height: 24),

                      // Steps
                      _buildSteps(context),

                      const SizedBox(height: 20),

                      // Progress dots
                      _buildProgressDots(),
                    ],
                  ),
                ),
              ),
            ),

            // Cancel Button
            Positioned(
              bottom: 20,
              left: 0,
              right: 0,
              child: Center(
                child: TextButton.icon(
                  onPressed: () => context.go('/plan'),
                  icon: Icon(
                    Icons.close_rounded,
                    color: AppColors.adaptiveTextSecondary(context),
                    size: 18,
                  ),
                  label: Text(
                    'إلغاء والعودة',
                    style: AppTextStyles.bodyMedium.copyWith(
                      color: AppColors.adaptiveTextSecondary(context),
                    ),
                  ),
                ),
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

  Widget _buildSteps(BuildContext context) {
    final stepsList = _steps(context);
    return SizedBox(
      width: 280,
      child: Column(
        children: stepsList.asMap().entries.map((entry) {
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
                              : AppColors.adaptiveGlass(context),
                      border: Border.all(
                        color: isDone
                            ? AppColors.success
                            : isActive
                                ? AppColors.accentAmber
                                : AppColors.adaptiveBorder(context),
                      ),
                    ),
                    child: Center(
                      child: isDone
                          ? const Icon(Icons.check_rounded,
                              size: 14, color: Colors.white)
                          : isActive
                              ? SizedBox(
                                  width: 12,
                                  height: 12,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: AppColors.adaptiveBgPrimary(context),
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
                            ? AppColors.adaptiveTextPrimary(context)
                            : AppColors.adaptiveTextSecondary(context),
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
