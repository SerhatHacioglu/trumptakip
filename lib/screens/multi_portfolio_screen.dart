import 'dart:async';
import 'dart:math' as math;
import 'package:f      print('Fetching stock prices for: $stockSymbols');
      
      // Sadece Finnhub kullan (Yahoo kaldırıldı)
      Map<String, double> stockPricesMap = {};
      if (stockSymbols.isNotEmpty) {
        print('Fetching from Finnhub...');
        
        final finnhubResult = await _finnhubService.getStockPrices(stockSymbols);
        stockPricesMap = finnhubResult;
      }
      
      print('Final stock prices: $stockPricesMap');ial.dart';
import '../models/multi_portfolio.dart';
import '../services/coingecko_service.dart';
import '../services/exchange_rate_service.dart';
import '../services/yahoo_finance_service.dart';
import '../services/finnhub_service.dart';
import '../services/alpha_vantage_service.dart';

class MultiPortfolioScreen extends StatefulWidget {
  const MultiPortfolioScreen({super.key});

  @override
  State<MultiPortfolioScreen> createState() => _MultiPortfolioScreenState();
}

class _MultiPortfolioScreenState extends State<MultiPortfolioScreen> {
  final CoinGeckoService _coinGeckoService = CoinGeckoService();
  final ExchangeRateService _exchangeRateService = ExchangeRateService();
  final YahooFinanceService _yahooFinanceService = YahooFinanceService();
  final FinnhubService _finnhubService = FinnhubService();
  final AlphaVantageService _alphaVantageService = AlphaVantageService();
  
  Map<String, double> _cryptoPrices = {};
  Map<String, double> _stockPrices = {};
  double _usdtTryRate = 34.5;
  Timer? _autoRefreshTimer;
  List<PortfolioGroup> _portfolios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
    
    // Her 30 saniyede otomatik yenile
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadData();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final portfolios = await PortfolioItem.getPortfoliosWithSettings();
      final prices = await _coinGeckoService.getCryptoPrices();
      final usdtTry = await _exchangeRateService.getUsdtTryRate();
      
      // Hisse senedi sembollerini topla
      final stockSymbols = portfolios
          .expand((p) => p.items)
          .where((item) => item.type == AssetType.stock)
          .map((item) => item.symbol)
          .toSet()
          .toList();
      
      print('Fetching stock prices for: $stockSymbols');
      
      // Sadece Finnhub kullan (Yahoo kaldırıldı)
      Map<String, double> stockPricesMap = {};
      if (stockSymbols.isNotEmpty) {
        print('� Fetching from Finnhub...');
        
        final finnhubResult = await _finnhubService.getStockPrices(stockSymbols);
        stockPricesMap = finnhubResult;
      }
      
      print('✅ Final stock prices: $stockPricesMap');
      
      setState(() {
        _portfolios = portfolios;
        _cryptoPrices = prices.map((key, value) => MapEntry(key, value.price));
        _stockPrices = stockPricesMap;
        _usdtTryRate = usdtTry;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
      print('Error loading data: $e');
    }
  }

  double _getTotalValue() {
    return _portfolios.fold(0.0, (sum, portfolio) {
      return sum + portfolio.getTotalValueTRY(_cryptoPrices, _stockPrices, _usdtTryRate);
    });
  }

