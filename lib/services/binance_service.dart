import 'dart:convert';
import 'package:http/http.dart' as http;

class CryptoPrice {
  final double price;
  final double change24h;

  CryptoPrice({
    required this.price,
    required this.change24h,
  });
}

class BinanceService {
  static const String _baseUrl = 'https://api.binance.com/api/v3';

  Future<Map<String, CryptoPrice>> getCryptoPrices() async {
    try {
      // Binance'den BTC, ETH, SOL, XRP, AVAX fiyatlarını al
      final symbols = ['BTCUSDT', 'ETHUSDT', 'SOLUSDT', 'XRPUSDT', 'AVAXUSDT'];
      final Map<String, CryptoPrice> prices = {};

      for (final symbol in symbols) {
        try {
          final response = await http.get(
            Uri.parse('$_baseUrl/ticker/24hr?symbol=$symbol'),
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            final price = double.parse(data['lastPrice']);
            final priceChange = double.parse(data['priceChangePercent']);
            
            // Symbol'den coin adını çıkar (BTCUSDT -> BTC)
            final coinName = symbol.replaceAll('USDT', '');
            
            prices[coinName] = CryptoPrice(
              price: price,
              change24h: priceChange,
            );
          }
        } catch (e) {
          // Hata durumunda sessizce devam et
        }
      }

      return prices;
    } catch (e) {
      return {};
    }
  }
}
