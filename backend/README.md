# Backend Sunucu - Telegram Bot 📱

**%100 ÜCRETSİZ** pozisyon takip sistemi! Telegram Bot ile bildirimler.

## ✨ Özellikler

- ✅ Ücretsiz Telegram bildirimleri
- ✅ Her 1 dakikada bir kontrol (ayarlanabilir)
- ✅ Yeni pozisyon bildirimleri
- ✅ Pozisyon kapatma bildirimleri
- ✅ Pozisyona ekleme bildirimleri (%5+ değişim)
- ✅ Kısmi kapatma bildirimleri (%5+ değişim)
- ✅ P&L değişim bildirimleri (%10+ değişim)

## 🚀 Kurulum

### 1. Telegram Bot Oluştur

1. Telegram'da [@BotFather](https://t.me/botfather)'ı aç
2. `/newbot` komutunu gönder
3. Bot ismi ve kullanıcı adı belirle
4. Bot token'ını kaydet (örn: `123456:ABC-DEF1234ghIkl-zyx57W2v1u123ew11`)

### 2. Telegram Chat ID'ni Öğren

1. [@userinfobot](https://t.me/userinfobot)'u aç
2. `/start` komutunu gönder
3. Chat ID'ni kaydet (örn: `123456789`)

### 3. Projeyi Kur

```bash
cd backend
npm install
```

### 4. `.env` Dosyasını Düzenle

```env
PORT=3000
TELEGRAM_BOT_TOKEN=buraya_bot_tokeninizi_yapiştirin
TELEGRAM_CHAT_ID=buraya_chat_id_nizi_yapiştirin
WALLET_ADDRESS=0xc2a30212a8ddac9e123944d6e29faddce994e5f2
```

### 5. Sunucuyu Başlat

```bash
npm start
```

veya geliştirme modu için:

```bash
npm run dev
```

## 📱 Bildirim Örnekleri

**Yeni Pozisyon:**
```
📈 YENİ POZİSYON AÇILDI

💰 BTC LONG
📊 Miktar: 0.0500
💵 Giriş: $95000.00
⚡ Kaldıraç: 5.0x
```

**Pozisyona Ekleme:**
```
➕ POZİSYONA EKLEME YAPILDI

💰 BTC LONG
📊 Eklenen: +0.0250
📈 Yeni Toplam: 0.0750
💵 Ortalama Giriş: $94500.00
```

**Pozisyon Kapatma:**
```
🔚 POZİSYON KAPATILDI

💰 BTC LONG
✅ P&L: $1250.50
```

## ⚙️ Ayarlar

### Kontrol Sıklığı

`server.js` dosyasında cron ayarını değiştirebilirsiniz:

```javascript
// Her 1 dakika
cron.schedule('*/1 * * * *', () => {
  checkPositions();
});

// Her 5 dakika
cron.schedule('*/5 * * * *', () => {
  checkPositions();
});

// Her 10 dakika
cron.schedule('*/10 * * * *', () => {
  checkPositions();
});
```

### Duyarlılık Ayarları

`compareAndNotify` fonksiyonunda eşik değerlerini değiştirebilirsiniz:

```javascript
// Pozisyon ekleme/azaltma için (varsayılan %5)
if (sizeChangePercent > 5) { ... }

// P&L değişimi için (varsayılan %10)
if (pnlChange > 10) { ... }
```

## 🌐 Ücretsiz Deployment

### 1. Render.com (ÖNERİLEN - ÜCRETSİZ)

1. [Render.com](https://render.com)'a git
2. "New +" → "Web Service"
3. GitHub repo'nuzu bağla
4. Build Command: `cd backend && npm install`
5. Start Command: `cd backend && node server.js`
6. Environment Variables'ı ekle:
   - `TELEGRAM_BOT_TOKEN`
   - `TELEGRAM_CHAT_ID`
   - `WALLET_ADDRESS`
7. Deploy!

### 2. Railway.app (ÜCRETSİZ)

1. [Railway.app](https://railway.app)'e git
2. "New Project" → "Deploy from GitHub"
3. Repo'yu seç
4. Environment Variables'ı ekle
5. Deploy!

### 3. Fly.io (ÜCRETSİZ)

```bash
flyctl launch
flyctl secrets set TELEGRAM_BOT_TOKEN=your_token
flyctl secrets set TELEGRAM_CHAT_ID=your_chat_id
flyctl deploy
```

### 4. Kendi Bilgisayarında (24/7 Çalışırsa)

PM2 ile arka planda çalıştır:

```bash
npm install -g pm2
pm2 start server.js --name trump-takip
pm2 startup
pm2 save
```

## 🧪 Test

Sunucu çalıştıktan sonra:

```bash
# Sağlık kontrolü
curl http://localhost:3000/api/health

# Manuel kontrol tetikle
curl -X POST http://localhost:3000/api/check-now
```

## 🔧 Sorun Giderme

**Bot mesaj göndermiyor:**
- Bot token'ı doğru mu kontrol et
- Bota `/start` komutu gönderin
- Chat ID'nin doğru olduğundan emin olun

**Pozisyonlar bulunmuyor:**
- Wallet adresi doğru mu kontrol et
- HyperLiquid API erişilebilir mi test et

## 💡 İpuçları

- İlk çalıştırmada mevcut pozisyonları kaydet, değişiklik bildirmez
- Her 1 dakika yerine 5-10 dakika yaparak daha az bildirim alabilirsiniz
- Birden fazla wallet için kodu genişletebilirsiniz

## 📊 API Endpoints

- `GET /api/health` - Sunucu durumu
- `GET /api/positions` - Mevcut pozisyonlar
- `POST /api/check-now` - Manuel kontrol

---

**NOT:** Bu tamamen ücretsizdir! Telegram Bot API hiçbir ücret almaz.
