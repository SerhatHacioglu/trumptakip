import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

enum AssetType { crypto, usStock, bistStock }

class PortfolioAsset {
  final String symbol;
  final String name;
  final String emoji;
  final double amount;
  final double investedTRY;
  final String coingeckoId;
  final AssetType assetType;
  final bool isCustom;

  PortfolioAsset({
    required this.symbol,
    required this.name,
    required this.emoji,
    required this.amount,
    required this.investedTRY,
    required this.coingeckoId,
    this.assetType = AssetType.crypto,
    this.isCustom = false,
  });

  Map<String, dynamic> toJson() {
    return {
      'symbol': symbol,
      'name': name,
      'emoji': emoji,
      'amount': amount,
      'investedTRY': investedTRY,
      'coingeckoId': coingeckoId,
      'assetType': assetType.toString(),
      'isCustom': isCustom,
    };
  }

  factory PortfolioAsset.fromJson(Map<String, dynamic> json) {
    return PortfolioAsset(
      symbol: json['symbol'],
      name: json['name'],
      emoji: json['emoji'],
      amount: json['amount'],
      investedTRY: json['investedTRY'],
      coingeckoId: json['coingeckoId'],
      assetType: AssetType.values.firstWhere(
        (e) => e.toString() == json['assetType'],
        orElse: () => AssetType.crypto,
      ),
      isCustom: json['isCustom'] ?? false,
    );
  }

  static List<PortfolioAsset> getAssets() {
    return [
      PortfolioAsset(
        symbol: 'AVAX',
        amount: 141.93,
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
        amount: 0.850274,
        name: 'Ethereum',
        emoji: '💎',
        investedTRY: 162000,
        coingeckoId: 'ethereum',
      ),
      PortfolioAsset(
        symbol: 'HYPE',
        amount: 23.0152,
        name: 'Hype',
        emoji: '🌊',
        investedTRY: 47000,
        coingeckoId: 'hyperliquid',
      ),
    ];
  }

  static Future<List<PortfolioAsset>> getAssetsWithSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultAssets = getAssets();
    
    // Load hidden assets list
    final hiddenAssetsJson = prefs.getString('hidden_assets') ?? '[]';
    final List<dynamic> hiddenAssetsList = json.decode(hiddenAssetsJson);
    final hiddenSymbols = hiddenAssetsList.cast<String>().toSet();
    
    // Load custom assets
    final customAssetsJson = prefs.getString('custom_assets') ?? '[]';
    final List<dynamic> customAssetsList = json.decode(customAssetsJson);
    final customAssets = customAssetsList.map((json) => PortfolioAsset.fromJson(json)).toList();
    
    // Merge default assets with their saved values (excluding hidden ones)
    final defaultWithSettings = defaultAssets
        .where((asset) => !hiddenSymbols.contains(asset.symbol))
        .map((asset) {
      final savedAmount = prefs.getDouble('amount_${asset.symbol}') ?? asset.amount;
      final savedInvested = prefs.getDouble('invested_${asset.symbol}') ?? asset.investedTRY;
      
      return PortfolioAsset(
        symbol: asset.symbol,
        name: asset.name,
        emoji: asset.emoji,
        amount: savedAmount,
        investedTRY: savedInvested,
        coingeckoId: asset.coingeckoId,
        assetType: asset.assetType,
        isCustom: false,
      );
    }).toList();
    
    // Return default + custom assets
    return [...defaultWithSettings, ...customAssets];
  }

  static Future<void> addCustomAsset(PortfolioAsset asset) async {
    final prefs = await SharedPreferences.getInstance();
    final customAssetsJson = prefs.getString('custom_assets') ?? '[]';
    final List<dynamic> customAssetsList = json.decode(customAssetsJson);
    
    customAssetsList.add(asset.toJson());
    await prefs.setString('custom_assets', json.encode(customAssetsList));
  }

  static Future<void> removeCustomAsset(String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    
    // Check if it's a custom asset
    final customAssetsJson = prefs.getString('custom_assets') ?? '[]';
    final List<dynamic> customAssetsList = json.decode(customAssetsJson);
    
    final isCustom = customAssetsList.any((json) => json['symbol'] == symbol);
    
    if (isCustom) {
      // Remove from custom assets
      customAssetsList.removeWhere((json) => json['symbol'] == symbol);
      await prefs.setString('custom_assets', json.encode(customAssetsList));
    } else {
      // Add to hidden default assets list
      final hiddenAssetsJson = prefs.getString('hidden_assets') ?? '[]';
      final List<dynamic> hiddenAssetsList = json.decode(hiddenAssetsJson);
      
      if (!hiddenAssetsList.contains(symbol)) {
        hiddenAssetsList.add(symbol);
        await prefs.setString('hidden_assets', json.encode(hiddenAssetsList));
      }
    }
  }

  static double getTotalInvested() {
    return getAssets().fold(0.0, (sum, asset) => sum + asset.investedTRY);
  }

  double getCurrentValue(Map<String, double> cryptoPrices, double usdtTryRate, {Map<String, double>? stockPrices, double? usdTryRate}) {
    if (assetType == AssetType.crypto) {
      final price = cryptoPrices[symbol] ?? 0;
      return amount * price * usdtTryRate;
    } else if (assetType == AssetType.usStock) {
      final price = stockPrices?[symbol] ?? 0;
      final tryRate = usdTryRate ?? 34.3;
      return amount * price * tryRate;
    } else { // BIST stock
      final price = stockPrices?[symbol] ?? 0;
      return amount * price; // Already in TL
    }
  }

  double getProfitLoss(Map<String, double> cryptoPrices, double usdtTryRate, {Map<String, double>? stockPrices, double? usdTryRate}) {
    return getCurrentValue(cryptoPrices, usdtTryRate, stockPrices: stockPrices, usdTryRate: usdTryRate) - investedTRY;
  }

  double getProfitLossPercent(Map<String, double> cryptoPrices, double usdtTryRate, {Map<String, double>? stockPrices, double? usdTryRate}) {
    if (investedTRY == 0) return 0;
    return (getProfitLoss(cryptoPrices, usdtTryRate, stockPrices: stockPrices, usdTryRate: usdTryRate) / investedTRY) * 100;
  }
}
