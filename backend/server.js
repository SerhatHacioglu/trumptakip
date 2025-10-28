const express = require('express');
const cron = require('node-cron');
const TelegramBot = require('node-telegram-bot-api');
const axios = require('axios');
require('dotenv').config();

const app = express();
app.use(express.json());

// Telegram Bot başlat (polling kapalı - sadece mesaj göndermek için)
const bot = new TelegramBot(process.env.TELEGRAM_BOT_TOKEN, { polling: false });
const TELEGRAM_CHAT_ID = process.env.TELEGRAM_CHAT_ID;

// Telegram mesaj gönder
async function sendTelegramMessage(text) {
  try {
    await bot.sendMessage(TELEGRAM_CHAT_ID, text, { parse_mode: 'HTML' });
    console.log('Telegram mesajı gönderildi');
  } catch (error) {
    console.error('Telegram mesaj gönderme hatası:', error.message);
  }
}

let lastPositions = [];
let lastNotifiedPrice = {}; // Son bildirim gönderilen fiyat değerlerini sakla: {coin_side: markPrice}
let lastNotifiedSize = {}; // Son bildirim gönderilen pozisyon miktarlarını sakla: {coin_side: size}

const WALLET_ADDRESS = process.env.WALLET_ADDRESS || '0xc2a30212a8ddac9e123944d6e29faddce994e5f2';
const HYPERLIQUID_API = 'https://api.hyperliquid.xyz';

// Pozisyonları kontrol et
async function checkPositions() {
  try {
    console.log('Pozisyonlar kontrol ediliyor...', new Date().toISOString());
    
    // HyperLiquid API'den pozisyonları al
    const response = await axios.post(`${HYPERLIQUID_API}/info`, {
      type: 'clearinghouseState',
      user: WALLET_ADDRESS
    });
    
    if (!response.data || !response.data.assetPositions) {
      console.log('Pozisyon verisi bulunamadı');
      return;
    }
    
    // Mevcut fiyatları al
    const pricesResponse = await axios.post(`${HYPERLIQUID_API}/info`, {
      type: 'allMids'
    });
    
    const currentPrices = pricesResponse.data || {};
    
    // Pozisyonları işle
    const currentPositions = [];
    for (const posData of response.data.assetPositions) {
      if (posData.position && posData.position.szi && parseFloat(posData.position.szi) !== 0) {
        const pos = posData.position;
        const coin = pos.coin;
        const szi = parseFloat(pos.szi);
        const size = Math.abs(szi);
        const side = szi > 0 ? 'LONG' : 'SHORT';
        
        currentPositions.push({
          coin,
          side,
          size,
          entryPrice: parseFloat(pos.entryPx || 0),
          markPrice: parseFloat(currentPrices[coin] || 0),
          unrealizedPnl: parseFloat(pos.unrealizedPnl || 0),
          positionValue: parseFloat(pos.positionValue || 0),
          leverage: parseFloat(pos.leverage?.leverage || 1)
        });
      }
    }
    
    console.log(`${currentPositions.length} açık pozisyon bulundu`);
    
    // İlk çalıştırmada sadece kaydet
    if (lastPositions.length === 0) {
      lastPositions = currentPositions;
      
      // Bot başlatma mesajı
      await sendTelegramMessage(
        `🤖 <b>Bot Başlatıldı</b>\n\n` +
        `📊 Mevcut ${currentPositions.length} pozisyon izleniyor\n` +
        `💡 Değişiklikler bildirilecek`
      );
      
      // Tüm pozisyonların başlangıç durumunu bildir
      for (const pos of currentPositions) {
        const positionKey = `${pos.coin}_${pos.side}`;
        const isProfit = pos.unrealizedPnl >= 0;
        const emoji = isProfit ? '💚' : '❤️';
        const sideEmoji = pos.side === 'LONG' ? '📈' : '📉';
        
        await sendTelegramMessage(
          `${sideEmoji} <b>İZLENEN POZİSYON</b>\n\n` +
          `💰 <b>${pos.coin}</b> ${pos.side}\n` +
          `📊 Miktar: ${pos.size.toFixed(4)}\n` +
          `🎯 Giriş: $${formatNumber(pos.entryPrice)}\n` +
          `💵 Anlık Fiyat: $${formatNumber(pos.markPrice)}\n` +
          `${emoji} Mevcut P&L: ${isProfit ? '+' : '-'}$${formatNumber(pos.unrealizedPnl)}\n` +
          `⚡ Kaldıraç: ${pos.leverage.toFixed(1)}x`
        );
        
        // Başlangıç fiyatını ve miktarını kaydet
        lastNotifiedPrice[positionKey] = pos.markPrice;
        lastNotifiedSize[positionKey] = pos.size;
      }
      
      return;
    }
    
    // Değişiklikleri kontrol et
    await compareAndNotify(currentPositions);
    
    // Güncel pozisyonları kaydet
    lastPositions = currentPositions;
    
  } catch (error) {
    console.error('Pozisyon kontrolü hatası:', error.message);
  }
}

// Rakamları 3'lü formatta göster
function formatNumber(num) {
  return Math.abs(num).toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, '.');
}

