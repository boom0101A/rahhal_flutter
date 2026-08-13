import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../core/constants/app_colors.dart';
import '../../core/constants/app_strings.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/services/map_launcher_service.dart';
import '../../core/utils/haptics.dart';

/// Converts a phone number as Google Places returns it (national format, e.g.
/// "0770 123 4567") into the digits-only international form WhatsApp needs
/// ("9647701234567").
///
/// Returns null when there aren't enough digits to be a real number, so callers
/// can hide the WhatsApp action instead of opening a broken chat.
String? whatsAppNumber(String? raw, {String? countryCode}) {
  if (raw == null) return null;
  var digits = raw.replaceAll(RegExp(r'[^\d+]'), '');
  if (digits.isEmpty) return null;

  // Already international ("+964...") — just drop the plus.
  if (digits.startsWith('+')) {
    digits = digits.substring(1);
    return digits.length >= 8 ? digits : null;
  }

  final dial = _dialingCode(countryCode);
  // National numbers start with a trunk "0" that must be dropped before the
  // country code is prefixed.
  if (digits.startsWith('0')) {
    digits = digits.replaceFirst(RegExp(r'^0+'), '');
    if (digits.isEmpty) return null;
    return dial == null ? null : '$dial$digits';
  }

  // No trunk zero and no plus: if it already looks like it carries a country
  // code, use as-is; otherwise prefix the trip's country.
  if (dial != null && digits.startsWith(dial)) return digits;
  if (dial != null) return '$dial$digits';
  return digits.length >= 10 ? digits : null;
}

/// ISO country code → international dialing code, for the destinations this app
/// actually plans trips to. Unknown codes return null, which hides WhatsApp
/// rather than guessing a wrong prefix.
String? _dialingCode(String? iso) {
  if (iso == null || iso.trim().isEmpty) return null;
  return const {
    'IQ': '964', 'SA': '966', 'AE': '971', 'KW': '965', 'QA': '974',
    'BH': '973', 'OM': '968', 'JO': '962', 'EG': '20', 'LB': '961',
    'SY': '963', 'YE': '967', 'TR': '90', 'IR': '98', 'MA': '212',
    'TN': '216', 'DZ': '213', 'LY': '218', 'SD': '249', 'PS': '970',
    'GB': '44', 'US': '1', 'FR': '33', 'DE': '49', 'IT': '39',
    'ES': '34', 'NL': '31', 'GR': '30', 'MY': '60', 'ID': '62',
    'PK': '92', 'IN': '91', 'TH': '66', 'AZ': '994', 'GE': '995',
    'AM': '374', 'CY': '357', 'RU': '7', 'CN': '86', 'JP': '81',
  }[iso.trim().toUpperCase()];
}

/// The "Booking & Contact" block shared by the restaurant and hotel detail
/// sheets. Deliberately honest: it only offers channels the venue actually has.
///
/// Booking in Iraq happens by phone or WhatsApp far more often than online, so
/// those lead; Maps is always offered because coordinates are always known.
class BookingContactSection extends StatelessWidget {
  /// Name used for the Maps deep link.
  final String placeName;
  final String? placeNameEn;
  final String? phone;
  final String? address;
  final double latitude;
  final double longitude;
  final String? placeId;

  /// Trip country (ISO-2), used to build the international WhatsApp number.
  final String? countryCode;

  /// Shows a small "report this place" icon next to the section title when
  /// provided. Omitted (null) by default so existing callers are unaffected.
  final VoidCallback? onReport;

  const BookingContactSection({
    super.key,
    required this.placeName,
    this.placeNameEn,
    this.phone,
    this.address,
    required this.latitude,
    required this.longitude,
    this.placeId,
    this.countryCode,
    this.onReport,
  });

  bool get _hasPhone => phone != null && phone!.trim().isNotEmpty;

