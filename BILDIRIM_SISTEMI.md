# 📢 Telegram Bildirim Sistemi

## Bildirim Türle### 5. ➕ Pozisyona Ekleme### 5. ➕ Pozisyona Ekleme
**Önemli:** **$3,000,000 veya daha fazla** değişim olduğunda bildirim gelir:
```
➕ POZİSYONA EKLEME YAPILDI

💰 BTC LONG
📊 Eklenen: +16.0000 (+32.0%)
💵 Eklenen D- 🔄 Bot her yeniden başlatıldığında tüm pozisyonlar için "İZLENEN POZİSYON" bildirimi gider
- 💾 Fiyat ve miktar geçmişi bellekte tutulur (bot yeniden başlatılınca sıfırlanır)
- ⏰ 1 dakikalık kontrol döngüsü optimal (API rate limit için)
- 📊 P&L bilgisi her bildirimde gösterilir ama tetikleyici değildir
- 💵 **Sabit USD Eşiği**: $3M değişim = önemli pozisyon hareketi (küçük-büyük tüm pozisyonlar için adil)
- 💹 **Fiyat Değişimi**: %2+ değişim = anlamlı piyasa hareketi
- 📍 **Son Bildirim Referansı**: Her bildirimde son gönderilen değer gösterilir (trend takibi)1,088,000.00
📈 Yeni Toplam: 66.0000
💎 Pozisyon Değeri: $4,488,000.00
📍 Son Bildirim: 50.0000
🎯 Ortalama Giriş: $67,500.00
💵 Anlık Fiyat: $68,000.00
```

### 6. ➖ Kısmi Kapatma
**Önemli:** **$3,000,000 veya daha fazla** değişim olduğunda bildirim gelir:,000,000 veya daha fazla** değişim olduğunda bildirim gelir:
```
➕ POZİSYONA EKLEME YAPILDI

💰 BTC LONG
📊 Eklenen: +15.0000 (+3.0%)
💵 Eklenen Değer: $1,020,000.00
📈 Yeni Toplam: 515.0000
💎 Pozisyon Değeri: $35,020,000.00
📍 Son Bildirim: 500.0000
🎯 Ortalama Giriş: $67,500.00
💵 Anlık Fiyat: $68,000.00
```

### 6. ➖ Kısmi Kapatma
**Önemli:** **$3,000,000 veya daha fazla** değişim olduğunda bildirim gelir:
```
➖ POZİSYON KISMİ KAPATILDI

💰 ETH SHORT
📊 Kapatılan: -30.0000 (-6.0%)
💵 Kapatılan Değer: $1,050,000.00
📉 Kalan: 470.0000
💎 Kalan Değer: $16,450,000.00
📍 Son Bildirim: 500.0000
💵 Kapanış Fiyatı: $35,000.00
```Bot Başlatma
Bot ilk çalıştığında gönderilir:
```
🤖 Bot Başlatıldı

📊 Mevcut X pozisyon izleniyor
💡 Değişiklikler bildirilecek
```

### 2. 📈/📉 İzlenen Pozisyon (İlk Başlangıç)
Her pozisyon için ayrı ayrı gönderilir:
```
📈 İZLENEN POZİSYON

💰 BTC LONG
📊 Miktar: 0.5000
🎯 Giriş: $67,500.00
💵 Anlık Fiyat: $68,200.00
💚 Mevcut P&L: +$350.00
⚡ Kaldıraç: 5.0x
```

### 3. 📈/📉 Yeni Pozisyon
Yeni bir pozisyon açıldığında:
```
📈 YENİ POZİSYON AÇILDI

💰 ETH LONG
📊 Miktar: 5.0000
🎯 Giriş: $2,500.00
💵 Anlık Fiyat: $2,500.00
⚡ Kaldıraç: 10.0x
```

### 4. 🔚 Pozisyon Kapatıldı
Pozisyon tamamen kapatıldığında:
```
🔚 POZİSYON KAPATILDI

💰 BTC LONG
✅ P&L: +$1,250.00
🎯 Giriş: $67,500.00
💵 Kapanış: $70,000.00
```

### 5. ➕ Pozisyona Ekleme
**Önemli:** **$3,000,000 veya daha fazla** değişim olduğunda bildirim gelir:
```
➕ POZİSYONA EKLEME YAPILDI

💰 BTC LONG
📊 Eklenen: +45.0000 (+90.0%)
� Eklenen Değer: $3,060,000.00
�📈 Yeni Toplam: 95.0000
💎 Pozisyon Değeri: $6,460,000.00
📍 Son Bildirim: 50.0000
🎯 Ortalama Giriş: $67,500.00
💵 Anlık Fiyat: $68,000.00
```

