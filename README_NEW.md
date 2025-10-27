# Trump Takip - HyperLiquid Pozisyon Takip Uygulaması 📊

Flutter mobil uygulama + Node.js backend ile **tamamen ücretsiz** pozisyon takip sistemi!

## 🎯 Özellikler

### 📱 Flutter Uygulaması
- Modern ve kullanıcı dostu arayüz
- Gerçek zamanlı pozisyon takibi
- Detaylı P&L görüntüleme
- Pull-to-refresh
- Kompakt ve okunabilir kartlar

### 🤖 Backend Sunucu (Telegram Bot)
- **%100 Ücretsiz** Telegram bildirimleri
- Uygulama kapalıyken bile çalışır
- Her 1 dakikada kontrol (ayarlanabilir)
- 5 farklı bildirim türü:
  - 📈 Yeni pozisyon açıldığında
  - 📉 Pozisyon kapandığında
  - ➕ Pozisyona ekleme yapıldığında
  - ➖ Kısmi kapatma yapıldığında
  - 💰 P&L önemli değiştiğinde

## 🚀 Hızlı Başlangıç

### 1. Flutter Uygulaması

```bash
# Bağımlılıkları yükle
flutter pub get

# Uygulamayı çalıştır
flutter run
```

### 2. Backend Sunucu (Telegram Bot)

#### Telegram Bot Oluştur
1. [@BotFather](https://t.me/botfather)'ı aç
2. `/newbot` komutu ile bot oluştur
3. Bot token'ını kaydet

#### Chat ID'ni Öğren
1. [@userinfobot](https://t.me/userinfobot)'u aç
2. Chat ID'ni kaydet

#### Sunucuyu Başlat
```bash
cd backend
npm install

# .env dosyasını düzenle
# TELEGRAM_BOT_TOKEN ve TELEGRAM_CHAT_ID ekle

npm start
```

Detaylı kurulum için: [backend/README.md](backend/README.md)

## 📦 Proje Yapısı

```
trumptakip/
├── lib/
│   ├── models/              # Veri modelleri
│   │   ├── position.dart
│   │   └── trader_data.dart
│   ├── services/            # API ve servisler
│   │   ├── hyperdash_service.dart
│   │   ├── notification_service.dart
│   │   ├── background_service.dart
│   │   └── firebase_service.dart
│   ├── screens/             # UI ekranları
│   │   └── positions_screen.dart
│   └── main.dart            # Ana dosya
├── backend/                 # Node.js backend
│   ├── server.js           # Ana sunucu dosyası
│   ├── package.json
│   ├── .env               # Konfigürasyon
│   └── README.md          # Backend dökümanı
└── pubspec.yaml
```

## 🌐 Ücretsiz Deployment

Backend'i ücretsiz hostlamak için:

1. **Render.com** (Önerilen)
   - 750 saat/ay ücretsiz
   - Kolay kurulum
   - Otomatik deploy

2. **Railway.app**
   - $5 ücretsiz kredi
   - Basit arayüz

3. **Fly.io**
   - 3 ücretsiz VM
   - CLI ile deploy

Detaylar için: [backend/README.md](backend/README.md)

## 🔧 Konfigürasyon

### Wallet Adresi Değiştirme

**Flutter:**
`lib/screens/positions_screen.dart` dosyasında:
```dart
final String walletAddress = 'YOUR_WALLET_ADDRESS';
```

**Backend:**
`.env` dosyasında:
```env
WALLET_ADDRESS=YOUR_WALLET_ADDRESS
```

### Bildirim Sıklığı

`backend/server.js` dosyasında:
```javascript
// Her 1 dakika
cron.schedule('*/1 * * * *', ...);

// Her 5 dakika
cron.schedule('*/5 * * * *', ...);
```

## 📸 Ekran Görüntüleri

- Özet kartı ile toplam pozisyon ve P&L
- Detaylı pozisyon kartları
- LONG/SHORT göstergeleri
- Kar/zarar renklendirmesi
- Modern gradient tasarım

## 🛠️ Teknolojiler

### Frontend
- Flutter 3.8+
- Material Design 3
- HTTP client
- Local notifications
- Work Manager

### Backend
- Node.js
- Express.js
- node-cron (zamanlama)
- node-telegram-bot-api
- Axios (HTTP client)

## 💡 İpuçları

1. **Bildirim Sıklığı**: Pil tasarrufu için 5-10 dakika önerilir
2. **Telegram Bot**: İlk çalıştırmada bota `/start` göndermeyi unutmayın
3. **Testing**: `npm start` sonrası `/api/check-now` ile manuel test yapın
4. **Multiple Wallets**: Kod kolayca genişletilebilir

## 🆘 Sorun Giderme

**Bot mesaj göndermiyor?**
- Bot token doğru mu?
- Bota `/start` gönderildi mi?
- Chat ID doğru mu?

**Pozisyonlar görünmüyor?**
- Wallet adresi doğru mu?
- İnternet bağlantısı var mı?
- HyperLiquid API erişilebilir mi?

## 📄 Lisans

Bu proje özel kullanım içindir.

## 🙏 Katkıda Bulunma

Pull request'ler memnuniyetle karşılanır!

---

**Not:** Bu proje tamamen ücretsiz servisleri kullanır:
- Telegram Bot API (Ücretsiz)
- HyperLiquid Public API (Ücretsiz)
- Render.com Free Tier (750 saat/ay)

Herhangi bir ödeme bilgisi gerekmez! 🎉
