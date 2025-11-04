import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/position.dart';
import '../services/hyperdash_service.dart';
import '../services/coingecko_service.dart';
import 'portfolio_screen.dart';
import 'multi_portfolio_screen.dart';

class PositionsScreen extends StatefulWidget {
  const PositionsScreen({super.key});

  @override
  State<PositionsScreen> createState() => _PositionsScreenState();
}

class _PositionsScreenState extends State<PositionsScreen> {
  final HyperDashService _service = HyperDashService();
  final CoinGeckoService _coinGeckoService = CoinGeckoService();
  
  // Cüzdan 1
  final String wallet1Address = '0xc2a30212a8ddac9e123944d6e29faddce994e5f2';
  List<Position> _wallet1Positions = [];
  bool _isWallet1Expanded = false;
  bool _isWallet1Loading = false;
  
  // Cüzdan 2
  final String wallet2Address = '0xb317d2bc2d3d2df5fa441b5bae0ab9d8b07283ae';
  List<Position> _wallet2Positions = [];
  bool _isWallet2Expanded = false;
  bool _isWallet2Loading = false;
  
  Map<String, CryptoPrice> _cryptoPrices = {};
  bool _isPricesLoading = false;
  String? _error;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadWallet1Positions();
    _loadWallet2Positions();
    _loadCryptoPrices();
    
    // Her 1 dakikada otomatik yenile
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _loadWallet1Positions();
      _loadWallet2Positions();
      _loadCryptoPrices();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadWallet1Positions() async {
    setState(() {
      _isWallet1Loading = true;
      _error = null;
    });

    try {
      final positions = await _service.getOpenPositions(wallet1Address);
      setState(() {
        _wallet1Positions = positions;
        _isWallet1Loading = false;
      });
    } catch (e) {
      setState(() {
        _error = e.toString();
        _isWallet1Loading = false;
      });
    }
  }

