import 'dart:async';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import '../models/position.dart';
import '../models/wallet.dart';
import '../services/hyperdash_service.dart';
import '../services/coingecko_service.dart';
import '../services/wallet_sync_service.dart';
import '../widgets/add_wallet_dialog.dart';
import 'portfolio_screen.dart';
import 'multi_portfolio_screen.dart';

class PositionsScreenDynamic extends StatefulWidget {
  const PositionsScreenDynamic({super.key});

  @override
  State<PositionsScreenDynamic> createState() => _PositionsScreenDynamicState();
}

class _PositionsScreenDynamicState extends State<PositionsScreenDynamic> {
  final HyperDashService _service = HyperDashService();
  final CoinGeckoService _coinGeckoService = CoinGeckoService();
  
  List<Wallet> _wallets = [];
  final Map<String, List<Position>> _walletPositions = {};
  final Map<String, bool> _walletExpandedStates = {};
  final Map<String, bool> _walletLoadingStates = {};
  
  Map<String, CryptoPrice> _cryptoPrices = {};
  bool _isPricesLoading = false;
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _loadWallets();
    _loadCryptoPrices();
    
    // Her 1 dakikada otomatik yenile
    _autoRefreshTimer = Timer.periodic(const Duration(minutes: 1), (timer) {
      _refreshAllWallets();
      _loadCryptoPrices();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    super.dispose();
  }

  Future<void> _loadWallets() async {
    final wallets = await Wallet.loadWallets();
    setState(() {
      _wallets = wallets;
      for (var wallet in wallets) {
        _walletExpandedStates[wallet.id] = false;
        _walletLoadingStates[wallet.id] = false;
        _walletPositions[wallet.id] = [];
      }
    });
    
    // Backend ile senkronize et
    await WalletSyncService.syncWallets(wallets);
    
    _refreshAllWallets();
  }

  Future<void> _refreshAllWallets() async {
    for (var wallet in _wallets) {
      await _loadWalletPositions(wallet.id, wallet.address);
    }
  }

  Future<void> _loadWalletPositions(String walletId, String address) async {
    setState(() {
      _walletLoadingStates[walletId] = true;
    });

    try {
      final positions = await _service.getOpenPositions(address);
      setState(() {
        _walletPositions[walletId] = positions;
        _walletLoadingStates[walletId] = false;
      });
    } catch (e) {
      setState(() {
        _walletLoadingStates[walletId] = false;
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

  Future<void> _showAddWalletDialog({Wallet? wallet}) async {
    final result = await showDialog<Wallet>(
      context: context,
      builder: (context) => AddWalletDialog(wallet: wallet),
    );

    if (result != null) {
      if (wallet == null) {
        // Yeni cüzdan
        final newOrder = _wallets.length;
        final newWallet = result.copyWith(order: newOrder);
        await Wallet.addWallet(newWallet);
      } else {
        // Güncelleme
        await Wallet.updateWallet(wallet.id, result);
      }
      await _loadWallets();
    }
  }

  Future<void> _deleteWallet(Wallet wallet) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Cüzdanı Sil'),
        content: Text('${wallet.name} cüzdanını silmek istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            child: const Text('Sil'),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      await Wallet.deleteWallet(wallet.id);
      await _loadWallets();
    }
  }

  @override
  Widget build(BuildContext context) {
    final btcPrice = _cryptoPrices['BTC'];
    final btcChange = btcPrice?.change24h ?? 0;
    final isBtcPositive = btcChange >= 0;
    
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
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
              Icons.bar_chart_rounded,
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
              await _refreshAllWallets();
              await _loadCryptoPrices();
            },
            tooltip: 'Yenile',
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: () async {
          await _refreshAllWallets();
          await _loadCryptoPrices();
        },
        child: _wallets.isEmpty
            ? Center(
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.account_balance_wallet_outlined,
                      size: 64,
                      color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
                    ),
                    const SizedBox(height: 16),
                    Text(
                      'Henüz cüzdan eklenmemiş',
                      style: TextStyle(
                        fontSize: 16,
                        color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                    const SizedBox(height: 8),
                    FilledButton.icon(
                      onPressed: () => _showAddWalletDialog(),
                      icon: const Icon(Icons.add),
                      label: const Text('İlk Cüzdanı Ekle'),
                    ),
                  ],
                ),
              )
            : ReorderableListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: _wallets.length + 2, // +2 for header widgets
                onReorder: (oldIndex, newIndex) async {
                  if (oldIndex < 2 || newIndex < 2) return; // Skip header widgets
                  await Wallet.reorderWallets(oldIndex - 2, newIndex - 2);
                  await _loadWallets();
                },
                itemBuilder: (context, index) {
                  if (index == 0) {
                    return _buildCryptoPricesWidget();
                  }
                  if (index == 1) {
                    return _buildPositionPricesWidget();
                  }
                  
                  final walletIndex = index - 2;
                  final wallet = _wallets[walletIndex];
                  return _buildWalletCard(wallet, key: ValueKey(wallet.id));
                },
              ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => _showAddWalletDialog(),
        tooltip: 'Yeni Cüzdan Ekle',
        child: const Icon(Icons.add),
      ),
    );
  }

