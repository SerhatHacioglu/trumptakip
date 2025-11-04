class AssetSuggestion {
  final String symbol;
  final String name;
  final String coingeckoId;
  final String emoji;

  AssetSuggestion({
    required this.symbol,
    required this.name,
    required this.coingeckoId,
    this.emoji = '💰',
  });
}

class AssetSuggestions {
  // Popüler Kripto Paralar
  static final List<AssetSuggestion> cryptos = [
    AssetSuggestion(symbol: 'BTC', name: 'Bitcoin', coingeckoId: 'bitcoin', emoji: '₿'),
    AssetSuggestion(symbol: 'ETH', name: 'Ethereum', coingeckoId: 'ethereum', emoji: '💎'),
    AssetSuggestion(symbol: 'SOL', name: 'Solana', coingeckoId: 'solana', emoji: '☀️'),
    AssetSuggestion(symbol: 'AVAX', name: 'Avalanche', coingeckoId: 'avalanche-2', emoji: '🔺'),
    AssetSuggestion(symbol: 'XRP', name: 'Ripple', coingeckoId: 'ripple', emoji: '💧'),
    AssetSuggestion(symbol: 'ADA', name: 'Cardano', coingeckoId: 'cardano', emoji: '🔷'),
    AssetSuggestion(symbol: 'DOGE', name: 'Dogecoin', coingeckoId: 'dogecoin', emoji: '🐕'),
    AssetSuggestion(symbol: 'DOT', name: 'Polkadot', coingeckoId: 'polkadot', emoji: '⚫'),
    AssetSuggestion(symbol: 'MATIC', name: 'Polygon', coingeckoId: 'polygon', emoji: '🟣'),
    AssetSuggestion(symbol: 'LINK', name: 'Chainlink', coingeckoId: 'chainlink', emoji: '🔗'),
    AssetSuggestion(symbol: 'UNI', name: 'Uniswap', coingeckoId: 'uniswap', emoji: '🦄'),
    AssetSuggestion(symbol: 'LTC', name: 'Litecoin', coingeckoId: 'litecoin', emoji: '🪙'),
    AssetSuggestion(symbol: 'BCH', name: 'Bitcoin Cash', coingeckoId: 'bitcoin-cash', emoji: '💚'),
    AssetSuggestion(symbol: 'ATOM', name: 'Cosmos', coingeckoId: 'cosmos', emoji: '⚛️'),
    AssetSuggestion(symbol: 'SUI', name: 'Sui', coingeckoId: 'sui', emoji: '🌊'),
    AssetSuggestion(symbol: 'APT', name: 'Aptos', coingeckoId: 'aptos', emoji: '🅰️'),
    AssetSuggestion(symbol: 'ARB', name: 'Arbitrum', coingeckoId: 'arbitrum', emoji: '🔵'),
    AssetSuggestion(symbol: 'OP', name: 'Optimism', coingeckoId: 'optimism', emoji: '🔴'),
    AssetSuggestion(symbol: 'INJ', name: 'Injective', coingeckoId: 'injective-protocol', emoji: '💉'),
    AssetSuggestion(symbol: 'TIA', name: 'Celestia', coingeckoId: 'celestia', emoji: '🌌'),
    AssetSuggestion(symbol: 'HYPE', name: 'Hyperliquid', coingeckoId: 'hyperliquid', emoji: '⚡'),
  ];

  // Popüler ABD Hisseleri
  static final List<AssetSuggestion> usStocks = [
    AssetSuggestion(symbol: 'AAPL', name: 'Apple', coingeckoId: 'AAPL', emoji: '🍎'),
    AssetSuggestion(symbol: 'MSFT', name: 'Microsoft', coingeckoId: 'MSFT', emoji: '🪟'),
    AssetSuggestion(symbol: 'GOOGL', name: 'Google', coingeckoId: 'GOOGL', emoji: '🔍'),
    AssetSuggestion(symbol: 'AMZN', name: 'Amazon', coingeckoId: 'AMZN', emoji: '📦'),
    AssetSuggestion(symbol: 'TSLA', name: 'Tesla', coingeckoId: 'TSLA', emoji: '🚗'),
    AssetSuggestion(symbol: 'META', name: 'Meta', coingeckoId: 'META', emoji: '👥'),
    AssetSuggestion(symbol: 'NVDA', name: 'NVIDIA', coingeckoId: 'NVDA', emoji: '🎮'),
    AssetSuggestion(symbol: 'NFLX', name: 'Netflix', coingeckoId: 'NFLX', emoji: '🎬'),
    AssetSuggestion(symbol: 'AMD', name: 'AMD', coingeckoId: 'AMD', emoji: '💻'),
    AssetSuggestion(symbol: 'COIN', name: 'Coinbase', coingeckoId: 'COIN', emoji: '🪙'),
    AssetSuggestion(symbol: 'MSTR', name: 'MicroStrategy', coingeckoId: 'MSTR', emoji: '📊'),
    AssetSuggestion(symbol: 'TQQQ', name: 'ProShares UltraPro QQQ', coingeckoId: 'TQQQ', emoji: '📈'),
    AssetSuggestion(symbol: 'SBET', name: 'SharpLink Gaming', coingeckoId: 'SBET', emoji: '🎰'),
    AssetSuggestion(symbol: 'SPY', name: 'S&P 500 ETF', coingeckoId: 'SPY', emoji: '📊'),
    AssetSuggestion(symbol: 'QQQ', name: 'Nasdaq ETF', coingeckoId: 'QQQ', emoji: '📈'),
    AssetSuggestion(symbol: 'VOO', name: 'Vanguard S&P 500', coingeckoId: 'VOO', emoji: '🏦'),
    AssetSuggestion(symbol: 'DIA', name: 'Dow Jones ETF', coingeckoId: 'DIA', emoji: '💼'),
  ];

