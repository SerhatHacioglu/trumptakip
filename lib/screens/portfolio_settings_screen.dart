import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/portfolio_asset.dart';

class PortfolioSettingsScreen extends StatefulWidget {
  const PortfolioSettingsScreen({super.key});

  @override
  State<PortfolioSettingsScreen> createState() => _PortfolioSettingsScreenState();
}

class _PortfolioSettingsScreenState extends State<PortfolioSettingsScreen> {
  final Map<String, TextEditingController> _amountControllers = {};
  final Map<String, TextEditingController> _investedControllers = {};
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
    final prefs = await SharedPreferences.getInstance();
    final assets = PortfolioAsset.getAssets();
    
    for (var asset in assets) {
      final savedAmount = prefs.getDouble('amount_${asset.symbol}') ?? asset.amount;
      final savedInvested = prefs.getDouble('invested_${asset.symbol}') ?? asset.investedTRY;
      
      _amountControllers[asset.symbol] = TextEditingController(
        text: savedAmount.toStringAsFixed(4),
      );
      _investedControllers[asset.symbol] = TextEditingController(
        text: savedInvested.toStringAsFixed(0),
      );
    }
    
    setState(() {});
  }

  Future<void> _saveSettings() async {
    final prefs = await SharedPreferences.getInstance();
    
    for (var entry in _amountControllers.entries) {
      final symbol = entry.key;
      final amount = double.tryParse(entry.value.text) ?? 0;
      final invested = double.tryParse(_investedControllers[symbol]?.text ?? '0') ?? 0;
      
      await prefs.setDouble('amount_$symbol', amount);
      await prefs.setDouble('invested_$symbol', invested);
    }
    
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
    final assets = PortfolioAsset.getAssets();
    
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
          ...assets.map((asset) => _buildAssetSettingCard(asset)),
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
    final color = _getColorForAsset(PortfolioAsset.getAssets().indexOf(asset));
    
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
