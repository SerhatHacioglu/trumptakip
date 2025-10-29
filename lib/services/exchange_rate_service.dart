import 'dart:convert';
import 'package:http/http.dart' as http;

class ExchangeRateService {
  static const String _binanceApi = 'https://api.binance.com/api/v3/ticker/price?symbol=USDTTRY';

  Future<double> getUsdtTryRate() async {
    try {
      final response = await http.get(Uri.parse(_binanceApi));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return double.parse(data['price']);
      }
      return 34.5; // Fallback rate
    } catch (e) {
      print('USDT/TRY rate error: $e');
      return 34.5; // Fallback rate
    }
  }
}
