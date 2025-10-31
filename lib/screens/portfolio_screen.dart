import 'dart:async';
import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/portfolio_asset.dart';
import '../services/coingecko_service.dart';
import '../services/exchange_rate_service.dart';
import './portfolio_settings_screen.dart';

class PortfolioScreen extends StatefulWidget {
  const PortfolioScreen({super.key});

  @override
  State<PortfolioScreen> createState() => _PortfolioScreenState();
}

class _PortfolioScreenState extends State<PortfolioScreen> with SingleTickerProviderStateMixin {
  final CoinGeckoService _coinGeckoService = CoinGeckoService();
  final ExchangeRateService _exchangeRateService = ExchangeRateService();
  
  Map<String, double> _cryptoPrices = {};
  double _usdtTryRate = 34.5;
  late AnimationController _animationController;
  List<PortfolioAsset> _assets = [];

  @override
  void initState() {
    super.initState();
    _animationController = AnimationController(
      duration: const Duration(milliseconds: 1500),
      vsync: this,
    );
    _loadData();
  }

  @override
  void dispose() {
    _animationController.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    try {
      final prices = await _coinGeckoService.getCryptoPrices();
      final usdtTry = await _exchangeRateService.getUsdtTryRate();
      final assets = await PortfolioAsset.getAssetsWithSettings();
      
      setState(() {
        _cryptoPrices = prices.map((key, value) => MapEntry(key, value.price));
        _usdtTryRate = usdtTry;
        _assets = assets;
      });
      
      _animationController.forward(from: 0);
    } catch (e) {
      // Handle error silently
    }
  }

  double _getCurrentValueTRY() {
    double total = 0;
    
    for (var asset in _assets) {
      total += asset.getCurrentValue(_cryptoPrices, _usdtTryRate);
    }
    
    return total;
  }

  double _getTotalInvested() {
    return _assets.fold(0.0, (sum, asset) => sum + asset.investedTRY);
  }

