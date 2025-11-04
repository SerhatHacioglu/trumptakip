import 'dart:convert';
import 'package:http/http.dart' as http;
import 'yahoo_finance_service.dart';

class FinnhubService {
  // Finnhub API - Free tier: 60 calls/minute (US Stocks only)
  // Yahoo Finance - Free (BIST Stocks)
  static const String _apiKey = 'd41ij6hr01qo6qdgquqgd41ij6hr01qo6qdgqur0';
  static const String _baseUrl = 'https://finnhub.io/api/v1';
  final YahooFinanceService _yahooService = YahooFinanceService();

  Future<Map<String, double>> getStockPrices(List<String> symbols) async {
    final Map<String, double> prices = {};

    if (_apiKey == 'YOUR_API_KEY_HERE') {
      return prices;
    }

    try {
      // Separate BIST and US stocks
      final bistSymbols = symbols.where((s) => _isBistStock(s)).toList();
      final usSymbols = symbols.where((s) => !_isBistStock(s)).toList();
      
      // Fetch BIST stocks from Yahoo Finance
      if (bistSymbols.isNotEmpty) {
        try {
          final bistPrices = await _yahooService.getStockPrices(
            bistSymbols.map((s) => '$s.IS').toList()
          );
          
          // Remove .IS suffix from results
          bistPrices.forEach((key, value) {
            final symbol = key.replaceAll('.IS', '');
            prices[symbol] = value.price;
          });
        } catch (e) {
          // BIST prices fetch failed (CORS issue in browser)
        }
      }
      
      // Fetch US stocks from Finnhub
      if (usSymbols.isNotEmpty) {
        for (var symbol in usSymbols) {
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
            // Error fetching from Finnhub
          }
        }
      }
    } catch (e) {
      // Error in getStockPrices
    }

    return prices;
  }
  
  bool _isBistStock(String symbol) {
    // BIST stocks are typically 5-7 characters and all caps
    // Common BIST symbols: THYAO, BIMAS, AKBNK, GARAN, etc.
    final bistSymbols = [
      'THYAO', 'BIMAS', 'SAHOL', 'AKBNK', 'GARAN', 'ISCTR', 'YKBNK', 
      'KCHOL', 'TUPRS', 'EREGL', 'SISE', 'PETKM', 'ASELS', 'SASA', 'KOZAL',
      'GLDTR', 'GMSTR', 'ALTIN', // Altın ETF'leri (Yahoo Finance: .IS suffix ile)
    ];
    return bistSymbols.contains(symbol) || (symbol.length >= 5 && symbol == symbol.toUpperCase());
  }

  Future<double> getStockPrice(String symbol) async {
    try {
      if (_isBistStock(symbol)) {
        // Use Yahoo Finance for BIST stocks
        return await _yahooService.getStockPrice('$symbol.IS');
      } else {
        // Use Finnhub for US stocks
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
      }
    } catch (e) {
      // Error fetching stock price
    }

    return 0.0;
  }
}
