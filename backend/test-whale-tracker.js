const axios = require('axios');

// HyperDash API'si büyük pozisyonları izlemek için
const HYPERDASH_API = 'https://hypurrscan.io/api';
const HYPERLIQUID_API = 'https://api.hyperliquid.xyz';

async function getWhalePositions() {
  try {
    // HyperDash'in leaderboard endpoint'ini dene
    console.log('Testing HyperDash leaderboard...\n');
    
    const response = await axios.get(`${HYPERDASH_API}/leaderboard`, {
      params: {
        period: '1d',
        limit: 20
      }
    });
    
    console.log('Leaderboard response:', JSON.stringify(response.data, null, 2));
    
  } catch (error) {
    console.error('Error:', error.message);
    if (error.response) {
      console.error('Response data:', error.response.data);
    }
  }
}

async function testMetaEndpoint() {
  try {
    console.log('\nTesting HyperLiquid meta endpoint...\n');
    
    const response = await axios.post(`${HYPERLIQUID_API}/info`, {
      type: 'metaAndAssetCtxs'
    });
    
    console.log('Meta response:', JSON.stringify(response.data, null, 2).substring(0, 500));
    
  } catch (error) {
    console.error('Error:', error.message);
  }
}

async function testAllPositions() {
  try {
    console.log('\nTesting all positions endpoint...\n');
    
    // Bu endpoint tüm açık pozisyonları döndürebilir
    const response = await axios.post(`${HYPERLIQUID_API}/info`, {
      type: 'allMids'
    });
    
    console.log('All mids:', Object.keys(response.data).length, 'coins');
    console.log('Sample:', Object.entries(response.data).slice(0, 5));
    
  } catch (error) {
    console.error('Error:', error.message);
  }
}

// Test fonksiyonlarını çalıştır
(async () => {
  console.log('=== WHALE TRACKER TEST ===\n');
  await getWhalePositions();
  await testMetaEndpoint();
  await testAllPositions();
})();