  // Popüler BIST Hisseleri
  static final List<AssetSuggestion> bistStocks = [
    AssetSuggestion(symbol: 'THYAO', name: 'Türk Hava Yolları', coingeckoId: 'THYAO', emoji: '✈️'),
    AssetSuggestion(symbol: 'BIMAS', name: 'BIM', coingeckoId: 'BIMAS', emoji: '🛒'),
    AssetSuggestion(symbol: 'SAHOL', name: 'Sabancı Holding', coingeckoId: 'SAHOL', emoji: '🏢'),
    AssetSuggestion(symbol: 'AKBNK', name: 'Akbank', coingeckoId: 'AKBNK', emoji: '🏦'),
    AssetSuggestion(symbol: 'GARAN', name: 'Garanti BBVA', coingeckoId: 'GARAN', emoji: '🏦'),
    AssetSuggestion(symbol: 'ISCTR', name: 'İş Bankası', coingeckoId: 'ISCTR', emoji: '🏦'),
    AssetSuggestion(symbol: 'YKBNK', name: 'Yapı Kredi', coingeckoId: 'YKBNK', emoji: '🏦'),
    AssetSuggestion(symbol: 'KCHOL', name: 'Koç Holding', coingeckoId: 'KCHOL', emoji: '🏢'),
    AssetSuggestion(symbol: 'TUPRS', name: 'Tüpraş', coingeckoId: 'TUPRS', emoji: '⛽'),
    AssetSuggestion(symbol: 'EREGL', name: 'Ereğli Demir Çelik', coingeckoId: 'EREGL', emoji: '🏭'),
    AssetSuggestion(symbol: 'SISE', name: 'Şişe Cam', coingeckoId: 'SISE', emoji: '🍾'),
    AssetSuggestion(symbol: 'PETKM', name: 'Petkim', coingeckoId: 'PETKM', emoji: '🧪'),
    AssetSuggestion(symbol: 'ASELS', name: 'Aselsan', coingeckoId: 'ASELS', emoji: '⚙️'),
    AssetSuggestion(symbol: 'SASA', name: 'Sasa Polyester', coingeckoId: 'SASA', emoji: '🧵'),
    AssetSuggestion(symbol: 'KOZAL', name: 'Koza Altın', coingeckoId: 'KOZAL', emoji: '🥇'),
    AssetSuggestion(symbol: 'GLDTR', name: 'Altın TRF', coingeckoId: 'GLDTR', emoji: '🪙'),
    AssetSuggestion(symbol: 'GMSTR', name: 'Gümüş TRF', coingeckoId: 'GMSTR', emoji: '🥈'),
    AssetSuggestion(symbol: 'ALTIN', name: 'Altın Endeksi', coingeckoId: 'ALTIN', emoji: '💰'),
  ];

  static List<AssetSuggestion> getSuggestions(String assetType) {
    switch (assetType) {
      case 'crypto':
        return cryptos;
      case 'usStock':
        return usStocks;
      case 'bistStock':
        return bistStocks;
      default:
        return [];
    }
  }

  static List<AssetSuggestion> searchSuggestions(String assetType, String query) {
    final suggestions = getSuggestions(assetType);
    if (query.isEmpty) return suggestions;
    
    final lowerQuery = query.toLowerCase();
    return suggestions.where((asset) => 
      asset.symbol.toLowerCase().contains(lowerQuery) ||
      asset.name.toLowerCase().contains(lowerQuery)
    ).toList();
  }
}
