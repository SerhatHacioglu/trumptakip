# 🐋 Whale Adresleri Nasıl Bulunur?

## HyperLiquid'de Büyük Trader'ları Takip Etme

### 1. HyperLiquid Leaderboard
- [https://app.hyperliquid.xyz/leaderboard](https://app.hyperliquid.xyz/leaderboard)
- En çok kazanan, en çok işlem yapan trader'ları görebilirsiniz
- Her trader'ın yanında cüzdan adresi bulunur

### 2. HyperLiquid Stats
- [https://stats.hyperliquid.xyz/](https://stats.hyperliquid.xyz/)
- "Largest Users By USD Volume" tablosu
- "Largest User Deposits By USD Value" tablosu
- Bu tablolarda cüzdan adreslerini görebilirsiniz

### 3. HyperLiquid Explorer
- [https://app.hyperliquid.xyz/explorer](https://app.hyperliquid.xyz/explorer)
- Büyük pozisyonları ve likidasyonları görebilirsiniz
- Cüzdan adreslerine tıklayarak detaylı bilgi alabilirsiniz

### 4. Twitter/X ve Discord
- HyperLiquid topluluk hesapları
- Büyük trader'lar genellikle sosyal medyada paylaşım yapar
- Bazıları cüzdan adreslerini açıklar

## Whale Cüzdan Nasıl Eklenir?

### Adım 1: Whale Adresini Bulun
Yukarıdaki kaynaklardan birini kullanarak aktif bir whale trader adresi bulun.

### Adım 2: Adresi Doğrulayın
```bash
# Terminal'de test edin:
curl -X POST https://api.hyperliquid.xyz/info \
  -H "Content-Type: application/json" \
  -d '{"type":"clearinghouseState","user":"WHALE_ADRESI"}'

# Eğer assetPositions boş değilse, aktif bir adrestir
```

### Adım 3: Konfigürasyona Ekleyin
`lib/config/wallet_config.dart` dosyasını açın ve yeni whale ekleyin:

```dart
static final List<Wallet> wallets = [
  Wallet(
    address: '0xc2a30212a8ddac9e123944d6e29faddce994e5f2',
    name: 'Ana Cüzdan',
    isMain: true,
  ),
  Wallet(
    address: '0x...whale-adresi-buraya...',
    name: 'Whale #1', // İsterseniz trader'ın adını yazabilirsiniz
    isMain: false,
  ),
  // Daha fazla whale ekleyebilirsiniz
];
```

### Adım 4: Uygulamayı Yeniden Başlatın
```bash
flutter run
```

## Örnek Whale Kriterleri

**Büyük Whale Özellikleri:**
- 💰 Account Value: $500K+
- 📊 Pozisyon Sayısı: 5+
- 💎 Tek Pozisyon Değeri: $100K+
- 📈 Günlük Hacim: $1M+

## Whale Takip İpuçları

1. **Çeşitlendir**: 5-10 farklı whale takip edin
2. **Aktif Olanları Seç**: Son 24 saatte işlem yapmış olanlara öncelik verin
3. **Farklı Stratejiler**: Bazı whale'ler long, bazıları short odaklıdır
4. **Risk Yönetimi**: Whale'leri kopyalamayın, sadece trend için kullanın
5. **Düzenli Güncelle**: Aktif olmayan adresleri kaldırın, yenilerini ekleyin

## API ile Whale Bulma (İleri Seviye)

```javascript
// Node.js ile otomatik whale bulma
const axios = require('axios');

async function findWhales() {
  // HyperLiquid API'den leaderboard çek
  // $1M+ pozisyonu olanları filtrele
  // Otomatik olarak config'e ekle
}
```

## Notlar

- ⚠️ Whale adresleri halka açık blockchain verileridir
- ⚠️ Privacy için hiçbir whale'i doxx etmeyin
- ⚠️ DYOR (Do Your Own Research) - Her whale'in stratejisi farklıdır
- ⚠️ Whale takibi tavsiye değil, sadece piyasa analizi içindir

## Yararlı Linkler

- [HyperLiquid Docs](https://hyperliquid.gitbook.io/hyperliquid-docs/)
- [HyperLiquid API](https://hyperliquid.gitbook.io/hyperliquid-docs/for-developers/api)
- [HyperLiquid Discord](https://discord.gg/hyperliquid)
- [HyperLiquid Twitter](https://twitter.com/HyperliquidX)
