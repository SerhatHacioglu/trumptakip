import 'package:flutter/material.dart';
import '../models/portfolio_asset.dart';
import '../models/asset_suggestions.dart';

class AddAssetDialog extends StatefulWidget {
  const AddAssetDialog({super.key});

  @override
  State<AddAssetDialog> createState() => _AddAssetDialogState();
}

class _AddAssetDialogState extends State<AddAssetDialog> {
  final _formKey = GlobalKey<FormState>();
  final _amountController = TextEditingController();
  final _investedController = TextEditingController();
  
  AssetType _selectedType = AssetType.crypto;
  AssetSuggestion? _selectedAsset;
  List<AssetSuggestion> _availableAssets = [];

  @override
  void initState() {
    super.initState();
    _updateAvailableAssets();
  }

  void _updateAvailableAssets() {
    final typeString = _selectedType == AssetType.crypto ? 'crypto' 
        : _selectedType == AssetType.usStock ? 'usStock' : 'bistStock';
    setState(() {
      _availableAssets = AssetSuggestions.getSuggestions(typeString);
      _selectedAsset = _availableAssets.isNotEmpty ? _availableAssets.first : null;
    });
  }

  @override
  void dispose() {
    _amountController.dispose();
    _investedController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AlertDialog(
      title: const Text('Yeni Varlık Ekle'),
      content: SizedBox(
        width: 400,
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Varlık Tipi
              DropdownButtonFormField<AssetType>(
                value: _selectedType,
                decoration: const InputDecoration(
                  labelText: 'Varlık Tipi',
                  border: OutlineInputBorder(),
                ),
                items: const [
                  DropdownMenuItem(value: AssetType.crypto, child: Text('Kripto Para')),
                  DropdownMenuItem(value: AssetType.usStock, child: Text('ABD Hissesi')),
                  DropdownMenuItem(value: AssetType.bistStock, child: Text('BIST Hissesi')),
                ],
                onChanged: (value) {
                  setState(() {
                    _selectedType = value!;
                    _updateAvailableAssets();
                  });
                },
              ),
              
              const SizedBox(height: 16),
              
              // Sembol (Açılır Liste)
              DropdownButtonFormField<AssetSuggestion>(
                value: _selectedAsset,
                decoration: const InputDecoration(
                  labelText: 'Sembol',
                  border: OutlineInputBorder(),
                ),
                isExpanded: true,
                items: _availableAssets.map((asset) => DropdownMenuItem(
                  value: asset,
                  child: Row(
                    children: [
                      Text(asset.emoji, style: const TextStyle(fontSize: 20)),
                      const SizedBox(width: 8),
                      Text(asset.symbol, style: const TextStyle(fontWeight: FontWeight.bold)),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          asset.name,
                          style: TextStyle(fontSize: 12, color: Colors.grey[600]),
                          overflow: TextOverflow.ellipsis,
                        ),
                      ),
                    ],
                  ),
                )).toList(),
                onChanged: (value) {
                  setState(() {
                    _selectedAsset = value;
                  });
                },
                validator: (v) => v == null ? 'Lütfen sembol seçin' : null,
              ),
              
              const SizedBox(height: 16),
              
              // Adet
              TextFormField(
                controller: _amountController,
                decoration: const InputDecoration(
                  labelText: 'Adet',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Lütfen adet girin' : double.tryParse(v) == null ? 'Geçerli sayı girin' : null,
              ),
              
              const SizedBox(height: 16),
              
              // Yatırım (TL)
              TextFormField(
                controller: _investedController,
                decoration: const InputDecoration(
                  labelText: 'Yatırım (TL)',
                  border: OutlineInputBorder(),
                ),
                keyboardType: TextInputType.number,
                validator: (v) => v == null || v.isEmpty ? 'Lütfen yatırım miktarı girin' : double.tryParse(v) == null ? 'Geçerli sayı girin' : null,
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () {
            if (Navigator.of(context).canPop()) {
              Navigator.of(context).pop();
            }
          },
          child: const Text('İptal'),
        ),
        TextButton(
          onPressed: () {
            if (_formKey.currentState!.validate() && _selectedAsset != null) {
              if (Navigator.of(context).canPop()) {
                final typeString = _selectedType == AssetType.crypto ? 'crypto' 
                    : _selectedType == AssetType.usStock ? 'usStock' : 'bistStock';
                
                Navigator.of(context).pop({
                  'type': typeString,
                  'symbol': _selectedAsset!.symbol,
                  'name': _selectedAsset!.name,
                  'emoji': _selectedAsset!.emoji,
                  'amount': double.parse(_amountController.text),
                  'investedTRY': double.parse(_investedController.text),
                  'coingeckoId': _selectedAsset!.coingeckoId,
                });
              }
            }
          },
          child: const Text('Ekle'),
        ),
      ],
    );
  }
}