  @override
  Widget build(BuildContext context) {
    final totalValue = _getTotalValue();
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Text(
              '📁',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              'Çoklu Portföy',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _loadData,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    CircularProgressIndicator(
                      color: Theme.of(context).colorScheme.primary,
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Veriler yükleniyor...',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              )
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Toplam Değer Kartı
                  _buildTotalValueCard(totalValue),
                  
                  const SizedBox(height: 8),
                  
                  // USDT/TRY Kuru
                  _buildExchangeRateCard(),
                  
                  const SizedBox(height: 24),
                  
                  // Portföy Kartları
                  ..._portfolios.map((portfolio) => _buildPortfolioCard(portfolio)),
                ],
              ),
      ),
    );
  }

  Widget _buildTotalValueCard(double totalValue) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primary,
            Theme.of(context).colorScheme.primary.withOpacity(0.7),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Colors.white.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Icon(
                  Icons.account_balance_wallet,
                  color: Colors.white,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Text(
                'Toplam Portföy Değeri',
                style: TextStyle(
                  color: Colors.white.withOpacity(0.9),
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Text(
            '₺${_formatNumber(totalValue)}',
            style: TextStyle(
              color: Colors.white,
              fontSize: 32,
              fontWeight: FontWeight.bold,
              letterSpacing: -0.5,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            '${_portfolios.length} Portföy',
            style: TextStyle(
              color: Colors.white.withOpacity(0.8),
              fontSize: 13,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildExchangeRateCard() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Icon(
            Icons.currency_exchange,
            size: 18,
            color: Theme.of(context).colorScheme.primary,
          ),
          const SizedBox(width: 8),
          Text(
            'USDT/TRY:',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '₺${_usdtTryRate.toStringAsFixed(2)}',
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
              color: Theme.of(context).colorScheme.primary,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPortfolioCard(PortfolioGroup portfolio) {
    final totalValue = portfolio.getTotalValueTRY(_cryptoPrices, _stockPrices, _usdtTryRate);
    final color = _getColorForPortfolio(portfolio.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.1),
              color.withOpacity(0.05),
            ],
          ),
        ),
        child: Column(
          children: [
            // Header
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: color.withOpacity(0.1),
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(18),
                  topRight: Radius.circular(18),
                ),
              ),
              child: Row(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: color.withOpacity(0.2),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Center(
                      child: Text(
                        portfolio.emoji,
                        style: TextStyle(fontSize: 24),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          portfolio.name,
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                            color: Theme.of(context).colorScheme.onSurface,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          '${portfolio.items.length} Varlık',
                          style: TextStyle(
                            fontSize: 12,
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Text(
                        '₺${_formatNumberShort(totalValue)}',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            
            // Asset List
            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                children: portfolio.items.map((item) => _buildAssetRow(item, color)).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetRow(PortfolioItem item, Color accentColor) {
    final price = item.type == AssetType.crypto 
        ? _cryptoPrices[item.symbol] ?? 0 
        : _stockPrices[item.symbol] ?? 0;
    final value = item.getCurrentValue(_cryptoPrices, _stockPrices, _usdtTryRate);
    final isPriceAvailable = price > 0;
    
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: isPriceAvailable 
              ? accentColor.withOpacity(0.2)
              : Colors.orange.withOpacity(0.3),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: isPriceAvailable
                  ? accentColor.withOpacity(0.1)
                  : Colors.orange.withOpacity(0.1),
              borderRadius: BorderRadius.circular(10),
            ),
            child: Center(
              child: isPriceAvailable
                  ? Text(
                      item.emoji,
                      style: TextStyle(fontSize: 18),
                    )
                  : Icon(
                      Icons.warning_amber,
                      size: 18,
                      color: Colors.orange.shade600,
                    ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Text(
                      item.symbol,
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                    const SizedBox(width: 6),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                      decoration: BoxDecoration(
                        color: item.type == AssetType.crypto 
                            ? Colors.blue.withOpacity(0.1)
                            : Colors.purple.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        item.type == AssetType.crypto ? 'Crypto' : 'Stock',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: item.type == AssetType.crypto 
                              ? Colors.blue.shade600
                              : Colors.purple.shade600,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text(
                  '${item.amount} ${item.symbol}',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              isPriceAvailable
                  ? Text(
                      '₺${_formatNumberShort(value)}',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    )
                  : Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 14,
                          color: Colors.orange.shade600,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'Fiyat Yok',
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.bold,
                            color: Colors.orange.shade600,
                          ),
                        ),
                      ],
                    ),
              const SizedBox(height: 4),
              isPriceAvailable
                  ? Text(
                      '\$${price.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 11,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
                      ),
                    )
                  : Text(
                      'API Hatası',
                      style: TextStyle(
                        fontSize: 10,
                        color: Colors.orange.shade600,
                      ),
                    ),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColorForPortfolio(String id) {
    switch (id) {
      case 'portfolio_1':
        return Colors.blue.shade400;
      case 'portfolio_2':
        return Colors.purple.shade400;
      case 'portfolio_3':
        return Colors.orange.shade400;
      default:
        return Colors.teal.shade400;
    }
  }

  String _formatNumber(double number) {
    if (number == 0) return '0,00';
    
    final parts = number.toStringAsFixed(2).split('.');
    String intPart = parts[0];
    final decPart = parts[1];
    
    String formatted = '';
    for (int i = intPart.length - 1; i >= 0; i--) {
      formatted = intPart[i] + formatted;
      if ((intPart.length - i) % 3 == 0 && i != 0) {
        formatted = '.$formatted';
      }
    }
    
    return '$formatted,$decPart';
  }

  String _formatNumberShort(double number) {
    if (number == 0) return '0';
    
    if (number >= 1000000) {
      return '${(number / 1000000).toStringAsFixed(2)}M';
    } else if (number >= 1000) {
      return '${(number / 1000).toStringAsFixed(1)}K';
    } else {
      return number.toStringAsFixed(0);
    }
  }
}
