# Backend Wallet Sync API

## 🔄 Dinamik Cüzdan Senkronizasyonu

Backend artık frontend'den gelen cüzdan listesini dinamik olarak takip ediyor.

### API Endpoints

#### 1. Wallet Listesini Senkronize Et
```http
POST /api/wallets/sync
Content-Type: application/json

{
  "wallets": [
    {
      "id": "wallet_uuid_1",
      "name": "Ana Cüzdan",
      "address": "0x...",
      "color": "ff2196f3"
    },
    {
      "id": "wallet_uuid_2",
      "name": "Trading Wallet",
      "address": "0x...",
      "color": "ff9c27b0"
    }
  ]
}
```

**Response:**
```json
{
  "success": true,
  "message": "2 cüzdan senkronize edildi",
  "trackedWallets": ["wallet_wallet_uuid_1", "wallet_wallet_uuid_2"]
}
```

#### 2. Aktif Wallet Listesini Getir
```http
GET /api/wallets
```

**Response:**
```json
{
  "wallets": [
    {
      "key": "wallet_wallet_uuid_1",
      "address": "0x...",
      "name": "Ana Cüzdan",
      "color": "ff2196f3"
    }
  ]
}
```

## 🚀 Nasıl Çalışır?

1. **Frontend'de cüzdan ekleme/silme/güncelleme** yapıldığında:
   - SharedPreferences'a kaydedilir
   - `WalletSyncService.syncWallets()` çağrılır
   - Backend'e POST isteği gönderilir

2. **Backend tarafında**:
   - `trackedWallets` global değişkeni güncellenir
   - `lastPositions`, `lastNotifiedPrice`, `lastNotifiedSize` haritaları yeniden oluşturulur
   - Cron job tüm takip edilen cüzdanları kontrol eder

3. **Pozisyon değişikliklerinde**:
   - Backend her cüzdan için Telegram bildirimi gönderir
   - Cüzdan adı ve rengi bildirimde gösterilir

## 🔧 Kurulum

1. Backend'i başlat:
```bash
cd backend
npm install
npm start
```

2. Frontend'de servis otomatik çalışır:
```dart
// Wallet eklendiğinde
await Wallet.addWallet(newWallet);
await _loadWallets(); // Otomatik senkronize eder

// Wallet silindiğinde
await Wallet.deleteWallet(wallet.id);
await _loadWallets(); // Otomatik senkronize eder
```

## 📝 Notlar

- Backend erişilemez olsa bile uygulama çalışmaya devam eder
- Senkronizasyon 10 saniye timeout ile korunur
- Varsayılan olarak `localhost:3000` kullanılır
- Production için `WalletSyncService.baseUrl` değiştirin

## 🔐 Güvenlik

- Backend API'yi production'da authentication ile koruyun
- Environment variables kullanın
- CORS ayarlarını yapılandırın
