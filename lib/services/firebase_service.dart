import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

// Arka planda gelen bildirimleri işle
@pragma('vm:entry-point')
Future<void> firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  print('Arka plan bildirimi alındı: ${message.messageId}');
}

class FirebaseService {
  static final FirebaseService _instance = FirebaseService._internal();
  factory FirebaseService() => _instance;
  FirebaseService._internal();

  final FirebaseMessaging _messaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  
  static const String backendUrl = 'http://your-backend-url.com'; // Backend URL'inizi buraya girin
  
  String? _fcmToken;
  
  Future<void> initialize() async {
    // Bildirim izni iste
    NotificationSettings permissionSettings = await _messaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
      provisional: false,
    );

    if (permissionSettings.authorizationStatus == AuthorizationStatus.authorized) {
      print('Bildirim izni verildi');
    }

    // Lokal bildirimleri başlat
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(initSettings);

    // FCM token al ve backend'e gönder
    await _getTokenAndRegister();

    // Token yenilendiğinde güncelle
    _messaging.onTokenRefresh.listen(_registerToken);

    // Uygulama açıkken gelen bildirimleri dinle
    FirebaseMessaging.onMessage.listen(_handleForegroundMessage);

    // Bildirime tıklandığında
    FirebaseMessaging.onMessageOpenedApp.listen(_handleMessageOpenedApp);

    // Arka plan bildirimleri için handler
    FirebaseMessaging.onBackgroundMessage(firebaseMessagingBackgroundHandler);
  }

  Future<void> _getTokenAndRegister() async {
    try {
      _fcmToken = await _messaging.getToken();
      if (_fcmToken != null) {
        print('FCM Token: $_fcmToken');
        await _registerToken(_fcmToken!);
      }
    } catch (e) {
      print('Token alma hatası: $e');
    }
  }

  Future<void> _registerToken(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$backendUrl/api/register-token'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'userId': 'default_user', // Gerçek uygulamada kullanıcı ID'si
          'token': token,
        }),
      );

      if (response.statusCode == 200) {
        print('Token backend\'e kaydedildi');
      } else {
        print('Token kaydetme başarısız: ${response.statusCode}');
      }
    } catch (e) {
      print('Token kaydetme hatası: $e');
    }
  }

  // Uygulama açıkken gelen bildirimler
  void _handleForegroundMessage(RemoteMessage message) {
    print('Bildirim alındı (foreground): ${message.notification?.title}');
    
    _showLocalNotification(
      message.notification?.title ?? 'Bildirim',
      message.notification?.body ?? '',
      message.data,
    );
  }

  // Bildirime tıklandığında
  void _handleMessageOpenedApp(RemoteMessage message) {
    print('Bildirime tıklandı: ${message.notification?.title}');
    // Gerekirse belirli bir ekrana yönlendirme yapılabilir
  }

  // Lokal bildirim göster
  Future<void> _showLocalNotification(
    String title,
    String body,
    Map<String, dynamic> data,
  ) async {
    const androidDetails = AndroidNotificationDetails(
      'position_changes',
      'Pozisyon Değişiklikleri',
      channelDescription: 'HyperLiquid pozisyon değişiklik bildirimleri',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
      icon: '@mipmap/ic_launcher',
    );

    const iosDetails = DarwinNotificationDetails(
      presentAlert: true,
      presentBadge: true,
      presentSound: true,
    );

    const details = NotificationDetails(
      android: androidDetails,
      iOS: iosDetails,
    );

    await _notifications.show(
      DateTime.now().millisecond,
      title,
      body,
      details,
      payload: jsonEncode(data),
    );
  }

  String? get fcmToken => _fcmToken;
}