  Widget _buildCryptoPricesWidget() {
    if (_cryptoPrices.isEmpty) {
      return Container(
        key: const ValueKey('crypto_prices'),
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surfaceContainerHighest.withOpacity(0.5),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Center(
          child: _isPricesLoading
              ? const CircularProgressIndicator()
              : const Text('Fiyatlar yüklenemedi'),
        ),
      );
    }

    final displayPrices = Map<String, CryptoPrice>.from(_cryptoPrices);
    displayPrices.remove('BTC');

    if (displayPrices.isEmpty) {
      return const SizedBox.shrink(key: ValueKey('crypto_prices_empty'));
    }

    return Container(
      key: const ValueKey('crypto_prices'),
      margin: const EdgeInsets.only(bottom: 16),
      padding: const EdgeInsets.all(12),
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
                  entry.key,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '\$${crypto.price.toStringAsFixed(2)}',
                  style: TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.bold,
                    color: Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                const SizedBox(height: 2),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      isPositive ? Icons.arrow_drop_up : Icons.arrow_drop_down,
                      color: changeColor,
                      size: 16,
                    ),
                    Text(
                      '${isPositive ? '+' : ''}${crypto.change24h.toStringAsFixed(2)}%',
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
    final allPositions = <Position>[];
    for (var positions in _walletPositions.values) {
      allPositions.addAll(positions);
    }

    if (allPositions.isEmpty) {
      return const SizedBox.shrink(key: ValueKey('position_prices_empty'));
    }

    final Map<String, double> uniqueCoins = {};
    for (var position in allPositions) {
      final coinSymbol = position.coin.replaceAll('USDT', '').replaceAll('PERP', '');
      if (!uniqueCoins.containsKey(coinSymbol)) {
        uniqueCoins[coinSymbol] = position.markPrice;
      }
    }

    final sortedCoins = uniqueCoins.entries.toList()
      ..sort((a, b) => a.key.compareTo(b.key));

    return Container(
      key: const ValueKey('position_prices'),
      margin: const EdgeInsets.only(bottom: 16),
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

  Widget _buildWalletCard(Wallet wallet, {required Key key}) {
    final positions = _walletPositions[wallet.id] ?? [];
    final isExpanded = _walletExpandedStates[wallet.id] ?? false;
    final isLoading = _walletLoadingStates[wallet.id] ?? false;

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
      final price = position.markPrice; // HyperDash API'sinden gelen güncel fiyat
      final positionValue = position.size.abs() * price;
      totalValue += positionValue;
      totalPnl += position.unrealizedPnl;
      
      // Marj hesaplama: Position Value / Leverage
      if (position.leverage > 0) {
        totalMargin += positionValue / position.leverage;
        avgLeverage += position.leverage;
      }
      
      // Long/Short sayımı
      if (position.side == 'LONG') {
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
      key: key,
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 4,
      shadowColor: wallet.color.withOpacity(0.3),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
        side: BorderSide(color: wallet.color.withOpacity(0.5), width: 2),
      ),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(20),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              wallet.color.withOpacity(0.05),
              wallet.color.withOpacity(0.02),
            ],
          ),
        ),
        child: InkWell(
          onTap: () {
            setState(() {
              _walletExpandedStates[wallet.id] = !isExpanded;
            });
          },
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
                        wallet.color.withOpacity(0.2),
                        wallet.color.withOpacity(0.1),
                      ],
                    ),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Row(
                    children: [
                      // Sürükle handle + Wallet icon
                      Row(
                        children: [
                          Icon(
                            Icons.drag_indicator,
                            color: wallet.color.withOpacity(0.5),
                            size: 20,
                          ),
                          const SizedBox(width: 4),
                          Container(
                            padding: const EdgeInsets.all(8),
                            decoration: BoxDecoration(
                              color: wallet.color.withOpacity(0.2),
                              borderRadius: BorderRadius.circular(10),
                              boxShadow: [
                                BoxShadow(
                                  color: wallet.color.withOpacity(0.3),
                                  blurRadius: 8,
                                  spreadRadius: 0,
                                ),
                              ],
                            ),
                            child: Icon(
                              Icons.account_balance_wallet,
                              color: wallet.color,
                              size: 20,
                            ),
                          ),
                        ],
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
                                    wallet.name,
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.bold,
                                      color: wallet.color,
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
                                Clipboard.setData(ClipboardData(text: wallet.address));
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
                                    backgroundColor: wallet.color,
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
                                    wallet.shortAddress,
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
                      // Edit ve Delete butonları
                      IconButton(
                        icon: Icon(Icons.edit, size: 16, color: wallet.color.withOpacity(0.7)),
                        onPressed: () => _showAddWalletDialog(wallet: wallet),
                        tooltip: 'Düzenle',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 4),
                      IconButton(
                        icon: Icon(Icons.delete, size: 16, color: Colors.red.shade400.withOpacity(0.7)),
                        onPressed: () => _deleteWallet(wallet),
                        tooltip: 'Sil',
                        padding: EdgeInsets.zero,
                        constraints: const BoxConstraints(),
                      ),
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: wallet.color.withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Icon(
                          isExpanded ? Icons.keyboard_arrow_up_rounded : Icons.keyboard_arrow_down_rounded,
                          size: 24,
                          color: wallet.color,
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
                            valueColor: AlwaysStoppedAnimation<Color>(wallet.color),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          'Yükleniyor...',
                          style: TextStyle(
                            color: wallet.color,
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
                      color: wallet.color.withOpacity(0.2),
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
                              color: wallet.color,
                            ),
                          ),
                          Expanded(
                            child: _buildEnhancedSummaryItem(
                              icon: Icons.account_balance_wallet_outlined,
                              label: 'Toplam Değer',
                              value: '\$${_formatPrice(totalValue)}',
                              color: wallet.color,
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
                      Divider(color: wallet.color.withOpacity(0.2), height: 1),
                      const SizedBox(height: 10),
                      Row(
                        children: [
                          Expanded(
                            child: _buildEnhancedSummaryItem(
                              icon: Icons.swap_vert,
                              label: 'Long/Short',
                              value: '$longCount / $shortCount',
                              color: wallet.color,
                              subtitle: longCount > shortCount ? '🟢 Bull' : shortCount > longCount ? '🔴 Bear' : '⚪',
                            ),
                          ),
                          Expanded(
                            child: _buildEnhancedSummaryItem(
                              icon: Icons.security,
                              label: 'Marj',
                              value: '\$${_formatPrice(totalMargin)}',
                              color: wallet.color,
                              subtitle: '${marginUsagePercent.toStringAsFixed(1)}%',
                            ),
                          ),
                          Expanded(
                            child: _buildEnhancedSummaryItem(
                              icon: Icons.speed,
                              label: 'Kaldıraç',
                              value: '${avgLeverage.toStringAsFixed(1)}x',
                              color: avgLeverage > 15 ? Colors.orange : wallet.color,
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
                          wallet.color.withOpacity(0.3),
                          Colors.transparent,
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  ...positions.map((position) => _buildPositionDetailTile(position, wallet.color)),
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

  Widget _buildPositionDetailTile(Position position, Color walletColor) {
    final price = position.markPrice; // HyperDash API'sinden gelen güncel fiyat
    final positionValue = position.size.abs() * price;
    final isPnlPositive = position.unrealizedPnl >= 0;
    final pnlColor = isPnlPositive ? Colors.green.shade400 : Colors.red.shade400;
    final isLong = position.side == 'LONG';
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
    final isLong = position.side == 'LONG';
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
    if (price >= 10000) {
      return price.toStringAsFixed(0);
    } else if (price >= 1000) {
      return price.toStringAsFixed(1);
    } else if (price >= 1) {
      return price.toStringAsFixed(2);
    } else {
      return price.toStringAsFixed(4);
    }
  }
}
