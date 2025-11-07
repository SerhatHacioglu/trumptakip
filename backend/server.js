const express = require('express');
const cron = require('node-cron');
const TelegramBot = require('node-telegram-bot-api');
const axios = require('axios');
const { Pool } = require('pg');
require('dotenv').config();

const app = express();
app.use(express.json());

// PostgreSQL bağlantısı (Render'dan gelecek)
const pool = new Pool({
  connectionString: process.env.DATABASE_URL,
  ssl: process.env.DATABASE_URL ? { rejectUnauthorized: false } : false
});

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

// Dinamik wallet yönetimi
let trackedWallets = {};
let lastPositions = {};
let lastNotifiedSize = {};

// Kripto fiyat takibi (BTC, ETH, SOL) - Pozisyonlardan bağımsız
let cryptoPrices = {
  BTC: { currentPrice: 0, lastNotifiedPrice: 0 },
  ETH: { currentPrice: 0, lastNotifiedPrice: 0 },
  SOL: { currentPrice: 0, lastNotifiedPrice: 0 }
};

// Default wallets (backward compatibility)
const DEFAULT_WALLETS = {
  wallet1: {
    address: process.env.WALLET_ADDRESS || '0xc2a30212a8ddac9e123944d6e29faddce994e5f2',
    name: 'Cüzdan 1'
  },
  wallet2: {
    address: process.env.WALLET_ADDRESS_2 || '0xb317d2bc2d3d2df5fa441b5bae0ab9d8b07283ae',
    name: 'Cüzdan 2'
  },
  wallet3: {
    address: process.env.WALLET_ADDRESS_3 || '0x9263c1bd29aa87a118242f3fbba4517037f8cc7a',
    name: 'Cüzdan 3'
  }
};

// Veritabanı tablosunu oluştur
async function initializeDatabase() {
  try {
    await pool.query(`
      CREATE TABLE IF NOT EXISTS wallets (
        key VARCHAR(255) PRIMARY KEY,
        address VARCHAR(255) NOT NULL,
        name VARCHAR(255) NOT NULL,
        color VARCHAR(50),
        created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
        updated_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP
      )
    `);
    console.log('✅ Veritabanı tablosu hazır');
    
    // Eğer tablo boşsa, default wallets'i ekle
    const result = await pool.query('SELECT COUNT(*) FROM wallets');
    if (parseInt(result.rows[0].count) === 0) {
      console.log('� Default cüzdanlar ekleniyor...');
      for (const [key, wallet] of Object.entries(DEFAULT_WALLETS)) {
        await pool.query(
          'INSERT INTO wallets (key, address, name) VALUES ($1, $2, $3)',
          [key, wallet.address, wallet.name]
        );
      }
      console.log('✅ Default cüzdanlar eklendi');
    }
  } catch (error) {
    console.error('Veritabanı başlatma hatası:', error.message);
  }
}

// Veritabanından wallets'i yükle
async function loadWalletsFromDatabase() {
  try {
    const result = await pool.query('SELECT * FROM wallets ORDER BY key');
    const wallets = {};
    result.rows.forEach(row => {
      wallets[row.key] = {
        address: row.address,
        name: row.name,
        color: row.color
      };
    });
    console.log(`📂 ${Object.keys(wallets).length} cüzdan veritabanından yüklendi`);
    return wallets;
  } catch (error) {
    console.error('Wallets yükleme hatası:', error.message);
    return DEFAULT_WALLETS;
  }
}

// Wallets'i veritabanına kaydet
async function saveWalletsToDatabase(wallets) {
  try {
    // Önce tüm kayıtları sil
    await pool.query('DELETE FROM wallets');
    
    // Yeni kayıtları ekle
    for (const [key, wallet] of Object.entries(wallets)) {
      await pool.query(
        'INSERT INTO wallets (key, address, name, color) VALUES ($1, $2, $3, $4)',
        [key, wallet.address, wallet.name, wallet.color || null]
      );
    }
    console.log(`💾 ${Object.keys(wallets).length} cüzdan veritabanına kaydedildi`);
  } catch (error) {
    console.error('Wallets kaydetme hatası:', error.message);
  }
}

// Initialize with saved or default wallets
async function initializeWallets() {
  await initializeDatabase();
  const savedWallets = await loadWalletsFromDatabase();
  Object.entries(savedWallets).forEach(([key, wallet]) => {
    trackedWallets[key] = wallet;
    lastPositions[key] = [];
    lastNotifiedSize[key] = {};
  });
}