  @override
  Widget build(BuildContext context) {
    final currentValueTRY = _getCurrentValueTRY();
    final initialInvestment = _getTotalInvested();
    final targetAmount = initialInvestment; // Hedef = Toplam yatırım
    final profitLossTRY = currentValueTRY - initialInvestment;
    final profitLossPercent = initialInvestment > 0 
        ? (profitLossTRY / initialInvestment) * 100.0
        : 0.0;
    final requiredGrowth = (currentValueTRY > 0) ? (((targetAmount - currentValueTRY) / currentValueTRY) * 100).toDouble() : 0.0;
    final isAboveTarget = currentValueTRY >= targetAmount;
    final isProfit = profitLossTRY >= 0;
    final profitColor = isProfit ? Colors.green.shade400 : Colors.red.shade400;

    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Text(
              '💼',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              'Kişisel Portföy',
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
              Icons.settings,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () async {
              final result = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => const PortfolioSettingsScreen(),
                ),
              );
              
              // Ayarlar sayfasından dönünce veriyi yenile
              if (result == true) {
                _loadData();
              }
            },
            tooltip: 'Ayarlar',
          ),
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
        child: _cryptoPrices.isEmpty
            ? const Center(child: CircularProgressIndicator())
            : ListView(
                padding: const EdgeInsets.all(16),
                children: [
                  // Toplam Değer Kartı
                  _buildSummaryCard(
                    currentValueTRY,
                    profitLossTRY,
                    requiredGrowth,
                    initialInvestment,
                    isAboveTarget,
                    profitColor,
                  ),
                  
                  const SizedBox(height: 16),
                  
                  // USD/TRY Kuru
                  _buildExchangeRateCard(),
                  
                  const SizedBox(height: 16),
                  
                  // Asset Dağılımı
                  _buildAssetDistribution(),
                  
                  const SizedBox(height: 16),
                  
                  // Asset Listesi
                  ..._assets.map((asset) => _buildAssetCard(asset)),
                ],
              ),
      ),
    );
  }

  Widget _buildSummaryCard(
    double currentValue,
    double profitLoss,
    double requiredGrowth,
    double invested,
    bool isAboveTarget,
    Color profitColor,
  ) {
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
                      'Portföy Değeri',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                    const SizedBox(height: 4),
                    FadeTransition(
                      opacity: _animationController,
                      child: Text(
                        '₺${_formatNumber(currentValue)}',
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                          height: 1,
                        ),
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
                child: _buildStatItem(
                  'Yatırım',
                  '₺${_formatNumber(invested)}',
                  Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: profitColor.withOpacity(0.2),
              ),
              Expanded(
                child: _buildStatItem(
                  'Kar/Zarar',
                  '${profitLoss >= 0 ? '+' : ''}₺${_formatNumber(profitLoss)}',
                  profitColor,
                ),
              ),
              Container(
                width: 1,
                height: 40,
                color: profitColor.withOpacity(0.2),
              ),
              Expanded(
                child: _buildStatItem(
                  isAboveTarget ? 'Durum' : 'Gerekli',
                  isAboveTarget 
                      ? '✓ Aşıldı'
                      : '+${requiredGrowth.toStringAsFixed(1)}%',
                  profitColor,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 6),
        FittedBox(
          fit: BoxFit.scaleDown,
          child: Text(
            value,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.bold,
              color: valueColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildExchangeRateCard() {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        children: [
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '💱',
              style: TextStyle(fontSize: 20),
            ),
          ),
          const SizedBox(width: 12),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'USDT/TRY Kuru',
                style: TextStyle(
                  fontSize: 11,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                ),
              ),
              const SizedBox(height: 4),
              Text(
                '₺${_usdtTryRate.toStringAsFixed(2)}',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildAssetDistribution() {
    final total = _getCurrentValueTRY();
    
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.3),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.pie_chart,
                size: 20,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 8),
              Text(
                'Varlık Dağılımı',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          
          // Circular progress bars
          SizedBox(
            height: 150,
            child: Center(
              child: Stack(
                alignment: Alignment.center,
                children: [
                  SizedBox(
                    width: 150,
                    height: 150,
                    child: CustomPaint(
                      painter: _PieChartPainter(
                        assets: _assets,
                        prices: _cryptoPrices,
                        usdtTryRate: _usdtTryRate,
                        animation: _animationController,
                      ),
                    ),
                  ),
                  Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(
                        'Toplam',
                        style: TextStyle(
                          fontSize: 10,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        ),
                      ),
                      Text(
                        '₺${_formatNumberShort(total)}',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
          
          const SizedBox(height: 16),
          
          // Legend
          Wrap(
            spacing: 12,
            runSpacing: 8,
            children: _assets.map((asset) {
              final percentage = total > 0 
                  ? (asset.getCurrentValue(_cryptoPrices, _usdtTryRate) / total * 100)
                  : 0;
              final color = _getColorForAsset(_assets.indexOf(asset));
              
              return Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: color,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Text(
                    '${asset.symbol} ${percentage.toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ],
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  Widget _buildAssetCard(PortfolioAsset asset) {
    final price = _cryptoPrices[asset.symbol] ?? 0;
    final valueTRY = asset.getCurrentValue(_cryptoPrices, _usdtTryRate);
    final profitLoss = asset.getProfitLoss(_cryptoPrices, _usdtTryRate);
    final profitPercent = asset.getProfitLossPercent(_cryptoPrices, _usdtTryRate);
    final isProfit = profitLoss >= 0;
    final profitColor = isProfit ? Colors.green.shade400 : Colors.red.shade400;
    final color = _getColorForAsset(PortfolioAsset.getAssets().indexOf(asset));

    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: color.withOpacity(0.3),
          width: 2,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(16),
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
            Row(
              children: [
                Container(
                  width: 50,
                  height: 50,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      asset.emoji,
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
                        asset.symbol,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        asset.name,
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
                      '₺${_formatNumberShort(valueTRY)}',
                      style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: color,
                      ),
                    ),
                    Row(
                      children: [
                        Icon(
                          isProfit ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                          color: profitColor,
                          size: 16,
                        ),
                        Text(
                          '${isProfit ? '+' : ''}${profitPercent.toStringAsFixed(1)}%',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: profitColor,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildAssetDetailItem(
                      'Miktar',
                      asset.amount.toStringAsFixed(4),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildAssetDetailItem(
                      'Fiyat',
                      '\$${price.toStringAsFixed(2)}',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 30,
                    color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildAssetDetailItem(
                      'Yatırım',
                      '₺${_formatNumberShort(asset.investedTRY)}',
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Kar/Zarar Göstergesi
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: profitColor.withOpacity(0.12),
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: profitColor.withOpacity(0.3),
                  width: 1,
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Row(
                    children: [
                      Icon(
                        isProfit ? Icons.trending_up : Icons.trending_down,
                        size: 16,
                        color: profitColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Kar/Zarar',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: profitColor,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${isProfit ? '+' : ''}₺${_formatNumber(profitLoss.abs())}',
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
      ),
    );
  }

  Widget _buildAssetDetailItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
      ],
    );
  }

  Color _getColorForAsset(int index) {
    final colors = [
      Colors.red.shade400,
      Colors.purple.shade400,
      Colors.blue.shade400,
      Colors.cyan.shade400,
      Colors.teal.shade400,
    ];
    return colors[index % colors.length];
  }

  String _formatNumber(double number) {
    final abs = number.abs();
    final parts = abs.toStringAsFixed(2).split('.');
    final intPart = parts[0];
    final decPart = parts[1];
    
    // 3'lü gruplara ayır
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
    final abs = number.abs().round();
    final str = abs.toString();
    
    // 3'lü gruplara ayır
    String formatted = '';
    for (int i = str.length - 1; i >= 0; i--) {
      formatted = str[i] + formatted;
      if ((str.length - i) % 3 == 0 && i != 0) {
        formatted = '.$formatted';
      }
    }
    
    return formatted;
  }
}

class _PieChartPainter extends CustomPainter {
  final List<PortfolioAsset> assets;
  final Map<String, double> prices;
  final double usdtTryRate;
  final Animation<double> animation;

  _PieChartPainter({
    required this.assets,
    required this.prices,
    required this.usdtTryRate,
    required this.animation,
  }) : super(repaint: animation);

  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = math.min(size.width, size.height) / 2;
    
    double total = 0;
    for (var asset in assets) {
      total += asset.getCurrentValue(prices, usdtTryRate);
    }
    
    if (total == 0) return;
    
    double startAngle = -math.pi / 2;
    
    for (int i = 0; i < assets.length; i++) {
      final asset = assets[i];
      final value = asset.getCurrentValue(prices, usdtTryRate);
      final sweepAngle = (value / total) * 2 * math.pi * animation.value;
      
      final paint = Paint()
        ..color = _getColorForIndex(i)
        ..style = PaintingStyle.stroke
        ..strokeWidth = 20
        ..strokeCap = StrokeCap.round;
      
      canvas.drawArc(
        Rect.fromCircle(center: center, radius: radius - 10),
        startAngle,
        sweepAngle,
        false,
        paint,
      );
      
      startAngle += sweepAngle;
    }
  }

  Color _getColorForIndex(int index) {
    final colors = [
      Colors.red.shade400,
      Colors.purple.shade400,
      Colors.blue.shade400,
      Colors.cyan.shade400,
      Colors.teal.shade400,
    ];
    return colors[index % colors.length];
  }

  @override
  bool shouldRepaint(_PieChartPainter oldDelegate) => true;
}
