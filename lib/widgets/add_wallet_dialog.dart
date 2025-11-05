import 'package:flutter/material.dart';
import '../models/wallet.dart';

class AddWalletDialog extends StatefulWidget {
  final Wallet? wallet; // Düzenleme için

  const AddWalletDialog({super.key, this.wallet});

  @override
  State<AddWalletDialog> createState() => _AddWalletDialogState();
}

class _AddWalletDialogState extends State<AddWalletDialog> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  Color _selectedColor = Colors.blue;

  @override
  void initState() {
    super.initState();
    if (widget.wallet != null) {
      _nameController.text = widget.wallet!.name;
      _addressController.text = widget.wallet!.address;
      _selectedColor = widget.wallet!.color;
    }
  }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final isEdit = widget.wallet != null;

    return AlertDialog(
      title: Text(isEdit ? 'Cüzdanı Düzenle' : 'Yeni Cüzdan Ekle'),
      content: SingleChildScrollView(
        child: Form(
          key: _formKey,
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // İsim
              TextFormField(
                controller: _nameController,
                decoration: const InputDecoration(
                  labelText: 'Cüzdan Adı',
                  hintText: 'Örn: Cüzdan 4',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir isim girin';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Adres
              TextFormField(
                controller: _addressController,
                decoration: const InputDecoration(
                  labelText: 'Cüzdan Adresi',
                  hintText: '0x...',
                  border: OutlineInputBorder(),
                ),
                validator: (value) {
                  if (value == null || value.isEmpty) {
                    return 'Lütfen bir adres girin';
                  }
                  if (!value.startsWith('0x') || value.length != 42) {
                    return 'Geçersiz Ethereum adresi';
                  }
                  return null;
                },
              ),
              
              const SizedBox(height: 16),
              
              // Renk seçimi
              const Text(
                'Renk Seçin:',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: Wallet.getColorPalette().map((color) {
                  final isSelected = _selectedColor == color;
                  return GestureDetector(
                    onTap: () {
                      setState(() {
                        _selectedColor = color;
                      });
                    },
                    child: Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: color,
                        shape: BoxShape.circle,
                        border: Border.all(
                          color: isSelected ? Colors.white : Colors.transparent,
                          width: 3,
                        ),
                        boxShadow: isSelected
                            ? [
                                BoxShadow(
                                  color: color.withOpacity(0.5),
                                  blurRadius: 8,
                                  spreadRadius: 2,
                                ),
                              ]
                            : null,
                      ),
                      child: isSelected
                          ? const Icon(
                              Icons.check,
                              color: Colors.white,
                              size: 20,
                            )
                          : null,
                    ),
                  );
                }).toList(),
              ),
            ],
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text('İptal'),
        ),
        FilledButton(
          onPressed: () {
            if (_formKey.currentState!.validate()) {
              final wallet = Wallet(
                id: widget.wallet?.id ?? 'wallet_${DateTime.now().millisecondsSinceEpoch}',
                name: _nameController.text,
                address: _addressController.text.toLowerCase(),
                color: _selectedColor,
                order: widget.wallet?.order ?? 999, // Yeni ise en sona ekle
              );
              Navigator.pop(context, wallet);
            }
          },
          child: Text(isEdit ? 'Güncelle' : 'Ekle'),
        ),
      ],
    );
  }
}
