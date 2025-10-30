import 'dart:convert';
import 'package:http/http.dart' as http;

class FinnhubService {
  // Finnhub API - Free tier: 60 calls/minute
  // ÜCRETSİZ API KEY almak için: https://finnhub.io/register
  // 1. Kayıt olun (email + şifre)
  // 2. Email'inizi doğrulayın
  // 3. Dashboard'dan API key'inizi kopyalayın
  // 4. Aşağıdaki satıra yapıştırın
  static const String _apiKey = 'd41ij6hr01qo6qdgquqgd41ij6hr01qo6qdgqur0';
  static const String _baseUrl = 'https://finnhub.io/api/v1';

  Future<Map<String, double>> getStockPrices(List<String> symbols) async {
    final Map<String, double> prices = {};

    if (_apiKey == 'YOUR_API_KEY_HERE') {
      return prices;
    }

    try {
      for (var symbol in symbols) {
        try {
          final response = await http.get(
            Uri.parse('$_baseUrl/quote?symbol=$symbol&token=$_apiKey'),
          ).timeout(const Duration(seconds: 10));

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            
            final currentPrice = data['c'] as num?; // 'c' is current price
            
            if (currentPrice != null && currentPrice > 0) {
              prices[symbol] = currentPrice.toDouble();
            }
          } else if (response.statusCode == 401) {
            break; // Stop trying if API key is invalid
          }
          
          // Rate limiting - 1 second between requests
          await Future.delayed(const Duration(seconds: 1));
        } catch (e) {
          // Silently handle error
        }
      }
    } catch (e) {
      // Silently handle error
    }

    return prices;
  }

  Future<double> getStockPrice(String symbol) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/quote?symbol=$symbol&token=$_apiKey'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final currentPrice = data['c'] as num?;
        
        if (currentPrice != null && currentPrice > 0) {
          return currentPrice.toDouble();
        }
      }
    } catch (e) {
      // Silently handle error
    }

    return 0.0;
  }
}
