# ملف كود Dart: lib\features\auth\presentation\screens\notification_settings_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';

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
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _tripReminders = prefs.getBool('notifications_trip_reminders') ?? true;
      _aiSuggestions = prefs.getBool('notifications_ai_suggestions') ?? true;
      _loading = false;
    });
  }

  Future<void> _toggleTripReminders(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_trip_reminders', value);
    setState(() {
      _tripReminders = value;
    });
  }

  Future<void> _toggleAiSuggestions(bool value) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool('notifications_ai_suggestions', value);
    setState(() {
      _aiSuggestions = value;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      appBar: AppBar(
        backgroundColor: AppColors.bgPrimary,
        elevation: 0,
        leading: IconButton(
          onPressed: () => Navigator.of(context).pop(),
          icon: const Icon(Icons.arrow_back_ios_new_rounded, color: Colors.white, size: 20),
        ),
        title: Text(
          'الإشعارات',
          style: AppTextStyles.headlineMedium,
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
                  title: 'تذكير الرحلات القادمة',
                  subtitle: 'تلقي إشعارات لتذكيرك بمواعيد رحلاتك المجدولة',
                  value: _tripReminders,
                  onChanged: _toggleTripReminders,
                ),
                const SizedBox(height: 16),
                _buildToggleCard(
                  title: 'اقتراحات ذكية من الذكاء الاصطناعي',
                  subtitle: 'احصل على نصائح سفر وتوصيات مخصصة لرحلاتك القادمة',
                  value: _aiSuggestions,
                  onChanged: _toggleAiSuggestions,
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
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: AppTextStyles.titleMedium.copyWith(color: AppColors.textPrimary),
                ),
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: AppTextStyles.bodySmall.copyWith(color: AppColors.textSecondary),
                ),
              ],
            ),
          ),
          const SizedBox(width: 16),
          Switch(
            value: value,
            onChanged: onChanged,
            activeColor: AppColors.accentAmber,
            activeTrackColor: AppColors.accentAmber.withValues(alpha: 0.3),
            inactiveThumbColor: AppColors.textSecondary,
            inactiveTrackColor: AppColors.glass,
          ),
        ],
      ),
    );
  }
}

```
