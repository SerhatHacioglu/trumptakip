class Position {
  final String coin;
  final double size;
  final double entryPrice;
  final double markPrice;
  final double unrealizedPnl;
  final double leverage;
  final String side;
  final double liquidationPrice;

  Position({
    required this.coin,
    required this.size,
    required this.entryPrice,
    required this.markPrice,
    required this.unrealizedPnl,
    required this.leverage,
    required this.side,
    required this.liquidationPrice,
  });

  factory Position.fromJson(Map<String, dynamic> json) {
    return Position(
      coin: json['coin'] ?? '',
      size: _parseDouble(json['szi'] ?? json['size'] ?? 0),
      entryPrice: _parseDouble(json['entryPx'] ?? json['entryPrice'] ?? 0),
      markPrice: _parseDouble(json['positionValue'] ?? json['markPrice'] ?? 0),
      unrealizedPnl: _parseDouble(json['unrealizedPnl'] ?? 0),
      leverage: _parseDouble(json['leverage'] ?? 1),
      side: json['side'] ?? '',
      liquidationPrice: _parseDouble(json['liquidationPx'] ?? json['liquidationPrice'] ?? 0),
    );
  }

  static double _parseDouble(dynamic value) {
    if (value is double) return value;
    if (value is int) return value.toDouble();
    if (value is String) return double.tryParse(value) ?? 0.0;
    return 0.0;
  }

  Map<String, dynamic> toJson() {
    return {
      'coin': coin,
      'size': size,
      'entryPrice': entryPrice,
      'markPrice': markPrice,
      'unrealizedPnl': unrealizedPnl,
      'leverage': leverage,
      'side': side,
      'liquidationPrice': liquidationPrice,
    };
  }
}
