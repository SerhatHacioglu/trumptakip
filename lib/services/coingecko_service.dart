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
      
      final url = Uri.parse('$_baseUrl/simple/price?ids=$ids&vs_currencies=usd');
      
      final response = await http.get(url);
      
      if (response.statusCode == 200) {
        final Map<String, dynamic> data = json.decode(response.body);
        
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
        data.forEach((coinId, priceData) {
          final symbol = idToSymbol[coinId] ?? coinId.toUpperCase();
          if (priceData['usd'] != null) {
            prices[symbol] = CryptoPrice(
              symbol: symbol,
              name: coinId, // Using coinId as name for now
              price: priceData['usd'].toDouble(),
              change24h: 0.0, // CoinGecko simple price doesn't include change
            );
          }
        });
        
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
