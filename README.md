# Trump Takip - HyperLiquid Pozisyon Takip Uygulaması

Bu Flutter uygulaması, HyperLiquid platformunda belirli bir wallet adresine ait açık pozisyonları görüntüler.

## Özellikler

- ✅ Açık pozisyonları listeler
- ✅ Her pozisyon için:
  - Coin adı
  - Pozisyon yönü (LONG/SHORT)
  - Miktar (adet)
  - Giriş fiyatı
  - Mevcut fiyat
  - Kaldıraç (leverage)
  - Likitasyon fiyatı
  - Gerçekleşmemiş kar/zarar (P&L)
- ✅ Yenileme özelliği
- ✅ Modern ve kullanıcı dostu arayüz

## Kurulum

### Gereksinimler

- Flutter SDK (3.8.1 veya üzeri)
- Android Studio veya VS Code
- Android SDK (Android uygulaması için)

### Adımlar

1. Projeyi klonlayın:
```bash
git clone <repo-url>
cd trumptakip
```

2. Bağımlılıkları yükleyin:
```bash
flutter pub get
```

3. Uygulamayı çalıştırın:
```bash
flutter run
```

## Kullanılan Teknolojiler

- **Flutter**: Mobil uygulama framework'ü
- **http**: API istekleri için
- **HyperLiquid API**: Pozisyon verilerini almak için

## API

Uygulama HyperLiquid API'sini kullanır:
- Endpoint: `https://api.hyperliquid.xyz/info`
- Wallet Adresi: `0xc2a30212a8ddac9e123944d6e29faddce994e5f2`

## Proje Yapısı

```
lib/
├── main.dart                      # Ana uygulama dosyası
├── models/
│   ├── position.dart              # Pozisyon veri modeli
│   └── trader_data.dart           # Trader veri modeli
├── services/
│   └── hyperdash_service.dart     # API servisi
└── screens/
    └── positions_screen.dart      # Ana ekran
```

## Ekran Görüntüleri

Uygulama şunları gösterir:
- Pozisyon listesi
- Her pozisyon için detaylı bilgiler
- Kar/zarar durumunu renkli olarak gösterim (yeşil: kar, kırmızı: zarar)
- LONG/SHORT pozisyonları farklı renklerde gösterim

## Geliştirme

Wallet adresini değiştirmek için `lib/screens/positions_screen.dart` dosyasındaki `walletAddress` değişkenini güncelleyin:

```dart
final String walletAddress = 'YENI_WALLET_ADRESI';
```

## Lisans

Bu proje özel kullanım içindir.
