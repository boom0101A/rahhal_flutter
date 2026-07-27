import 'package:flutter/material.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/injection.dart';
import '../../features/currency/data/currency_service.dart';

/// Shows a USD amount alongside the currencies the user actually reasons in:
///   • their HOME currency (an Iraqi sees dinars on every trip, anywhere), and
///   • the DESTINATION currency (what they'll hand over at the counter).
///
/// Duplicates collapse automatically — a Baghdad trip for an Iraqi user shows
/// one dinar figure, not two, and a USD-home user on a USD trip sees just "$25".
class DualCurrencyText extends StatefulWidget {
  final double amountUsd;

  /// ISO-2 country of the trip destination.
  final String? countryCode;
  final TextStyle? primaryStyle;
  final bool compact;

  const DualCurrencyText({
    super.key,
    required this.amountUsd,
    this.countryCode,
    this.primaryStyle,
    this.compact = false,
  });

  @override
  State<DualCurrencyText> createState() => _DualCurrencyTextState();
}

class _DualCurrencyTextState extends State<DualCurrencyText> {
  /// currency code → rate per 1 USD, in display order.
  final Map<String, double> _rates = {};
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRates();
  }

  @override
  void didUpdateWidget(DualCurrencyText old) {
    super.didUpdateWidget(old);
    if (old.countryCode != widget.countryCode) _fetchRates();
  }

  Future<void> _fetchRates() async {
    if (mounted) setState(() => _loading = true);

    final home = await CurrencyService.homeCurrency();
    final destination = CurrencyService.currencyForCountry(widget.countryCode);

    // Ordered + de-duplicated: home first (it's what the user feels), then the
    // destination. USD is the primary figure, so never repeat it here.
    final wanted = <String>{
      if (home != null && home != 'USD') home,
      if (destination != null && destination != 'USD') destination,
    };

    final fetched = <String, double>{};
    for (final code in wanted) {
      final rate = await sl<CurrencyService>().getRate(code);
      if (rate != null) fetched[code] = rate;
    }

    if (!mounted) return;
    setState(() {
      _rates
        ..clear()
        ..addAll(fetched);
      _loading = false;
    });
  }

  String get _primary =>
      '\$${widget.amountUsd.toStringAsFixed(widget.amountUsd < 10 ? 2 : 0)}';

  List<String> get _converted => _rates.entries
      .map((e) => CurrencyService.format(widget.amountUsd * e.value, e.key))
      .toList();

  @override
  Widget build(BuildContext context) {
    final primaryStyle = widget.primaryStyle ??
        (widget.compact ? AppTextStyles.bodyMedium : AppTextStyles.titleMedium);

    // No rates yet (loading, offline with an empty cache, or USD-only user):
    // show the dollar figure alone rather than a spinner or a gap.
    if (_loading || _converted.isEmpty) {
      return Text(_primary, style: primaryStyle);
    }

    final secondary = _converted.join(' · ');

    if (widget.compact) {
      return Text('$_primary  ≈  $secondary', style: primaryStyle);
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(_primary, style: primaryStyle),
        Text(
          '≈ $secondary',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.accentAmber.withValues(alpha: 0.85),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
