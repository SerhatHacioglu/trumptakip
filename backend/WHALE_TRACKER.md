# 🐋 Whale Tracker - Multi-Wallet Monitoring

## Özellikler

- ✅ Ana cüzdan takibi
- 🐋 Whale cüzdanları takibi (birden fazla)
- 📊 Büyük pozisyon algılama ($1M+)
- 💰 P&L değişim bildirimleri
- 📱 Telegram bildirimleri

## Whale Wallet Ekleme

`.env` dosyasına whale wallet'ları ekleyin:

```env
# Virgülle ayrılmış wallet adresleri
WHALE_WALLETS=0x1234567890abcdef...,0xabcdef1234567890...,0x9876543210fedcba...
```

## Bildirim Türleri

### Ana Cüzdan
- ✅ Tüm pozisyon değişiklikleri
- ✅ Detaylı P&L takibi
- ✅ İlk başlatmada tüm pozisyonlar

### Whale Cüzdanlar
- 🐋 Yeni büyük pozisyon açıldı ($1M+)
- 🐋 Büyük pozisyon kapandı ($100K+ P&L)
- 🐋 Pozisyon değişiklikleri
- 🐋 P&L değişimleri

## Bildirim Örnekleri

### Whale Bildirimi
```
🐋 [Whale #1]
📈 BÜYÜK YENİ POZİSYON AÇILDI

💰 BTC LONG
📊 Miktar: 25.0000
💎 Değer: $2.854.025,00
🎯 Giriş: $114.161
💵 Anlık Fiyat: $114.161
⚡ Kaldıraç: 10.0x
```

### Whale Pozisyon Kapandı
```
🐋 [Whale #2]
🔚 BÜYÜK POZİSYON KAPATILDI

💰 ETH SHORT
✅ P&L: +$125.450,00
🎯 Giriş: $3.850
💵 Kapanış: $3.800
```

## API Endpoints

- `GET /` - Bot durumu
- `GET /api/health` - Sağlık kontrolü
- `GET /api/positions` - Ana cüzdan pozisyonları
- `POST /api/check-now` - Manuel kontrol tetikle
- `GET /api/wallets` - İzlenen tüm cüzdanlar

## Kurulum

1. `.env` dosyasını kopyalayın:
```bash
cp .env.example .env
```

2. Whale wallet'ları ekleyin
3. `npm install && npm start`

## Render Deploy

`.env` değişkenlerini Render dashboard'da ayarlayın:
- `TELEGRAM_BOT_TOKEN`
- `TELEGRAM_CHAT_ID`
- `WALLET_ADDRESS`
- `WHALE_WALLETS` (virgülle ayrılmış)
