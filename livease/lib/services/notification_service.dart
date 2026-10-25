import 'dart:async';

import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../core/widgets.dart';
import '../features/auth/auth_repository.dart';

/// Topic every resident subscribes to. The `notifyNewNotice` Cloud Function
/// publishes to it whenever an admin posts a notice.
const String kSocietyTopic = 'society';

class NotificationService {
  NotificationService(this._auth);

  final AuthRepository _auth;
  final FirebaseMessaging _fcm = FirebaseMessaging.instance;

  String? _initializedFor;
  StreamSubscription<String>? _tokenSub;
  StreamSubscription<RemoteMessage>? _foregroundSub;

  Future<void> init(String uid) async {
    if (_initializedFor == uid) return;
    _initializedFor = uid;

    final settings = await _fcm.requestPermission();
    if (settings.authorizationStatus == AuthorizationStatus.denied) return;

    try {
      await _fcm.subscribeToTopic(kSocietyTopic);
    } catch (_) {
      // Topic subscription is not supported on every platform (e.g. web).
    }

    final token = await _fcm.getToken();
    if (token != null) await _saveToken(uid, token);

    await _tokenSub?.cancel();
    _tokenSub = _fcm.onTokenRefresh.listen((t) => _saveToken(uid, t));

    await _foregroundSub?.cancel();
    _foregroundSub = FirebaseMessaging.onMessage.listen((message) {
      final n = message.notification;
      if (n == null) return;
      final text = [n.title, n.body].whereType<String>().join(' - ');
      showSnack(text);
    });
  }

  Future<void> _saveToken(String uid, String token) async {
    try {
      await _auth.saveFcmToken(uid, token);
    } catch (_) {
      // Profile may not exist yet; the token is saved on the next launch.
    }
  }
}

final notificationServiceProvider = Provider<NotificationService>((ref) {
  final service = NotificationService(ref.watch(authRepositoryProvider));
  return service;
});
