import 'dart:convert';
import 'package:http/http.dart' as http;

class CoinGeckoService {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';

  Future<Map<String, CryptoPrice>> getCryptoPrices({List<String>? cryptoIds}) async {
    try {
      // Use provided IDs or default to main screen coins
      final ids = cryptoIds?.isNotEmpty == true 
          ? cryptoIds!.join(',')
          : 'bitcoin,ethereum,solana,avalanche-2,sui,ripple';
      
      // Use coins/markets endpoint to get price_change_percentage_24h
      final url = Uri.parse(
        '$_baseUrl/coins/markets?vs_currency=usd&ids=$ids&order=market_cap_desc&price_change_percentage=24h'
      );
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final List<dynamic> data = json.decode(response.body);
        
        final Map<String, CryptoPrice> prices = {};
        
        // Map of CoinGecko IDs to symbols
        final idToSymbol = {
          'bitcoin': 'BTC',
          'ethereum': 'ETH',
          'ripple': 'XRP',
          'cardano': 'ADA',
          'solana': 'SOL',
          'dogecoin': 'DOGE',
          'binancecoin': 'BNB',
          'polkadot': 'DOT',
          'litecoin': 'LTC',
          'chainlink': 'LINK',
          'uniswap': 'UNI',
          'avalanche-2': 'AVAX',
          'cosmos': 'ATOM',
          'stellar': 'XLM',
          'polygon': 'MATIC',
          'tron': 'TRX',
          'algorand': 'ALGO',
          'vechain': 'VET',
          'filecoin': 'FIL',
          'apecoin': 'APE',
          'sui': 'SUI',
          'hyperliquid': 'HYPE',
        };
        
        // Iterate over the response and build the prices map
        for (var coinData in data) {
          final coinId = coinData['id'] as String;
          final symbol = idToSymbol[coinId] ?? coinId.toUpperCase();
          
          prices[symbol] = CryptoPrice(
            symbol: symbol,
            name: coinData['name'] ?? coinId,
            price: (coinData['current_price'] ?? 0).toDouble(),
            change24h: (coinData['price_change_percentage_24h'] ?? 0).toDouble(),
          );
        }
        
        return prices;
      }
      
      return {};
    } catch (e) {
      return {};
    }
  }
}

class CryptoPrice {
  final String symbol;
  final String name;
  final double price;
  final double change24h;

  CryptoPrice({
    required this.symbol,
    required this.name,
    required this.price,
    required this.change24h,
  });
}
