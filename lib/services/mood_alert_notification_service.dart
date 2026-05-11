import 'package:flutter/foundation.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

class MoodAlertNotificationService {
  MoodAlertNotificationService._();
  static final MoodAlertNotificationService instance =
      MoodAlertNotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();
  bool _initialized = false;
  DateTime? _lastAlertAt;

  static const _channelId = 'mood_alerts_channel';
  static const _minInterval = Duration(seconds: 90);
  static const _confidenceThreshold = 40.0;
  static const _negativeEmotions = {'sad', 'angry', 'fear'};

  Future<void> init() async {
    if (_initialized) return;

    const android = AndroidInitializationSettings('@mipmap/ic_launcher');
    const darwin = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );

    await _plugin.initialize(
      settings: const InitializationSettings(
        android: android,
        iOS: darwin,
        macOS: darwin,
      ),
    );

    if (!kIsWeb) {
      await _plugin
          .resolvePlatformSpecificImplementation<
            AndroidFlutterLocalNotificationsPlugin
          >()
          ?.requestNotificationsPermission();

      await _plugin
          .resolvePlatformSpecificImplementation<
            IOSFlutterLocalNotificationsPlugin
          >()
          ?.requestPermissions(alert: true, badge: true, sound: true);
    }

    _initialized = true;
  }

  Future<void> maybeAlertNegativeEmotion(
    String emotion,
    double confidencePercent,
  ) async {
    if (kIsWeb) return;
    final e = emotion.toLowerCase();
    if (!_negativeEmotions.contains(e)) return;

    if (confidencePercent < _confidenceThreshold) return;

    if (!_initialized) await init();

    final now = DateTime.now();
    if (_lastAlertAt != null && now.difference(_lastAlertAt!) < _minInterval) {
      return;
    }
    _lastAlertAt = now;

    const androidDetails = AndroidNotificationDetails(
      _channelId,
      'Mood Updates',
      channelDescription: 'Custom alerts based on current emotion analysis',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: DarwinNotificationDetails(),
      macOS: DarwinNotificationDetails(),
    );

    final title = _titleForEmotion(e);
    final body = _messageForEmotion(e);

    await _plugin.show(
      id: 1001,
      title: title,
      body: body,
      notificationDetails: details,
    );
  }

  String _titleForEmotion(String lower) {
    switch (lower) {
      case 'sad':
        return 'We feel you.';
      case 'angry':
        return 'Take a moment to calm down';
      case 'fear':
        return 'You are safe — try to relax';
      case 'happy':
        return 'What a lovely smile!';
      case 'surprise':
        return 'What a surprising moment!';
      case 'neutral':
        return 'A quiet, peaceful moment';
      case 'disgust':
        return 'We understand your frustration';
      default:
        return 'How are you feeling now?';
    }
  }

  String _messageForEmotion(String lower) {
    switch (lower) {
      case 'sad':
        return 'Open the app for suggestions that may help you feel better.';
      case 'happy':
        return 'So happy to see you like this — enjoy your day!';
      case 'neutral':
        return 'A balanced day — how about some calm meditation?';
      case 'angry':
        return 'Take a deep breath — some calm music might help.';
      default:
        return 'Open the app to explore activities suited for you right now.';
    }
  }
}
