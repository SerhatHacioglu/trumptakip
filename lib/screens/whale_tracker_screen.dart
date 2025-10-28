import 'dart:async';
import 'package:flutter/material.dart';
import '../models/position.dart';
import '../models/wallet.dart';
import '../services/hyperdash_service.dart';
import '../config/wallet_config.dart';

class WhaleTrackerScreen extends StatefulWidget {
  const WhaleTrackerScreen({super.key});

  @override
  State<WhaleTrackerScreen> createState() => _WhaleTrackerScreenState();
}

class _WhaleTrackerScreenState extends State<WhaleTrackerScreen> with SingleTickerProviderStateMixin {
  final HyperDashService _service = HyperDashService();
  late TabController _tabController;
  
  Map<String, List<Position>> _walletPositions = {};
  Map<String, bool> _walletLoading = {};
  Map<String, String?> _walletErrors = {};
  Timer? _autoRefreshTimer;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: WalletConfig.wallets.length, vsync: this);
    
    // Initialize
    for (var wallet in WalletConfig.wallets) {
      _walletPositions[wallet.address] = [];
      _walletLoading[wallet.address] = false;
      _walletErrors[wallet.address] = null;
    }
    
    // Load all wallets
    _loadAllWallets();
    
    // Auto refresh every 30 seconds
    _autoRefreshTimer = Timer.periodic(const Duration(seconds: 30), (timer) {
      _loadAllWallets();
    });
  }

  @override
  void dispose() {
    _autoRefreshTimer?.cancel();
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _loadAllWallets() async {
    for (var wallet in WalletConfig.wallets) {
      await _loadWalletPositions(wallet);
    }
  }

  Future<void> _loadWalletPositions(Wallet wallet) async {
    setState(() {
      _walletLoading[wallet.address] = true;
      _walletErrors[wallet.address] = null;
    });

    try {
      final positions = await _service.getOpenPositions(wallet.address);
      setState(() {
        _walletPositions[wallet.address] = positions;
        _walletLoading[wallet.address] = false;
      });
    } catch (e) {
      setState(() {
        _walletErrors[wallet.address] = e.toString();
        _walletLoading[wallet.address] = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Text(
          '🐋 Whale Tracker',
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Theme.of(context).colorScheme.onSurface,
          ),
        ),
        actions: [
          IconButton(
            icon: Icon(
              Icons.refresh_rounded,
              color: Theme.of(context).colorScheme.onSurface,
            ),
            onPressed: _loadAllWallets,
            tooltip: 'Tümünü Yenile',
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          indicatorColor: Theme.of(context).colorScheme.primary,
          labelColor: Theme.of(context).colorScheme.onSurface,
          unselectedLabelColor: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          tabs: WalletConfig.wallets.map((wallet) {
            final positions = _walletPositions[wallet.address] ?? [];
            return Tab(
              child: Row(
                children: [
                  if (wallet.isMain) 
                    Icon(Icons.account_balance_wallet, size: 16)
                  else
                    Icon(Icons.waves, size: 16),
                  const SizedBox(width: 6),
                  Text(wallet.name),
                  const SizedBox(width: 6),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: positions.isNotEmpty 
                          ? Theme.of(context).colorScheme.primaryContainer
                          : Theme.of(context).colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(
                      '${positions.length}',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: positions.isNotEmpty
                            ? Theme.of(context).colorScheme.onPrimaryContainer
                            : Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: WalletConfig.wallets.map((wallet) {
          return _buildWalletView(wallet);
        }).toList(),
      ),
    );
  }

  Widget _buildWalletView(Wallet wallet) {
    final isLoading = _walletLoading[wallet.address] ?? false;
    final error = _walletErrors[wallet.address];
    final positions = _walletPositions[wallet.address] ?? [];

    if (isLoading && positions.isEmpty) {
      return Center(
        child: CircularProgressIndicator(
          strokeWidth: 3,
          color: Theme.of(context).colorScheme.primary.withOpacity(0.5),
        ),
      );
    }

    if (error != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(32),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                size: 64,
                color: Colors.red.shade400,
              ),
              const SizedBox(height: 16),
              Text(
                'Bir Hata Oluştu',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).colorScheme.onSurface,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                error,
                style: TextStyle(
                  color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                  fontSize: 14,
                ),
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 24),
              ElevatedButton.icon(
                onPressed: () => _loadWalletPositions(wallet),
                icon: const Icon(Icons.refresh),
                label: const Text('Tekrar Dene'),
              ),
            ],
          ),
        ),
      );
    }

    if (positions.isEmpty) {
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.inbox_outlined,
              size: 64,
              color: Theme.of(context).colorScheme.onSurface.withOpacity(0.4),
            ),
            const SizedBox(height: 16),
            Text(
              'Açık Pozisyon Yok',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              wallet.shortAddress,
              style: TextStyle(
                color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                fontSize: 12,
                fontFamily: 'monospace',
              ),
            ),
          ],
        ),
      );
    }

    // Calculate total stats
    double totalPnl = 0;
    double totalValue = 0;
    for (var pos in positions) {
      totalPnl += pos.unrealizedPnl;
      totalValue += pos.positionValue;
    }

    return RefreshIndicator(
      onRefresh: () => _loadWalletPositions(wallet),
      child: Stack(
        children: [
          ListView.builder(
            padding: const EdgeInsets.all(8),
            itemCount: positions.length + 1,
            itemBuilder: (context, index) {
              if (index == 0) {
                return _buildWalletSummaryCard(wallet, positions, totalPnl, totalValue);
              }
              return _buildPositionCard(positions[index - 1], wallet.isMain);
            },
          ),
          if (isLoading)
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

  Widget _buildWalletSummaryCard(Wallet wallet, List<Position> positions, double totalPnl, double totalValue) {
    final isProfitable = totalPnl >= 0;
    final bigPositions = positions.where((p) => p.positionValue > 1000000).length;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(
          color: Theme.of(context).colorScheme.outlineVariant.withOpacity(0.5),
          width: 1,
        ),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(
                  wallet.isMain ? Icons.account_balance_wallet : Icons.waves,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 8),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        wallet.name,
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Theme.of(context).colorScheme.onSurface,
                        ),
                      ),
                      Text(
                        wallet.shortAddress,
                        style: TextStyle(
                          fontSize: 11,
                          color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Row(
              children: [
                Expanded(
                  child: _buildStatItem(
                    '📊 Pozisyon',
                    '${positions.length}',
                    Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    '💎 Toplam Değer',
                    '\$${_formatNumber(totalValue)}',
                    Theme.of(context).colorScheme.onSurface,
                  ),
                ),
                Expanded(
                  child: _buildStatItem(
                    isProfitable ? '💚 P&L' : '❤️ P&L',
                    '${isProfitable ? '+' : ''}\$${_formatNumber(totalPnl)}',
                    isProfitable ? Colors.green.shade400 : Colors.red.shade400,
                  ),
                ),
              ],
            ),
            if (!wallet.isMain && bigPositions > 0) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(8),
                decoration: BoxDecoration(
                  color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.warning_amber_rounded,
                      size: 16,
                      color: Theme.of(context).colorScheme.onPrimaryContainer,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      '$bigPositions BÜYÜK POZİSYON (\$1M+)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }

  Widget _buildStatItem(String label, String value, Color valueColor) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 11,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.6),
          ),
        ),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold,
            color: valueColor,
          ),
        ),
      ],
    );
  }

  Widget _buildPositionCard(Position position, bool isMain) {
    final isProfitable = position.unrealizedPnl >= 0;
    final isBig = position.positionValue > 1000000;
    
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
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
            Row(
              children: [
                if (isBig)
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: Theme.of(context).colorScheme.primaryContainer,
                      borderRadius: BorderRadius.circular(4),
                    ),
                    child: Text(
                      '🐋 WHALE',
                      style: TextStyle(
                        fontSize: 9,
                        fontWeight: FontWeight.bold,
                        color: Theme.of(context).colorScheme.onPrimaryContainer,
                      ),
                    ),
                  ),
                if (isBig) const SizedBox(width: 6),
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
                    color: position.side == 'LONG' ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: Text(
                    position.side,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: position.side == 'LONG' ? Colors.green.shade400 : Colors.red.shade400,
                    ),
                  ),
                ),
                const Spacer(),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isProfitable ? Colors.green.withOpacity(0.15) : Colors.red.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(
                    '${isProfitable ? '+' : ''}\$${_formatNumber(position.unrealizedPnl)}',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                      color: isProfitable ? Colors.green.shade400 : Colors.red.shade400,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 8),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Miktar: ${position.size.toStringAsFixed(4)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
                if (isBig)
                  Text(
                    'Değer: \$${_formatNumber(position.positionValue)}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: Theme.of(context).colorScheme.primary,
                    ),
                  ),
              ],
            ),
            const SizedBox(height: 4),
            Row(
              children: [
                Expanded(
                  child: Text(
                    'Giriş: \$${_formatPrice(position.entryPrice)}',
                    style: TextStyle(
                      fontSize: 11,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                    ),
                  ),
                ),
                Text(
                  'Anlık: \$${_formatPrice(position.markPrice)}',
                  style: TextStyle(
                    fontSize: 11,
                    color: Theme.of(context).colorScheme.onSurface.withOpacity(0.7),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _formatNumber(double value) {
    if (value.abs() >= 1000000) {
      return '${(value / 1000000).toStringAsFixed(2)}M';
    } else if (value.abs() >= 1000) {
      return '${(value / 1000).toStringAsFixed(2)}K';
    }
    return value.toStringAsFixed(2);
  }

  String _formatPrice(double price) {
    if (price >= 1000) {
      return price.toStringAsFixed(0);
    } else if (price >= 1) {
      return price.toStringAsFixed(2);
    } else {
      return price.toStringAsFixed(4);
    }
  }
}
