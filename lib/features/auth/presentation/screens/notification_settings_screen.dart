import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/services/notification_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_strings.dart';

class NotificationSettingsScreen extends StatefulWidget {
  const NotificationSettingsScreen({super.key});

  @override
  State<NotificationSettingsScreen> createState() => _NotificationSettingsScreenState();
}

class _NotificationSettingsScreenState extends State<NotificationSettingsScreen> {
  bool _tripReminders = true;
  bool _aiSuggestions = true;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadPreferences();
  }

  Future<void> _loadPreferences() async {
    final trip =
        await NotificationPreferences.isEnabled(NotificationPreferences.tripReminders);
    final ai =
        await NotificationPreferences.isEnabled(NotificationPreferences.aiSuggestions);
    if (!mounted) return;
    setState(() {
      _tripReminders = trip;
      _aiSuggestions = ai;
      _loading = false;
    });
  }

  Future<void> _toggleTripReminders(bool value) async {
    // Goes through NotificationPreferences so switching off also cancels
    // anything already queued — the old code only wrote a flag nobody read.
    await NotificationPreferences.setEnabled(
        NotificationPreferences.tripReminders, value);
    if (!mounted) return;
    setState(() => _tripReminders = value);
  }

  Future<void> _toggleAiSuggestions(bool value) async {
    await NotificationPreferences.setEnabled(
        NotificationPreferences.aiSuggestions, value);
    if (!mounted) return;
    setState(() => _aiSuggestions = value);
  }

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Scaffold(
      backgroundColor: AppColors.adaptiveBgPrimary(context),
      appBar: AppBar(
        backgroundColor: AppColors.adaptiveBgPrimary(context),
        elevation: 0,
        leading: IconButton(
          tooltip: strings.back,
          onPressed: () => context.pop(),
          icon: Icon(Icons.arrow_back_ios_new_rounded,
            color: AppColors.adaptiveTextPrimary(context), size: 20),
        ),
        title: Text(
          strings.settingsNotifications,
          style: AppTextStyles.headlineMedium.copyWith(
            color: AppColors.adaptiveTextPrimary(context),
          ),
        ),
        centerTitle: true,
      ),
      body: _loading
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.accentAmber),
            )
          : ListView(
              padding: const EdgeInsets.all(20),
              children: [
                _buildToggleCard(
                  title: strings.notifTripReminders,
                  subtitle: strings.notifTripRemindersDesc,
                  value: _tripReminders,
                  onChanged: _toggleTripReminders,
                ),
                const SizedBox(height: 16),
                _buildToggleCard(
                  title: strings.notifAiSuggestions,
                  subtitle: strings.notifAiSuggestionsDesc,
                  value: _aiSuggestions,
                  onChanged: _toggleAiSuggestions,
                ),
                const SizedBox(height: 24),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    strings.notifComingSoon,
                    style: AppTextStyles.bodySmall.copyWith(
                      color: AppColors.adaptiveTextSecondary(context),
                      fontStyle: FontStyle.italic,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildToggleCard({
    required String title,
    required String subtitle,
    required bool value,
    required ValueChanged<bool> onChanged,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.adaptiveBgCard(context),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.adaptiveBorder(context)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.adaptiveTextPrimary(context)),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.adaptiveTextSecondary(context)),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeThumbColor: AppColors.accentAmber,
            activeTrackColor: AppColors.accentAmber.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.adaptiveTextSecondary(context),
            inactiveTrackColor: AppColors.adaptiveGlass(context),
          ),
        ],
      ),
    );
  }
}
