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
  
  // Gün başlangıç fiyatlarını sakla (UTC 00:00)
  static final Map<String, double> _dailyOpenPrices = {};
  static DateTime? _lastDailyUpdate;

  Future<Map<String, CryptoPrice>> getCryptoPrices() async {
    try {
      final now = DateTime.now().toUtc();
      final todayStart = DateTime.utc(now.year, now.month, now.day);
      
      // Gün değiştiyse veya ilk kez çağrılıyorsa, gün başlangıç fiyatlarını güncelle
      if (_lastDailyUpdate == null || 
          _lastDailyUpdate!.isBefore(todayStart)) {
        await _updateDailyOpenPrices();
        _lastDailyUpdate = now;
      }
      
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
            
            // Symbol'den coin adını çıkar (BTCUSDT -> BTC)
            final coinName = symbol.replaceAll('USDT', '');
            
            // Gün başlangıç fiyatına göre değişimi hesapla
            double dailyChange = 0.0;
            if (_dailyOpenPrices.containsKey(coinName) && _dailyOpenPrices[coinName]! > 0) {
              final openPrice = _dailyOpenPrices[coinName]!;
              dailyChange = ((price - openPrice) / openPrice) * 100;
            }
            
            prices[coinName] = CryptoPrice(
              price: price,
              change24h: dailyChange,
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
  
  // Gün başlangıç fiyatlarını güncelle (UTC 00:00)
  Future<void> _updateDailyOpenPrices() async {
    try {
      final symbols = ['BTCUSDT', 'ETHUSDT', 'SOLUSDT', 'XRPUSDT', 'AVAXUSDT'];
      
      for (final symbol in symbols) {
        try {
          // Bugünün UTC 00:00 timestamp'i
          final now = DateTime.now().toUtc();
          final todayStart = DateTime.utc(now.year, now.month, now.day);
          final startTime = todayStart.millisecondsSinceEpoch;
          
          // Kline (candlestick) verisi - 1 günlük interval, bugünün ilk mumunu al
          final response = await http.get(
            Uri.parse('$_baseUrl/klines?symbol=$symbol&interval=1d&startTime=$startTime&limit=1'),
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final List<dynamic> data = json.decode(response.body);
            if (data.isNotEmpty) {
              // Kline formatı: [openTime, open, high, low, close, ...]
              final openPrice = double.parse(data[0][1]); // index 1 = open price
              final coinName = symbol.replaceAll('USDT', '');
              _dailyOpenPrices[coinName] = openPrice;
            }
          }
        } catch (e) {
          // Hata durumunda sessizce devam et
        }
      }
    } catch (e) {
      // Genel hata
    }
  }
}