  bool get _hasLocation =>
      (placeId != null && placeId!.isNotEmpty) ||
      (latitude != 0.0 && longitude != 0.0);

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);
    final wa = whatsAppNumber(phone, countryCode: countryCode);

    // Nothing at all to offer — don't render a dead section.
    if (!_hasPhone && !_hasLocation) return const SizedBox.shrink();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(strings.bookingSectionTitle, style: AppTextStyles.titleSmall),
            ),
            if (onReport != null)
              IconButton(
                visualDensity: VisualDensity.compact,
                tooltip: strings.reportIssueTooltip,
                icon: Icon(Icons.flag_outlined,
                    size: 18, color: AppColors.adaptiveTextSecondary(context)),
                onPressed: onReport,
              ),
          ],
        ),
        const SizedBox(height: 10),
        if (!_hasPhone)
          Padding(
            padding: const EdgeInsets.only(bottom: 10),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(Icons.info_outline_rounded,
                    size: 15, color: AppColors.adaptiveTextSecondary(context)),
                const SizedBox(width: 6),
                Expanded(
                  child: Text(
                    strings.bookingNoContact,
                    style: AppTextStyles.labelSmall.copyWith(
                      color: AppColors.adaptiveTextSecondary(context),
                    ),
                  ),
                ),
              ],
            ),
          ),
        Row(
          children: [
            if (wa != null)
              Expanded(
                child: _ActionButton(
                  icon: Icons.chat_rounded,
                  label: strings.bookingWhatsApp,
                  color: const Color(0xFF25D366),
                  onTap: () => _open(
                    context,
                    Uri.parse('https://wa.me/$wa'),
                    strings.bookingLaunchFailed,
                  ),
                ),
              ),
            if (wa != null && _hasPhone) const SizedBox(width: 8),
            if (_hasPhone)
              Expanded(
                child: _ActionButton(
                  icon: Icons.call_rounded,
                  label: strings.callAction,
                  color: AppColors.accentTurquoise,
                  onTap: () => _open(
                    context,
                    Uri.parse('tel:${phone!.replaceAll(RegExp(r'\s'), '')}'),
                    strings.bookingLaunchFailed,
                  ),
                ),
              ),
            if (_hasPhone && _hasLocation) const SizedBox(width: 8),
            if (_hasLocation)
              Expanded(
                child: _ActionButton(
                  icon: Icons.map_rounded,
                  label: strings.bookingOpenMaps,
                  color: AppColors.accentAmber,
                  onTap: () {
                    Haptics.tap();
                    MapLauncherService.openInGoogleMaps(
                      placeName: placeNameEn?.isNotEmpty == true
                          ? placeNameEn!
                          : placeName,
                      city: address,
                      lat: latitude,
                      lon: longitude,
                      placeId: placeId,
                    );
                  },
                ),
              ),
          ],
        ),
      ],
    );
  }

  Future<void> _open(BuildContext context, Uri uri, String failureMsg) async {
    Haptics.tap();
    final messenger = ScaffoldMessenger.of(context);
    // Launch directly rather than probing with canLaunchUrl: resolving a scheme
    // needs a <queries> manifest entry on Android 11+, but starting the
    // activity does not — and touching the manifest would break OTA patching.
    try {
      final ok = await launchUrl(uri, mode: LaunchMode.externalApplication);
      if (!ok) messenger.showSnackBar(SnackBar(content: Text(failureMsg)));
    } catch (_) {
      messenger.showSnackBar(SnackBar(content: Text(failureMsg)));
    }
  }
}

class _ActionButton extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color color;
  final VoidCallback onTap;

  const _ActionButton({
    required this.icon,
    required this.label,
    required this.color,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 11),
        decoration: BoxDecoration(
          color: color.withValues(alpha: 0.12),
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: color.withValues(alpha: 0.35)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(icon, color: color, size: 20),
            const SizedBox(height: 4),
            Text(
              label,
              style: AppTextStyles.labelSmall.copyWith(color: color),
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}
