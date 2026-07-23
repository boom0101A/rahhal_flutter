import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/constants/app_strings.dart';
import '../../domain/entities/trip_entity.dart';

class ShareTripCard extends StatelessWidget {
  final TripEntity trip;

  const ShareTripCard({
    super.key,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    final strings = AppStrings.of(context);

    return Container(
      width: 600,
      height: 400,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFF0F2027),
            Color(0xFF203A43),
            Color(0xFF2C5364),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: AppColors.glassBorder.withValues(alpha: 0.2),
          width: 2,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header — every text is Flexible + single-line ellipsis so a
              // wider language (e.g. English) can never overflow the fixed
              // 600px card and paint the yellow overflow stripe into the image.
              Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: AppColors.accentAmber.withValues(alpha: 0.15),
                    ),
                    child: const Text('✈️', style: TextStyle(fontSize: 20)),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Text(
                      strings.appName,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.headlineLarge.copyWith(
                        color: AppColors.accentAmber,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Flexible(
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                      decoration: BoxDecoration(
                        color: AppColors.accentTurquoise.withValues(alpha: 0.15),
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: AppColors.accentTurquoise.withValues(alpha: 0.3),
                          width: 1,
                        ),
                      ),
                      child: Text(
                        strings.appTagline,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: AppTextStyles.labelSmall.copyWith(
                          color: AppColors.accentTurquoise,
                          fontSize: 10,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
              const Spacer(),
              
              // Destination Title — cap at two lines so a very long name
              // can't push the fixed-height card's content past its bounds.
              Text(
                trip.destination,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: AppTextStyles.displayLarge.copyWith(
                  fontSize: 38,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  shadows: [
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      offset: const Offset(0, 4),
                      blurRadius: 8,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 12),

              // Stats Row — Flexible items so longer localized labels
              // ("travelers", "days") shrink instead of overflowing.
              Row(
                children: [
                  Flexible(
                    child: _buildStatItem(
                      icon: Icons.calendar_today_rounded,
                      value: '${trip.durationDays} ${strings.planDurationDays}',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: _buildStatItem(
                      icon: Icons.people_rounded,
                      value: '${trip.travelersCount} ${strings.statsTravelers}',
                    ),
                  ),
                  const SizedBox(width: 16),
                  Flexible(
                    child: _buildStatItem(
                      icon: Icons.account_balance_wallet_rounded,
                      value: '\$${trip.budgetTotal.toStringAsFixed(0)}',
                      color: AppColors.accentAmber,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 20),

              // Divider
              Container(
                height: 1,
                color: Colors.white.withValues(alpha: 0.1),
              ),
              const SizedBox(height: 20),

              // Styles and Footer
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Travel styles tags
                  Expanded(
                    child: Wrap(
                      spacing: 8,
                      runSpacing: 8,
                      children: trip.travelStyles.take(3).map((style) {
                        return Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.white.withValues(alpha: 0.06),
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.white.withValues(alpha: 0.1),
                              width: 1,
                            ),
                          ),
                          child: Text(
                            _getStyleLabel(context, style),
                            style: AppTextStyles.bodySmall.copyWith(
                              color: AppColors.textPrimary,
                              fontSize: 12,
                            ),
                          ),
                        );
                      }).toList(),
                    ),
                  ),
                  
                  const SizedBox(width: 8),
                  // Footer branding tag
                  Flexible(
                    child: Text(
                      '${strings.aiSmartTip.split(' ').first} ✨',
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: AppTextStyles.bodySmall.copyWith(
                        color: AppColors.textSecondary,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String value,
    Color color = AppColors.textPrimary,
  }) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, color: AppColors.accentAmber, size: 18),
        const SizedBox(width: 8),
        Flexible(
          child: Text(
            value,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
            style: AppTextStyles.titleMedium.copyWith(
              color: color,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),
      ],
    );
  }

  String _getStyleLabel(BuildContext context, String styleId) {
    final strings = AppStrings.of(context);
    switch (styleId.toLowerCase()) {
      case 'culture':
        return strings.styleCulture;
      case 'adventure':
        return strings.styleAdventure;
      case 'food':
        return strings.styleFood;
      case 'shopping':
        return strings.styleShopping;
      case 'nature':
        return strings.styleNature;
      case 'relax':
        return strings.styleRelax;
      default:
        return styleId;
    }
  }
}
