import 'package:flutter/material.dart';
import '../../core/constants/app_text_styles.dart';
import '../../core/constants/app_colors.dart';
import '../../core/di/injection.dart';
import '../../features/currency/data/currency_service.dart';

/// Widget يعرض مبلغاً بالدولار + العملة المحلية للوجهة
class DualCurrencyText extends StatefulWidget {
  final double amountUsd;
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
  double? _rate;
  String? _localCurrency;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _fetchRate();
  }

  @override
  void didUpdateWidget(DualCurrencyText old) {
    super.didUpdateWidget(old);
    if (old.countryCode != widget.countryCode) _fetchRate();
  }

  Future<void> _fetchRate() async {
    final currency = CurrencyService.currencyForCountry(widget.countryCode);
    if (currency == null || currency == 'USD') {
      if (mounted) setState(() { _loading = false; _localCurrency = null; });
      return;
    }

    setState(() { _loading = true; _localCurrency = currency; });
    final rate = await sl<CurrencyService>().getRate(currency);
    if (mounted) setState(() { _rate = rate; _loading = false; });
  }

  @override
  Widget build(BuildContext context) {
    final primary = '\$${widget.amountUsd.toStringAsFixed(widget.amountUsd < 10 ? 2 : 0)}';

    if (_loading || _rate == null || _localCurrency == null) {
      return Text(primary, style: widget.primaryStyle ?? AppTextStyles.bodyMedium);
    }

    final localAmount = widget.amountUsd * _rate!;
    final localFormatted = CurrencyService.format(localAmount, _localCurrency!);

    if (widget.compact) {
      return Text(
        '$primary  ≈  $localFormatted',
        style: widget.primaryStyle ?? AppTextStyles.bodyMedium,
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(primary, style: widget.primaryStyle ?? AppTextStyles.titleMedium),
        Text(
          '≈ $localFormatted',
          style: AppTextStyles.bodySmall.copyWith(
            color: AppColors.accentAmber.withValues(alpha: 0.85),
            fontWeight: FontWeight.w500,
          ),
        ),
      ],
    );
  }
}
