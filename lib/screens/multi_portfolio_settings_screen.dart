import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/multi_portfolio.dart';
import '../models/asset_suggestions.dart';
import '../widgets/add_asset_dialog.dart';

class MultiPortfolioSettingsScreen extends StatefulWidget {
  const MultiPortfolioSettingsScreen({super.key});

  @override
  State<MultiPortfolioSettingsScreen> createState() => _MultiPortfolioSettingsScreenState();
}

class _MultiPortfolioSettingsScreenState extends State<MultiPortfolioSettingsScreen> {
  List<PortfolioGroup> _portfolios = [];
  bool _isLoading = true;
  final Map<String, TextEditingController> _controllers = {};

  @override
  void initState() {
    super.initState();
    _loadPortfolios();
  }

  @override
  void dispose() {
    for (var controller in _controllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadPortfolios() async {
    setState(() {
      _isLoading = true;
    });

    final portfolios = await PortfolioItem.getPortfoliosWithSettings();
    
    // Initialize controllers
    for (var portfolio in portfolios) {
      for (var item in portfolio.items) {
        final key = '${portfolio.id}_${item.symbol}';
        _controllers[key] = TextEditingController(text: item.amount.toString());
      }
    }

    setState(() {
      _portfolios = portfolios;
      _isLoading = false;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();

    for (var portfolio in _portfolios) {
      for (var item in portfolio.items) {
        final key = '${portfolio.id}_${item.symbol}';
        final controller = _controllers[key];
        if (controller != null) {
          final value = double.tryParse(controller.text) ?? item.amount;
          await prefs.setDouble('${portfolio.id}_${item.symbol}_amount', value);
        }
      }
    }

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Ayarlar kaydedildi'),
          backgroundColor: Colors.green,
          duration: Duration(seconds: 2),
        ),
      );
      Navigator.pop(context, true);
    }
  }

  Future<void> _resetSettings() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Varsayılana Dön'),
        content: const Text('Tüm değerler varsayılan değerlere sıfırlanacak. Emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Sıfırla', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      final keys = prefs.getKeys().where((key) => key.contains('portfolio_') && key.contains('_amount')).toList();
      for (var key in keys) {
        await prefs.remove(key);
      }
      // Reset custom and hidden assets
      await prefs.remove('multi_portfolio_custom_assets');
      await prefs.remove('multi_portfolio_hidden_assets');

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Varsayılan değerlere sıfırlandı'),
            backgroundColor: Colors.orange,
          ),
        );
        _loadPortfolios();
      }
    }
  }
  
  Future<void> _addAsset(PortfolioGroup portfolio) async {
    if (!mounted) return;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => const AddAssetDialog(),
    );

    if (!mounted) return;
    
    if (result != null) {
      final assetType = result['type'];
      String typeEnum;
      if (assetType == 'crypto') {
        typeEnum = 'crypto';
      } else if (assetType == 'usStock' || assetType == 'bistStock') {
        typeEnum = 'stock';
      } else {
        typeEnum = 'cash';
      }

      final item = PortfolioItem(
        symbol: result['symbol'],
        name: result['name'],
        emoji: result['emoji'],
        amount: result['amount'],
        type: AssetType.values.firstWhere((e) => e.toString() == 'AssetType.$typeEnum'),
        coingeckoId: result['coingeckoId'],
      );

      await PortfolioItem.addCustomAsset(portfolio.id, item);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${result['symbol']} eklendi'),
            backgroundColor: Colors.green,
            duration: const Duration(seconds: 2),
          ),
        );
        await _loadPortfolios();
      }
    }
  }

  Future<void> _removeAsset(PortfolioGroup portfolio, PortfolioItem item) async {
    if (!mounted) return;
    
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Varlığı Kaldır'),
        content: Text('${item.symbol} varlığını kaldırmak istediğinizden emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Kaldır', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (!mounted) return;
    
    if (confirmed == true) {
      await PortfolioItem.removeAsset(portfolio.id, item.symbol);
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('${item.symbol} kaldırıldı'),
            backgroundColor: Colors.orange,
            duration: const Duration(seconds: 2),
          ),
        );
        await _loadPortfolios();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: const Text(
          'Portföy Ayarları',
          style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _resetSettings,
            tooltip: 'Varsayılana Dön',
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: _portfolios.length,
                    itemBuilder: (context, index) {
                      return _buildPortfolioCard(_portfolios[index]);
                    },
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      Expanded(
                        child: OutlinedButton(
                          onPressed: () => Navigator.pop(context),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: const Text('İptal'),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: _saveSettings,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            backgroundColor: Theme.of(context).colorScheme.primary,
                            foregroundColor: Colors.white,
                          ),
                          child: const Text('Kaydet'),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
    );
  }

  Widget _buildPortfolioCard(PortfolioGroup portfolio) {
    final color = _getColorForPortfolio(portfolio.id);

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
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
                Expanded(
                  child: Text(
                    portfolio.name,
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.add_circle_outline),
                  color: color,
                  onPressed: () => _addAsset(portfolio),
                  tooltip: 'Varlık Ekle',
                ),
              ],
            ),
            const SizedBox(height: 16),
            ...portfolio.items.map((item) => _buildAssetField(portfolio, item)),
          ],
        ),
      ),
    );
  }

  Widget _buildAssetField(PortfolioGroup portfolio, PortfolioItem item) {
    final key = '${portfolio.id}_${item.symbol}';
    final controller = _controllers[key];
    final isCash = item.type == AssetType.cash;

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(item.emoji, style: const TextStyle(fontSize: 16)),
              const SizedBox(width: 8),
              Text(
                item.symbol,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(width: 4),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                decoration: BoxDecoration(
                  color: _getTypeColor(item.type).withOpacity(0.1),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  _getTypeLabel(item.type),
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.bold,
                    color: _getTypeColor(item.type),
                  ),
                ),
              ),
              const Spacer(),
              IconButton(
                icon: const Icon(Icons.delete_outline, size: 18),
                color: Colors.red.shade400,
                onPressed: () => _removeAsset(portfolio, item),
                tooltip: 'Kaldır',
                padding: EdgeInsets.zero,
                constraints: const BoxConstraints(),
              ),
            ],
          ),
          const SizedBox(height: 8),
          TextField(
            controller: controller,
            keyboardType: const TextInputType.numberWithOptions(decimal: true),
            decoration: InputDecoration(
              labelText: isCash ? 'Bakiye (TL)' : 'Miktar',
              hintText: isCash ? '500000' : '0.0',
              border: const OutlineInputBorder(),
              suffixText: isCash ? 'TL' : item.symbol,
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 12),
            ),
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

  Color _getTypeColor(AssetType type) {
    switch (type) {
      case AssetType.crypto: return Colors.blue.shade600;
      case AssetType.stock: return Colors.purple.shade600;
      case AssetType.cash: return Colors.green.shade600;
    }
  }

  String _getTypeLabel(AssetType type) {
    switch (type) {
      case AssetType.crypto: return 'Crypto';
      case AssetType.stock: return 'Stock';
      case AssetType.cash: return 'Cash';
    }
  }
}
