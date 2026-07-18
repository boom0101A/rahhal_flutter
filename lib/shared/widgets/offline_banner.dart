import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';

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
                  ? const Center(
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.wifi_off_rounded,
                              color: Colors.white, size: 16),
                          SizedBox(width: 8),
                          Text(
                            'لا يوجد اتصال بالإنترنت. يرجى التحقق من الشبكة.',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 13,
                              fontFamily: 'Inter',
                            ),
                          ),
                        ],
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
