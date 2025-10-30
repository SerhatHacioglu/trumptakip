import 'dart:convert';
import 'package:http/http.dart' as http;

class StockPrice {
  final String symbol;
  final double price;
  final double change;
  final double changePercent;

  StockPrice({
    required this.symbol,
    required this.price,
    required this.change,
    required this.changePercent,
  });
}

class YahooFinanceService {
  // Yahoo Finance API - yfinance library endpoint
  static const String _baseUrl = 'https://query1.finance.yahoo.com/v8/finance/chart/';

  Future<Map<String, StockPrice>> getStockPrices(List<String> symbols) async {
    final Map<String, StockPrice> prices = {};

    try {
      for (var symbol in symbols) {
        try {
          print('Fetching price for $symbol from Yahoo Finance...');
          
          final response = await http.get(
            Uri.parse('$_baseUrl$symbol?interval=1d&range=1d'),
            headers: {
              'User-Agent': 'Mozilla/5.0 (Windows NT 10.0; Win64; x64) AppleWebKit/537.36',
            },
          ).timeout(const Duration(seconds: 10));

          print('Response status for $symbol: ${response.statusCode}');

          if (response.statusCode == 200) {
            final data = json.decode(response.body);
            
            if (data['chart']['result'] != null && data['chart']['result'].isNotEmpty) {
              final result = data['chart']['result'][0];
              final meta = result['meta'];
              
              final currentPrice = meta['regularMarketPrice'];
              final previousClose = meta['previousClose'];
              
              if (currentPrice != null) {
                final change = previousClose != null ? currentPrice - previousClose : 0.0;
                final changePercent = previousClose != null && previousClose > 0 
                    ? (change / previousClose) * 100 
                    : 0.0;

                prices[symbol] = StockPrice(
                  symbol: symbol,
                  price: currentPrice.toDouble(),
                  change: change.toDouble(),
                  changePercent: changePercent.toDouble(),
                );
                print('Successfully fetched $symbol: \$${currentPrice.toDouble()}');
                continue;
              }
            }
          }
          
          print('Failed to fetch $symbol from Yahoo Finance');
        } catch (e) {
          print('Error fetching $symbol: $e');
        }
      }
    } catch (e) {
      print('Error in getStockPrices: $e');
    }

    return prices;
  }

  Future<double> getStockPrice(String symbol) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl$symbol?interval=1d&range=1d'),
      ).timeout(const Duration(seconds: 10));

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final result = data['chart']['result'][0];
        final meta = result['meta'];
        final currentPrice = meta['regularMarketPrice'] as num;
        
        return currentPrice.toDouble();
      }
    } catch (e) {
      print('Error fetching $symbol: $e');
    }

    return 0.0;
  }
}
