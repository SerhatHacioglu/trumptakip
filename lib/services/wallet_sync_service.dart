import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:flutter/foundation.dart' show kIsWeb, kDebugMode;
import '../models/wallet.dart';

class WalletSyncService {
  // Backend URL'ini environment'a göre ayarla
  static String get baseUrl {
    // APK/Release modda production URL kullan
    if (!kDebugMode || !kIsWeb) {
      return 'https://trumptakip-bot.onrender.com'; // Production
    }
    // Debug/Web modda localhost kullan
    return 'http://localhost:3000';
  }
  
  /// Wallet listesini backend ile senkronize et
  static Future<bool> syncWallets(List<Wallet> wallets) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/api/wallets/sync'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'wallets': wallets.map((wallet) => {
            'id': wallet.id,
            'name': wallet.name,
            'address': wallet.address,
            'color': wallet.color.value.toRadixString(16),
          }).toList(),
        }),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        return true;
      } else {
        return false;
      }
    } catch (e) {
      // Backend erişilemezse bile app çalışmaya devam etsin
      return false;
    }
  }

  /// Backend'deki aktif wallet listesini getir
  static Future<List<Map<String, dynamic>>?> getTrackedWallets() async {
    try {
      final response = await http.get(
        Uri.parse('$baseUrl/api/wallets'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return List<Map<String, dynamic>>.from(data['wallets']);
      }
      return null;
    } catch (e) {
      return null;
    }
  }
}
