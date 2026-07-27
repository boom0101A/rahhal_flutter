// ignore_for_file: deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/config/app_info.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../core/services/storage_service.dart';
import '../../../../features/currency/data/currency_service.dart';
import '../../../../shared/widgets/user_avatar.dart';
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

  /// null = follow the device region automatically.
  String? _homeCurrency;

  StorageUsage? _storage;
  bool _clearingCache = false;
  bool _deletingAccount = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
    _refreshStorage();
  }

  Future<void> _loadSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCurrency = prefs.getString('home_currency_code');
    if (!mounted) return;
    setState(() {
      _languageCode = prefs.getString('language_code') ?? 'ar';
      _themeModeStr = prefs.getString('theme_mode') ?? 'dark';
      _homeCurrency = savedCurrency;
      _loading = false;
    });
  }

  /// Measuring walks the cache directories, so it runs off the first frame and
  /// updates the tile in place rather than blocking the screen.
  Future<void> _refreshStorage() async {
    final usage = await sl<StorageService>().usage();
    if (!mounted) return;
    setState(() => _storage = usage);
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

  // ── Currency ──────────────────────────────────────────────────────────────

  /// Label for the currency row: the chosen code, or what auto-detection
  /// resolved to, so "Automatic" is never a mystery.
  String get _currencySubtitle {
    final strings = AppStrings.of(context);
    if (_homeCurrency != null) return _homeCurrency!;
    final detected =
        CurrencyService.currencyForCountry(CurrencyService.deviceCountryCode());
    return detected == null
        ? strings.settingsCurrencyAuto
        : '${strings.settingsCurrencyAuto} · $detected';
  }

  /// The currencies this app's travellers actually use, with automatic first.
  static const _currencyChoices = [
    null, // automatic
    'IQD', 'USD', 'EUR', 'TRY', 'SAR', 'AED', 'KWD', 'QAR', 'BHD', 'OMR',
    'JOD', 'EGP', 'LBP', 'SYP', 'GBP', 'IRR',
  ];

  Future<void> _showCurrencySheet() async {
    final strings = AppStrings.of(context);
    await showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.adaptiveBgCard(context),
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius:
            BorderRadius.only(topLeft: Radius.circular(20), topRight: Radius.circular(20)),
      ),
      builder: (ctx) => SafeArea(
        child: ConstrainedBox(
          constraints: BoxConstraints(
            maxHeight: MediaQuery.of(ctx).size.height * 0.7,
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Padding(
                padding: const EdgeInsets.symmetric(vertical: 20),
                child: Text(strings.selectCurrencyTitle,
                    style: AppTextStyles.titleMedium),
              ),
              const Divider(height: 1),
              Flexible(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: _currencyChoices.length,
                  itemBuilder: (_, i) {
                    final code = _currencyChoices[i];
                    final selected = code == _homeCurrency;
                    return ListTile(
                      title: Text(
                        code ?? strings.settingsCurrencyAuto,
                        style: AppTextStyles.bodyLarge,
                      ),
                      subtitle: code == null
                          ? null
                          : Text(CurrencyService.symbolFor(code),
                              style: AppTextStyles.labelSmall),
                      trailing: selected
                          ? const Icon(Icons.check_rounded,
                              color: AppColors.accentAmber)
                          : null,
                      onTap: () async {
                        await CurrencyService.setHomeCurrency(code);
                        if (!mounted) return;
                        setState(() => _homeCurrency = code);
                        if (ctx.mounted) Navigator.pop(ctx);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Storage ───────────────────────────────────────────────────────────────

  Future<void> _confirmClearCache() async {
    final strings = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.adaptiveBgCard(ctx),
            title: Text(strings.storageClear, style: AppTextStyles.titleMedium),
            content:
                Text(strings.storageClearConfirm, style: AppTextStyles.bodyMedium),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(strings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(strings.storageClear,
                    style: const TextStyle(
                        color: AppColors.accentAmber,
                        fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    setState(() => _clearingCache = true);
    await sl<StorageService>().clearCaches();
    await _refreshStorage();
    if (!mounted) return;
    setState(() => _clearingCache = false);
    messenger.showSnackBar(SnackBar(content: Text(strings.storageCleared)));
  }

  // ── Account ───────────────────────────────────────────────────────────────

  Future<void> _confirmDeleteAccount() async {
    final strings = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final router = GoRouter.of(context);
    final cubit = context.read<AuthCubit>();

    final confirmed = await showDialog<bool>(
          context: context,
          builder: (ctx) => AlertDialog(
            backgroundColor: AppColors.adaptiveBgCard(ctx),
            title: Text(strings.deleteAccountConfirmTitle,
                style: AppTextStyles.titleMedium),
            content: Text(strings.deleteAccountConfirmBody,
                style: AppTextStyles.bodyMedium),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(strings.cancel),
              ),
              TextButton(
                onPressed: () => Navigator.pop(ctx, true),
                child: Text(strings.deleteAccountConfirmAction,
                    style: const TextStyle(
                        color: AppColors.error, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ) ??
        false;
    if (!confirmed || !mounted) return;

    setState(() => _deletingAccount = true);
    final error = await cubit.deleteAccount();
    if (!mounted) return;
    setState(() => _deletingAccount = false);

    if (error == null) {
      messenger.showSnackBar(SnackBar(content: Text(strings.deleteAccountDone)));
      router.go('/auth');
      return;
    }
    // Firebase blocks deletion on a stale session; that specific case has a
    // fix the user can act on, so it gets its own message.
    messenger.showSnackBar(SnackBar(
      content: Text(error.contains('requires-recent-login')
          ? strings.deleteAccountReauth
          : strings.deleteAccountFailed),
    ));
  }

  Future<void> _openPrivacyPolicy() async {
    final strings = AppStrings.of(context);
    final messenger = ScaffoldMessenger.of(context);
    final uri = Uri.parse(AppInfo.privacyPolicyUrl);
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok && mounted) {
        messenger.showSnackBar(
            SnackBar(content: Text(strings.mailErrorCantOpen)));
      }
    } catch (_) {
      if (mounted) {
        messenger.showSnackBar(
            SnackBar(content: Text(strings.mailErrorCantOpen)));
      }
    }
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
      // Read from AppInfo instead of a literal, so it can't drift out of sync
      // with pubspec.yaml the way the old hardcoded '1.0.0' did.
      applicationVersion: AppInfo.fullVersion,
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
                        ? AppColors.adaptiveBgCard(context)
                        : Colors.white,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(
                      color: Theme.of(context).brightness == Brightness.dark
                          ? AppColors.adaptiveBorder(context)
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
                      // Shared with the Profile tab: a photo picked there
                      // shows up here too, and vice versa.
                      UserAvatar(
                        user: user,
                        radius: 40,
                        backgroundColor:
                            AppColors.accentAmber.withValues(alpha: 0.2),
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
                _buildSettingTile(
                  icon: Icons.payments_outlined,
                  title: AppStrings.of(context).settingsCurrency,
                  subtitle: _currencySubtitle,
                  onTap: _showCurrencySheet,
                ),

                // ── Storage ────────────────────────────────────────────────
                const SizedBox(height: 24),
                Text(
                  AppStrings.of(context).settingsStorage,
                  style: AppTextStyles.titleMedium
                      .copyWith(color: AppColors.accentAmber),
                ),
                const SizedBox(height: 12),
                _buildStorageCard(),

                // ── Account ────────────────────────────────────────────────
                const SizedBox(height: 24),
                Text(
                  AppStrings.of(context).accountSection,
                  style: AppTextStyles.titleMedium
                      .copyWith(color: AppColors.accentAmber),
                ),
                const SizedBox(height: 12),
                _buildSettingTile(
                  icon: Icons.privacy_tip_outlined,
                  title: AppStrings.of(context).settingsPrivacyPolicy,
                  onTap: _openPrivacyPolicy,
                ),
                // Only signed-in users have an account to delete; a guest
                // session has nothing on the server.
                if (user != null && !user.isAnonymous)
                  _buildSettingTile(
                    icon: Icons.person_remove_outlined,
                    title: AppStrings.of(context).settingsDeleteAccount,
                    isDestructive: true,
                    trailing: _deletingAccount
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                                strokeWidth: 2, color: AppColors.error),
                          )
                        : null,
                    onTap: _deletingAccount ? null : _confirmDeleteAccount,
                  ),

                // ── About ──────────────────────────────────────────────────
                const SizedBox(height: 24),
                Text(
                  AppStrings.of(context).aboutSection,
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
                  subtitle:
                      '${AppStrings.of(context).aboutVersion} ${AppInfo.fullVersion}',
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

  /// Shows what each cache is costing and offers to clear it. Deliberately
  /// spells out that only downloaded content goes — the biggest fear with a
  /// "clear" button is losing your trips.
  Widget _buildStorageCard() {
    final strings = AppStrings.of(context);
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final usage = _storage;

    Widget row(String label, String value) => Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(label,
                  style: AppTextStyles.bodySmall.copyWith(
                      color: isDark
                          ? AppColors.adaptiveTextSecondary(context)
                          : const Color(0xFF6B7280))),
              Text(value,
                  style: AppTextStyles.labelMedium.copyWith(
                      color: isDark
                          ? AppColors.adaptiveTextPrimary(context)
                          : const Color(0xFF0D1B2A))),
            ],
          ),
        );

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? AppColors.adaptiveBgCard(context) : Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isDark
              ? AppColors.adaptiveBorder(context)
              : const Color(0x1F000000),
        ),
      ),
      child: Column(
        children: [
          if (usage == null)
            row(strings.storageTotal, strings.storageCalculating)
          else ...[
            row(strings.storageImages,
                StorageService.formatBytes(usage.imageBytes)),
            row(strings.storageMapTiles,
                StorageService.formatBytes(usage.mapTileBytes)),
            Divider(height: 18, color: AppColors.adaptiveBorder(context)),
            row(strings.storageTotal,
                StorageService.formatBytes(usage.totalBytes)),
          ],
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (_clearingCache || (usage?.totalBytes ?? 0) == 0)
                  ? null
                  : _confirmClearCache,
              icon: _clearingCache
                  ? const SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: AppColors.accentAmber),
                    )
                  : const Icon(Icons.cleaning_services_rounded, size: 17),
              label: Text(strings.storageClear),
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.accentAmber,
                side: BorderSide(
                    color: AppColors.accentAmber.withValues(alpha: 0.5)),
                padding: const EdgeInsets.symmetric(vertical: 12),
                shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSettingTile({
    required IconData icon,
    required String title,
    String? subtitle,
    required VoidCallback? onTap,
    bool isDestructive = false,
    Widget? trailing,
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
            leading: Icon(icon,
                color: isDestructive ? AppColors.error : AppColors.accentAmber),
            title: Text(
              title,
              style: AppTextStyles.bodyMedium.copyWith(
                color: isDestructive
                    ? AppColors.error
                    : (isDark
                        ? AppColors.adaptiveTextPrimary(context)
                        : const Color(0xFF0D1B2A)),
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
            trailing: trailing ??
                Icon(
                  Icons.arrow_forward_ios_rounded,
                  color: isDark
                      ? AppColors.adaptiveTextSecondary(context)
                      : const Color(0xFF9CA3AF),
                  size: 16,
                ),
            onTap: onTap,
          ),
        ),
      ),
    );
  }
}