  Future<void> _loadWallet2Positions() async {
    setState(() {
      _isWallet2Loading = true;
    });

    try {
      final positions = await _service.getOpenPositions(wallet2Address);
      setState(() {
        _wallet2Positions = positions;
        _isWallet2Loading = false;
      });
    } catch (e) {
      setState(() {
        _isWallet2Loading = false;
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
              Icons.folder_open,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const MultiPortfolioScreen()),
              );
            },
            tooltip: 'Trader Takip',
          ),
          IconButton(
            icon: Icon(
              Icons.account_balance_wallet,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const PortfolioScreen()),
              );
            },
            tooltip: 'Kişisel Portföy',
          ),
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: () async {
              await _loadWallet1Positions();
              await _loadWallet2Positions();
            },
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: _buildBody(),
    );
  }

  Widget _buildBody() {
    return RefreshIndicator(
      onRefresh: () async {
        await _loadWallet1Positions();
        await _loadWallet2Positions();
        await _loadCryptoPrices();
      },
      child: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          _buildCryptoPricesWidget(),
          const SizedBox(height: 12),
          _buildPositionPricesWidget(),
          const SizedBox(height: 16),
          
          // Cüzdan 1
          _buildWalletCard(
            walletName: 'Cüzdan 1',
            walletAddress: wallet1Address,
            positions: _wallet1Positions,
            isExpanded: _isWallet1Expanded,
            isLoading: _isWallet1Loading,
            onExpandToggle: () {
              setState(() {
                _isWallet1Expanded = !_isWallet1Expanded;
              });
            },
            color: Colors.blue,
          ),
          
          const SizedBox(height: 16),
          
          // Cüzdan 2
          _buildWalletCard(
            walletName: 'Cüzdan 2',
            walletAddress: wallet2Address,
            positions: _wallet2Positions,
            isExpanded: _isWallet2Expanded,
            isLoading: _isWallet2Loading,
            onExpandToggle: () {
              setState(() {
                _isWallet2Expanded = !_isWallet2Expanded;
              });
            },
            color: Colors.purple,
          ),
        ],
      ),
    );
  }

  Widget _buildCryptoPricesWidget() {
    if (_cryptoPrices.isEmpty) {
      return Container(
        margin: const EdgeInsets.fromLTRB(16, 8, 16, 8),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: _isPricesLoading
              ? Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    SizedBox(
                      width: 16,
                      height: 16,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 8),
                    Text(
                      'Fiyatlar yükleniyor...',
                      style: TextStyle(
                        fontSize: 12,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                )
              : Text(
                  'Fiyatlar yüklenemedi',
                  style: TextStyle(
                    fontSize: 12,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
        ),
      );
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

  Widget _buildPositionPricesWidget() {
    // Her iki cüzdandaki tüm pozisyonları topla
    final allPositions = <Position>[
      ..._wallet1Positions,
      ..._wallet2Positions,
    ];

    if (allPositions.isEmpty) {
      return const SizedBox.shrink();
    }

    // Coin'leri unique yap ve fiyatları topla
    final Map<String, double> uniqueCoins = {};
    for (var position in allPositions) {
      final coinSymbol = position.coin.replaceAll('USDT', '').replaceAll('PERP', '');
      if (!uniqueCoins.containsKey(coinSymbol)) {
        uniqueCoins[coinSymbol] = position.markPrice;
      }
    }

    // Coin'leri alfabetik sırala
    final sortedCoins = uniqueCoins.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      margin: const EdgeInsets.fromLTRB(16, 0, 16, 0),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            Theme.of(context).colorScheme.primaryContainer.withOpacity(0.3),
            Theme.of(context).colorScheme.secondaryContainer.withOpacity(0.2),
          ],
        ),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Theme.of(context).colorScheme.outline.withOpacity(0.2),
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.trending_up,
                size: 16,
                color: Theme.of(context).colorScheme.primary,
              ),
              const SizedBox(width: 6),
              Text(
                'Açık Pozisyon Fiyatları',
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: sortedCoins.map((entry) {
              return Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.surface.withOpacity(0.6),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: Theme.of(context).colorScheme.outline.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      entry.key,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '\$${entry.value.toStringAsFixed(2)}',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w600,
                        color: Theme.of(context).colorScheme.onSurface,
                      ),
                    ),
                  ],
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildSummaryCard() {
    // Bu metod artık kullanılmıyor
    double totalPnl = 0;
    double totalValue = 0;
    final dummyPositions = <Position>[];
    for (var position in dummyPositions) {
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
                          '${dummyPositions.length}',
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

  // ignore: unused_element
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

  Widget _buildWalletCard({
    required String walletName,
    required String walletAddress,
    required List<Position> positions,
    required bool isExpanded,
    required bool isLoading,
    required VoidCallback onExpandToggle,
    required Color color,
  }) {
    // Toplam PnL ve diğer metrikleri hesapla
    double totalPnl = 0;
    double totalValue = 0;
    double totalMargin = 0;
    int longCount = 0;
    int shortCount = 0;
    double avgLeverage = 0;
    Position? topGainer;
    double topGainPnl = double.negativeInfinity;
    
    for (var position in positions) {
      final price = _cryptoPrices[position.coin]?.price ?? 0;
      final positionValue = position.size.abs() * price;
      totalValue += positionValue;
      totalPnl += position.unrealizedPnl;
      
      // Marj hesaplama: Position Value / Leverage
      if (position.leverage > 0) {
        totalMargin += positionValue / position.leverage;
        avgLeverage += position.leverage;
      }
      
      // Long/Short sayımı
      if (position.size > 0) {
        longCount++;
      } else {
        shortCount++;
      }
      
      // En karlı pozisyon
      if (position.unrealizedPnl > topGainPnl) {
        topGainPnl = position.unrealizedPnl;
        topGainer = position;
      }
    }
    
    if (positions.isNotEmpty && avgLeverage > 0) {
      avgLeverage = avgLeverage / positions.length;
    }
    
    final isPnlPositive = totalPnl >= 0;
    final pnlColor = isPnlPositive ? Colors.green.shade400 : Colors.red.shade400;
    final marginUsagePercent = totalValue > 0 ? (totalMargin / totalValue * 100) : 0.0;

    return Card(
      elevation: 4,
      shadowColor: color.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: color.withOpacity(0.5), width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              color.withOpacity(0.05),
              color.withOpacity(0.02),
            ],
          ),
        ),
        child: InkWell(
          onTap: onExpandToggle,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with gradient
                Container(
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        color.withOpacity(0.2),
                        color.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.2),
                          borderRadius: BorderRadius.circular(10),
                          boxShadow: [
                            BoxShadow(
                              color: color.withOpacity(0.3),
                              blurRadius: 8,
                              spreadRadius: 0,
                            ),
                          ],
                        ),
                        child: Icon(
                          Icons.account_balance_wallet,
                          color: color,
                          size: 20,
                        ),
                      ),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Flexible(
                                  child: Text(
                                    walletName,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: color,
                                    ),
                                    overflow: TextOverflow.ellipsis,
                                  ),
                                ),
                                if (positions.isNotEmpty && avgLeverage > 15) ...[
                                  const SizedBox(width: 6),
                                  Container(
                                    padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.orange.withOpacity(0.2),
                                      borderRadius: BorderRadius.circular(4),
                                      border: Border.all(color: Colors.orange, width: 1),
                                    ),
                                    child: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.warning_amber, size: 10, color: Colors.orange),
                                        const SizedBox(width: 2),
                                        Text(
                                          'Risk',
                                          style: TextStyle(
                                            fontSize: 8,
                                            fontWeight: FontWeight.bold,
                                            color: Colors.orange,
                                          ),
                                        ),
                                      ],
                                    ),
                                  ),
                                ],
                              ],
                            ),
                            const SizedBox(height: 3),
                            GestureDetector(
                              onTap: () {
                                Clipboard.setData(ClipboardData(text: walletAddress));
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Row(
                                      mainAxisSize: MainAxisSize.min,
                                      children: [
                                        Icon(Icons.check_circle, color: Colors.white, size: 16),
                                        const SizedBox(width: 8),
                                        const Text('Adres kopyalandı'),
                                      ],
                                    ),
                                    duration: const Duration(seconds: 2),
                                    behavior: SnackBarBehavior.floating,
                                    backgroundColor: color,
                                    shape: RoundedRectangleBorder(
                                      borderRadius: BorderRadius.circular(10),
                                    ),
                                  ),
                                );
                              },
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Icon(
                                    Icons.circle,
                                    size: 5,
                                    color: Colors.green.shade400,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${walletAddress.substring(0, 6)}...${walletAddress.substring(walletAddress.length - 4)}',
                                    style: TextStyle(
                                      fontSize: 10,
                                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                  const SizedBox(width: 3),
                                  Icon(
                                    Icons.copy_rounded,
                                    size: 10,
                                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 24,
                          color: color,
                        ),
                      ),
                    ],
                  ),
                ),
              
              const SizedBox(height: 12),
              
              // Özet Bilgiler
              if (isLoading)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        SizedBox(
                          width: 32,
                          height: 32,
                          child: CircularProgressIndicator(
                            strokeWidth: 3,
                            valueColor: AlwaysStoppedAnimation<Color>(color),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Yükleniyor...',
                          style: TextStyle(
                            color: color,
                            fontSize: 11,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else if (positions.isEmpty)
                Center(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      children: [
                        Icon(
                          Icons.inbox_outlined,
                          size: 40,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.3),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          'Açık pozisyon yok',
                          style: TextStyle(
                            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                            fontSize: 12,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                )
              else ...[
                // Top Gainer Badge
                if (topGainer != null && topGainPnl > 0) ...[
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.amber.withOpacity(0.2),
                          Colors.orange.withOpacity(0.1),
                        ],
                      ),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.amber.withOpacity(0.5), width: 1.5),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(Icons.local_fire_department, color: Colors.orange, size: 14),
                        const SizedBox(width: 4),
                        Flexible(
                          child: Text(
                            'En Karlı: ${topGainer.coin} ',
                            style: const TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        Text(
                          '+\$${_formatPrice(topGainPnl)}',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.green.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 10),
                ],
                
                // Statistics Cards
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
                    borderRadius: BorderRadius.circular(10),
                    border: Border.all(
                      color: color.withOpacity(0.2),
                      width: 1,
                    ),
                  ),
                  child: Column(
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: _buildEnhancedSummaryItem(
                              icon: Icons.assessment_outlined,
                              label: 'Pozisyon',
                              value: '${positions.length}',
                              color: color,
                            ),
                          ),
                          Expanded(
                            child: _buildEnhancedSummaryItem(
                              icon: Icons.account_balance_wallet_outlined,
                              label: 'Toplam Değer',
                              value: '\$${_formatPrice(totalValue)}',
                              color: color,
                            ),
                          ),
                          Expanded(
                            child: _buildEnhancedSummaryItem(
                              icon: isPnlPositive ? Icons.trending_up : Icons.trending_down,
                              label: 'PnL',
                              value: '${isPnlPositive ? '+' : ''}\$${_formatPrice(totalPnl)}',
                              color: pnlColor,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 10),
                      Divider(color: color.withOpacity(0.2), height: 1),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildEnhancedSummaryItem(
                              icon: Icons.swap_vert,
                              label: 'Long/Short',
                              value: '$longCount / $shortCount',
                              color: color,
                              subtitle: longCount > shortCount ? '🟢 Bull' : shortCount > longCount ? '🔴 Bear' : '⚪',
                            ),
                          ),
                          Expanded(
                            child: _buildEnhancedSummaryItem(
                              icon: Icons.security,
                              label: 'Marj',
                              value: '\$${_formatPrice(totalMargin)}',
                              color: color,
                              subtitle: '${marginUsagePercent.toStringAsFixed(1)}%',
                            ),
                          ),
                          Expanded(
                            child: _buildEnhancedSummaryItem(
                              icon: Icons.speed,
                              label: 'Kaldıraç',
                              value: '${avgLeverage.toStringAsFixed(1)}x',
                              color: avgLeverage > 15 ? Colors.orange : color,
                              subtitle: avgLeverage > 15 ? '⚠️' : avgLeverage > 10 ? '⚡' : '✓',
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                
                // Genişletilmiş detaylar
                if (isExpanded) ...[
                  const SizedBox(height: 12),
                  Container(
                    height: 2,
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        colors: [
                          Colors.transparent,
                          color.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...positions.map((position) => _buildPositionDetailTile(position, color)),
                ],
              ],
            ],
          ),
        ),
      ),
    ),
    );
  }

  Widget _buildEnhancedSummaryItem({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
    String? subtitle,
  }) {
    return Column(
      children: [
        Icon(icon, size: 15, color: color.withOpacity(0.7)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w500,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 12,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        if (subtitle != null) ...[
          const SizedBox(height: 2),
          Text(
            subtitle,
            style: TextStyle(
              fontSize: 8,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
              fontWeight: FontWeight.w500,
            ),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ],
    );
  }

  // ignore: unused_element
  Widget _buildSummaryItem(String label, String value, Color color) {
    return Column(
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: color,
          ),
        ),
      ],
    );
  }

  Widget _buildPositionDetailTile(Position position, Color walletColor) {
    final price = _cryptoPrices[position.coin]?.price ?? 0;
    final positionValue = position.size.abs() * price;
    final isPnlPositive = position.unrealizedPnl >= 0;
    final pnlColor = isPnlPositive ? Colors.green.shade400 : Colors.red.shade400;
    final isLong = position.size > 0;
    final pnlPercentage = position.entryPrice > 0 
        ? ((price - position.entryPrice) / position.entryPrice * 100) * (isLong ? 1 : -1)
        : 0.0;

    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [
            walletColor.withOpacity(0.03),
            Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          ],
        ),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: isPnlPositive 
              ? Colors.green.withOpacity(0.3)
              : Colors.red.withOpacity(0.3),
          width: 1.5,
        ),
      ),
      child: Column(
        children: [
          // Header Row
          Row(
            children: [
              // Coin badge
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: walletColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(10),
                  border: Border.all(
                    color: walletColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Text(
                  position.coin.substring(0, position.coin.length > 3 ? 3 : position.coin.length),
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                    color: walletColor,
                  ),
                ),
              ),
              const SizedBox(width: 8),
              
              // Coin info
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Wrap(
                      spacing: 4,
                      runSpacing: 4,
                      children: [
                        Text(
                          position.coin,
                          style: const TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 5, vertical: 2),
                          decoration: BoxDecoration(
                            color: isLong ? Colors.green : Colors.red,
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            isLong ? 'LONG' : 'SHORT',
                            style: const TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: position.leverage > 15 
                                ? Colors.orange.withOpacity(0.2)
                                : walletColor.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: Text(
                            '${position.leverage.toStringAsFixed(1)}x',
                            style: TextStyle(
                              fontSize: 8,
                              fontWeight: FontWeight.bold,
                              color: position.leverage > 15 ? Colors.orange : walletColor,
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 3),
                    Text(
                      '\$${_formatPriceNoShorthand(price)}',
                      style: TextStyle(
                        fontSize: 10,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ],
                ),
              ),
              
              // PnL Box
              Container(
                padding: const EdgeInsets.all(7),
                decoration: BoxDecoration(
                  color: pnlColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: pnlColor.withOpacity(0.3),
                    width: 1,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      '\$${_formatPrice(positionValue)}',
                      style: const TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    Text(
                      '${isPnlPositive ? '+' : ''}\$${_formatPrice(position.unrealizedPnl)}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: pnlColor,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 3, vertical: 1),
                      decoration: BoxDecoration(
                        color: pnlColor.withOpacity(0.2),
                        borderRadius: BorderRadius.circular(3),
                      ),
                      child: Text(
                        '${isPnlPositive ? '+' : ''}${pnlPercentage.toStringAsFixed(1)}%',
                        style: TextStyle(
                          fontSize: 8,
                          fontWeight: FontWeight.bold,
                          color: pnlColor,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          
          const SizedBox(height: 8),
          
          // Details Row
          Container(
            padding: const EdgeInsets.all(8),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.surface.withOpacity(0.5),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceEvenly,
              children: [
                Expanded(
                  child: _buildEnhancedDetailInfo(
                    icon: Icons.layers,
                    label: 'Miktar',
                    value: position.size.abs().toStringAsFixed(2),
                    color: walletColor,
                  ),
                ),
                Container(width: 1, height: 30, color: walletColor.withOpacity(0.2)),
                Expanded(
                  child: _buildEnhancedDetailInfo(
                    icon: Icons.login,
                    label: 'Giriş',
                    value: '\$${_formatPriceNoShorthand(position.entryPrice)}',
                    color: Colors.blue,
                  ),
                ),
                Container(width: 1, height: 30, color: walletColor.withOpacity(0.2)),
                Expanded(
                  child: _buildEnhancedDetailInfo(
                    icon: Icons.warning_amber,
                    label: 'Liq.',
                    value: '\$${_formatPriceNoShorthand(position.liquidationPrice)}',
                    color: Colors.orange,
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 6),
          _buildRiskIndicator(position, price, walletColor),
        ],
      ),
    );
  }

  Widget _buildEnhancedDetailInfo({
    required IconData icon,
    required String label,
    required String value,
    required Color color,
  }) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Icon(icon, size: 13, color: color.withOpacity(0.7)),
        const SizedBox(height: 4),
        Text(
          label,
          style: TextStyle(
            fontSize: 9,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
            fontWeight: FontWeight.w600,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        const SizedBox(height: 3),
        Text(
          value,
          style: TextStyle(
            fontSize: 10,
            fontWeight: FontWeight.bold,
            color: color,
          ),
          textAlign: TextAlign.center,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
      ],
    );
  }

  Widget _buildRiskIndicator(Position position, double currentPrice, Color walletColor) {
    final isLong = position.size > 0;
    final liqPrice = position.liquidationPrice;
    
    // Calculate distance to liquidation
    double distancePercent;
    if (isLong) {
      distancePercent = ((currentPrice - liqPrice) / currentPrice * 100);
    } else {
      distancePercent = ((liqPrice - currentPrice) / currentPrice * 100);
    }
    
    // Determine risk level
    Color riskColor;
    String riskText;
    IconData riskIcon;
    
    if (distancePercent > 50) {
      riskColor = Colors.green;
      riskText = 'Güvenli';
      riskIcon = Icons.check_circle;
    } else if (distancePercent > 25) {
      riskColor = Colors.orange;
      riskText = 'Orta';
      riskIcon = Icons.warning;
    } else {
      riskColor = Colors.red;
      riskText = 'Yüksek';
      riskIcon = Icons.error;
    }
    
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
      decoration: BoxDecoration(
        color: riskColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(6),
        border: Border.all(
          color: riskColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(riskIcon, size: 12, color: riskColor),
          const SizedBox(width: 4),
          Text(
            'Risk: ',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
              fontWeight: FontWeight.w500,
            ),
          ),
          Text(
            riskText,
            style: TextStyle(
              fontSize: 10,
              color: riskColor,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(width: 6),
          Text(
            '•',
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              'Liq\'e ${distancePercent.abs().toStringAsFixed(1)}%',
              style: TextStyle(
                fontSize: 9,
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontWeight: FontWeight.w500,
              ),
              overflow: TextOverflow.ellipsis,
            ),
          ),
        ],
      ),
    );
  }

  // ignore: unused_element
  Widget _buildDetailInfo(String label, String value) {
    return Expanded(
      child: Column(
        children: [
          Text(
            label,
            style: TextStyle(
              fontSize: 10,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.5),
            ),
          ),
          const SizedBox(height: 4),
          Text(
            value,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w600,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            textAlign: TextAlign.center,
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ],
      ),
    );
  }
}

