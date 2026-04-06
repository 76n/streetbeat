import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class LocalNotificationService {
  LocalNotificationService();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _ready = false;

  static const _phantomChannelId = 'streetbeat_phantom';
  static const _phantomChannelName = 'StreetBeat rewards';

  Future<void> init() async {
    if (kIsWeb || _ready) {
      return;
    }
    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings();
    await _plugin.initialize(
      const InitializationSettings(
        android: android,
        iOS: darwin,
      ),
    );
    _ready = true;
  }

  Future<void> showPhantomGoldCoin() async {
    if (kIsWeb || !_ready) {
      return;
    }
    const details = NotificationDetails(
      android: AndroidNotificationDetails(
        _phantomChannelId,
        _phantomChannelName,
        channelDescription: 'Rare coin spawns during runs',
        importance: Importance.high,
        priority: Priority.high,
      ),
      iOS: DarwinNotificationDetails(),
    );
    await _plugin.show(
      901,
      'Phantom gold coin!',
      'A rare coin appeared on your route — collect it within 45s.',
      details,
    );
  }
}
