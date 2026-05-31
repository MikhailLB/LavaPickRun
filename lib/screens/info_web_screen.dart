import 'package:flutter/material.dart';
import 'package:webview_flutter/webview_flutter.dart';
import '../ui/theme.dart';

/// Lightweight in-app browser for policy / support pages reached from the menu.
class InfoWebScreen extends StatefulWidget {
  const InfoWebScreen({super.key, required this.url, required this.title});

  final String url;
  final String title;

  @override
  State<InfoWebScreen> createState() => _InfoWebScreenState();
}

class _InfoWebScreenState extends State<InfoWebScreen> {
  late final WebViewController _controller;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setNavigationDelegate(
        NavigationDelegate(
          onPageFinished: (_) {
            if (mounted) setState(() => _loading = false);
          },
        ),
      )
      ..loadRequest(Uri.parse(widget.url));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Palette.ink,
      appBar: AppBar(
        backgroundColor: Palette.charcoal,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back_ios, color: Palette.gold),
          onPressed: () => Navigator.of(context).pop(),
        ),
        title: Text(widget.title, style: AppText.title(18)),
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(2),
          child: Container(
              height: 2, color: Palette.ember.withValues(alpha: 0.5)),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_loading)
            const ColoredBox(
              color: Palette.ink,
              child: Center(
                child: CircularProgressIndicator(color: Palette.ember),
              ),
            ),
        ],
      ),
    );
  }
}
