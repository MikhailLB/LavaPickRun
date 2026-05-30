import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';
import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'http_client.dart';
import 'app_state_service.dart';

@pragma('vm:entry-point')
Future<void> _bgMessageHandler(RemoteMessage message) async {}

class NotifService {
  final FlutterLocalNotificationsPlugin _local =
      FlutterLocalNotificationsPlugin();
  final AppStateService _storage;
  FirebaseMessaging? _messaging;
  String? _token;
  bool _initialized = false;

  Function(String url)? onNotificationUrl;
  Function(String newToken)? onTokenRefresh;

  NotifService(this._storage);

  String? get token => _token;

  Future<void> init() async {
    if (_initialized) return;
    try {
      await Firebase.initializeApp();
      _messaging = FirebaseMessaging.instance;
      FirebaseMessaging.onBackgroundMessage(_bgMessageHandler);
      await _initLocal();
      _token = await _messaging!.getToken();
      _messaging!.onTokenRefresh.listen((t) {
        _token = t;
        onTokenRefresh?.call(t);
      });
      FirebaseMessaging.onMessage.listen(_onForeground);
      FirebaseMessaging.onMessageOpenedApp.listen(_onOpenedFromBg);
      final init = await _messaging!.getInitialMessage();
      if (init != null) _onColdStart(init);
      _initialized = true;
    } catch (_) {}
  }

  Future<void> _initLocal() async {
    const android = AndroidInitializationSettings('@drawable/ic_notification');
    const ios = DarwinInitializationSettings(
      requestAlertPermission: false,
      requestBadgePermission: false,
      requestSoundPermission: false,
    );
    await _local.initialize(
      const InitializationSettings(android: android, iOS: ios),
      onDidReceiveNotificationResponse: (r) {
        if (r.payload == null) return;
        try {
          final data = jsonDecode(r.payload!) as Map<String, dynamic>;
          final url = data['url'] as String?;
          if (url != null && url.isNotEmpty) onNotificationUrl?.call(url);
        } catch (_) {}
      },
    );
    if (Platform.isAndroid) {
      final p = _local.resolvePlatformSpecificImplementation<
          AndroidFlutterLocalNotificationsPlugin>();
      await p?.createNotificationChannel(const AndroidNotificationChannel(
        'high_importance_channel',
        'High Importance Notifications',
        importance: Importance.high,
      ));
    }
  }

  Future<bool> requestPermission() async {
    if (_messaging == null) return false;
    final s = await _messaging!.requestPermission(
        alert: true, badge: true, sound: true);
    final granted =
        s.authorizationStatus == AuthorizationStatus.authorized ||
        s.authorizationStatus == AuthorizationStatus.provisional;
    await _storage.setNotificationGranted(granted);
    return granted;
  }

  void _onForeground(RemoteMessage message) async {
    final n = message.notification;
    if (n == null || !Platform.isAndroid) return;

    final imgUrl = n.android?.imageUrl;
    AndroidNotificationDetails? details;

    if (imgUrl != null && imgUrl.isNotEmpty) {
      final bytes = await _downloadImage(imgUrl);
      if (bytes != null) {
        details = AndroidNotificationDetails(
          'high_importance_channel', 'High Importance Notifications',
          importance: Importance.high, priority: Priority.high,
          icon: '@drawable/ic_notification',
          styleInformation: BigPictureStyleInformation(
            ByteArrayAndroidBitmap(bytes),
            largeIcon: const DrawableResourceAndroidBitmap('@mipmap/ic_launcher'),
          ),
        );
      }
    }

    details ??= const AndroidNotificationDetails(
      'high_importance_channel', 'High Importance Notifications',
      importance: Importance.high, priority: Priority.high,
      icon: '@drawable/ic_notification',
    );

    await _local.show(
      n.hashCode, n.title, n.body,
      NotificationDetails(android: details),
      payload: message.data.isNotEmpty ? jsonEncode(message.data) : null,
    );
  }

  void _onColdStart(RemoteMessage msg) {
    final url = msg.data['url'] as String?;
    if (url != null && url.isNotEmpty) _storage.setPushUrl(url);
  }

  void _onOpenedFromBg(RemoteMessage msg) {
    final url = msg.data['url'] as String?;
    if (url != null && url.isNotEmpty) onNotificationUrl?.call(url);
  }

  Future<Uint8List?> _downloadImage(String url) async {
    try {
      final r = await appHttpClient.get(Uri.parse(url))
          .timeout(const Duration(seconds: 10));
      if (r.statusCode == 200) return r.bodyBytes;
    } catch (_) {}
    return null;
  }
}
