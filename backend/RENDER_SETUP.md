# 🚀 Render Deployment Kurulumu

## 1️⃣ PostgreSQL Veritabanı Oluştur

1. Render Dashboard'a git: https://dashboard.render.com
2. **"New +"** → **"PostgreSQL"** seç
3. Ayarlar:
   - **Name:** `trumptakip-db`
   - **Database:** `trumptakip`
   - **User:** `trumptakip_user`
   - **Region:** `Frankfurt (EU Central)`
   - **Plan:** **Free** (512MB RAM, 1GB Disk)
4. **Create Database** tıkla
5. Oluşturulduktan sonra **Internal Database URL**'yi kopyala

## 2️⃣ Web Service Oluştur

1. **"New +"** → **"Web Service"** seç
2. GitHub repo'nuzu bağla: `SerhatHacioglu/trumptakip`
3. Ayarlar:
   - **Name:** `trumptakip-bot`
   - **Region:** `Frankfurt (EU Central)`
   - **Branch:** `main`
   - **Root Directory:** `backend`
   - **Runtime:** `Node`
   - **Build Command:** `npm install`
   - **Start Command:** `node server.js`
   - **Plan:** **Free**

## 3️⃣ Environment Variables Ekle

Web Service ayarlarında **Environment** → **Add Environment Variable**:

```bash
DATABASE_URL=<Internal Database URL buraya yapıştır>
TELEGRAM_BOT_TOKEN=<Telegram bot token>
TELEGRAM_CHAT_ID=<Telegram chat ID>
NODE_ENV=production
```

## 4️⃣ Deploy Et

- **Create Web Service** tıkla
- Otomatik deploy başlayacak (~2-3 dakika)

## 5️⃣ Test Et

Deploy tamamlandıktan sonra:
```bash
https://trumptakip-bot.onrender.com/
```

Çıktı:
```json
{
  "status": "running",
  "service": "TrumpTakip Bot",
  "walletsTracked": 3,
  "totalPositions": 0
}
```

## ✅ Tamamlandı!

- 📦 PostgreSQL veritabanı çalışıyor
- 🤖 Backend servisi çalışıyor
- 🔄 Cüzdanlar kalıcı olarak veritabanında tutuluyor
- 📱 Telegram bildirimleri aktif

## 📝 Notlar

- **Free tier:** 750 saat/ay (bir uygulama için yeterli)
- **Auto-sleep:** 15 dakika inaktif kalırsa uyur
- **Cold start:** İlk istekte 30-60 saniye gecikme
- **Database:** Free tier - 1GB disk, 90 gün inaktif kalırsa silinir
