import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// Shared "slide up + fade" transition for every full-destination screen
/// reached by drilling in (opening a trip, the map, generating a trip,
/// settings...). Vertical motion is used deliberately — it reads the same
/// in LTR and RTL locales, unlike a horizontal slide which would need to
/// be mirrored for Arabic.
CustomTransitionPage<T> slideUpPage<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic);
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 0.06),
          end: Offset.zero,
        ).animate(curved),
        child: FadeTransition(opacity: curved, child: child),
      );
    },
  );
}

/// Fuller "sheet reveal" transition for modal-like overlays (chat, stop
/// detail, documents) — a more pronounced slide from the bottom edge than
/// [slideUpPage], signalling "temporary layer" rather than "new section".
CustomTransitionPage<T> slideUpModalPage<T>({
  required GoRouterState state,
  required Widget child,
}) {
  return CustomTransitionPage<T>(
    key: state.pageKey,
    child: child,
    transitionDuration: const Duration(milliseconds: 320),
    reverseTransitionDuration: const Duration(milliseconds: 260),
    transitionsBuilder: (context, animation, secondaryAnimation, child) {
      return SlideTransition(
        position: Tween<Offset>(
          begin: const Offset(0, 1),
          end: Offset.zero,
        ).animate(CurvedAnimation(parent: animation, curve: Curves.easeOutCubic)),
        child: child,
      );
    },
  );
}
