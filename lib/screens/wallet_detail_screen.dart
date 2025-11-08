import 'dart:ui_web' as ui_web;
import 'dart:html' as html;
import 'package:flutter/foundation.dart' show kIsWeb;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../models/wallet.dart';

class WalletDetailScreen extends StatefulWidget {
  final Wallet wallet;

  const WalletDetailScreen({super.key, required this.wallet});

  @override
  State<WalletDetailScreen> createState() => _WalletDetailScreenState();
}

class _WalletDetailScreenState extends State<WalletDetailScreen> {
  WebViewController? _controller;
  bool _isLoading = true;
  final String _baseUrl = 'https://hyperdash.info/trader/';
  String? _iframeViewType;

  @override
  void initState() {
    super.initState();
    
    if (kIsWeb) {
      // Web platformunda iframe kullan
      _iframeViewType = 'iframe-${widget.wallet.address}';
      _registerIframe();
    } else {
      // Mobil platformlarda WebView kullan
      _controller = WebViewController()
        ..setJavaScriptMode(JavaScriptMode.unrestricted)
        ..setNavigationDelegate(
          NavigationDelegate(
            onPageStarted: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = true;
                });
              }
            },
            onPageFinished: (String url) {
              if (mounted) {
                setState(() {
                  _isLoading = false;
                });
              }
            },
          ),
        )
        ..loadRequest(Uri.parse('$_baseUrl${widget.wallet.address}'));
    }
  }

  void _registerIframe() {
    if (kIsWeb && _iframeViewType != null) {
      // ignore: undefined_prefixed_name
      ui_web.platformViewRegistry.registerViewFactory(
        _iframeViewType!,
        (int viewId) {
          final iframe = html.IFrameElement()
            ..src = '$_baseUrl${widget.wallet.address}'
            ..style.border = 'none'
            ..style.width = '100%'
            ..style.height = '100%';
          
          iframe.onLoad.listen((event) {
            if (mounted) {
              setState(() {
                _isLoading = false;
              });
            }
          });

          return iframe;
        },
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              width: 12,
              height: 12,
              decoration: BoxDecoration(
                color: widget.wallet.color,
                shape: BoxShape.circle,
              ),
            ),
            const SizedBox(width: 8),
            Text(widget.wallet.name),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.copy, size: 20),
            tooltip: 'Adresi Kopyala',
            onPressed: () {
              Clipboard.setData(ClipboardData(text: widget.wallet.address));
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Adres kopyalandı'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Yenile',
            onPressed: () {
              if (kIsWeb) {
                // Web'de sayfayı yeniden yükle
                Navigator.of(context).pushReplacement(
                  MaterialPageRoute(
                    builder: (context) => WalletDetailScreen(wallet: widget.wallet),
                  ),
                );
              } else {
                _controller?.reload();
              }
            },
          ),
        ],
      ),
      body: Stack(
        children: [
          if (kIsWeb && _iframeViewType != null)
            HtmlElementView(viewType: _iframeViewType!)
          else if (_controller != null)
            WebViewWidget(controller: _controller!),
          if (_isLoading)
            const Center(
              child: CircularProgressIndicator(),
            ),
        ],
      ),
    );
  }
}