// API endpoint: Wallet listesini güncelle
app.post('/api/wallets/sync', async (req, res) => {
  try {
    const { wallets } = req.body;
    
    if (!Array.isArray(wallets)) {
      return res.status(400).json({ error: 'Wallets must be an array' });
    }

    // Yeni wallet tracking yapısını oluştur
    const newTrackedWallets = {};
    const newLastPositions = {};
    const newLastNotifiedSize = {};

    wallets.forEach((wallet, index) => {
      const key = `wallet_${wallet.id}`;
      newTrackedWallets[key] = {
        address: wallet.address,
        name: wallet.name,
        color: wallet.color
      };
      
      // Eski verileri koru (eğer varsa)
      newLastPositions[key] = lastPositions[key] || [];
      newLastNotifiedSize[key] = lastNotifiedSize[key] || {};
    });

    // Global değişkenleri güncelle
    trackedWallets = newTrackedWallets;
    lastPositions = newLastPositions;
    lastNotifiedSize = newLastNotifiedSize;

    // Veritabanına kaydet (kalıcı hale getir)
    await saveWalletsToDatabase(newTrackedWallets);

    console.log(`✅ ${wallets.length} cüzdan senkronize edildi`);
    
    res.json({ 
      success: true, 
      message: `${wallets.length} cüzdan senkronize edildi`,
      trackedWallets: Object.keys(trackedWallets)
    });
  } catch (error) {
    console.error('Wallet senkronizasyon hatası:', error);
    res.status(500).json({ error: error.message });
  }
});

// API endpoint: Aktif wallet listesini getir
app.get('/api/wallets', (req, res) => {
  res.json({
    wallets: Object.entries(trackedWallets).map(([key, wallet]) => ({
      key,
      ...wallet
    }))
  });
});

// WALLETS referansını dinamik olarak kullan
const HYPERLIQUID_API = 'https://api.hyperliquid.xyz';
const COINGECKO_API = 'https://api.coingecko.com/api/v3';

// CoinGecko'dan kripto fiyatlarını al (BTC, ETH, SOL)
async function fetchCryptoPricesFromCoinGecko() {
  try {
    const coinIds = {
      'bitcoin': 'BTC',
      'ethereum': 'ETH',
      'solana': 'SOL'
    };
    
    const ids = Object.keys(coinIds).join(',');
    const response = await axios.get(`${COINGECKO_API}/simple/price`, {
      params: {
        ids: ids,
        vs_currencies: 'usd'
      }
    });
    
    const prices = {};
    for (const [coinId, symbol] of Object.entries(coinIds)) {
      if (response.data[coinId] && response.data[coinId].usd) {
        prices[symbol] = response.data[coinId].usd;
      }
    }
    
    return prices;
  } catch (error) {
    console.error('CoinGecko fiyat alma hatası:', error.message);
    return {};
  }
}

// Bot başlatıldığında CoinGecko'dan başlangıç fiyatlarını al
async function initializeCryptoPrices() {
  console.log('🔄 Kripto fiyatları başlatılıyor (CoinGecko)...');
  const prices = await fetchCryptoPricesFromCoinGecko();
  
  Object.entries(prices).forEach(([coin, price]) => {
    cryptoPrices[coin].currentPrice = price;
    cryptoPrices[coin].lastNotifiedPrice = price;
    console.log(`✅ ${coin}: $${price.toFixed(2)}`);
  });
}

