import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/portfolio_asset.dart';
import '../widgets/add_asset_dialog.dart';

class PortfolioSettingsScreen extends StatefulWidget {
  const PortfolioSettingsScreen({super.key});

  @override
  State<PortfolioSettingsScreen> createState() => _PortfolioSettingsScreenState();
}

class _PortfolioSettingsScreenState extends State<PortfolioSettingsScreen> {
  final Map<String, TextEditingController> _amountControllers = {};
  final Map<String, TextEditingController> _investedControllers = {};
  List<PortfolioAsset> _assets = [];
  bool _hasChanges = false;

  @override
  void initState() {
    super.initState();
    _loadSettings();
  }

  @override
  void dispose() {
    for (var controller in _amountControllers.values) {
      controller.dispose();
    }
    for (var controller in _investedControllers.values) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _loadSettings() async {
    final assets = await PortfolioAsset.getAssetsWithSettings();
    
    for (var asset in assets) {
      _amountControllers[asset.symbol] = TextEditingController(
        text: asset.amount.toStringAsFixed(4),
      );
      _investedControllers[asset.symbol] = TextEditingController(
        text: asset.investedTRY.toStringAsFixed(0),
      );
    }
    
    setState(() {
      _assets = assets;
    });
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    // Save default assets settings
    for (var asset in _assets.where((a) => !a.isCustom)) {
      final symbol = asset.symbol;
      final amount = double.tryParse(_amountControllers[symbol]?.text ?? '0') ?? 0;
      final invested = double.tryParse(_investedControllers[symbol]?.text ?? '0') ?? 0;
      
      await prefs.setDouble('amount_$symbol', amount);
      await prefs.setDouble('invested_$symbol', invested);
    }
    
    // Save custom assets with updated values
    final customAssets = _assets.where((a) => a.isCustom).map((asset) {
      final symbol = asset.symbol;
      final amount = double.tryParse(_amountControllers[symbol]?.text ?? '0') ?? asset.amount;
      final invested = double.tryParse(_investedControllers[symbol]?.text ?? '0') ?? asset.investedTRY;
      
      return PortfolioAsset(
        symbol: asset.symbol,
        name: asset.name,
        emoji: asset.emoji,
        amount: amount,
        investedTRY: invested,
        coingeckoId: asset.coingeckoId,
        assetType: asset.assetType,
        isCustom: true,
      );
    }).toList();
    
    // Save custom assets to JSON
    await prefs.setString('custom_assets', 
      jsonEncode(customAssets.map((a) => a.toJson()).toList()));
    
    setState(() {
      _hasChanges = false;
    });
    
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: const Text('✅ Ayarlar kaydedildi'),
          backgroundColor: Colors.green.shade600,
          behavior: SnackBarBehavior.floating,
        ),
      );
      
