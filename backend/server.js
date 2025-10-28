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
      await sendTelegramMessage(
        `🤖 <b>Bot Başlatıldı</b>\n\n` +
        `📊 Mevcut ${currentPositions.length} pozisyon izleniyor\n` +
        `💡 Değişiklikler bildirilecek`
      );
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

// Pozisyonları karşılaştır ve bildirim gönder
async function compareAndNotify(currentPositions) {
  // Rakamları 3'lü formatta göster
  const formatNumber = (num) => {
    return Math.abs(num).toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, '.');
  };
  
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
      const sizeDiff = newPos.size - oldPos.size;
      
      // Herhangi bir artış varsa (minimum 0.0001 fark)
      if (sizeDiff > 0.0001) {
        const sizeChangePercent = (sizeDiff / oldPos.size) * 100;
        await sendTelegramMessage(
          `➕ <b>POZİSYONA EKLEME YAPILDI</b>\n\n` +
          `💰 <b>${newPos.coin}</b> ${newPos.side}\n` +
          `📊 Eklenen: +${sizeDiff.toFixed(4)} (+${sizeChangePercent.toFixed(1)}%)\n` +
          `📈 Yeni Toplam: ${newPos.size.toFixed(4)}\n` +
          `🎯 Ortalama Giriş: $${formatNumber(newPos.entryPrice)}\n` +
          `💵 Anlık Fiyat: $${formatNumber(newPos.markPrice)}`
        );
      }
      
      // Herhangi bir azalış varsa (kısmi kapatma, minimum 0.0001 fark)
      if (sizeDiff < -0.0001) {
        const sizeChangePercent = (Math.abs(sizeDiff) / oldPos.size) * 100;
        await sendTelegramMessage(
          `➖ <b>POZİSYON KISMİ KAPATILDI</b>\n\n` +
          `💰 <b>${newPos.coin}</b> ${newPos.side}\n` +
          `📊 Kapatılan: ${sizeDiff.toFixed(4)} (-${sizeChangePercent.toFixed(1)}%)\n` +
          `📉 Kalan: ${newPos.size.toFixed(4)}\n` +
          `💵 Kapanış Fiyatı: $${formatNumber(newPos.markPrice)}`
        );
      }
      
      // 4. P&L %10'dan fazla değişti mi?
      if (Math.abs(oldPos.unrealizedPnl) > 100) {
        const pnlDiff = newPos.unrealizedPnl - oldPos.unrealizedPnl;
        const pnlChange = Math.abs((pnlDiff / Math.abs(oldPos.unrealizedPnl)) * 100);
        
        if (pnlChange > 10) {
          const isProfit = newPos.unrealizedPnl > 0;
          const isIncrease = pnlDiff > 0;
          
          // Başlık: Artış mı azalış mı?
          const changeDirection = isIncrease ? '📈 ARTIŞ' : '📉 AZALIŞ';
          const emoji = isProfit ? '💚' : '❤️';
          
          await sendTelegramMessage(
            `${emoji} <b>ÖNEMLİ P&L DEĞİŞİMİ - ${changeDirection}</b>\n\n` +
            `💰 <b>${newPos.coin}</b> ${newPos.side}\n` +
            `💵 Anlık Fiyat: $${formatNumber(newPos.markPrice)}\n` +
            `📊 Mevcut P&L: ${isProfit ? '+' : '-'}$${formatNumber(newPos.unrealizedPnl)}\n` +
            `${isIncrease ? '⬆️' : '⬇️'} Değişim: ${isIncrease ? '+' : '-'}$${formatNumber(pnlDiff)} (${pnlChange.toFixed(1)}%)\n` +
            `📍 Önceki P&L: ${oldPos.unrealizedPnl >= 0 ? '+' : '-'}$${formatNumber(oldPos.unrealizedPnl)}\n` +
            `🎯 Giriş Fiyatı: $${formatNumber(newPos.entryPrice)}`
          );
        }
      }
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
