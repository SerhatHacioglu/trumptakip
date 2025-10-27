import 'package:flutter/material.dart';
import 'package:firebase_core/firebase_core.dart';
import 'screens/positions_screen.dart';
import 'services/notification_service.dart';
import 'services/background_service.dart';
import 'services/firebase_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase'i başlat
  try {
    await Firebase.initializeApp();
    // Firebase Cloud Messaging'i başlat
    await FirebaseService().initialize();
  } catch (e) {
    print('Firebase başlatma hatası: $e');
  }
  
  // Lokal bildirimleri başlat
  await NotificationService().initialize();
  
  // Arka plan servisini başlat (yedek olarak)
  await BackgroundService.initialize();
  // Yorum: FCM kullanıyorsanız bu satırı kapatabilirsiniz
  // await BackgroundService.startPeriodicCheck();
  
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Trump Takip',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      home: const PositionsScreen(),
    );
  }
}