// Pozisyon değişim eşiği (USD cinsinden)
const POSITION_CHANGE_THRESHOLD_USD = 1000000; // $1,000,000

// Pozisyonları karşılaştır ve bildirim gönder
async function compareAndNotify(currentPositions) {
  
  // 1. Yeni pozisyon açıldı mı?
  for (const newPos of currentPositions) {
    const exists = lastPositions.find(old => 
      old.coin === newPos.coin && old.side === newPos.side
    );
    
    if (!exists) {
      const emoji = newPos.side === 'LONG' ? '📈' : '📉';
      await sendTelegramMessage(
        `${emoji} <b>YENİ POZİSYON AÇILDI</b>\n\n` +
        `💰 <b>${newPos.coin}</b> ${newPos.side}\n` +
        `📊 Miktar: ${newPos.size.toFixed(4)}\n` +
        `🎯 Giriş: $${formatNumber(newPos.entryPrice)}\n` +
        `💵 Anlık Fiyat: $${formatNumber(newPos.markPrice)}\n` +
        `⚡ Kaldıraç: ${newPos.leverage.toFixed(1)}x`
      );
    }
  }
  
  // 2. Pozisyon kapandı mı?
  for (const oldPos of lastPositions) {
    const exists = currentPositions.find(newPos => 
      newPos.coin === oldPos.coin && newPos.side === oldPos.side
    );
    
    if (!exists) {
      const pnlEmoji = oldPos.unrealizedPnl >= 0 ? '✅' : '❌';
      const pnlSign = oldPos.unrealizedPnl >= 0 ? '+' : '-';
      await sendTelegramMessage(
        `🔚 <b>POZİSYON KAPATILDI</b>\n\n` +
        `💰 <b>${oldPos.coin}</b> ${oldPos.side}\n` +
        `${pnlEmoji} P&L: ${pnlSign}$${formatNumber(oldPos.unrealizedPnl)}\n` +
        `🎯 Giriş: $${formatNumber(oldPos.entryPrice)}\n` +
        `💵 Kapanış: $${formatNumber(oldPos.markPrice)}`
      );
    }
  }
  
  // 3. Pozisyona ekleme/azaltma yapıldı mı?
  for (const newPos of currentPositions) {
    const oldPos = lastPositions.find(old => 
      old.coin === newPos.coin && old.side === newPos.side
    );
    
    if (oldPos) {
      const positionKey = `${newPos.coin}_${newPos.side}`;
      const sizeDiff = newPos.size - oldPos.size;
      
      // Son bildirim gönderilen miktarı al (yoksa eski pozisyon miktarını kullan)
      const lastNotifiedSizeValue = lastNotifiedSize[positionKey] !== undefined 
        ? lastNotifiedSize[positionKey] 
        : oldPos.size;
      
      // Son bildirime göre değişimi hesapla
      const sizeChangeFromLast = newPos.size - lastNotifiedSizeValue;
      const sizeChangePercent = lastNotifiedSizeValue > 0 
        ? Math.abs((sizeChangeFromLast / lastNotifiedSizeValue) * 100)
        : 0;
      
      // Pozisyon değişiminin USD değerini hesapla
      const sizeChangeValueUSD = Math.abs(sizeChangeFromLast * newPos.markPrice);
      const positionValueUSD = newPos.size * newPos.markPrice;
      
      // ARTIŞ: Son bildirimden beri $150K+ artış varsa
      if (sizeChangeFromLast > 0.0001 && sizeChangeValueUSD >= POSITION_CHANGE_THRESHOLD_USD) {
        await sendTelegramMessage(
          `➕ <b>POZİSYONA EKLEME YAPILDI</b>\n\n` +
          `💰 <b>${newPos.coin}</b> ${newPos.side}\n` +
          `📊 Eklenen: +${sizeChangeFromLast.toFixed(4)} (+${sizeChangePercent.toFixed(1)}%)\n` +
          `💵 Eklenen Değer: $${formatNumber(sizeChangeValueUSD)}\n` +
          `📈 Yeni Toplam: ${newPos.size.toFixed(4)}\n` +
          `💎 Pozisyon Değeri: $${formatNumber(positionValueUSD)}\n` +
          `📍 Son Bildirim: ${lastNotifiedSizeValue.toFixed(4)}\n` +
          `🎯 Ortalama Giriş: $${formatNumber(newPos.entryPrice)}\n` +
          `💵 Anlık Fiyat: $${formatNumber(newPos.markPrice)}`
        );
        
        // Yeni miktarı kaydet
        lastNotifiedSize[positionKey] = newPos.size;
      }
      
      // AZALIŞ: Son bildirimden beri $150K+ azalış varsa
      if (sizeChangeFromLast < -0.0001 && sizeChangeValueUSD >= POSITION_CHANGE_THRESHOLD_USD) {
        await sendTelegramMessage(
          `➖ <b>POZİSYON KISMİ KAPATILDI</b>\n\n` +
          `💰 <b>${newPos.coin}</b> ${newPos.side}\n` +
          `📊 Kapatılan: ${sizeChangeFromLast.toFixed(4)} (-${sizeChangePercent.toFixed(1)}%)\n` +
          `💵 Kapatılan Değer: $${formatNumber(sizeChangeValueUSD)}\n` +
          `📉 Kalan: ${newPos.size.toFixed(4)}\n` +
          `💎 Kalan Değer: $${formatNumber(positionValueUSD)}\n` +
          `📍 Son Bildirim: ${lastNotifiedSizeValue.toFixed(4)}\n` +
          `💵 Kapanış Fiyatı: $${formatNumber(newPos.markPrice)}`
        );
        
        // Yeni miktarı kaydet
        lastNotifiedSize[positionKey] = newPos.size;
      }
      
      // İlk kez görüyorsak miktarı kaydet
      if (lastNotifiedSize[positionKey] === undefined) {
        lastNotifiedSize[positionKey] = newPos.size;
      }
      
      // 4. Fiyat %2'den fazla değişti mi? (Son gönderilen bildirime göre)
      // positionKey zaten yukarıda tanımlı
      const lastNotifiedValue = lastNotifiedPrice[positionKey];
      
      // İlk kez kontrol ediyorsak veya daha önce bildirim gönderilmişse
      if (lastNotifiedValue !== undefined && lastNotifiedValue > 0) {
        // Son bildirime göre fiyat değişimini hesapla
        const priceDiff = newPos.markPrice - lastNotifiedValue;
        const priceChangePercent = Math.abs((priceDiff / lastNotifiedValue) * 100);
        
        // Fiyat %2'den fazla değişti mi?
        if (priceChangePercent >= 2) {
          const isProfit = newPos.unrealizedPnl > 0;
          const isPriceIncrease = priceDiff > 0;
          
          // Başlık: Fiyat artışı mı azalışı mı?
          const changeDirection = isPriceIncrease ? '📈 YUKARI' : '📉 AŞAĞI';
          const emoji = isProfit ? '💚' : '❤️';
          
          await sendTelegramMessage(
            `${emoji} <b>ÖNEMLİ FİYAT HAREKETİ - ${changeDirection}</b>\n\n` +
            `💰 <b>${newPos.coin}</b> ${newPos.side}\n` +
            `💵 Yeni Fiyat: $${formatNumber(newPos.markPrice)}\n` +
            `${isPriceIncrease ? '⬆️' : '⬇️'} Değişim: ${isPriceIncrease ? '+' : ''}$${formatNumber(priceDiff)} (${isPriceIncrease ? '+' : '-'}${priceChangePercent.toFixed(2)}%)\n` +
            `📍 Son Bildirim Fiyatı: $${formatNumber(lastNotifiedValue)}\n` +
            `🎯 Giriş Fiyatı: $${formatNumber(newPos.entryPrice)}\n` +
            `${emoji} Güncel P&L: ${isProfit ? '+' : ''}$${formatNumber(newPos.unrealizedPnl)}`
          );
          
          // Yeni fiyatı kaydet
          lastNotifiedPrice[positionKey] = newPos.markPrice;
        }
      } else {
        // İlk kez görüyoruz, kaydet
        lastNotifiedPrice[positionKey] = newPos.markPrice;
      }
    }
  }
  
  // Kapanan pozisyonların fiyat ve miktar kayıtlarını temizle
  for (const key in lastNotifiedPrice) {
    const [coin, side] = key.split('_');
    const exists = currentPositions.find(pos => 
      pos.coin === coin && pos.side === side
    );
    if (!exists) {
      delete lastNotifiedPrice[key];
      delete lastNotifiedSize[key];
    }
  }
}