### 6. ➖ Kısmi Kapatma
**Önemli:** **$3,000,000 veya daha fazla** değişim olduğunda bildirim gelir:
```
➖ POZİSYON KISMİ KAPATILDI

💰 ETH SHORT
📊 Kapatılan: -30.0000 (-60.0%)
💵 Kapatılan Değer: $1,050,000.00
📉 Kalan: 20.0000
💎 Kalan Değer: $700,000.00
📍 Son Bildirim: 50.0000
💵 Kapanış Fiyatı: $35,000.00
```

### 7. 💚/❤️ Önemli Fiyat Hareketi (YENİ!)
**Fiyat %2 veya daha fazla değiştiğinde:**
```
💚 ÖNEMLİ FİYAT HAREKETİ - 📈 YUKARI

💰 BTC LONG
💵 Yeni Fiyat: $69,360.00
⬆️ Değişim: +$1,360.00 (+2.00%)
📍 Son Bildirim Fiyatı: $68,000.00
🎯 Giriş Fiyatı: $67,500.00
💚 Güncel P&L: +$930.00
```

veya

```
❤️ ÖNEMLİ FİYAT HAREKETİ - 📉 AŞAĞI

💰 ETH SHORT
💵 Yeni Fiyat: $2,450.00
⬇️ Değişim: -$50.00 (-2.00%)
📍 Son Bildirim Fiyatı: $2,500.00
🎯 Giriş Fiyatı: $2,600.00
💚 Güncel P&L: +$750.00
```

## Bildirim Mantığı

### Fiyat Değişimi Bildirimi
- ✅ **Tetikleyici**: Son bildirim gönderilen fiyattan **%2 veya daha fazla** değişim
- ✅ **Kontrol Sıklığı**: Her 1 dakikada bir
- ✅ **Bildirimde Gösterilen**:
  - Yeni fiyat
  - Fiyat değişimi ($ ve %)
  - Son bildirim fiyatı
  - Giriş fiyatı
  - **Güncel P&L bilgisi** (ek bilgi olarak)

### Pozisyon Ekleme/Azaltma Bildirimi
- ✅ **Tetikleyici**: Son bildirim gönderilen miktardan **$3,000,000 veya daha fazla USD değişimi**
- ✅ **Sabit Eşik**: Tüm pozisyonlar için $3M (yüzde bazlı değil)
- ✅ **Kontrol Sıklığı**: Her 1 dakikada bir
- ✅ **Bildirimde Gösterilen**:
  - Eklenen/Kapatılan miktar
  - Değişim yüzdesi
  - **Eklenen/Kapatılan değer (USD)**
  - Yeni toplam/kalan miktar
  - Pozisyon değeri (USD)
  - Son bildirim miktarı
  - Anlık fiyat

### Diğer Bildirimler
- **Yeni Pozisyon**: Anında
- **Pozisyon Kapatma**: Anında

## Emoji Rehberi

| Emoji | Anlamı |
|-------|--------|
| 📈 | LONG pozisyon / Fiyat artışı |
| 📉 | SHORT pozisyon / Fiyat düşüşü |
| 💚 | Karda olan pozisyon |
| ❤️ | Zararda olan pozisyon |
| 🎯 | Giriş fiyatı |
| 💵 | Anlık/Yeni fiyat |
| 📍 | Son bildirim referansı |
| ⬆️ | Artış |
| ⬇️ | Azalış |
| ✅ | Başarılı/Karda kapatma |
| ❌ | Zararda kapatma |
| ➕ | Ekleme |
| ➖ | Çıkarma/Kısmi kapatma |
| 🔚 | Kapatma |
| 🤖 | Bot durumu |
| ⚡ | Kaldıraç |

## Avantajlar

### Eski Sistem
- ❌ **Fiyat**: P&L tabanlı, çok fazla bildirim
- ❌ **Pozisyon Değişimi**: Yüzde bazlı (%10), küçük pozisyonlarda hassas, büyüklerde hassasiyetsiz
- ❌ Noise fazlaydı

### Yeni Sistem
- ✅ **Fiyat**: %2+ değişimde bildirim (anlamlı hareketler)
- ✅ **Pozisyon Değişimi**: Sabit $3M eşik (küçük-büyük tüm pozisyonlar için adil)
- ✅ P&L bilgisi hala gösteriliyor (ek bilgi)
- ✅ Son bildirime göre karşılaştırma (kademeli değişimler birleştirilir)
- ✅ **Büyüklükten bağımsız hassasiyet**
- ✅ Gereksiz küçük değişiklikler filtrelenir
- ✅ Önemli değişiklikler kaçırılmaz

## Ayarlar

### Fiyat Değişim Eşiği
Varsayılan: **%2**

Değiştirmek için `server.js` dosyasında:
```javascript
// Satır 240 civarı
if (priceChangePercent >= 2) {  // 2'yi değiştirin (örn: 1, 3, 5)
```

