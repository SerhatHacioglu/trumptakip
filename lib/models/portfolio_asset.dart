class PortfolioAsset {
  final String symbol;
  final double amount;
  final String name;
  final String emoji;
  final double investedTRY;

  PortfolioAsset({
    required this.symbol,
    required this.amount,
    required this.name,
    required this.emoji,
    required this.investedTRY,
  });

  static List<PortfolioAsset> getAssets() {
    return [
      PortfolioAsset(
        symbol: 'AVAX',
        amount: 138.38,
        name: 'Avalanche',
        emoji: '🔺',
        investedTRY: 162000,
      ),
      PortfolioAsset(
        symbol: 'SOL',
        amount: 17.2576,
        name: 'Solana',
        emoji: '☀️',
        investedTRY: 159000,
      ),
      PortfolioAsset(
        symbol: 'ETH',
        amount: 0.8397,
        name: 'Ethereum',
        emoji: '💎',
        investedTRY: 155000,
      ),
      PortfolioAsset(
        symbol: 'SUI',
        amount: 170.3824,
        name: 'Sui',
        emoji: '🌊',
        investedTRY: 24000,
      ),
      PortfolioAsset(
        symbol: 'XRP',
        amount: 972.9,
        name: 'Ripple',
        emoji: '💧',
        investedTRY: 100000,
      ),
    ];
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
