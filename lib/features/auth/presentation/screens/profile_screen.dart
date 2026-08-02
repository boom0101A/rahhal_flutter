import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_strings.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/widgets/user_avatar.dart';
import '../cubit/auth_cubit.dart';
import '../../data/local_avatar_service.dart';
import '../../data/profile_stats_service.dart';
import '../../domain/entities/user_entity.dart';
import '../../../trip_planner/domain/entities/trip_entity.dart';
import '../../../trip_planner/presentation/cubit/saved_trips_cubit.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  int? _visitedPlaces;
  int? _messagesSent;

  /// Owned here, not created inside `build()`'s BlocProvider — otherwise the
  /// provider sits BELOW this State and `context.read` from `_refreshAll`
  /// throws "Could not find the correct Provider", silently breaking
  /// pull-to-refresh (so the trip count never updated after a deletion).
  /// Same root cause as the saved-trips screen.
  late final SavedTripsCubit _tripsCubit;

  @override
  void initState() {
    super.initState();
    _tripsCubit = sl<SavedTripsCubit>()..loadTrips();
    _loadStats();
  }

  @override
  void dispose() {
    // BlocProvider.value does not own the cubit, so we close it.
    _tripsCubit.close();
    super.dispose();
  }

  Future<void> _loadStats() async {
    final stats = sl<ProfileStatsService>();
    final results = await Future.wait([
      stats.visitedPlacesCount(),
      stats.messagesSentCount(),
    ]);
    if (!mounted) return;
    setState(() {
      _visitedPlaces = results[0];
      _messagesSent = results[1];
    });
  }

  Future<void> _refreshAll() async {
    await Future.wait([
      _tripsCubit.loadTrips(),
      _loadStats(),
    ]);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return BlocProvider.value(
      value: _tripsCubit,
      child: BlocBuilder<AuthCubit, AuthState>(
        builder: (context, authState) {
          final user = authState is AuthAuthenticated ? authState.user : null;

          return Scaffold(
            backgroundColor: AppColors.adaptiveBgPrimary(context),
            body: RefreshIndicator(
              onRefresh: _refreshAll,
              color: AppColors.accentAmber,
              child: CustomScrollView(
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
                          // User Stats + quick links, both driven by the same
                          // trips list so they stay in sync with one query.
                          BlocBuilder<SavedTripsCubit, SavedTripsState>(
                            builder: (context, state) {
                              final trips =
                                  state is SavedTripsLoaded ? state.trips : const <TripEntity>[];
                              return Column(
                                children: [
                                  _buildStatsRow(context, trips.length),
                                  const SizedBox(height: 16),
                                  _buildQuickLinks(context, trips),
                                ],
                              );
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
            ),
          );
        },
      ),
    );
  }

  Widget _buildProfileHeader(BuildContext context, UserEntity? user) {
    final strings = AppStrings.of(context);
    final displayName = user?.displayName ?? strings.authGuestMode;
    final email = user?.email ?? '';

    // This header was a `const BoxDecoration` with a fixed navy gradient and
    // hardcoded white text, so it stayed dark while the rest of the screen
    // went light — the one section of the app that ignored the theme.
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final headerColors = isDark
        ? const [Color(0xFF1B2A47), Color(0xFF0D1B2A)]
        : const [Color(0xFFE8EDF5), Color(0xFFF5F7FA)];
    final onHeaderPrimary =
        isDark ? Colors.white : AppColors.textPrimaryLight;
    final onHeaderSecondary =
        isDark ? Colors.white70 : AppColors.textSecondaryLight;

    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: headerColors,
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
        ),
      ),
      child: SafeArea(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Stack(
              clipBehavior: Clip.none,
              children: [
                UserAvatar(user: user, radius: 42)
                    .animate()
                    .scale(duration: 400.ms, curve: Curves.easeOutBack),
                // Editing a Google/Firebase profile makes no sense for a
                // signed-out visitor — there's no account to write to.
                if (user != null)
                  Positioned(
                    bottom: -2,
                    right: -2,
                    child: GestureDetector(
                      onTap: () => _showEditProfileSheet(user),
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: AppColors.accentAmber,
                          shape: BoxShape.circle,
                          // Ring matches the header behind it so the badge
                          // reads as lifted off the avatar in both themes.
                          border: Border.all(color: headerColors.last, width: 2),
                        ),
                        child: const Icon(Icons.edit_rounded,
                            size: 14, color: Colors.black),
                      ),
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              displayName,
              style: AppTextStyles.headlineMedium.copyWith(color: onHeaderPrimary),
            ),
            if (email.isNotEmpty) ...[
              const SizedBox(height: 4),
              Text(
                email,
                style: AppTextStyles.bodySmall.copyWith(color: onHeaderSecondary),
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
          _buildStatColumn(
            context,
            _visitedPlaces == null ? '—' : '${_visitedPlaces!}',
            strings.statsPlaces,
            Icons.place_rounded,
          ),
          Container(height: 30, width: 1, color: AppColors.adaptiveBorder(context)),
          _buildStatColumn(
            context,
            _messagesSent == null ? '—' : '${_messagesSent!}',
            strings.statsMessages,
            Icons.auto_awesome_rounded,
          ),
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

  Widget _buildQuickLinks(BuildContext context, List<TripEntity> trips) {
    final strings = AppStrings.of(context);
    // Trips arrive newest-first (TripRepository.getAllTrips orders by
    // created_at DESC), so the first entry is the trip whose documents a user
    // most likely wants — there's no "all documents" screen independent of a
    // trip, so this is the closest honest shortcut to one.
    final mostRecentTripId = trips.isEmpty ? null : trips.first.id;

    return Row(
      children: [
        Expanded(
          child: _quickLinkCard(
            context,
            icon: Icons.favorite_rounded,
            label: strings.profileQuickFavorites,
            onTap: () => context.push('/favorites'),
          ),
        ),
        const SizedBox(width: 12),
        Expanded(
          child: _quickLinkCard(
            context,
            icon: Icons.folder_rounded,
            label: strings.profileQuickDocuments,
            onTap: mostRecentTripId == null
                ? null
                : () => context.push('/trip/$mostRecentTripId/documents'),
          ),
        ),
      ],
    );
  }

  Widget _quickLinkCard(
    BuildContext context, {
    required IconData icon,
    required String label,
    required VoidCallback? onTap,
  }) {
    final disabled = onTap == null;
    return InkWell(
      onTap: onTap ??
          () => ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                    content: Text(AppStrings.of(context).profileNoTripForDocuments)),
              ),
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14),
        decoration: BoxDecoration(
          color: AppColors.adaptiveBgCard(context),
          borderRadius: BorderRadius.circular(16),
          border: Border.all(color: AppColors.adaptiveBorder(context)),
        ),
        child: Column(
          children: [
            Icon(icon,
                size: 20,
                color: disabled
                    ? AppColors.adaptiveTextSecondary(context)
                    : AppColors.accentAmber),
            const SizedBox(height: 6),
            Text(
              label,
              style: AppTextStyles.labelMedium.copyWith(
                color: disabled
                    ? AppColors.adaptiveTextSecondary(context)
                    : AppColors.adaptiveTextPrimary(context),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Edit profile ────────────────────────────────────────────────────────

  Future<void> _showEditProfileSheet(UserEntity user) async {
    // Uses the State's own `context` throughout (not a parameter), so the
    // `mounted` checks below actually guard every use of it across the awaits.
    final strings = AppStrings.of(context);
    final cubit = context.read<AuthCubit>();
    final hasLocalAvatar = await sl<LocalAvatarService>().currentAvatar() != null;
    if (!mounted) return;

    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.adaptiveBgCard(context),
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (sheetCtx) => SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: 8),
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: AppColors.adaptiveBorder(sheetCtx),
                borderRadius: BorderRadius.circular(50),
              ),
            ),
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 16),
              child: Text(strings.profileEditPhoto, style: AppTextStyles.titleMedium),
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_outlined, color: AppColors.accentAmber),
              title: Text(strings.profileChooseFromGallery, style: AppTextStyles.bodyLarge),
              onTap: () {
                Navigator.pop(sheetCtx);
                _pickAvatar(ImageSource.gallery);
              },
            ),
            ListTile(
              leading: const Icon(Icons.camera_alt_outlined, color: AppColors.accentAmber),
              title: Text(strings.profileTakePhoto, style: AppTextStyles.bodyLarge),
              onTap: () {
                Navigator.pop(sheetCtx);
                _pickAvatar(ImageSource.camera);
              },
            ),
            if (hasLocalAvatar)
              ListTile(
                leading: const Icon(Icons.delete_outline_rounded, color: AppColors.error),
                title: Text(strings.profileRemovePhoto,
                    style: AppTextStyles.bodyLarge.copyWith(color: AppColors.error)),
                onTap: () async {
                  Navigator.pop(sheetCtx);
                  await sl<LocalAvatarService>().clear();
                },
              ),
            Divider(height: 1, color: AppColors.adaptiveBorder(sheetCtx)),
            ListTile(
              leading: const Icon(Icons.edit_outlined, color: AppColors.accentAmber),
              title: Text(strings.profileEditName, style: AppTextStyles.bodyLarge),
              onTap: () {
                Navigator.pop(sheetCtx);
                _showEditNameDialog(cubit, user.displayName ?? '');
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }

  Future<void> _pickAvatar(ImageSource source) async {
    final messenger = ScaffoldMessenger.of(context);
    final strings = AppStrings.of(context);
    try {
      final saved = await sl<LocalAvatarService>().pickAndSave(source);
      if (saved == null) return; // user cancelled — no message needed
      if (!mounted) return;
      // UserAvatar listens to LocalAvatarService.version itself, so no manual
      // setState is needed here for the picture to update.
      messenger.showSnackBar(SnackBar(content: Text(strings.profileNameUpdated)));
    } on AvatarPermissionDeniedException {
      if (!mounted) return;
      messenger.showSnackBar(SnackBar(
        content: Text(strings.avatarPermissionDenied),
        backgroundColor: AppColors.error,
      ));
    }
  }

  Future<void> _showEditNameDialog(AuthCubit cubit, String currentName) async {
    final strings = AppStrings.of(context);
    final controller = TextEditingController(text: currentName);
    final messenger = ScaffoldMessenger.of(context);

    final newName = await showDialog<String>(
      context: context,
      builder: (dialogCtx) => AlertDialog(
        backgroundColor: AppColors.adaptiveBgCard(dialogCtx),
        title: Text(strings.profileEditName, style: AppTextStyles.titleMedium),
        content: TextField(
          controller: controller,
          autofocus: true,
          style: AppTextStyles.bodyLarge,
          decoration: InputDecoration(hintText: strings.profileNameHint),
          textInputAction: TextInputAction.done,
          onSubmitted: (v) => Navigator.pop(dialogCtx, v),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx),
            child: Text(strings.cancel),
          ),
          TextButton(
            onPressed: () => Navigator.pop(dialogCtx, controller.text),
            child: Text(strings.save,
                style: const TextStyle(
                    color: AppColors.accentAmber, fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );
    controller.dispose();

    if (newName == null) return; // cancelled
    if (newName.trim().isEmpty) {
      messenger.showSnackBar(SnackBar(content: Text(strings.profileNameEmpty)));
      return;
    }
    if (newName.trim() == currentName.trim()) return; // no-op, nothing to save

    final error = await cubit.updateDisplayName(newName);
    if (!mounted) return;
    messenger.showSnackBar(SnackBar(
      content: Text(error == null ? strings.profileNameUpdated : strings.profileUpdateFailed),
    ));
  }
}
