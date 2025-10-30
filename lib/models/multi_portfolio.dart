import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PortfolioGroup {
  final String id;
  final String name;
  final String emoji;
  final List<PortfolioItem> items;

  PortfolioGroup({
    required this.id,
    required this.name,
    required this.emoji,
    required this.items,
  });

  double getTotalValueTRY(Map<String, double> cryptoPrices, Map<String, double> stockPrices, double usdtTryRate) {
    return items.fold(0.0, (sum, item) {
      if (item.type == AssetType.crypto) {
        final price = cryptoPrices[item.symbol] ?? 0;
        return sum + (item.amount * price * usdtTryRate);
      } else {
        final price = stockPrices[item.symbol] ?? 0;
        return sum + (item.amount * price * usdtTryRate);
      }
    });
  }
}

enum AssetType {
  crypto,
  stock,
}

class PortfolioItem {
  final String symbol;
  final String name;
  final String emoji;
  final double amount;
  final AssetType type;
  final String? coingeckoId;

  PortfolioItem({
    required this.symbol,
    required this.name,
    required this.emoji,
    required this.amount,
    required this.type,
    this.coingeckoId,
  });

  double getCurrentValue(Map<String, double> cryptoPrices, Map<String, double> stockPrices, double usdtTryRate) {
    if (type == AssetType.crypto) {
      final price = cryptoPrices[symbol] ?? 0;
      return amount * price * usdtTryRate;
    } else {
      final price = stockPrices[symbol] ?? 0;
      return amount * price * usdtTryRate;
    }
  }

  static List<PortfolioGroup> getDefaultPortfolios() {
    return [
      PortfolioGroup(
        id: 'portfolio_1',
        name: 'Portföy 1',
        emoji: '💼',
        items: [
          PortfolioItem(
            symbol: 'SOL',
            name: 'Solana',
            emoji: '☀️',
            amount: 8.093,
            type: AssetType.crypto,
            coingeckoId: 'solana',
          ),
          PortfolioItem(
            symbol: 'AVAX',
            name: 'Avalanche',
            emoji: '🔺',
            amount: 65.82,
            type: AssetType.crypto,
            coingeckoId: 'avalanche-2',
          ),
        ],
      ),
      PortfolioGroup(
        id: 'portfolio_2',
        name: 'Portföy 2',
        emoji: '📊',
        items: [
          PortfolioItem(
            symbol: 'SOL',
            name: 'Solana',
            emoji: '☀️',
            amount: 3.4364,
            type: AssetType.crypto,
            coingeckoId: 'solana',
          ),
          PortfolioItem(
            symbol: 'ETH',
            name: 'Ethereum',
            emoji: '💎',
            amount: 0.14755,
            type: AssetType.crypto,
            coingeckoId: 'ethereum',
          ),
          PortfolioItem(
            symbol: 'AVAX',
            name: 'Avalanche',
            emoji: '🔺',
            amount: 27.858,
            type: AssetType.crypto,
            coingeckoId: 'avalanche-2',
          ),
        ],
      ),
      PortfolioGroup(
        id: 'portfolio_3',
        name: 'Portföy 3 (US Stocks)',
        emoji: '🇺🇸',
        items: [
          PortfolioItem(
            symbol: 'SBET',
            name: 'SharpLink Gaming',
            emoji: '🎰',
            amount: 20,
            type: AssetType.stock,
          ),
          PortfolioItem(
            symbol: 'TQQQ',
            name: 'ProShares UltraPro QQQ',
            emoji: '📈',
            amount: 41.8698,
            type: AssetType.stock,
          ),
        ],
      ),
    ];
  }

  static Future<List<PortfolioGroup>> getPortfoliosWithSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultPortfolios = getDefaultPortfolios();
    
    return defaultPortfolios.map((portfolio) {
      return PortfolioGroup(
        id: portfolio.id,
        name: prefs.getString('${portfolio.id}_name') ?? portfolio.name,
        emoji: prefs.getString('${portfolio.id}_emoji') ?? portfolio.emoji,
        items: portfolio.items.map((item) {
          final savedAmount = prefs.getDouble('${portfolio.id}_${item.symbol}_amount') ?? item.amount;
          return PortfolioItem(
            symbol: item.symbol,
            name: item.name,
            emoji: item.emoji,
            amount: savedAmount,
            type: item.type,
            coingeckoId: item.coingeckoId,
          );
        }).toList(),
      );
    }).toList();
  }
}
