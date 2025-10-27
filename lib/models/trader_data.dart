class TraderData {
  final String address;
  final List<dynamic> openPositions;
  final Map<String, dynamic>? stats;

  TraderData({
    required this.address,
    required this.openPositions,
    this.stats,
  });

  factory TraderData.fromJson(Map<String, dynamic> json) {
    return TraderData(
      address: json['address'] ?? '',
      openPositions: json['openPositions'] ?? json['assetPositions'] ?? [],
      stats: json['stats'],
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'address': address,
      'openPositions': openPositions,
      'stats': stats,
    };
  }
}
