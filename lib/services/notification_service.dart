import 'dart:async';
import 'dart:convert';
import 'package:http/http.dart' as http;

class NotificationService {
  static const String backendUrl = 'https://trumptakip-bot.onrender.com'; // Render URL'iniz
  
  // Son bildirimleri al
  static Future<List<Map<String, dynamic>>> getRecentNotifications({int limit = 20}) async {
    try {
      final response = await http.get(
        Uri.parse('$backendUrl/api/notifications?limit=$limit'),
      );
      
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        return List<Map<String, dynamic>>.from(data['notifications'] ?? []);
      }
      return [];
    } catch (e) {
      print('Bildirim alma hatası: $e');
      return [];
    }
  }
  
  // Gerçek zamanlı bildirimleri dinle (SSE)
  static Stream<Map<String, dynamic>> listenToNotifications() {
    final controller = StreamController<Map<String, dynamic>>();
    
    void startListening() async {
      try {
        final client = http.Client();
        final request = http.Request('GET', Uri.parse('$backendUrl/api/notifications/stream'));
        
        final response = await client.send(request);
        
        response.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
              if (line.startsWith('data: ')) {
                try {
                  final jsonData = line.substring(6);
                  final notification = jsonDecode(jsonData);
                  controller.add(notification);
                } catch (e) {
                  print('Parse hatası: $e');
                }
              }
            },
            onError: (error) {
              print('SSE hatası: $error');
              // Yeniden bağlan
              Future.delayed(const Duration(seconds: 5), startListening);
            },
            onDone: () {
              print('SSE bağlantısı kapandı, yeniden bağlanılıyor...');
              Future.delayed(const Duration(seconds: 5), startListening);
            },
          );
      } catch (e) {
        print('Bağlantı hatası: $e');
        Future.delayed(const Duration(seconds: 5), startListening);
      }
    }
    
    startListening();
    
    return controller.stream;
  }
}
