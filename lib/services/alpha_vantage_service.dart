import 'dart:convert';
import 'package:http/http.dart' as http;

class AlphaVantageService {
  // Alpha Vantage API - Free tier: 500 calls/day, 5 calls/minute
  static const String _apiKey = 'P87AE6OHDPLSBHAU';
  static const String _baseUrl = 'https://www.alphavantage.co/query';

  Future<Map<String, double>> getStockPrices(List<String> symbols) async {
    final Map<String, double> prices = {};

    try {
      for (var symbol in symbols) {
        try {
          print('Fetching $symbol from Alpha Vantage...');
          
          final response = await http.get(
            Uri.parse('$_baseUrl?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$_apiKey'),
          ).timeout(const Duration(seconds: 15));

          print('Alpha Vantage response for $symbol: ${response.statusCode}');

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            
            // Rate limit check
            if (data.containsKey('Note')) {
              print('Alpha Vantage rate limit reached: ${data['Note']}');
              break; // Stop trying other symbols
            }
            
            if (data.containsKey('Global Quote')) {
              final quote = data['Global Quote'];
              final priceStr = quote['05. price'];
              
              if (priceStr != null && priceStr.toString().isNotEmpty) {
                final price = double.tryParse(priceStr.toString());
                if (price != null && price > 0) {
                  prices[symbol] = price;
                  print('Alpha Vantage: Successfully fetched $symbol: \$${price}');
                } else {
                  print('Alpha Vantage: Invalid price for $symbol: $priceStr');
                }
              } else {
                print('Alpha Vantage: No price data for $symbol');
              }
            } else {
              print('Alpha Vantage: No Global Quote for $symbol');
              print('Response: ${response.body}');
            }
          } else {
            print('Alpha Vantage: HTTP ${response.statusCode} for $symbol');
          }
          
          // Rate limiting - wait 13 seconds between requests for free tier (5 calls/minute)
          await Future.delayed(const Duration(seconds: 13));
        } catch (e) {
          print('Alpha Vantage error fetching $symbol: $e');
        }
      }
    } catch (e) {
      print('Alpha Vantage error in getStockPrices: $e');
    }

    return prices;
  }

  Future<double> getStockPrice(String symbol) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl?function=GLOBAL_QUOTE&symbol=$symbol&apikey=$_apiKey'),
      ).timeout(const Duration(seconds: 15));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        
        if (data.containsKey('Global Quote')) {
          final quote = data['Global Quote'];
          final priceStr = quote['05. price'];
          
          if (priceStr != null) {
            final price = double.tryParse(priceStr.toString());
            if (price != null && price > 0) {
              return price;
            }
          }
        }
      }
    } catch (e) {
      print('Alpha Vantage error fetching $symbol: $e');
    }

    return 0.0;
  }
}
