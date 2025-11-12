import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

class Wallet {
  final String id;
  final String address;
  final String name;
  final Color color;
  final int order;
  
  Wallet({
    required this.id,
    required this.address,
    required this.name,
    required this.color,
    required this.order,
  });
  
  String get shortAddress => '${address.substring(0, 6)}...${address.substring(38)}';

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'address': address,
      'name': name,
      'color': color.value,
      'order': order,
    };
  }

  factory Wallet.fromJson(Map<String, dynamic> json) {
    return Wallet(
      id: json['id'] as String,
      address: json['address'] as String,
      name: json['name'] as String,
      color: Color(json['color'] as int),
      order: json['order'] as int,
    );
  }

  Wallet copyWith({
    String? id,
    String? address,
    String? name,
    Color? color,
    int? order,
  }) {
    return Wallet(
      id: id ?? this.id,
      address: address ?? this.address,
      name: name ?? this.name,
      color: color ?? this.color,
      order: order ?? this.order,
    );
  }

  static Future<void> saveWallets(List<Wallet> wallets) async {
    final prefs = await SharedPreferences.getInstance();
    final walletsJson = wallets.map((w) => w.toJson()).toList();
    await prefs.setString('wallets', jsonEncode(walletsJson));
  }

  static Future<List<Wallet>> loadWallets() async {
    final prefs = await SharedPreferences.getInstance();
    final walletsString = prefs.getString('wallets');
    
    if (walletsString == null) {
      final defaultWallets = getDefaultWallets();
      await saveWallets(defaultWallets);
      return defaultWallets;
    }
    
    try {
      final List<dynamic> walletsJson = jsonDecode(walletsString);
      return walletsJson.map((json) => Wallet.fromJson(json)).toList()
        ..sort((a, b) => a.order.compareTo(b.order));
    } catch (e) {
      final defaultWallets = getDefaultWallets();
      await saveWallets(defaultWallets);
      return defaultWallets;
    }
  }

  static List<Wallet> getDefaultWallets() {
    return [
      Wallet(
        id: 'wallet_1',
        name: 'Barron',
        address: '0xc2a30212a8ddac9e123944d6e29faddce994e5f2',
        color: Colors.red,
        order: 0,
      ),
      Wallet(
        id: 'wallet_2',
        name: 'Cüzdan 2',
        address: '0xb317d2bc2d3d2df5fa441b5bae0ab9d8b07283ae',
        color: Colors.purple,
        order: 1,
      ),
      Wallet(
        id: 'wallet_3',
        name: 'Cüzdan 3',
        address: '0x9263c1bd29aa87a118242f3fbba4517037f8cc7a',
        color: Colors.teal,
        order: 2,
      ),
      Wallet(
        id: 'wallet_4',
        name: 'Shortcu',
        address: '0x7b7b908c076b9784487180de92e7161c2982734e',
        color: Colors.orange,
        order: 3,
      ),
      Wallet(
        id: 'wallet_5',
        name: 'Cüzdan 5',
        address: '0x089fe537f4b2af55fa990bc64ff4125800bba4f8',
        color: Colors.deepOrange,
        order: 4,
      ),
    ];
  }

  static Future<void> addWallet(Wallet wallet) async {
    final wallets = await loadWallets();
    wallets.add(wallet);
    await saveWallets(wallets);
  }

  static Future<void> updateWallet(String id, Wallet updatedWallet) async {
    final wallets = await loadWallets();
    final index = wallets.indexWhere((w) => w.id == id);
    if (index != -1) {
      wallets[index] = updatedWallet;
      await saveWallets(wallets);
    }
  }

  static Future<void> deleteWallet(String id) async {
    final wallets = await loadWallets();
    wallets.removeWhere((w) => w.id == id);
    for (int i = 0; i < wallets.length; i++) {
      wallets[i] = wallets[i].copyWith(order: i);
    }
    await saveWallets(wallets);
  }

  static Future<void> reorderWallets(int oldIndex, int newIndex) async {
    final wallets = await loadWallets();
    if (newIndex > oldIndex) {
      newIndex -= 1;
    }
    final wallet = wallets.removeAt(oldIndex);
    wallets.insert(newIndex, wallet);
    
    for (int i = 0; i < wallets.length; i++) {
      wallets[i] = wallets[i].copyWith(order: i);
    }
    
    await saveWallets(wallets);
  }

  static List<Color> getColorPalette() {
    return [
      Colors.red,
      Colors.purple,
      Colors.teal,
      Colors.blue,
      Colors.green,
      Colors.orange,
      Colors.pink,
      Colors.indigo,
      Colors.cyan,
      Colors.amber,
    ];
  }
}

