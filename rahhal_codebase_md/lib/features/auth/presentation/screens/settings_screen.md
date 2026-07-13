# ملف كود Dart: lib\features\auth\presentation\screens\settings_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../main.dart';
import '../../../../core/constants/app_strings.dart';
import '../cubit/auth_cubit.dart';
import 'notification_settings_screen.dart';

class SettingsScreen extends StatefulWidget {
  const SettingsScreen({super.key});

  @override
  State<SettingsScreen> createState() => _SettingsScreenState();
}

class _SettingsScreenState extends State<SettingsScreen> {
  String _languageCode = 'ar';
  String _themeModeStr = 'dark';
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _languageCode = prefs.getString('language_code') ?? 'ar';
      _themeModeStr = prefs.getString('theme_mode') ?? 'dark';
      _loading = false;
    });
  }

  Future<void> _updateLanguage(String code) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('language_code', code);
    setState(() {
      _languageCode = code;
    });
    if (mounted) {
      final countryCode = code == 'ar' ? 'AE' : 'US';
      RahhalApp.of(context)?.setLocale(Locale(code, countryCode));
    }
  }

  Future<void> _updateTheme(String themeVal) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('theme_mode', themeVal);
    setState(() {
      _themeModeStr = themeVal;
    });
    if (mounted) {
      ThemeMode mode = ThemeMode.dark;
      if (themeVal == 'light') {
        mode = ThemeMode.light;
      } else if (themeVal == 'system') {
        mode = ThemeMode.system;
      }
      RahhalApp.of(context)?.setThemeMode(mode);
    }
  }

  String get _languageSubtitle {
    if (_languageCode == 'ar') return AppStrings.languageArabic;
    if (_languageCode == 'en') return AppStrings.languageEnglish;
    return AppStrings.languageArabicDefault;
  }

  String get _themeSubtitle {
    if (_themeModeStr == 'dark') return AppStrings.themeDark;
    if (_themeModeStr == 'light') return AppStrings.themeLight;
    if (_themeModeStr == 'system') return AppStrings.themeSystem;
    return AppStrings.themeDarkDefault;
  }

  void _showLanguageBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.bgCard,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.only(
          topLeft: Radius.circular(20),
          topRight: Radius.circular(20),
        ),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(
                  AppStrings.selectLanguageTitle,
                  style: AppTextStyles.titleMedium,
                ),
              ),
              const Divider(),
              ListTile(
                title: Text(AppStrings.languageArabic, style: AppTextStyles.bodyLarge),
                trailing: _languageCode == 'ar'
                    ? const Icon(Icons.check_rounded, color: AppColors.accentAmber)
                    : null,
                onTap: () {
                  _updateLanguage('ar');
                  Navigator.pop(ctx);
                },
              ),
              ListTile(
                title: Text('English', style: AppTextStyles.bodyLarge),
                trailing: _languageCode == 'en'
                    ? const Icon(Icons.check_rounded, color: AppColors.accentAmber)
                    : null,
                onTap: () {
                  _updateLanguage('en');
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  void _showThemeDialog() {
    showDialog(
      context: context,
      builder: (ctx) {
        return AlertDialog(
          backgroundColor: AppColors.bgCard,
          title: Text(AppStrings.themeTitle, style: AppTextStyles.headlineMedium),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              RadioListTile<String>(
                title: Text(AppStrings.themeDark, style: AppTextStyles.bodyLarge),
                value: 'dark',
                groupValue: _themeModeStr,
                activeColor: AppColors.accentAmber,
                onChanged: (val) {
                  if (val != null) _updateTheme(val);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<String>(
                title: Text(AppStrings.themeLight, style: AppTextStyles.bodyLarge),
                value: 'light',
                groupValue: _themeModeStr,
                activeColor: AppColors.accentAmber,
                onChanged: (val) {
                  if (val != null) _updateTheme(val);
                  Navigator.pop(ctx);
                },
              ),
              RadioListTile<String>(
                title: Text(AppStrings.themeSystem, style: AppTextStyles.bodyLarge),
                value: 'system',
                groupValue: _themeModeStr,
                activeColor: AppColors.accentAmber,
                onChanged: (val) {
                  if (val != null) _updateTheme(val);
                  Navigator.pop(ctx);
                },
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openSupportMail() async {
    final Uri emailUri = Uri(
      scheme: 'mailto',
      path: 'support@rahhal-ai.com',
      queryParameters: {
        'subject': 'Help and Support - Rahhal AI',
      },
    );
    try {
      if (await canLaunchUrl(emailUri)) {
        await launchUrl(emailUri);
      } else {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(AppStrings.mailErrorCantOpen)),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.mailErrorGeneral)),
        );
      }
    }
  }

  void _showAboutAppDialog() {
    showAboutDialog(
      context: context,
      applicationName: AppStrings.appName,
      applicationVersion: '1.0.0',
      applicationIcon: const Text('✈️', style: TextStyle(fontSize: 40)),
      applicationLegalese: AppStrings.copyrightText,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        backgroundColor: AppColors.bgPrimary,
        body: Center(
          child: CircularProgressIndicator(color: AppColors.accentAmber),
        ),
      );
    }

    return BlocProvider(
      create: (_) => sl<AuthCubit>()..checkCurrentUser(),
      child: Scaffold(
        backgroundColor: Theme.of(context).scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: Theme.of(context).appBarTheme.backgroundColor,
          elevation: 0,
          leading: IconButton(
            onPressed: () => context.go('/home'),
            icon: Icon(
              Icons.arrow_back_ios_new_rounded,
              color: Theme.of(context).brightness == Brightness.dark
                  ? Colors.white
                  : const Color(0xFF0D1B2A),
              size: 20,
            ),
          ),
          title: Text(
            AppStrings.settingsTitle,
            style: Theme.of(context).appBarTheme.titleTextStyle,
          ),
          centerTitle: true,
        ),
        body: BlocBuilder<AuthCubit, AuthState>(
          builder: (context, state) {
            final user = state is AuthAuthenticated ? state.user : null;

            return ListView(
              padding: const EdgeInsets.all(20),
              children: [
                // Profile Section
                Container(
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: Theme.of(context).brightness == Brightness.dark
                        ? AppColors.bgCard
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.border
                          : const Color(0x1F000000),
                    ),
                    boxShadow: Theme.of(context).brightness == Brightness.light
                        ? [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.05),
                              blurRadius: 10,
                              offset: const Offset(0, 4),
                            )
                          ]
                        : null,
                  ),
                  child: Column(
                    children: [
                      CircleAvatar(
                        radius: 40,
                        backgroundColor:
                            AppColors.accentAmber.withValues(alpha: 0.2),
                        child: Text(
                          user?.initials ?? '؟',
                          style: AppTextStyles.displayMedium.copyWith(
                            color: AppColors.accentAmber,
                          ),
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        user?.displayName ?? AppStrings.authGuestMode,
                        style: Theme.of(context).brightness == Brightness.dark
                            ? AppTextStyles.headlineSmall
                            : AppTextStyles.headlineSmall.copyWith(color: const Color(0xFF0D1B2A)),
                      ),
                      if (user?.email != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          user!.email!,
                          style: Theme.of(context).brightness == Brightness.dark
                              ? AppTextStyles.bodySmall
                              : AppTextStyles.bodySmall.copyWith(color: const Color(0xFF4B5563)),
                        ),
                      ],
                    ],
                  ),
                ),
                const SizedBox(height: 24),

                // Settings Options
                Text(
                  AppStrings.appSettingsSection,
                  style: AppTextStyles.titleMedium
                      .copyWith(color: AppColors.accentAmber),
                ),
                const SizedBox(height: 12),
                _buildSettingTile(
                  icon: Icons.language_rounded,
                  title: AppStrings.settingsLanguage,
                  subtitle: _languageSubtitle,
                  onTap: _showLanguageBottomSheet,
                ),
                _buildSettingTile(
                  icon: Icons.dark_mode_rounded,
                  title: AppStrings.themeTitle,
                  subtitle: _themeSubtitle,
                  onTap: _showThemeDialog,
                ),
                _buildSettingTile(
                  icon: Icons.notifications_none_rounded,
                  title: AppStrings.settingsNotifications,
                  onTap: () {
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const NotificationSettingsScreen(),
                      ),
                    );
                  },
                ),

                const SizedBox(height: 24),
                Text(
                  AppStrings.legalSection,
                  style: AppTextStyles.titleMedium
                      .copyWith(color: AppColors.accentAmber),
                ),
                const SizedBox(height: 12),
                _buildSettingTile(
                  icon: Icons.help_outline_rounded,
                  title: AppStrings.helpSupport,
                  onTap: _openSupportMail,
                ),
                _buildSettingTile(
                  icon: Icons.info_outline_rounded,
                  title: AppStrings.aboutApp,
                  onTap: _showAboutAppDialog,
                ),

                const SizedBox(height: 32),

                // Logout/Exit Guest button
                if (user != null)
                  SizedBox(
                    width: double.infinity,
                    child: ElevatedButton.icon(
                      onPressed: () {
                        context.read<AuthCubit>().signOut();
                        context.go('/auth');
                      },
                      icon:
                          const Icon(Icons.logout_rounded, color: Colors.white),
                      label: Text(
                        AppStrings.settingsLogout,
                        style: const TextStyle(
                            color: Colors.white, fontWeight: FontWeight.bold),
                      ),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
              ],
            );
          },
        ),
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: isDark ? AppColors.bgCard : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark ? AppColors.border : const Color(0x1F000000),
        ),
        boxShadow: !isDark
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.03),
                  blurRadius: 6,
                  offset: const Offset(0, 2),
                )
              ]
            : null,
      ),
      child: ListTile(
        leading: Icon(icon, color: AppColors.accentAmber),
        title: Text(
          title,
          style: AppTextStyles.bodyMedium.copyWith(
            color: isDark ? AppColors.textPrimary : const Color(0xFF0D1B2A),
          ),
        ),
        subtitle: subtitle != null
            ? Text(
                subtitle,
                style: AppTextStyles.labelSmall.copyWith(
                  color: isDark ? AppColors.textSecondary : const Color(0xFF6B7280),
                ),
              )
            : null,
        trailing: Icon(
          Icons.arrow_forward_ios_rounded,
          color: isDark ? AppColors.textSecondary : const Color(0xFF9CA3AF),
          size: 16,
        ),
        onTap: onTap,
      ),
    );
  }
}

```
