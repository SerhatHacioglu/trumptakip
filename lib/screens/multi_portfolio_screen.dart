import 'dart:async';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/multi_portfolio.dart';
import '../services/coingecko_service.dart';
import '../services/exchange_rate_service.dart';
import '../services/finnhub_service.dart';
import 'multi_portfolio_settings_screen.dart';

class MultiPortfolioScreen extends StatefulWidget {
  const MultiPortfolioScreen({super.key});

  @override
  State<MultiPortfolioScreen> createState() => _MultiPortfolioScreenState();
}

class _MultiPortfolioScreenState extends State<MultiPortfolioScreen> {
  final CoinGeckoService _coinGeckoService = CoinGeckoService();
  final ExchangeRateService _exchangeRateService = ExchangeRateService();
  final FinnhubService _finnhubService = FinnhubService();
  
  Map<String, double> _cryptoPrices = {};
  Map<String, double> _stockPrices = {};
  double _usdtTryRate = 34.5;
  double _usdTryRate = 34.3;
  double _targetAmount = 2000000;
  List<PortfolioGroup> _portfolios = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadTarget();
    _loadData();
  }

  Future<void> _loadTarget() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _targetAmount = prefs.getDouble('portfolio_target') ?? 2000000;
    });
  }

  @override
  void dispose() {
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      setState(() {
        _isLoading = true;
      });

      final portfolios = await PortfolioItem.getPortfoliosWithSettings();
      
      // Get crypto IDs from all portfolios
      final cryptoIds = portfolios
          .expand((p) => p.items)
          .where((item) => item.type == AssetType.crypto && item.coingeckoId != null && item.coingeckoId!.isNotEmpty)
          .map((item) => item.coingeckoId!)
          .toSet()
          .toList();
      
      final prices = await _coinGeckoService.getCryptoPrices(cryptoIds: cryptoIds);
      final usdtTry = await _exchangeRateService.getUsdtTryRate();
      final usdTry = await _exchangeRateService.getUsdTryRate();
      
      final stockSymbols = portfolios
          .expand((p) => p.items)
          .where((item) => item.type == AssetType.stock)
          .map((item) => item.symbol)
          .toSet()
          .toList();
      
      Map<String, double> stockPricesMap = {};
      if (stockSymbols.isNotEmpty) {
        final finnhubResult = await _finnhubService.getStockPrices(stockSymbols);
        stockPricesMap = finnhubResult;
      }
      
      setState(() {
        _portfolios = portfolios;
        _cryptoPrices = prices.map((key, value) => MapEntry(key, value.price));
        _stockPrices = stockPricesMap;
        _usdtTryRate = usdtTry;
        _usdTryRate = usdTry;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _isLoading = false;
      });
    }
  }

  double _getTotalValue() {
    return _portfolios.fold(0.0, (sum, portfolio) {
      return sum + portfolio.getTotalValueTRY(_cryptoPrices, _stockPrices, _usdtTryRate, _usdTryRate);
    });
  }

  Future<void> _editTarget() async {
    String targetText = _targetAmount.toStringAsFixed(0);
    
    final result = await showDialog<double>(
      context: context,
      builder: (context) {
        final controller = TextEditingController(text: targetText);
        return AlertDialog(
          title: const Text('Hedef Düzenle'),
          content: TextField(
            controller: controller,
            keyboardType: TextInputType.number,
            autofocus: true,
            decoration: const InputDecoration(
              labelText: 'Hedef (TL)',
              hintText: '2000000',
              suffixText: '₺',
              border: OutlineInputBorder(),
            ),
            onChanged: (value) => targetText = value,
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: const Text('İptal'),
            ),
            TextButton(
              onPressed: () {
                final value = double.tryParse(targetText) ?? 2000000;
                Navigator.of(context).pop(value);
              },
              child: const Text('Kaydet'),
            ),
          ],
        );
      },
    );

    if (result != null && mounted) {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setDouble('portfolio_target', result);
      setState(() {
        _targetAmount = result;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final totalValue = _getTotalValue();
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: const Row(
          children: [
            Text('📊', style: TextStyle(fontSize: 20)),
            SizedBox(width: 8),
            Text('Trader Takip', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.flag),
            onPressed: _editTarget,
            tooltip: 'Hedef Düzenle',
          ),
          IconButton(
            icon: const Icon(Icons.settings),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MultiPortfolioSettingsScreen()),
              );
              if (result == true) {
                _loadData();
              }
            },
            tooltip: 'Ayarlar',
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            onPressed: _loadData,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadData,
        child: _isLoading
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  _buildTotalValueCard(totalValue),
                  const SizedBox(height: 8),
                  _buildExchangeRateCard(),
                  const SizedBox(height: 24),
                  ..._portfolios.map((portfolio) => _buildPortfolioCard(portfolio)),
                ],
              ),
      ),
    );
  }

  Widget _buildTotalValueCard(double totalValue) {
    final difference = totalValue - _targetAmount;
    final percentage = (_targetAmount > 0) ? (totalValue / _targetAmount * 100) : 0;
    final requiredGrowth = (totalValue > 0) ? (((_targetAmount - totalValue) / totalValue) * 100) : 0;
    final isAboveTarget = totalValue >= _targetAmount;
    final profitColor = isAboveTarget ? Colors.green.shade400 : Colors.deepPurple.shade400;
    
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            profitColor.withOpacity(0.15),
            profitColor.withOpacity(0.05),
          ],
        ),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: profitColor.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: profitColor.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  isAboveTarget ? Icons.check_circle : Icons.flag,
                  color: profitColor,
                  size: 24,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toplam Portföy Değeri',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₺${_formatNumber(totalValue)}',
                      style: TextStyle(
                        fontSize: 32,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface,
                        height: 1,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 16),
          
          Divider(color: profitColor.withOpacity(0.2)),
          
          const SizedBox(height: 16),
          
          Row(
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Hedef',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '₺${_formatNumber(_targetAmount)}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: profitColor.withOpacity(0.2),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Fark',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      '${difference >= 0 ? '+' : ''}₺${_formatNumber(difference.abs())}',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: profitColor,
                      ),
                    ),
                  ],
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: profitColor.withOpacity(0.2),
              ),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      isAboveTarget ? 'Durum' : 'Gerekli',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      isAboveTarget 
                          ? '✓ Aşıldı'
                          : '+${requiredGrowth.toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                        color: profitColor,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 12),
          
          Text(
            '${_portfolios.length} Portföy',
            style: TextStyle(
              fontSize: 12,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
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
          Icon(Icons.currency_exchange, size: 18, color: Theme.of(context).colorScheme.primary),
          const SizedBox(width: 8),
          const Text('USDT/TRY:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Text('₺${_usdtTryRate.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
          const SizedBox(width: 16),
          const Text('USD/TRY:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
          const SizedBox(width: 6),
          Text('₺${_usdTryRate.toStringAsFixed(2)}', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: Theme.of(context).colorScheme.primary)),
        ],
      ),
    );
  }

  Widget _buildPortfolioCard(PortfolioGroup portfolio) {
    final totalValue = portfolio.getTotalValueTRY(_cryptoPrices, _stockPrices, _usdtTryRate, _usdTryRate);
    final color = _getColorForPortfolio(portfolio.id);
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.3), width: 2),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Text(portfolio.emoji, style: const TextStyle(fontSize: 24)),
                const SizedBox(width: 12),
                Expanded(child: Text(portfolio.name, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold))),
                Text('₺${_formatNumberShort(totalValue)}', style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold, color: color)),
              ],
            ),
            const SizedBox(height: 16),
            ...portfolio.items.map((item) => _buildAssetRow(item, color)),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetRow(PortfolioItem item, Color accentColor) {
    final isCash = item.type == AssetType.cash;
    final price = !isCash && item.type == AssetType.crypto 
        ? _cryptoPrices[item.symbol] ?? 0 
        : !isCash ? _stockPrices[item.symbol] ?? 0 : 0;
    final value = item.getCurrentValue(_cryptoPrices, _stockPrices, _usdtTryRate, _usdTryRate);
    final isPriceAvailable = !isCash && price > 0;
    
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        children: [
          Text(item.emoji, style: const TextStyle(fontSize: 18)),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(item.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
                Text(isCash ? item.name : '${item.amount} ${item.symbol}', style: const TextStyle(fontSize: 12, color: Colors.grey)),
              ],
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              Text(isCash || isPriceAvailable ? '₺${_formatNumberShort(value)}' : 'N/A', style: const TextStyle(fontWeight: FontWeight.bold)),
              if (isPriceAvailable) Text('\$${price.toStringAsFixed(2)}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
            ],
          ),
        ],
      ),
    );
  }

  Color _getColorForPortfolio(String id) {
    switch (id) {
      case 'portfolio_1': return Colors.blue.shade400;
      case 'portfolio_2': return Colors.purple.shade400;
      case 'portfolio_3': return Colors.orange.shade400;
      case 'portfolio_4': return Colors.green.shade400;
      case 'portfolio_5': return Colors.red.shade400;
      default: return Colors.teal.shade400;
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