// Her 1 dakikada bir kontrol et (istediğiniz süreyi ayarlayabilirsiniz)
// '*/1 * * * *' = Her dakika
// '*/5 * * * *' = Her 5 dakika
// '*/10 * * * *' = Her 10 dakika
cron.schedule('*/1 * * * *', () => {
  checkPositions();
});

// Sunucu başladığında bir kez kontrol et
setTimeout(() => {
  checkPositions();
}, 5000);

// API endpoint'leri
app.get('/', (req, res) => {
  res.json({ 
    status: 'running',
    service: 'TrumpTakip Bot',
    timestamp: new Date().toISOString(),
    positionsTracked: lastPositions.length
  });
});

app.get('/api/health', (req, res) => {
  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    lastCheck: lastPositions.length > 0 ? 'OK' : 'Waiting...',
    positionsCount: lastPositions.length
  });
});

app.get('/api/positions', async (req, res) => {
  try {
    const response = await axios.post(`${HYPERLIQUID_API}/info`, {
      type: 'clearinghouseState',
      user: WALLET_ADDRESS
    });
    
    res.json(response.data);
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Manuel kontrol endpoint'i
app.post('/api/check-now', async (req, res) => {
  try {
    await checkPositions();
    res.json({ success: true, message: 'Kontrol başlatıldı' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Backend sunucu çalışıyor: http://localhost:${PORT}`);
  console.log('📱 Telegram Bot aktif');
  console.log('⏰ Pozisyon kontrolü her 1 dakikada bir yapılacak');
  console.log(`💼 İzlenen wallet: ${WALLET_ADDRESS}`);
});
