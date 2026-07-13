import 'dart:async';
import 'package:flutter/foundation.dart';
import '../di/injection.dart';
import '../../features/auth/domain/repositories/auth_repository.dart';

class AuthNotifier extends ChangeNotifier {
  late final StreamSubscription _sub;

  AuthNotifier() {
    _sub = sl<AuthRepository>().authStateChanges.listen((_) {
      notifyListeners();
    });
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
