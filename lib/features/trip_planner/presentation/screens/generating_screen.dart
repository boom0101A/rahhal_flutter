import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/services/notification_service.dart';
import '../../domain/entities/trip_entity.dart';
import '../../../../core/config/app_config.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/utils/haptics.dart';
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
  TripPlannerState? _pendingSuccessState; // hold success state until animation done

  int _factIndex = 0;
  Timer? _factTimer;

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
    _startFactRotation();
    // Trigger generation after the frame is built so BlocProvider is ready
    WidgetsBinding.instance.addPostFrameCallback((_) => _startGeneration());
  }

  void _startFactRotation() {
    _factTimer?.cancel();
    _factTimer = Timer.periodic(const Duration(seconds: 5), (_) {
      if (!mounted) return;
      final facts = AppStrings.of(context).travelFacts;
      setState(() => _factIndex = (_factIndex + 1) % facts.length);
    });
  }

  @override
  void dispose() {
    _factTimer?.cancel();
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
    context.read<TripPlannerCubit>().generateTripPlan(
      destination: widget.params['destination'] as String,
      durationDays: widget.params['durationDays'] as int,
      budgetTier: widget.params['budgetTier'] as String,
      travelStyles: (widget.params['travelStyles'] as List).cast<String>(),
      travelersCount: widget.params['travelersCount'] as int,
      startDate: widget.params['startDate'] as DateTime?,
      userLat: widget.params['userLat'] as double?,
      userLng: widget.params['userLng'] as double?,
      countryCode: widget.params['countryCode'] as String?,
    );
  }

  void _handleState(TripPlannerState state) {
    if (state is TripPlannerSuccess) {
      _aiCompleted = true;
        Haptics.success();
      final allStepsShown = _currentStep >= 4;
      if (allStepsShown) {
        _navigateToSuccess(state);
      } else {
        _pendingSuccessState = state; // wait for animation
      }
    } else if (state is TripPlannerError) {
        Haptics.warning();
      // show error dialog immediately regardless of animation
      _showErrorDialog(state.message);
    }
  }

  void _navigateToSuccess(TripPlannerState state) {
    if (state is TripPlannerSuccess && mounted) {
      _scheduleTripReminder(state.trip);
      context.go('/trip/${state.trip.id}', extra: state.trip);
    }
  }

  /// If the trip has a start date, schedule a "your trip is coming up"
  /// reminder for a few days before. Fire-and-forget — a failed reminder must
  /// never block opening the trip.
  Future<void> _scheduleTripReminder(TripEntity trip) async {
    final start = trip.startDate;
    if (start == null) return;
    final strings = AppStrings.of(context);
    await NotificationService.requestPermission();
    await NotificationService.scheduleTripReminder(
      tripId: trip.id,
      title: strings.notifTripSoonTitle(trip.destination),
      body: strings.notifTripSoonBody,
      tripStartDate: start,
    );
  }

  void _showErrorDialog(String message) {
    // Map technical error codes to user-friendly messages
    final String userMessage = _localizeError(context, message);

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

  /// Converts technical error codes from AIException into user-friendly text.
  String _localizeError(BuildContext context, String code) {
    final strings = AppStrings.of(context);
    if (code.contains('server-warmup-timeout') || code.contains('network-exception') || code.contains('connectionTimeout')) {
      return strings.genErrorServerAsleep;
    }
    if (code.contains('invalid-api-key') || code.contains('missing-api-key')) {
      return strings.genErrorApiKey;
    }
    if (code.contains('rate-limit')) {
      return strings.genErrorRateLimit;
    }
    if (code.contains('server-error')) {
      return strings.genErrorServer;
    }
    return strings.genErrorGeneric;
  }

  @override
  Widget build(BuildContext context) {
    return BlocListener<TripPlannerCubit, TripPlannerState>(
      listener: (context, state) => _handleState(state),
      child: Scaffold(
        backgroundColor: AppColors.adaptiveBgPrimary(context),
        // ✅ Use resizeToAvoidBottomInset to handle keyboard edge cases
        resizeToAvoidBottomInset: false,
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

            // ✅ KEY FIX: Use SafeArea + CustomScrollView instead of Center + SingleChildScrollView
            SafeArea(
              child: CustomScrollView(
                // ✅ This ensures content is always scrollable if it exceeds screen
                physics: const BouncingScrollPhysics(),
                slivers: [
                  SliverFillRemaining(
                    // The child is a plain Column, which cannot scroll itself.
                    // hasScrollBody: false stretches it to fill a tall viewport
                    // (keeping the content centred) but lets it grow past the
                    // viewport and scroll with the CustomScrollView when the
                    // window is short or the slow-warning banner expands —
                    // whereas `true` would pin it to the viewport height and
                    // paint the yellow/black overflow stripes.
                    hasScrollBody: false,
                    child: Padding(
                      padding: const EdgeInsets.fromLTRB(20, 20, 20, 80),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          // Spinning logo
                          _buildSpinningLogo(),
                          const SizedBox(height: 20),

                          // Title
                          Text(
                            AppStrings.of(context).generatingTitle,
                            style: AppTextStyles.headlineLarge,
                            textAlign: TextAlign.center,
                          ).animate(onPlay: (c) => c.repeat(reverse: true))
                              .fadeIn(duration: 600.ms),

                          const SizedBox(height: 6),
                          Text(
                            AppStrings.of(context).generatingSubtitle,
                            style: AppTextStyles.bodyMedium,
                            textAlign: TextAlign.center,
                          ),

                          // Warmup hint
                          if (AppConfig.kServerMayNeedWarmup) ...[
                            const SizedBox(height: 8),
                            Container(
                              margin: const EdgeInsets.symmetric(horizontal: 24),
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 14, vertical: 8),
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
                                      AppStrings.of(context).genFirstRunHint,
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

                          const SizedBox(height: 20),

                          // Steps
                          _buildSteps(context),

                          const SizedBox(height: 16),

                          // Progress dots
                          _buildProgressDots(),

                          const SizedBox(height: 20),

                          // Rotating "did you know" travel facts — gives the
                          // wait a purpose instead of just spinning.
                          _buildTravelFact(context),

                          const SizedBox(height: 12),

                          // ✅ Cancel button INSIDE scroll — not Positioned
                          TextButton.icon(
                            onPressed: () => context.go('/plan'),
                            icon: Icon(
                              Icons.close_rounded,
                              color: AppColors.adaptiveTextSecondary(context),
                              size: 18,
                            ),
                            label: Text(
                              AppStrings.of(context).genCancelAndBack,
                              style: AppTextStyles.bodyMedium.copyWith(
                                color: AppColors.adaptiveTextSecondary(context),
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

  Widget _buildTravelFact(BuildContext context) {
    final facts = AppStrings.of(context).travelFacts;
    final fact = facts[_factIndex % facts.length];

    return Container(
      constraints: const BoxConstraints(maxWidth: 320),
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: AppColors.adaptiveGlass(context),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppColors.adaptiveGlassBorder(context)),
      ),
      child: AnimatedSwitcher(
        duration: const Duration(milliseconds: 400),
        transitionBuilder: (child, animation) => FadeTransition(
          opacity: animation,
          child: SizeTransition(sizeFactor: animation, child: child),
        ),
        child: Row(
          key: ValueKey(_factIndex),
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('💡', style: TextStyle(fontSize: 16)),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                fact,
                style: AppTextStyles.bodySmall.copyWith(
                  color: AppColors.adaptiveTextSecondary(context),
                ),
                textAlign: TextAlign.start,
              ),
            ),
          ],
        ),
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