### Pozisyon Değişim Eşiği (USD)
Varsayılan: **$3,000,000**

Değiştirmek için `server.js` dosyasında:
```javascript
// Satır 131 civarı
const POSITION_CHANGE_THRESHOLD_USD = 3000000; // İstediğiniz değeri yazın
```

### Kontrol Sıklığı
Varsayılan: **1 dakika**

Değiştirmek için `server.js` dosyasında:
```javascript
// Satır 280 civarı
cron.schedule('* * * * *', async () => {  // Her dakika
```

Örnekler:
- `'*/5 * * * *'` - Her 5 dakika
- `'*/15 * * * *'` - Her 15 dakika
- `'*/30 * * * *'` - Her 30 dakika

## Test

Backend'i test etmek için:
```bash
cd backend
node server.js
```

İlk çalıştırmada:
1. Bot başlatma mesajı gelir
2. Her pozisyon için "İZLENEN POZİSYON" mesajı gelir
3. Fiyatlar kaydedilir

Sonraki dakikalarda:
- Fiyat %2+ değişirse → Bildirim gelir
- Pozisyon açılır/kapanır → Anında bildirim

## Notlar

- 🔄 Bot her yeniden başlatıldığında tüm pozisyonlar için "İZLENEN POZİSYON" bildirimi gider
- 💾 Fiyat ve miktar geçmişi bellekte tutulur (bot yeniden başlatılınca sıfırlanır)
- ⏰ 1 dakikalık kontrol döngüsü optimal (API rate limit için)
- 📊 P&L bilgisi her bildirimde gösterilir ama tetikleyici değildir
- � **Sabit USD Eşiği**: $150K değişim = önemli pozisyon hareketi (küçük-büyük tüm pozisyonlar için adil)
- 💹 **Fiyat Değişimi**: %2+ değişim = anlamlı piyasa hareketi
- 📍 **Son Bildirim Referansı**: Her bildirimde son gönderilen değer gösterilir (trend takibi)

## Senaryo Örnekleri

### Örnek 1: Küçük Pozisyon ($50K)
1. **İlk durum**: 5 BTC × $10K = $50K
2. **Ekleme**: +5 BTC = $50K değer → Bildirim yok ($3M altı)
3. **Büyük ekleme**: +310 BTC = $3.1M değer → **BİLDİRİM GELİR** ✅

### Örnek 2: Orta Pozisyon ($500K)
1. **İlk durum**: 50 BTC × $10K = $500K
2. **Küçük azaltma**: -50 BTC = $500K değer → Bildirim yok
3. **Orta azaltma**: -80 BTC = $800K değer → Bildirim yok (toplam hala $3M altı)
4. **Büyük azaltma**: -310 BTC = $3.1M değer → **BİLDİRİM GELİR** ✅

### Örnek 3: Büyük Pozisyon ($5M)
1. **İlk durum**: 500 BTC × $10K = $5M
2. **Ekleme**: +50 BTC = $500K değer → Bildirim yok
3. **Daha fazla ekleme**: +310 BTC = $3.1M değer → **BİLDİRİM GELİR** ✅ (toplam $3.1M)

### Örnek 4: Fiyat Hareketi
1. **İlk durum**: BTC $68,000
2. **1 dk sonra**: $68,500 → %0.73 artış, bildirim yok
3. **2 dk sonra**: $69,400 → %2.05 artış → **BİLDİRİM GELİR** ($68k → $69.4k)

## USD Eşik Mantığı

### Neden $3M?
- ✅ **Küçük pozisyonlar** ($50K-500K): Gereksiz bildirim engellenir
- ✅ **Orta pozisyonlar** ($3M-10M): Önemli değişiklikler yakalanır  
- ✅ **Büyük pozisyonlar** ($10M+): Hassasiyet korunur
- ✅ **Adil**: Pozisyon büyüklüğüne bağlı değil, sabit değer

### Yüzde vs USD Karşılaştırması

**Senaryo: $5M pozisyon, +$3M ekleme**
- Yüzde: +%60 → Bildirim ✅
- USD: +$3M → Bildirim ✅

**Senaryo: $10M pozisyon, +$3M ekleme**  
- Yüzde: +%10 → Eski %3 eşikte bildirim ✅
- USD: +$3M → Bildirim ✅ (Tutarlı!)

**Senaryo: $500K pozisyon, +$2M ekleme**
- Yüzde: +%60 → Eski sistemde bildirim ✅ (Gürültü!)
- USD: +$100K → Bildirim yok ✅ (Doğru, küçük pozisyon!)

**Senaryo: $50M pozisyon, +$2M ekleme**
- Yüzde: +%1 → Eski %3 eşikte bildirim yok ❌
- USD: +$2M → Bildirim yok ✅ (Doğru, $3M altı!)
