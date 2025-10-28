import 'dart:convert';
import 'package:http/http.dart' as http;

class CoinGeckoService {
  static const String _baseUrl = 'https://api.coingecko.com/api/v3';

  Future<Map<String, CryptoPrice>> getCryptoPrices() async {
    try {
      final ids = 'bitcoin,ethereum,solana,avalanche-2,ripple,sui';
      final response = await http.get(
        Uri.parse('$_baseUrl/simple/price?ids=$ids&vs_currencies=usd&include_24hr_change=true'),
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        
        return {
          'BTC': CryptoPrice(
            symbol: 'BTC',
            name: 'Bitcoin',
            price: data['bitcoin']['usd'].toDouble(),
            change24h: data['bitcoin']['usd_24h_change']?.toDouble() ?? 0,
          ),
          'ETH': CryptoPrice(
            symbol: 'ETH',
            name: 'Ethereum',
            price: data['ethereum']['usd'].toDouble(),
            change24h: data['ethereum']['usd_24h_change']?.toDouble() ?? 0,
          ),
          'SOL': CryptoPrice(
            symbol: 'SOL',
            name: 'Solana',
            price: data['solana']['usd'].toDouble(),
            change24h: data['solana']['usd_24h_change']?.toDouble() ?? 0,
          ),
          'AVAX': CryptoPrice(
            symbol: 'AVAX',
            name: 'Avalanche',
            price: data['avalanche-2']['usd'].toDouble(),
            change24h: data['avalanche-2']['usd_24h_change']?.toDouble() ?? 0,
          ),
          'XRP': CryptoPrice(
            symbol: 'XRP',
            name: 'Ripple',
            price: data['ripple']['usd'].toDouble(),
            change24h: data['ripple']['usd_24h_change']?.toDouble() ?? 0,
          ),
          'SUI': CryptoPrice(
            symbol: 'SUI',
            name: 'Sui',
            price: data['sui']['usd'].toDouble(),
            change24h: data['sui']['usd_24h_change']?.toDouble() ?? 0,
          ),
        };
      } else {
        throw Exception('Failed to load crypto prices');
      }
    } catch (e) {
      rethrow;
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
