class PortfolioAsset {
  final String symbol;
  final double amount;
  final String name;
  final String emoji;

  PortfolioAsset({
    required this.symbol,
    required this.amount,
    required this.name,
    required this.emoji,
  });

  static List<PortfolioAsset> getAssets() {
    return [
      PortfolioAsset(
        symbol: 'AVAX',
        amount: 138.38,
        name: 'Avalanche',
        emoji: '🔺',
      ),
      PortfolioAsset(
        symbol: 'SOL',
        amount: 17.2576,
        name: 'Solana',
        emoji: '☀️',
      ),
      PortfolioAsset(
        symbol: 'ETH',
        amount: 0.8397,
        name: 'Ethereum',
        emoji: '💎',
      ),
      PortfolioAsset(
        symbol: 'XRP',
        amount: 972.9,
        name: 'Ripple',
        emoji: '💧',
      ),
      PortfolioAsset(
        symbol: 'SUI',
        amount: 170.3824,
        name: 'Sui',
        emoji: '🌊',
      ),
    ];
  }

  double getCurrentValue(Map<String, double> prices) {
    final price = prices[symbol] ?? 0;
    return amount * price;
  }
}
