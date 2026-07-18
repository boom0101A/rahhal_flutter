import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection.dart';
import '../cubit/auth_cubit.dart';
import '../../domain/entities/user_entity.dart';
import '../../../trip_planner/presentation/cubit/saved_trips_cubit.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return BlocProvider(
      create: (_) => sl<SavedTripsCubit>()..loadTrips(),
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final user = authState is AuthAuthenticated ? authState.user : null;

          return Scaffold(
            backgroundColor: AppColors.adaptiveBgPrimary(context),
            body: CustomScrollView(
              slivers: [
                // Header with avatar and user details
                SliverAppBar(
                  expandedHeight: 220,
                  pinned: true,
                  backgroundColor: AppColors.adaptiveBgPrimary(context),
                  elevation: 0,
                  flexibleSpace: FlexibleSpaceBar(
                    background: _buildProfileHeader(context, user),
                  ),
                ),

                SliverToBoxAdapter(
                  child: Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
                    child: Column(
                      children: [
                        // User Stats
                        BlocBuilder<SavedTripsCubit, SavedTripsState>(
                          builder: (context, state) {
                            final tripCount = state is SavedTripsLoaded ? state.trips.length : 0;
                            return _buildStatsRow(context, tripCount);
                          },
                        ),

                        const SizedBox(height: 24),

                        // Options Group
                        Container(
                          decoration: BoxDecoration(
                            color: AppColors.adaptiveBgCard(context),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: AppColors.adaptiveBorder(context)),
                          ),
                          child: Column(
                            children: [
                              ListTile(
                                leading: Icon(Icons.settings_rounded, color: AppColors.accentAmber),
                                title: Text(strings.settingsTitle, style: AppTextStyles.titleMedium.copyWith(color: AppColors.adaptiveTextPrimary(context))),
                                trailing: Icon(Icons.chevron_right_rounded, color: AppColors.adaptiveTextSecondary(context)),
                                onTap: () => context.push('/settings'),
                              ),
                              Divider(height: 1, color: AppColors.adaptiveBorder(context)),
                              ListTile(
                                leading: Icon(Icons.notifications_outlined, color: AppColors.accentAmber),
                                title: Text(strings.settingsNotifications, style: AppTextStyles.titleMedium.copyWith(color: AppColors.adaptiveTextPrimary(context))),
                                trailing: Icon(Icons.chevron_right_rounded, color: AppColors.adaptiveTextSecondary(context)),
                                onTap: () => context.push('/settings/notifications'),
                              ),
                              if (user != null && !user.isAnonymous) ...[
                                Divider(height: 1, color: AppColors.adaptiveBorder(context)),
                                ListTile(
                                  leading: const Icon(Icons.logout_rounded, color: AppColors.error),
                                  title: Text(strings.settingsSignOut, style: AppTextStyles.titleMedium.copyWith(color: AppColors.error)),
                                  onTap: () => context.read<AuthCubit>().signOut(),
                                ),
                              ],
                            ],
                          ),
                        ).animate().fadeIn(duration: 400.ms),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserEntity? user) {
    final displayName = user?.displayName ?? AppStrings.of(context).authGuestMode;
    final email = user?.email ?? '';
    final photoUrl = user?.photoUrl;

    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B2A47), Color(0xFF0D1B2A)],
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: AppColors.accentAmber,
              backgroundImage: (photoUrl != null && photoUrl.isNotEmpty)
                  ? NetworkImage(photoUrl)
                  : null,
              child: (photoUrl == null || photoUrl.isEmpty)
                  ? Text(
                      displayName.isNotEmpty ? displayName[0].toUpperCase() : '👤',
                      style: AppTextStyles.displaySmall.copyWith(color: Colors.black),
                    )
                  : null,
            ).animate().scale(duration: 400.ms, curve: Curves.easeOutBack),
            const SizedBox(height: 12),
            Text(
              displayName,
              style: AppTextStyles.headlineMedium.copyWith(color: Colors.white),
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                email,
                style: AppTextStyles.bodySmall.copyWith(color: Colors.white70),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatsRow(BuildContext context, int tripCount) {
    final strings = AppStrings.of(context);

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
      decoration: BoxDecoration(
        color: AppColors.adaptiveBgCard(context),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppColors.adaptiveBorder(context)),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildStatColumn(context, '$tripCount', strings.navMyTrips, Icons.flight_takeoff_rounded),
          Container(height: 30, width: 1, color: AppColors.adaptiveBorder(context)),
          _buildStatColumn(context, '${(tripCount * 0.7).ceil()}', strings.statsPlaces, Icons.place_rounded),
          Container(height: 30, width: 1, color: AppColors.adaptiveBorder(context)),
          _buildStatColumn(context, 'AI 🤖', strings.splashSubtitle, Icons.auto_awesome_rounded),
        ],
      ),
    ).animate().fadeIn(duration: 400.ms);
  }

  Widget _buildStatColumn(BuildContext context, String value, String label, IconData icon) {
    return Column(
      children: [
        Icon(icon, color: AppColors.accentAmber, size: 20),
        const SizedBox(height: 6),
        Text(
          value,
          style: AppTextStyles.titleMedium.copyWith(
            fontWeight: FontWeight.bold,
            color: AppColors.adaptiveTextPrimary(context),
          ),
        ),
        Text(
          label,
          style: AppTextStyles.labelSmall.copyWith(
            color: AppColors.adaptiveTextSecondary(context),
          ),
        ),
      ],
    );
  }
}
