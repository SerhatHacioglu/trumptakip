import 'dart:convert';
import 'package:http/http.dart' as http;

class ExchangeRateService {
  static const String _apiUrl = 'https://api.exchangerate-api.com/v4/latest/USD';

  Future<double> getUsdTryRate() async {
    try {
      final response = await http.get(Uri.parse(_apiUrl));
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return (data['rates']['TRY'] as num).toDouble();
      }
      return 34.5; // Fallback rate
    } catch (e) {
      print('Exchange rate error: $e');
      return 34.5; // Fallback rate
    }
  }
}
