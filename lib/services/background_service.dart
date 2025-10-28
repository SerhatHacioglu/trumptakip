import 'package:workmanager/workmanager.dart';
import 'notification_service.dart';

// Bu fonksiyon arka planda çalışır
@pragma('vm:entry-point')
void callbackDispatcher() {
  Workmanager().executeTask((task, inputData) async {
    try {
      // Pozisyon değişikliklerini kontrol et
      await NotificationService().checkAndNotify();
      return Future.value(true);
    } catch (e) {
      print('Arka plan görevi hatası: $e');
      return Future.value(false);
    }
  });
}

class BackgroundService {
  static const String _taskName = 'positionCheckTask';
  
  static Future<void> initialize() async {
    await Workmanager().initialize(
      callbackDispatcher,
      isInDebugMode: false, // Release'de false olmalı
    );
  }

  // Periyodik kontrol başlat (15 dakikada bir - minimum süre)
  static Future<void> startPeriodicCheck() async {
    await Workmanager().registerPeriodicTask(
      _taskName,
      _taskName,
      frequency: const Duration(minutes: 15), // Android minimum 15 dakika
      initialDelay: const Duration(minutes: 1),
      constraints: Constraints(
        networkType: NetworkType.connected, // İnternet gerekli
        requiresBatteryNotLow: true, // Pil düşükken çalışma
        requiresCharging: false,
      ),
      backoffPolicy: BackoffPolicy.exponential,
      backoffPolicyDelay: const Duration(minutes: 5),
    );
  }

  // Periyodik kontrolü durdur
  static Future<void> stopPeriodicCheck() async {
    await Workmanager().cancelByUniqueName(_taskName);
  }

  // Tek seferlik kontrol (hemen)
  static Future<void> checkNow() async {
    await Workmanager().registerOneOffTask(
      'oneTimeCheck',
      'oneTimeCheck',
      initialDelay: const Duration(seconds: 5),
      constraints: Constraints(
        networkType: NetworkType.connected,
      ),
    );
  }
}
