import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/position.dart';
import '../services/hyperdash_service.dart';
import '../services/coingecko_service.dart';
import 'whale_tracker_screen.dart';

class PositionsScreen extends StatefulWidget {
  const PositionsScreen({super.key});

  @override
  State<PositionsScreen> createState() => _PositionsScreenState();
}

class _PositionsScreenState extends State<PositionsScreen> {
  final HyperDashService _service = HyperDashService();
  final CoinGeckoService _coinGeckoService = CoinGeckoService();
  final String walletAddress = '0xc2a30212a8ddac9e123944d6e29faddce994e5f2';
  
  List<Position> _positions = [];
  Map<String, CryptoPrice> _cryptoPrices = {};
  bool _isLoading = false;
  bool _isPricesLoading = false;
  String? _error;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadPositions();
    _loadCryptoPrices();
    
    // Her 30 saniyede otomatik yenile
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadPositions();
      _loadCryptoPrices();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadPositions() async {
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final positions = await _service.getOpenPositions(walletAddress);
      setState(() {
        _positions = positions;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isLoading = false;
      });
    }
  }

  Future<void> _loadCryptoPrices() async {
    setState(() {
      _isPricesLoading = true;
    });

    try {
      final prices = await _coinGeckoService.getCryptoPrices();
      setState(() {
        _cryptoPrices = prices;
        _isPricesLoading = false;
      });
    } catch (e) {
      setState(() {
        _isPricesLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final btcPrice = _cryptoPrices['BTC'];
    final btcChange = btcPrice?.change24h ?? 0;
    final isBtcPositive = btcChange >= 0;
    
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: btcPrice != null
            ? Row(
                children: [
                  Text(
                    'BTC ',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                    ),
                  ),
                  Text(
                    '\$${btcPrice.price.toStringAsFixed(0)}',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Icon(
                    isBtcPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                    color: isBtcPositive ? Colors.green.shade400 : Colors.red.shade400,
                    size: 18,
                  ),
                  Text(
                    '${btcChange.abs().toStringAsFixed(1)}%',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                      color: isBtcPositive ? Colors.green.shade400 : Colors.red.shade400,
                    ),
                  ),
                ],
              )
            : Text(
                'HyperLiquid',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.waves,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const WhaleTrackerScreen()),
              );
            },
            tooltip: 'Whale Tracker',
          ),
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _loadPositions,
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    if (_error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.red.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.error_outline,
                  size: 64,
                  color: Colors.red.shade400,
                ),
              ),
              const SizedBox(height: 24),
              Text(
                'Bir Hata Oluştu',
                style: TextStyle(
                  fontSize: 22,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _error!,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: _loadPositions,
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 32,
                    vertical: 16,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
              ),
            ],
          ),
        ),
      );
    }

    if (_positions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest,
                shape: BoxShape.circle,
              ),
              child: Icon(
                Icons.inbox_outlined,
                size: 64,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Açık Pozisyon Bulunamadı',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Bu wallet için açık pozisyon bulunmuyor.',
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 14,
              ),
            ),
          ],
        ),
      );
    }

    return RefreshIndicator(
      onRefresh: () async {
        await _loadPositions();
        await _loadCryptoPrices();
      },
      child: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: _positions.length + 2, // +2 for crypto prices and summary card
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildCryptoPricesWidget();
              }
              if (index == 1) {
                return _buildSummaryCard();
              }
              return _buildPositionCard(_positions[index - 2]);
            },
          ),
          if (_isLoading)
            Center(
              child: Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.8),
                  shape: BoxShape.circle,
                ),
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: CircularProgressIndicator(
                    strokeWidth: 3,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildCryptoPricesWidget() {
    if (_cryptoPrices.isEmpty) {
      return const SizedBox.shrink();
    }

    // BTC'yi çıkar, sadece diğerlerini göster
    final displayPrices = Map<String, CryptoPrice>.from(_cryptoPrices);
    displayPrices.remove('BTC');

    if (displayPrices.isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      decoration: BoxDecoration(
        color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: displayPrices.entries.map((entry) {
          final crypto = entry.value;
          final isPositive = crypto.change24h >= 0;
          final changeColor = isPositive ? Colors.green.shade400 : Colors.red.shade400;

          return Expanded(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  crypto.symbol,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '\$${crypto.symbol == 'BTC' || crypto.symbol == 'ETH' ? crypto.price.toStringAsFixed(0) : crypto.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: changeColor,
                      size: 16,
                    ),
                    Text(
                      '${crypto.change24h.abs().toStringAsFixed(1)}%',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: changeColor,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildSummaryCard() {
    double totalPnl = 0;
    double totalValue = 0;
    for (var position in _positions) {
      totalPnl += position.unrealizedPnl;
      totalValue += position.positionValue;
    }
    final isProfit = totalPnl >= 0;
    final profitColor = isProfit ? Colors.green.shade400 : Colors.red.shade400;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Container(
        padding: const EdgeInsets.all(14),
        child: Column(
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Toplam Pozisyon',
                      style: TextStyle(
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Text(
                          '${_positions.length}',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface,
                            fontSize: 28,
                            fontWeight: FontWeight.bold,
                            height: 1,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Padding(
                          padding: const EdgeInsets.only(bottom: 2),
                          child: Text(
                            '\$${_formatPrice(totalValue)}',
                            style: TextStyle(
                              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                              fontSize: 14,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 14,
                    vertical: 8,
                  ),
                  decoration: BoxDecoration(
                    color: profitColor.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.end,
                    children: [
                      Row(
                        children: [
                          Icon(
                            isProfit ? Icons.trending_up : Icons.trending_down,
                            color: profitColor,
                            size: 16,
                          ),
                          const SizedBox(width: 3),
                          Text(
                            'P&L',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: profitColor,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 2),
                      Text(
                        '${isProfit ? '+' : ''}\$${_formatPrice(totalPnl)}',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: profitColor,
                          height: 1,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPositionCard(Position position) {
    final isProfit = position.unrealizedPnl >= 0;
    final profitColor = isProfit ? Colors.green.shade400 : Colors.red.shade400;
    final isLong = position.side == 'LONG';
    final isBig = position.positionValue > 1000000;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 4, horizontal: 16),
      elevation: isBig ? 2 : 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: isBig 
            ? BorderSide(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                width: 2,
              )
            : BorderSide(
                color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
                width: 1,
              ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(12),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Üst satır: Coin, Side Badge, Leverage
            Row(
              children: [
                Text(
                  position.coin,
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(width: 8),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                  decoration: BoxDecoration(
                    color: isLong ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    position.side,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: isLong ? Colors.green.shade600 : Colors.red.shade600,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondaryContainer,
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        Icons.flash_on,
                        size: 12,
                        color: Theme.of(context).colorScheme.onSecondaryContainer,
                      ),
                      const SizedBox(width: 2),
                      Text(
                        '${position.leverage.round()}x',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            
            const SizedBox(height: 12),
            
            // Pozisyon detayları grid
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCompactDetailItem(
                      'Miktar',
                      position.size.toStringAsFixed(4),
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 35,
                    color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildCompactDetailItem(
                      'Değer',
                      '\$${_formatPrice(position.positionValue)}',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 35,
                    color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildCompactDetailItem(
                      'Giriş',
                      '\$${_formatPriceNoShorthand(position.entryPrice)}',
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // Fiyat bilgileri
            Container(
              padding: const EdgeInsets.all(10),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.4),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: _buildCompactDetailItem(
                      'Mevcut Fiyat',
                      '\$${_formatPriceNoShorthand(position.markPrice)}',
                    ),
                  ),
                  Container(
                    width: 1,
                    height: 35,
                    color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.3),
                  ),
                  Expanded(
                    child: _buildCompactDetailItem(
                      'Liq. Fiyat',
                      position.liquidationPrice > 0 
                          ? '\$${_formatPriceNoShorthand(position.liquidationPrice)}'
                          : 'N/A',
                    ),
                  ),
                ],
              ),
            ),
            
            const SizedBox(height: 8),
            
            // P&L kutusu
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
                        'Gerçekleşmemiş P&L',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: profitColor,
                        ),
                      ),
                    ],
                  ),
                  Text(
                    '${isProfit ? '+' : ''}\$${_formatPrice(position.unrealizedPnl)}',
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

  Widget _buildCompactDetailItem(String label, String value) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 10,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  String _formatPrice(double price) {
    final absPrice = price.abs();
    if (absPrice >= 1000000) {
      return '${(absPrice / 1000000).toStringAsFixed(2)}M';
    } else if (absPrice >= 1000) {
      return '${(absPrice / 1000).toStringAsFixed(2)}K';
    } else {
      return absPrice.toStringAsFixed(2);
    }
  }

  String _formatPriceNoShorthand(double price) {
    if (price >= 1000) {
      // Binlerden büyük sayılar için virgülsüz gösterim
      return price.toStringAsFixed(2);
    } else if (price >= 1) {
      return price.toStringAsFixed(2);
    } else {
      // 1'den küçük sayılar için daha fazla ondalık basamak
      return price.toStringAsFixed(4);
    }
  }
}
