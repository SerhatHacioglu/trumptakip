// Bilinen whale wallet adresleri ve büyük pozisyon takibi
const WHALE_WALLETS = [
  { address: '0x...', name: 'Whale #1', minPosition: 20000000 },
  { address: '0x...', name: 'Whale #2', minPosition: 10000000 },
  // Daha fazla whale eklenebilir
];

// Alternatif: Leaderboard verisi için Hyperliquid'in unofficial API'si
const HYPERLIQUID_EXPLORER_API = 'https://api-ui.hyperliquid.xyz';

async function getTopTraders() {
  try {
    const axios = require('axios');
    
    // Hyperliquid'in explorer API'sini dene
    const response = await axios.post(`${HYPERLIQUID_EXPLORER_API}/info`, {
      type: 'leaderboard',
      user: 'day' // veya 'week', 'month'
    });
    
    console.log('Leaderboard:', JSON.stringify(response.data, null, 2));
    
    // En karlı trader'ları filtrele
    const topTraders = response.data
      .filter(trader => trader.accountValue > 20000000) // $20M+
      .slice(0, 10);
    
    return topTraders;
    
  } catch (error) {
    console.error('Leaderboard API error:', error.message);
    return [];
  }
}

module.exports = { getTopTraders, WHALE_WALLETS };
