import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import '../../core/constants/app_text_styles.dart';

/// A banner that appears at the top of the screen when there is no internet connection.
class OfflineBanner extends StatelessWidget {
  final Widget child;
  const OfflineBanner({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return StreamBuilder<List<ConnectivityResult>>(
      stream: Connectivity().onConnectivityChanged,
      builder: (context, snapshot) {
        final results = snapshot.data ?? [];
        final isOffline = results.isNotEmpty &&
            results.every((r) => r == ConnectivityResult.none);

        return Column(
          children: [
            AnimatedContainer(
              duration: const Duration(milliseconds: 300),
              height: isOffline ? 36 : 0,
              width: double.infinity,
              color: Colors.red.shade700,
              child: isOffline
                  ? Center(
                      child: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 12),
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            const Icon(Icons.wifi_off_rounded,
                                color: Colors.white, size: 16),
                            const SizedBox(width: 8),
                            // Flexible + ellipsis: the Arabic message is long
                            // enough to overflow a narrow screen otherwise,
                            // which paints the yellow/black overflow stripes.
                            Flexible(
                              child: Text(
                                'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.',
                                maxLines: 1,
                                overflow: TextOverflow.ellipsis,
                                style: AppTextStyles.labelSmall.copyWith(
                                  color: Colors.white,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                    )
                  : null,
            ),
            Expanded(child: child),
          ],
        );
      },
    );
  }
}