// Kripto fiyat değişimlerini kontrol et (BTC, ETH, SOL)
async function checkCryptoPrices() {
  try {
    console.log('🔍 Kripto fiyatları kontrol ediliyor...', new Date().toISOString());
    
    const prices = await fetchCryptoPricesFromCoinGecko();
    
    for (const [coin, currentPrice] of Object.entries(prices)) {
      if (!cryptoPrices[coin]) continue;
      
      cryptoPrices[coin].currentPrice = currentPrice;
      const lastNotified = cryptoPrices[coin].lastNotifiedPrice;
      
      // İlk kez kontrol ediyorsak atla
      if (lastNotified === 0) {
        cryptoPrices[coin].lastNotifiedPrice = currentPrice;
        continue;
      }
      
      // Son bildirim fiyatına göre %2'den fazla değişim var mı?
      const priceDiff = currentPrice - lastNotified;
      const priceChangePercent = Math.abs((priceDiff / lastNotified) * 100);
      
      if (priceChangePercent >= 2) {
        const isPriceIncrease = priceDiff > 0;
        const changeDirection = isPriceIncrease ? '📈 YUKARI' : '📉 AŞAĞI';
        const emoji = isPriceIncrease ? '🟢' : '🔴';
        
        await sendTelegramMessage(
          `${emoji} <b>ÖNEMLİ FİYAT HAREKETİ - ${changeDirection}</b>\n\n` +
          `💰 <b>${coin}/USDT</b>\n` +
          `💵 Yeni Fiyat: $${formatNumber(currentPrice)}\n` +
          `${isPriceIncrease ? '⬆️' : '⬇️'} Değişim: ${isPriceIncrease ? '+' : ''}$${formatNumber(priceDiff)} (${isPriceIncrease ? '+' : '-'}${priceChangePercent.toFixed(2)}%)\n` +
          `📍 Son Bildirim Fiyatı: $${formatNumber(lastNotified)}\n` +
          `🕐 ${new Date().toLocaleString('tr-TR')}`
        );
        
        // Yeni fiyatı son bildirim fiyatı olarak kaydet
        cryptoPrices[coin].lastNotifiedPrice = currentPrice;
      }
    }
    
  } catch (error) {
    console.error('Kripto fiyat kontrolü hatası:', error.message);
  }
}

// Pozisyonları kontrol et
async function checkPositions() {
  try {
    console.log('Pozisyonlar kontrol ediliyor...', new Date().toISOString());
    
    // Tüm cüzdanları kontrol et
    for (const [walletKey, walletInfo] of Object.entries(trackedWallets)) {
      await checkWalletPositions(walletKey, walletInfo);
    }
    
  } catch (error) {
    console.error('Pozisyon kontrolü hatası:', error.message);
  }
}

// Tek bir cüzdanın pozisyonlarını kontrol et
async function checkWalletPositions(walletKey, walletInfo) {
  try {
    const { address, name } = walletInfo;
    
    // HyperLiquid API'den pozisyonları al
    const response = await axios.post(`${HYPERLIQUID_API}/info`, {
      type: 'clearinghouseState',
      user: address
    });
    
    if (!response.data || !response.data.assetPositions) {
      console.log(`${name} - Pozisyon verisi bulunamadı`);
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
          leverage: parseFloat(pos.leverage?.value || pos.leverage?.leverage || 1)
        });
      }
    }
    
    console.log(`${name} - ${currentPositions.length} açık pozisyon bulundu`);
    
    // İlk çalıştırmada sadece kaydet
    if (lastPositions[walletKey].length === 0 && currentPositions.length === 0) {
      // Hiç pozisyon yok, sessizce kaydet
      lastPositions[walletKey] = currentPositions;
      return;
    }
    
    if (lastPositions[walletKey].length === 0 && currentPositions.length > 0) {
      lastPositions[walletKey] = currentPositions;
      
      // Bot başlatma mesajı (sadece pozisyon varsa)
      await sendTelegramMessage(
        `🤖 <b>Bot Başlatıldı - ${name}</b>\n\n` +
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
          `${sideEmoji} <b>İZLENEN POZİSYON - ${name}</b>\n\n` +
          `💰 <b>${pos.coin}</b> ${pos.side}\n` +
          `📊 Miktar: ${pos.size.toFixed(4)}\n` +
          `🎯 Giriş: $${formatNumber(pos.entryPrice)}\n` +
          `💵 Anlık Fiyat: $${formatNumber(pos.markPrice)}\n` +
          `${emoji} Mevcut P&L: ${isProfit ? '+' : '-'}$${formatNumber(pos.unrealizedPnl)}\n` +
          `⚡ Kaldıraç: ${Math.round(pos.leverage)}x`
        );
        
        // Başlangıç miktarını kaydet
        lastNotifiedSize[walletKey][positionKey] = pos.size;
      }
      
      return;
    }
    
    // Değişiklikleri kontrol et
    await compareAndNotify(walletKey, name, currentPositions);
    
    // Güncel pozisyonları kaydet
    lastPositions[walletKey] = currentPositions;
    
  } catch (error) {
    console.error(`${walletInfo.name} pozisyon kontrolü hatası:`, error.message);
  }
}

