import '../models/wallet.dart';

// İzlenecek wallet'lar
class WalletConfig {
  static final List<Wallet> wallets = [
    Wallet(
      address: '0xc2a30212a8ddac9e123944d6e29faddce994e5f2',
      name: 'Ana Cüzdan',
      isMain: true,
    ),
    // Whale cüzdan adresleri buraya eklenebilir
    // HyperLiquid'de aktif olarak işlem yapan büyük trader'ların adreslerini ekleyin
    // Örnek:
    // Wallet(
    //   address: '0x...whale-address-1...',
    //   name: 'Whale #1',
    //   isMain: false,
    // ),
    // Wallet(
    //   address: '0x...whale-address-2...',
    //   name: 'Whale #2',
    //   isMain: false,
    // ),
  ];
  
  static Wallet get mainWallet => wallets.firstWhere((w) => w.isMain);
  static List<Wallet> get whaleWallets => wallets.where((w) => !w.isMain).toList();
}
