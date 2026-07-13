# ملف كود Dart: lib\features\itinerary\presentation\screens\stop_detail_screen.dart

```dart
import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_text_styles.dart';
import '../../../../core/di/injection.dart';
import '../../../../shared/widgets/app_badges.dart';
import '../../../../shared/widgets/glass_card.dart';
import '../../../../shared/widgets/gradient_button.dart';
import '../../../trip_planner/domain/entities/stop_entity.dart';
import '../../domain/repositories/itinerary_repository.dart';

class StopDetailScreen extends StatefulWidget {
  final String stopId;

  const StopDetailScreen({super.key, required this.stopId});

  @override
  State<StopDetailScreen> createState() => _StopDetailScreenState();
}

class _StopDetailScreenState extends State<StopDetailScreen> {
  bool _isLoading = true;
  String? _errorMessage;
  StopEntity? _stop;

  @override
  void initState() {
    super.initState();
    _loadStopDetails();
  }

  Future<void> _loadStopDetails() async {
    final result = await sl<ItineraryRepository>().getStopById(widget.stopId);
    if (mounted) {
      result.fold(
        (failure) => setState(() {
          _errorMessage = failure.message;
          _isLoading = false;
        }),
        (stop) => setState(() {
          _stop = stop;
          _isLoading = false;
        }),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.bgPrimary,
      body: _isLoading
          ? const Center(child: CircularProgressIndicator(color: AppColors.accentAmber))
          : _errorMessage != null
              ? _buildErrorView()
              : _buildContentView(),
    );
  }

  Widget _buildErrorView() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          const Text('⚠️', style: TextStyle(fontSize: 48)),
          const SizedBox(height: 16),
          Text(_errorMessage ?? 'حدث خطأ ما', style: AppTextStyles.bodyMedium),
          const SizedBox(height: 24),
          ElevatedButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('رجوع'),
          ),
        ],
      ),
    );
  }

  Widget _buildContentView() {
    final stop = _stop!;
    return Stack(
      children: [
        // Custom Scroll View for smooth scrolling behavior
        CustomScrollView(
          slivers: [
            // Sliver App Bar with Image
            SliverAppBar(
              expandedHeight: 240,
              pinned: true,
              backgroundColor: AppColors.bgPrimary,
              leading: IconButton(
                onPressed: () => Navigator.pop(context),
                icon: const Icon(Icons.close_rounded, color: Colors.white, size: 24),
              ),
              flexibleSpace: FlexibleSpaceBar(
                background: Stack(
                  fit: StackFit.expand,
                  children: [
                    if (stop.imageUrl != null)
                      Image.network(
                        stop.imageUrl!,
                        fit: BoxFit.cover,
                        errorBuilder: (_, __, ___) => _buildPlaceholderImage(),
                      )
                    else
                      _buildPlaceholderImage(),
                    const DecoratedBox(
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          begin: Alignment.topCenter,
                          end: Alignment.bottomCenter,
                          colors: [
                            Colors.transparent,
                            AppColors.bgPrimary,
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ),

            // Content
            SliverPadding(
              padding: const EdgeInsets.all(20),
              sliver: SliverList(
                delegate: SliverChildListDelegate([
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      CategoryChip(category: stop.category),
                      PeriodBadge(period: stop.timeOfDay),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    stop.name,
                    style: AppTextStyles.headlineLarge,
                  ),
                  if (stop.nameEn != null && stop.nameEn!.isNotEmpty) ...[
                    const SizedBox(height: 4),
                    Text(
                      stop.nameEn!,
                      style: AppTextStyles.bodyMedium.copyWith(color: AppColors.textSecondary),
                    ),
                  ],
                  const SizedBox(height: 20),

                  // Stop statistics
                  Row(
                    children: [
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.schedule_rounded,
                          label: 'المدة المقترحة',
                          value: stop.durationLabel,
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: _buildStatItem(
                          icon: Icons.attach_money_rounded,
                          label: 'التكلفة التقديرية',
                          value: stop.costLabel,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 20),

                  // Address
                  if (stop.address != null) ...[
                    Text('العنوان', style: AppTextStyles.titleMedium),
                    const SizedBox(height: 8),
                    Text(
                      stop.address!,
                      style: AppTextStyles.bodyMedium,
                    ),
                    const SizedBox(height: 20),
                  ],

                  // AI Tip
                  if (stop.aiTip != null) ...[
                    Text('نصيحة رحّال الذكية ✨', style: AppTextStyles.titleMedium.copyWith(color: AppColors.accentAmber)),
                    const SizedBox(height: 8),
                    GlassCard(
                      padding: const EdgeInsets.all(16),
                      child: Text(
                        stop.aiTip!,
                        style: AppTextStyles.bodyMedium.copyWith(height: 1.6),
                      ),
                    ),
                    const SizedBox(height: 20),
                  ],

                  // Location on Map Placeholder/Button
                  Text('الموقع الجغرافي', style: AppTextStyles.titleMedium),
                  const SizedBox(height: 8),
                  Text(
                    'خط العرض: ${stop.latitude.toStringAsFixed(6)} • خط الطول: ${stop.longitude.toStringAsFixed(6)}',
                    style: AppTextStyles.bodySmall,
                  ),
                  const SizedBox(height: 100), // Spacing for bottom button
                ]),
              ),
            ),
          ],
        ),

        // Booking Action
        if (stop.bookingRequired)
          Positioned(
            bottom: 20,
            left: 20,
            right: 20,
            child: GradientButton(
              label: 'حجز التذاكر الآن',
              icon: Icons.bookmark_added_rounded,
              onPressed: () => _openBookingUrl(stop.bookingUrl),
            ),
          ),
      ],
    );
  }

  Widget _buildPlaceholderImage() {
    return Container(
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          colors: [Color(0xFF1B2A47), Color(0xFF0F1B29)],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
      ),
      child: const Center(
        child: Text('📍', style: TextStyle(fontSize: 72)),
      ),
    );
  }

  Widget _buildStatItem({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.bgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: AppColors.accentAmber, size: 24),
          const SizedBox(height: 8),
          Text(label, style: AppTextStyles.labelSmall),
          const SizedBox(height: 4),
          Text(value, style: AppTextStyles.titleSmall),
        ],
      ),
    );
  }

  Future<void> _openBookingUrl(String? url) async {
    if (url == null || url.isEmpty) return;
    final uri = Uri.parse(url);
    if (await canLaunchUrl(uri)) {
      await launchUrl(uri, mode: LaunchMode.externalApplication);
    }
  }
}

```
