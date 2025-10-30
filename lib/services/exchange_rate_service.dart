import 'dart:convert';
import 'package:http/http.dart' as http;

class ExchangeRateService {
  static const String _binanceApi = 'https://api.binance.com/api/v3/ticker/price?symbol=USDTTRY';
  static const String _tcmbApi = 'https://api.exchangerate-api.com/v4/latest/USD';

  Future<double> getUsdtTryRate() async {
    try {
      final response = await http.get(Uri.parse(_binanceApi));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return double.parse(data['price']);
      }
      return 34.5; // Fallback rate
    } catch (e) {
      return 34.5; // Fallback rate
    }
  }

  Future<double> getUsdTryRate() async {
    try {
      final response = await http.get(Uri.parse(_tcmbApi));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final rates = data['rates'] as Map<String, dynamic>;
        return (rates['TRY'] as num).toDouble();
      }
      return 34.3; // Fallback rate
    } catch (e) {
      return 34.3; // Fallback rate
    }
  }
}
