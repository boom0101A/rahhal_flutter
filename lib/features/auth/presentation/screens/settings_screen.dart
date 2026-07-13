// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
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
    final strings = AppStrings.of(context);
    if (_languageCode == 'ar') return strings.languageArabic;
    if (_languageCode == 'en') return strings.languageEnglish;
    return strings.languageArabicDefault;
  }

  String get _themeSubtitle {
    final strings = AppStrings.of(context);
    if (_themeModeStr == 'dark') return strings.themeDark;
    if (_themeModeStr == 'light') return strings.themeLight;
    if (_themeModeStr == 'system') return strings.themeSystem;
    return strings.themeDarkDefault;
  }

  void _showLanguageBottomSheet() {
    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.adaptiveBgCard(context),
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
                  AppStrings.of(context).selectLanguageTitle,
                  style: AppTextStyles.titleMedium,
                ),
              ),
              const Divider(),
              ListTile(
                title: Text(AppStrings.of(context).languageArabic, style: AppTextStyles.bodyLarge),
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
    final strings = AppStrings.of(context);
    showDialog(
      context: context,
      builder: (ctx) {
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              backgroundColor: AppColors.adaptiveBgCard(context),
              title: Text(strings.themeTitle, style: AppTextStyles.headlineMedium),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  RadioListTile<String>(
                    title: Text(strings.themeDark, style: AppTextStyles.bodyLarge),
                    value: 'dark',
                    groupValue: _themeModeStr,
                    activeColor: AppColors.accentAmber,
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          _themeModeStr = val;
                        });
                        _updateTheme(val);
                        Navigator.pop(ctx);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: Text(strings.themeLight, style: AppTextStyles.bodyLarge),
                    value: 'light',
                    groupValue: _themeModeStr,
                    activeColor: AppColors.accentAmber,
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          _themeModeStr = val;
                        });
                        _updateTheme(val);
                        Navigator.pop(ctx);
                      }
                    },
                  ),
                  RadioListTile<String>(
                    title: Text(strings.themeSystem, style: AppTextStyles.bodyLarge),
                    value: 'system',
                    groupValue: _themeModeStr,
                    activeColor: AppColors.accentAmber,
                    onChanged: (val) {
                      if (val != null) {
                        setDialogState(() {
                          _themeModeStr = val;
                        });
                        _updateTheme(val);
                        Navigator.pop(ctx);
                      }
                    },
                  ),
                ],
              ),
            );
          },
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
            SnackBar(content: Text(AppStrings.of(context).mailErrorCantOpen)),
          );
        }
      }
    } catch (_) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(AppStrings.of(context).mailErrorGeneral)),
        );
      }
    }
  }

  void _showAboutAppDialog() {
    final strings = AppStrings.of(context);
    showAboutDialog(
      context: context,
      applicationName: strings.appName,
      applicationVersion: '1.0.0',
      applicationIcon: const Text('✈️', style: TextStyle(fontSize: 40)),
      applicationLegalese: strings.copyrightText,
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return Scaffold(
        backgroundColor: AppColors.adaptiveBgPrimary(context),
        body: const Center(
          child: CircularProgressIndicator(color: AppColors.accentAmber),
        ),
      );
    }

    return Scaffold(
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
            AppStrings.of(context).settingsTitle,
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
                        user?.displayName ?? AppStrings.of(context).authGuestMode,
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
                  AppStrings.of(context).appSettingsSection,
                  style: AppTextStyles.titleMedium
                      .copyWith(color: AppColors.accentAmber),
                ),
                const SizedBox(height: 12),
                _buildSettingTile(
                  icon: Icons.language_rounded,
                  title: AppStrings.of(context).settingsLanguage,
                  subtitle: _languageSubtitle,
                  onTap: _showLanguageBottomSheet,
                ),
                _buildSettingTile(
                  icon: Icons.dark_mode_rounded,
                  title: AppStrings.of(context).themeTitle,
                  subtitle: _themeSubtitle,
                  onTap: _showThemeDialog,
                ),
                _buildSettingTile(
                  icon: Icons.notifications_none_rounded,
                  title: AppStrings.of(context).settingsNotifications,
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
                  AppStrings.of(context).legalSection,
                  style: AppTextStyles.titleMedium
                      .copyWith(color: AppColors.accentAmber),
                ),
                const SizedBox(height: 12),
                _buildSettingTile(
                  icon: Icons.help_outline_rounded,
                  title: AppStrings.of(context).helpSupport,
                  onTap: _openSupportMail,
                ),
                _buildSettingTile(
                  icon: Icons.info_outline_rounded,
                  title: AppStrings.of(context).aboutApp,
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
                        AppStrings.of(context).settingsLogout,
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
      );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback onTap,
  }) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Material(
        color: isDark ? AppColors.adaptiveBgCard(context) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        clipBehavior: Clip.antiAlias,
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(12),
            border: Border.all(
              color: isDark ? AppColors.adaptiveBorder(context) : const Color(0x1F000000),
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
                color: isDark ? AppColors.adaptiveTextPrimary(context) : const Color(0xFF0D1B2A),
              ),
            ),
            subtitle: subtitle != null
                ? Text(
                    subtitle,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: isDark ? AppColors.adaptiveTextSecondary(context) : const Color(0xFF6B7280),
                    ),
                  )
                : null,
            trailing: Icon(
              Icons.arrow_forward_ios_rounded,
              color: isDark ? AppColors.adaptiveTextSecondary(context) : const Color(0xFF9CA3AF),
              size: 16,
            ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