// Rakamları 3'lü formatta göster
function formatNumber(num) {
  return Math.abs(num).toFixed(2).replace(/\B(?=(\d{3})+(?!\d))/g, '.');
}

// Pozisyon değişim eşiği (USD cinsinden)
const POSITION_CHANGE_THRESHOLD_USD = 3000000; // $3,000,000

// Pozisyonları karşılaştır ve bildirim gönder
async function compareAndNotify(walletKey, walletName, currentPositions) {
  const oldPositions = lastPositions[walletKey];
  
  // 1. Yeni pozisyon açıldı mı?
  for (const newPos of currentPositions) {
    const exists = oldPositions.find(old => 
      old.coin === newPos.coin && old.side === newPos.side
    );
    
    if (!exists) {
      const emoji = newPos.side === 'LONG' ? '📈' : '📉';
      await sendTelegramMessage(
        `${emoji} <b>YENİ POZİSYON AÇILDI - ${walletName}</b>\n\n` +
        `💰 <b>${newPos.coin}</b> ${newPos.side}\n` +
        `📊 Miktar: ${newPos.size.toFixed(4)}\n` +
        `🎯 Giriş: $${formatNumber(newPos.entryPrice)}\n` +
        `💵 Anlık Fiyat: $${formatNumber(newPos.markPrice)}\n` +
        `⚡ Kaldıraç: ${Math.round(newPos.leverage)}x`
      );
    }
  }
  
  // 2. Pozisyon kapandı mı?
  for (const oldPos of oldPositions) {
    const exists = currentPositions.find(newPos => 
      newPos.coin === oldPos.coin && newPos.side === oldPos.side
    );
    
    if (!exists) {
      const pnlEmoji = oldPos.unrealizedPnl >= 0 ? '✅' : '❌';
      const pnlSign = oldPos.unrealizedPnl >= 0 ? '+' : '-';
      await sendTelegramMessage(
        `🔚 <b>POZİSYON KAPATILDI - ${walletName}</b>\n\n` +
        `💰 <b>${oldPos.coin}</b> ${oldPos.side}\n` +
        `${pnlEmoji} P&L: ${pnlSign}$${formatNumber(oldPos.unrealizedPnl)}\n` +
        `🎯 Giriş: $${formatNumber(oldPos.entryPrice)}\n` +
        `💵 Kapanış: $${formatNumber(oldPos.markPrice)}`
      );
    }
  }
  
  // 3. Pozisyona ekleme/azaltma yapıldı mı?
  for (const newPos of currentPositions) {
    const oldPos = oldPositions.find(old => 
      old.coin === newPos.coin && old.side === newPos.side
    );
    
    if (oldPos) {
      const positionKey = `${newPos.coin}_${newPos.side}`;
      
      // Son bildirim gönderilen miktarı al (yoksa eski pozisyon miktarını kullan)
      const lastNotifiedSizeValue = lastNotifiedSize[walletKey][positionKey] !== undefined 
        ? lastNotifiedSize[walletKey][positionKey] 
        : oldPos.size;
      
      // Son bildirime göre değişimi hesapla
      const sizeChangeFromLast = newPos.size - lastNotifiedSizeValue;
      const sizeChangePercent = lastNotifiedSizeValue > 0 
        ? Math.abs((sizeChangeFromLast / lastNotifiedSizeValue) * 100)
        : 0;
      
      // Pozisyon değişiminin USD değerini hesapla
      const sizeChangeValueUSD = Math.abs(sizeChangeFromLast * newPos.markPrice);
      const positionValueUSD = newPos.size * newPos.markPrice;
      
      // ARTIŞ: Son bildirimden beri $3M+ artış varsa
      if (sizeChangeFromLast > 0.0001 && sizeChangeValueUSD >= POSITION_CHANGE_THRESHOLD_USD) {
        await sendTelegramMessage(
          `➕ <b>POZİSYONA EKLEME YAPILDI - ${walletName}</b>\n\n` +
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
        lastNotifiedSize[walletKey][positionKey] = newPos.size;
      }
      
      // AZALIŞ: Son bildirimden beri $3M+ azalış varsa
      if (sizeChangeFromLast < -0.0001 && sizeChangeValueUSD >= POSITION_CHANGE_THRESHOLD_USD) {
        await sendTelegramMessage(
          `➖ <b>POZİSYON KISMİ KAPATILDI - ${walletName}</b>\n\n` +
          `💰 <b>${newPos.coin}</b> ${newPos.side}\n` +
          `📊 Kapatılan: ${sizeChangeFromLast.toFixed(4)} (-${sizeChangePercent.toFixed(1)}%)\n` +
          `💵 Kapatılan Değer: $${formatNumber(sizeChangeValueUSD)}\n` +
          `📉 Kalan: ${newPos.size.toFixed(4)}\n` +
          `💎 Kalan Değer: $${formatNumber(positionValueUSD)}\n` +
          `📍 Son Bildirim: ${lastNotifiedSizeValue.toFixed(4)}\n` +
          `💵 Kapanış Fiyatı: $${formatNumber(newPos.markPrice)}`
        );
        
        // Yeni miktarı kaydet
        lastNotifiedSize[walletKey][positionKey] = newPos.size;
      }
      
      // İlk kez görüyorsak miktarı kaydet
      if (lastNotifiedSize[walletKey][positionKey] === undefined) {
        lastNotifiedSize[walletKey][positionKey] = newPos.size;
      }
    }
  }
  
  // Kapanan pozisyonların miktar kayıtlarını temizle
  for (const key in lastNotifiedSize[walletKey]) {
    const [coin, side] = key.split('_');
    const exists = currentPositions.find(pos => 
      pos.coin === coin && pos.side === side
    );
    if (!exists) {
      delete lastNotifiedSize[walletKey][key];
    }
  }
}

// Her 1 dakikada bir kontrol et
// Pozisyonlar ve kripto fiyatları için ayrı ayrı kontrol
cron.schedule('*/1 * * * *', () => {
  checkPositions();
  checkCryptoPrices();
});

// Sunucu başladığında başlangıç işlemleri
setTimeout(async () => {
  await initializeWallets();
  await initializeCryptoPrices();
  await checkPositions();
}, 5000);

// API endpoint'leri
app.get('/', (req, res) => {
  const totalPositions = Object.values(lastPositions).reduce((sum, positions) => sum + positions.length, 0);
  
  res.json({ 
    status: 'running',
    service: 'TrumpTakip Bot',
    timestamp: new Date().toISOString(),
    walletsTracked: Object.keys(trackedWallets).length,
    totalPositions: totalPositions,
    wallets: Object.entries(trackedWallets).map(([key, wallet]) => ({
      key,
      name: wallet.name,
      address: wallet.address,
      positions: lastPositions[key]?.length || 0
    }))
  });
});

app.get('/api/health', (req, res) => {
  const walletsInfo = {};
  Object.entries(trackedWallets).forEach(([key, wallet]) => {
    walletsInfo[key] = {
      name: wallet.name,
      address: wallet.address,
      positions: lastPositions[key]?.length || 0
    };
  });

  res.json({ 
    status: 'ok', 
    timestamp: new Date().toISOString(),
    wallets: walletsInfo
  });
});

app.get('/api/positions/:wallet', async (req, res) => {
  try {
    const walletKey = req.params.wallet;
    if (!trackedWallets[walletKey]) {
      return res.status(404).json({ error: 'Wallet not found' });
    }
    
    const response = await axios.post(`${HYPERLIQUID_API}/info`, {
      type: 'clearinghouseState',
      user: trackedWallets[walletKey].address
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
    await checkCryptoPrices();
    res.json({ success: true, message: 'Kontrol başlatıldı' });
  } catch (error) {
    res.status(500).json({ error: error.message });
  }
});

// Kripto fiyatları endpoint'i
app.get('/api/crypto-prices', (req, res) => {
  res.json({
    prices: cryptoPrices,
    timestamp: new Date().toISOString()
  });
});

const PORT = process.env.PORT || 3000;
app.listen(PORT, () => {
  console.log(`🚀 Backend sunucu çalışıyor: http://localhost:${PORT}`);
  console.log('📱 Telegram Bot aktif');
  console.log('⏰ Pozisyon kontrolü her 1 dakikada bir yapılacak');
  console.log('📈 Kripto fiyat takibi aktif (BTC, ETH, SOL)');
  console.log('💼 İzlenen cüzdanlar:');
  Object.entries(trackedWallets).forEach(([key, wallet]) => {
    console.log(`   - ${wallet.name}: ${wallet.address}`);
  });
});
