import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../models/position.dart';
import 'hyperdash_service.dart';

class NotificationService {
  static final NotificationService _instance = NotificationService._internal();
  factory NotificationService() => _instance;
  NotificationService._internal();

  final FlutterLocalNotificationsPlugin _notifications = FlutterLocalNotificationsPlugin();
  final HyperDashService _apiService = HyperDashService();
  
  static const String _prefsKey = 'last_positions';
  static const String _walletAddress = '0xc2a30212a8ddac9e123944d6e29faddce994e5f2';

  Future<void> initialize() async {
    const androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings(
      requestAlertPermission: true,
      requestBadgePermission: true,
      requestSoundPermission: true,
    );
    
    const settings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );

    await _notifications.initialize(
      settings,
      onDidReceiveNotificationResponse: (details) {
        // Bildirime tıklandığında yapılacak işlem
      },
    );

    // İzin iste (Android 13+)
    await _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await _notifications
        .resolvePlatformSpecificImplementation<AndroidFlutterLocalNotificationsPlugin>()
        ?.requestNotificationsPermission();
  }

  Future<void> checkAndNotify() async {
    try {
      // Yeni pozisyonları al
      final currentPositions = await _apiService.getOpenPositions(_walletAddress);
      
      // Önceki pozisyonları al
      final prefs = await SharedPreferences.getInstance();
      final lastPositionsJson = prefs.getString(_prefsKey);
      
      if (lastPositionsJson != null) {
        final List<dynamic> lastPositionsData = jsonDecode(lastPositionsJson);
        final lastPositions = lastPositionsData
            .map((json) => Position.fromJson(json))
            .toList();
        
        // Değişiklikleri kontrol et
        await _compareAndNotify(lastPositions, currentPositions);
      }
      
      // Yeni pozisyonları kaydet
      final currentPositionsJson = jsonEncode(
        currentPositions.map((p) => p.toJson()).toList(),
      );
      await prefs.setString(_prefsKey, currentPositionsJson);
      
    } catch (e) {
      print('Bildirim kontrolü hatası: $e');
    }
  }

  Future<void> _compareAndNotify(
    List<Position> oldPositions,
    List<Position> newPositions,
  ) async {
    // Yeni açılan pozisyonlar
    for (var newPos in newPositions) {
      final exists = oldPositions.any((old) => 
        old.coin == newPos.coin && old.side == newPos.side
      );
      
      if (!exists) {
        await _showNotification(
          'Yeni Pozisyon Açıldı',
          '${newPos.coin} ${newPos.side} - ${newPos.size.toStringAsFixed(4)} adet',
          1,
        );
      }
    }

    // Kapanan pozisyonlar
    for (var oldPos in oldPositions) {
      final exists = newPositions.any((newPos) => 
        newPos.coin == oldPos.coin && newPos.side == oldPos.side
      );
      
      if (!exists) {
        await _showNotification(
          'Pozisyon Kapatıldı',
          '${oldPos.coin} ${oldPos.side} pozisyonu kapatıldı',
          2,
        );
      }
    }

    // P&L değişiklikleri (örn: %10'dan fazla değişim)
    for (var newPos in newPositions) {
      final oldPos = oldPositions.firstWhere(
        (old) => old.coin == newPos.coin && old.side == newPos.side,
        orElse: () => newPos,
      );
      
      if (oldPos != newPos) {
        final pnlChange = ((newPos.unrealizedPnl - oldPos.unrealizedPnl) / 
                          oldPos.unrealizedPnl.abs() * 100).abs();
        
        if (pnlChange > 10) {
          final isProfit = newPos.unrealizedPnl > 0;
          await _showNotification(
            'Önemli P&L Değişimi',
            '${newPos.coin}: ${isProfit ? "+" : ""}\$${newPos.unrealizedPnl.toStringAsFixed(2)}',
            3,
          );
        }
      }
    }
  }

  Future<void> _showNotification(String title, String body, int id) async {
    const androidDetails = AndroidNotificationDetails(
      'position_changes',
      'Pozisyon Değişiklikleri',
      channelDescription: 'Pozisyon değişikliklerini bildirir',
      importance: Importance.high,
      priority: Priority.high,
      showWhen: true,
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

    await _notifications.show(id, title, body, details);
  }

  // Manuel kontrol için
  Future<void> manualCheck() async {
    await checkAndNotify();
  }
}
