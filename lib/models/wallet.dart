class Wallet {
  final String address;
  final String name;
  final bool isMain;
  
  Wallet({
    required this.address,
    required this.name,
    this.isMain = false,
  });
  
  String get shortAddress => '${address.substring(0, 6)}...${address.substring(38)}';
}
