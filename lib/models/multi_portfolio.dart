import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'portfolio_asset.dart';

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

  double getTotalValueTRY(Map<String, double> cryptoPrices, Map<String, double> stockPrices, double usdtTryRate, double usdTryRate) {
    return items.fold(0.0, (sum, item) {
      if (item.type == AssetType.crypto) {
        final price = cryptoPrices[item.symbol] ?? 0;
        return sum + (item.amount * price * usdtTryRate);
      } else if (item.type == AssetType.stock) {
        final price = stockPrices[item.symbol] ?? 0;
        return sum + (item.amount * price * usdTryRate);
      } else {
        // Cash - amount already in TRY
        return sum + item.amount;
      }
    });
  }
}

enum AssetType {
  crypto,
  stock,
  cash,
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

  double getCurrentValue(Map<String, double> cryptoPrices, Map<String, double> stockPrices, double usdtTryRate, double usdTryRate) {
    if (type == AssetType.crypto) {
      final price = cryptoPrices[symbol] ?? 0;
      return amount * price * usdtTryRate;
    } else if (type == AssetType.stock) {
      final price = stockPrices[symbol] ?? 0;
      return amount * price * usdTryRate;
    } else {
      // Cash - amount already in TRY
      return amount;
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
            amount: 5.093,
            type: AssetType.crypto,
            coingeckoId: 'solana',
          ),
          PortfolioItem(
            symbol: 'AVAX',
            name: 'Avalanche',
            emoji: '🔺',
            amount: 55.82,
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
        name: 'Portföy 3',
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
            amount: 59.3827,
            type: AssetType.stock,
          ),
        ],
      ),
      PortfolioGroup(
        id: 'portfolio_4',
        name: 'Portföy 4',
        emoji: '💰',
        items: [
          PortfolioItem(
            symbol: 'AVAX',
            name: 'Avalanche',
            emoji: '🔺',
            amount: 141.93,
            type: AssetType.crypto,
            coingeckoId: 'avalanche-2',
          ),
          PortfolioItem(
            symbol: 'SOL',
            name: 'Solana',
            emoji: '☀️',
            amount: 17.2576,
            type: AssetType.crypto,
            coingeckoId: 'solana',
          ),
          PortfolioItem(
            symbol: 'ETH',
            name: 'Ethereum',
            emoji: '💎',
            amount: 0.850274,
            type: AssetType.crypto,
            coingeckoId: 'ethereum',
          ),
          PortfolioItem(
            symbol: 'HYPE',
            name: 'Hype',
            emoji: '🌊',
            amount: 23.0152,
            type: AssetType.crypto,
            coingeckoId: 'hyperliquid',
          ),
        ],
      ),
      PortfolioGroup(
        id: 'portfolio_5',
        name: 'Nakit Bakiye',
        emoji: '💵',
        items: [
          PortfolioItem(
            symbol: 'TRY',
            name: 'Türk Lirası',
            emoji: '🇹🇷',
            amount: 0,
            type: AssetType.cash,
          ),
        ],
      ),
    ];
  }

  static Future<List<PortfolioGroup>> getPortfoliosWithSettings() async {
    final prefs = await SharedPreferences.getInstance();
    final defaultPortfolios = getDefaultPortfolios();
    
    // Load custom assets
    final customAssetsJson = prefs.getString('multi_portfolio_custom_assets') ?? '{}';
    final Map<String, dynamic> customAssetsByPortfolio = json.decode(customAssetsJson);
    
    // Load hidden assets
    final hiddenAssetsJson = prefs.getString('multi_portfolio_hidden_assets') ?? '{}';
    final Map<String, dynamic> hiddenAssetsByPortfolio = json.decode(hiddenAssetsJson);
    
    // Process portfolios one by one to handle async operations
    final List<PortfolioGroup> result = [];
    
    for (var portfolio in defaultPortfolios) {
      // Special handling for portfolio_4 - sync with personal portfolio
      if (portfolio.id == 'portfolio_4') {
        // Get all personal portfolio assets (defaults + custom, excluding hidden)
        final personalAssets = await PortfolioAsset.getAssetsWithSettings();
        
        final personalItems = personalAssets.map((asset) {
          return PortfolioItem(
            symbol: asset.symbol,
            name: asset.name,
            emoji: asset.emoji,
            amount: asset.amount,
            type: _convertAssetType(asset.assetType.toString()),
            coingeckoId: asset.coingeckoId,
          );
        }).toList();
        
        result.add(PortfolioGroup(
          id: portfolio.id,
          name: prefs.getString('${portfolio.id}_name') ?? portfolio.name,
          emoji: prefs.getString('${portfolio.id}_emoji') ?? portfolio.emoji,
          items: personalItems,
        ));
        continue;
      }
      
      // Get default items
      final defaultItems = portfolio.items.map((item) {
        final savedAmount = prefs.getDouble('${portfolio.id}_${item.symbol}_amount') ?? item.amount;
        return PortfolioItem(
          symbol: item.symbol,
          name: item.name,
          emoji: item.emoji,
          amount: savedAmount,
          type: item.type,
          coingeckoId: item.coingeckoId,
        );
      }).toList();
      
      // Get custom items
      final customItems = <PortfolioItem>[];
      final customList = customAssetsByPortfolio[portfolio.id] as List<dynamic>?;
      if (customList != null) {
        for (var item in customList) {
          customItems.add(PortfolioItem(
            symbol: item['symbol'],
            name: item['name'],
            emoji: item['emoji'],
            amount: item['amount'],
            type: AssetType.values.firstWhere((e) => e.toString() == 'AssetType.${item['type']}'),
            coingeckoId: item['coingeckoId'],
          ));
        }
      }
      
      // Get hidden items
      final hiddenList = (hiddenAssetsByPortfolio[portfolio.id] as List<dynamic>?) ?? [];
      final hiddenSymbols = hiddenList.cast<String>().toSet();
      
      // Filter out hidden items and combine with custom items
      final visibleDefaultItems = defaultItems.where((item) => !hiddenSymbols.contains(item.symbol)).toList();
      
      result.add(PortfolioGroup(
        id: portfolio.id,
        name: prefs.getString('${portfolio.id}_name') ?? portfolio.name,
        emoji: prefs.getString('${portfolio.id}_emoji') ?? portfolio.emoji,
        items: [...visibleDefaultItems, ...customItems],
      ));
    }
    
    return result;
  }
  
  static AssetType _convertAssetType(String assetTypeString) {
    if (assetTypeString.contains('crypto')) {
      return AssetType.crypto;
    } else if (assetTypeString.contains('usStock') || assetTypeString.contains('bistStock')) {
      return AssetType.stock;
    } else {
      return AssetType.cash;
    }
  }
  
  static Future<void> addCustomAsset(String portfolioId, PortfolioItem item) async {
    final prefs = await SharedPreferences.getInstance();
    final customAssetsJson = prefs.getString('multi_portfolio_custom_assets') ?? '{}';
    final Map<String, dynamic> customAssetsByPortfolio = json.decode(customAssetsJson);
    
    final portfolioAssets = (customAssetsByPortfolio[portfolioId] as List<dynamic>?) ?? [];
    portfolioAssets.add({
      'symbol': item.symbol,
      'name': item.name,
      'emoji': item.emoji,
      'amount': item.amount,
      'type': item.type.toString().split('.').last,
      'coingeckoId': item.coingeckoId,
    });
    
    customAssetsByPortfolio[portfolioId] = portfolioAssets;
    await prefs.setString('multi_portfolio_custom_assets', json.encode(customAssetsByPortfolio));
  }
  
  static Future<void> removeAsset(String portfolioId, String symbol) async {
    final prefs = await SharedPreferences.getInstance();
    final defaultPortfolios = getDefaultPortfolios();
    
    // Check if it's a default asset
    final defaultPortfolio = defaultPortfolios.firstWhere((p) => p.id == portfolioId);
    final isDefault = defaultPortfolio.items.any((item) => item.symbol == symbol);
    
    if (isDefault) {
      // Hide default asset
      final hiddenAssetsJson = prefs.getString('multi_portfolio_hidden_assets') ?? '{}';
      final Map<String, dynamic> hiddenAssetsByPortfolio = json.decode(hiddenAssetsJson);
      
      final hiddenList = (hiddenAssetsByPortfolio[portfolioId] as List<dynamic>?) ?? [];
      if (!hiddenList.contains(symbol)) {
        hiddenList.add(symbol);
      }
      hiddenAssetsByPortfolio[portfolioId] = hiddenList;
      await prefs.setString('multi_portfolio_hidden_assets', json.encode(hiddenAssetsByPortfolio));
    } else {
      // Remove custom asset
      final customAssetsJson = prefs.getString('multi_portfolio_custom_assets') ?? '{}';
      final Map<String, dynamic> customAssetsByPortfolio = json.decode(customAssetsJson);
      
      final portfolioAssets = (customAssetsByPortfolio[portfolioId] as List<dynamic>?) ?? [];
      portfolioAssets.removeWhere((item) => item['symbol'] == symbol);
      customAssetsByPortfolio[portfolioId] = portfolioAssets;
      await prefs.setString('multi_portfolio_custom_assets', json.encode(customAssetsByPortfolio));
    }
  }
  
  static Future<void> updateAssetAmount(String portfolioId, String symbol, double amount) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setDouble('${portfolioId}_${symbol}_amount', amount);
  }
}
