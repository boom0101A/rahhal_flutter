import 'dart:async';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart' as firebase_auth;
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'notification_service.dart';

/// FCM (server-push) token lifecycle — separate from [NotificationService],
/// which is purely local/device-time-based scheduling and knows nothing
/// about the network or the signed-in user.
///
/// Token registration listens to [firebase_auth.FirebaseAuth.authStateChanges]
/// directly rather than hooking into AuthRepository's per-method Firestore
/// writes: those only cover 2 of the 4 sign-in paths (registerWithEmail and
/// signInWithGoogle — signInWithEmail and signInAnonymously write nothing to
/// Firestore at all), so a listener here is the only way every sign-in path,
/// plus an already-signed-in relaunch, reliably gets a token registered.
class FcmService {
  StreamSubscription<firebase_auth.User?>? _authSub;
  StreamSubscription<String>? _refreshSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;

  Future<void> initialize() async {
    // Skip a second permission prompt if NotificationService already has one.
    if (!await NotificationService.hasPermission()) {
      try {
        await FirebaseMessaging.instance.requestPermission();
      } catch (e) {
        debugPrint('FcmService requestPermission error: $e');
      }
    }

    _authSub = firebase_auth.FirebaseAuth.instance.authStateChanges().listen((user) {
      if (user != null) _syncToken(user.uid);
    });

    _refreshSub = FirebaseMessaging.instance.onTokenRefresh.listen((token) {
      final uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
      if (uid != null) _persistToken(uid, token);
    });

    // Android only shows FCM's own tray notification automatically while the
    // app is backgrounded/terminated — a foreground push needs to be shown
    // explicitly, via the same local channel every other notification uses.
    _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
      final notification = message.notification;
      if (notification == null) return;
      NotificationService.showImmediate(
        title: notification.title ?? '',
        body: notification.body ?? '',
      );
    });
  }

  Future<void> _syncToken(String uid) async {
    try {
      final token = await FirebaseMessaging.instance.getToken();
      if (token != null) await _persistToken(uid, token);
    } catch (e) {
      debugPrint('FcmService sync token error: $e');
    }
  }

  Future<void> _persistToken(String uid, String token) async {
    try {
      await FirebaseFirestore.instance.collection('users').doc(uid).set({
        'fcmTokens.$token': {
          'platform': 'android',
          'updatedAt': FieldValue.serverTimestamp(),
        },
      }, SetOptions(merge: true));
    } catch (e) {
      // Non-critical, same contract as every other Firestore write in this
      // app: the token just won't be reachable until the next sync attempt.
      debugPrint('FcmService persist token error: $e');
    }
  }

  /// Removes this device's token from FCM and from the user's Firestore doc
  /// — called on sign-out and when the user disables push in Settings, so a
  /// device that opted out truly stops being reachable rather than just
  /// silently ignoring pushes it still receives.
  Future<void> deleteToken() async {
    final uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    try {
      final token = await FirebaseMessaging.instance.getToken();
      await FirebaseMessaging.instance.deleteToken();
      if (uid != null && token != null) {
        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .update({'fcmTokens.$token': FieldValue.delete()});
      }
    } catch (e) {
      debugPrint('FcmService delete token error: $e');
    }
  }

  /// Re-registers a fresh token for the current user — called when the user
  /// re-enables push in Settings after having disabled it.
  Future<void> enable() async {
    final uid = firebase_auth.FirebaseAuth.instance.currentUser?.uid;
    if (uid != null) await _syncToken(uid);
  }

  Future<void> dispose() async {
    await _authSub?.cancel();
    await _refreshSub?.cancel();
    await _foregroundSub?.cancel();
  }
}