      // Geri dön ve sayfayı yenile
      Navigator.pop(context, true);
    }
  }

  Future<void> _addAsset() async {
    if (!mounted) return;
    
    final result = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (dialogContext) => const AddAssetDialog(),
    );
    
    if (!mounted) return;
    
    if (result != null) {
      final asset = PortfolioAsset(
        symbol: result['symbol'],
        name: result['name'],
        emoji: result['emoji'],
        amount: result['amount'],
        investedTRY: result['investedTRY'],
        coingeckoId: result['coingeckoId'] ?? '',
        assetType: AssetType.values.firstWhere(
          (e) => e.toString() == 'AssetType.${result['type']}',
          orElse: () => AssetType.crypto,
        ),
        isCustom: true,
      );
      
      await PortfolioAsset.addCustomAsset(asset);
      await _loadSettings();
      setState(() {
        _hasChanges = true;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Varlık eklendi'),
            duration: Duration(seconds: 2),
          ),
        );
      }
    }
  }

  Future<void> _removeAsset(String symbol) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Varlık Sil'),
        content: Text('$symbol varlığını silmek istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
            child: const Text('Sil'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      await PortfolioAsset.removeCustomAsset(symbol);
      await _loadSettings();
    }
  }

  Future<void> _resetToDefaults() async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Varsayılana Sıfırla'),
        content: const Text('Tüm ayarları varsayılan değerlere sıfırlamak istediğinize emin misiniz?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('İptal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            style: TextButton.styleFrom(
              foregroundColor: Colors.red,
            ),
            child: const Text('Sıfırla'),
          ),
        ],
      ),
    );
    
    if (confirmed == true) {
      final prefs = await SharedPreferences.getInstance();
      final assets = PortfolioAsset.getAssets();
      
      for (var asset in assets) {
        await prefs.remove('amount_${asset.symbol}');
        await prefs.remove('invested_${asset.symbol}');
        
        _amountControllers[asset.symbol]?.text = asset.amount.toStringAsFixed(4);
        _investedControllers[asset.symbol]?.text = asset.investedTRY.toStringAsFixed(0);
      }
      
      setState(() {
        _hasChanges = false;
      });
      
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text('✅ Varsayılan değerlere sıfırlandı'),
            backgroundColor: Colors.orange.shade600,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    }
  }

  void _onChanged() {
    if (!_hasChanges) {
      setState(() {
        _hasChanges = true;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Theme.of(context).colorScheme.surface,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.surface,
        surfaceTintColor: Colors.transparent,
        title: Row(
          children: [
            Text(
              '⚙️',
              style: TextStyle(fontSize: 20),
            ),
            const SizedBox(width: 8),
            Text(
              'Portföy Ayarları',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
                color: Theme.of(context).colorScheme.onSurface,
              ),
            ),
          ],
        ),
        actions: [
          TextButton.icon(
            onPressed: _resetToDefaults,
            icon: const Icon(Icons.restore, size: 18),
            label: const Text('Sıfırla'),
            style: TextButton.styleFrom(
              foregroundColor: Colors.orange.shade600,
            ),
          ),
        ],
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _addAsset,
        icon: const Icon(Icons.add),
        label: const Text('Varlık Ekle'),
      ),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          // Bilgilendirme kartı
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.primaryContainer.withOpacity(0.5),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Theme.of(context).colorScheme.primary.withOpacity(0.3),
              ),
            ),
            child: Row(
              children: [
                Icon(
                  Icons.info_outline,
                  color: Theme.of(context).colorScheme.primary,
                  size: 24,
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    'Coin miktarlarını ve yatırım tutarlarını buradan düzenleyebilirsiniz.',
                    style: TextStyle(
                      fontSize: 13,
                      color: Theme.of(context).colorScheme.onSurface.withOpacity(0.8),
                    ),
                  ),
                ),
              ],
            ),
          ),
          
          const SizedBox(height: 24),
          
          // Asset listesi
          ..._assets.map((asset) => _buildAssetSettingCard(asset)),
          
          const SizedBox(height: 80), // Space for FAB
        ],
      ),
      bottomNavigationBar: _hasChanges
          ? Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surface,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.1),
                    blurRadius: 8,
                    offset: const Offset(0, -2),
                  ),
                ],
              ),
              child: SafeArea(
                child: ElevatedButton(
                  onPressed: _saveSettings,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Theme.of(context).colorScheme.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                  child: const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.save),
                      SizedBox(width: 8),
                      Text(
                        'Kaydet',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            )
          : null,
    );
  }

  Widget _buildAssetSettingCard(PortfolioAsset asset) {
    final defaultAssets = PortfolioAsset.getAssets();
    final defaultIndex = defaultAssets.indexWhere((a) => a.symbol == asset.symbol);
    final color = _getColorForAsset(defaultIndex >= 0 ? defaultIndex : _assets.indexOf(asset));
    
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
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
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header
            Row(
              children: [
                Container(
                  width: 45,
                  height: 45,
                  decoration: BoxDecoration(
                    color: color.withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Center(
                    child: Text(
                      asset.emoji,
                      style: TextStyle(fontSize: 22),
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
                            asset.symbol,
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                              color: Theme.of(context).colorScheme.onSurface,
                            ),
                          ),
                          if (asset.isCustom) ...[
                            const SizedBox(width: 8),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: Colors.blue.shade100,
                                borderRadius: BorderRadius.circular(4),
                              ),
                              child: Text(
                                asset.assetType == AssetType.crypto ? 'CRYPTO' : 
                                asset.assetType == AssetType.usStock ? 'US' : 'BIST',
                                style: TextStyle(
                                  fontSize: 9,
                                  fontWeight: FontWeight.bold,
                                  color: Colors.blue.shade700,
                                ),
                              ),
                            ),
                          ],
                        ],
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
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red),
                  onPressed: () => _removeAsset(asset.symbol),
                  tooltip: 'Sil',
                ),
              ],
            ),
            
            const SizedBox(height: 16),
            
            // Miktar girişi
            TextField(
              controller: _amountControllers[asset.symbol],
              onChanged: (_) => _onChanged(),
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              inputFormatters: [
                FilteringTextInputFormatter.allow(RegExp(r'^\d+\.?\d{0,4}')),
              ],
              decoration: InputDecoration(
                labelText: 'Miktar',
                prefixIcon: Icon(Icons.numbers, color: color),
                suffixText: asset.symbol,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
            
            const SizedBox(height: 12),
            
            // Yatırım tutarı girişi
            TextField(
              controller: _investedControllers[asset.symbol],
              onChanged: (_) => _onChanged(),
              keyboardType: TextInputType.number,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
              ],
              decoration: InputDecoration(
                labelText: 'Yatırım Tutarı',
                prefixIcon: Icon(Icons.account_balance_wallet, color: color),
                prefixText: '₺',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                filled: true,
                fillColor: Theme.of(context).colorScheme.surface,
              ),
            ),
          ],
        ),
      ),
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
}
