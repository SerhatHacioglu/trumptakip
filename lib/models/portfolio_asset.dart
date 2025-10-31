import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PortfolioAsset {
  final String symbol;
  final String name;
  final String emoji;
  final double amount;
  final double investedTRY;
  final String coingeckoId;

  PortfolioAsset({
    required this.symbol,
    required this.name,
    required this.emoji,
    required this.amount,
    required this.investedTRY,
    required this.coingeckoId,
  });

  static List<PortfolioAsset> getAssets() {
    return [
      PortfolioAsset(
        symbol: 'AVAX',
        amount: 138.38,
        name: 'Avalanche',
        emoji: '🔺',
        investedTRY: 162000,
        coingeckoId: 'avalanche-2',
      ),
      PortfolioAsset(
        symbol: 'SOL',
        amount: 17.2576,
        name: 'Solana',
        emoji: '☀️',
        investedTRY: 159000,
        coingeckoId: 'solana',
      ),
      PortfolioAsset(
        symbol: 'ETH',
        amount: 1.0000,
        name: 'Ethereum',
        emoji: '💎',
        investedTRY: 182000,
        coingeckoId: 'ethereum',
      ),
      PortfolioAsset(
        symbol: 'SUI',
        amount: 412.6824,
        name: 'Sui',
        emoji: '🌊',
        investedTRY: 47000,
        coingeckoId: 'sui',
      ),
      PortfolioAsset(
        symbol: 'XRP',
        amount: 972.9,
        name: 'Ripple',
        emoji: '💧',
        investedTRY: 100000,
        coingeckoId: 'ripple',
      ),
    ];
  }

  static Future<List<PortfolioAsset>> getAssetsWithSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultAssets = getAssets();
    
    return defaultAssets.map((asset) {
      final savedAmount = prefs.getDouble('amount_${asset.symbol}') ?? asset.amount;
      final savedInvested = prefs.getDouble('invested_${asset.symbol}') ?? asset.investedTRY;
      
      return PortfolioAsset(
        symbol: asset.symbol,
        name: asset.name,
        emoji: asset.emoji,
        amount: savedAmount,
        investedTRY: savedInvested,
        coingeckoId: asset.coingeckoId,
      );
    }).toList();
  }

  static double getTotalInvested() {
    return getAssets().fold(0.0, (sum, asset) => sum + asset.investedTRY);
  }

  double getCurrentValue(Map<String, double> prices, double usdtTryRate) {
    final price = prices[symbol] ?? 0;
    return amount * price * usdtTryRate;
  }

  double getProfitLoss(Map<String, double> prices, double usdtTryRate) {
    return getCurrentValue(prices, usdtTryRate) - investedTRY;
  }

  double getProfitLossPercent(Map<String, double> prices, double usdtTryRate) {
    if (investedTRY == 0) return 0;
    return (getProfitLoss(prices, usdtTryRate) / investedTRY) * 100;
  }
}
