import 'dart:convert';
import 'package:http/http.dart' as http;
import '../models/position.dart';

class HyperDashService {
  static const String baseUrl = 'https://api.hyperliquid.xyz';
  static const String hyperdashApiUrl = 'https://hyperdash.info/api';
  
  // HyperLiquid API kullanarak açık pozisyonları getir
  Future<List<Position>> getOpenPositions(String walletAddress) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'clearinghouseState',
          'user': walletAddress,
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final List<Position> positions = [];
        
        // Mevcut fiyatları al
        final pricesResponse = await http.post(
          Uri.parse('$baseUrl/info'),
          headers: {'Content-Type': 'application/json'},
          body: jsonEncode({
            'type': 'allMids',
          }),
        );
        
        Map<String, double> currentPrices = {};
        if (pricesResponse.statusCode == 200) {
          final pricesData = jsonDecode(pricesResponse.body);
          pricesData.forEach((key, value) {
            currentPrices[key] = double.tryParse(value.toString()) ?? 0.0;
          });
        }
        
        if (data['assetPositions'] != null) {
          for (var posData in data['assetPositions']) {
            if (posData['position'] != null) {
              final pos = posData['position'];
              final coin = pos['coin'] ?? '';
              final szi = double.tryParse(pos['szi']?.toString() ?? '0') ?? 0.0;
              
              // Sadece açık pozisyonları ekle (szi != 0)
              if (szi != 0) {
                // Leverage hesaplama: positionValue / marginUsed
                final positionValue = double.tryParse(pos['positionValue']?.toString() ?? '0') ?? 0.0;
                final marginUsed = double.tryParse(pos['marginUsed']?.toString() ?? '0') ?? 0.0;
                final leverage = marginUsed > 0 ? positionValue / marginUsed : 1.0;
                
                // Mevcut fiyatı al
                final currentPrice = currentPrices[coin] ?? 0.0;
                
                positions.add(Position(
                  coin: coin,
                  size: szi.abs(),
                  entryPrice: double.tryParse(pos['entryPx']?.toString() ?? '0') ?? 0.0,
                  markPrice: currentPrice,
                  unrealizedPnl: double.tryParse(pos['unrealizedPnl']?.toString() ?? '0') ?? 0.0,
                  leverage: leverage,
                  side: szi > 0 ? 'LONG' : 'SHORT',
                  liquidationPrice: double.tryParse(pos['liquidationPx']?.toString() ?? '0') ?? 0.0,
                ));
              }
            }
          }
        }
        
        return positions;
      } else {
        throw Exception('API isteği başarısız: ${response.statusCode}');
      }
    } catch (e) {
      throw Exception('Pozisyonlar alınamadı: $e');
    }
  }

  // Trader istatistiklerini getir (opsiyonel)
  Future<Map<String, dynamic>?> getTraderStats(String walletAddress) async {
    try {
      final response = await http.get(
        Uri.parse('$hyperdashApiUrl/trader/$walletAddress'),
        headers: {'Content-Type': 'application/json'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  // Coin için güncel fiyat bilgisi al
  Future<double> getCurrentPrice(String coin) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'allMids',
        }),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data != null && data[coin] != null) {
          return double.tryParse(data[coin].toString()) ?? 0.0;
        }
      }
      return 0.0;
    } catch (e) {
      return 0.0;
    }
  }

  // Get detailed wallet info with all available data
  Future<Map<String, dynamic>> getWalletDetails(String walletAddress) async {
    try {
      final Map<String, dynamic> details = {};
      
      // 1. Clearinghouse State (positions, margin, account value)
      final stateResponse = await http.post(
        Uri.parse('$baseUrl/info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'clearinghouseState',
          'user': walletAddress,
        }),
      );
      if (stateResponse.statusCode == 200) {
        details['clearinghouseState'] = jsonDecode(stateResponse.body);
      }
      
      // 2. User Funding (funding payments history)
      final fundingResponse = await http.post(
        Uri.parse('$baseUrl/info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'userFunding',
          'user': walletAddress,
          'startTime': DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch,
        }),
      );
      if (fundingResponse.statusCode == 200) {
        details['userFunding'] = jsonDecode(fundingResponse.body);
      }
      
      // 3. User Fills (trade history - last 100 trades)
      final fillsResponse = await http.post(
        Uri.parse('$baseUrl/info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'userFills',
          'user': walletAddress,
        }),
      );
      if (fillsResponse.statusCode == 200) {
        details['userFills'] = jsonDecode(fillsResponse.body);
      }
      
      // 4. Ledger Updates (deposits, withdrawals, transfers)
      final ledgerResponse = await http.post(
        Uri.parse('$baseUrl/info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'userNonFundingLedgerUpdates',
          'user': walletAddress,
          'startTime': DateTime.now().subtract(const Duration(days: 30)).millisecondsSinceEpoch,
        }),
      );
      if (ledgerResponse.statusCode == 200) {
        details['ledgerUpdates'] = jsonDecode(ledgerResponse.body);
      }
      
      // 5. User Rates (cumulative trading volume and fees)
      final ratesResponse = await http.post(
        Uri.parse('$baseUrl/info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'userRateLimit',
          'user': walletAddress,
        }),
      );
      if (ratesResponse.statusCode == 200) {
        details['userRates'] = jsonDecode(ratesResponse.body);
      }
      
      // 6. Referral State
      final referralResponse = await http.post(
        Uri.parse('$baseUrl/info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'referral',
          'user': walletAddress,
        }),
      );
      if (referralResponse.statusCode == 200) {
        details['referral'] = jsonDecode(referralResponse.body);
      }
      
      // 7. Historical PnL
      final pnlResponse = await http.post(
        Uri.parse('$baseUrl/info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'accountPnlHistory',
          'user': walletAddress,
        }),
      );
      if (pnlResponse.statusCode == 200) {
        details['pnlHistory'] = jsonDecode(pnlResponse.body);
      }
      
      // 8. Current prices
      final pricesResponse = await http.post(
        Uri.parse('$baseUrl/info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'allMids',
        }),
      );
      if (pricesResponse.statusCode == 200) {
        details['allMids'] = jsonDecode(pricesResponse.body);
      }
      
      // 9. Meta info
      final metaResponse = await http.post(
        Uri.parse('$baseUrl/info'),
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({
          'type': 'meta',
        }),
      );
      if (metaResponse.statusCode == 200) {
        details['meta'] = jsonDecode(metaResponse.body);
      }
      
      return details;
    } catch (e) {
      return {};
    }
  }
}
