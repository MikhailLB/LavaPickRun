import 'package:flutter/material.dart';

// Background assets — orientation-aware
// Portrait:  assets/Nowifi/Vertical_Nowifi_Screen.webp
// Landscape: assets/Nowifi/Horizontal_Nowifi_Screen.webp

class NoInternetScreen extends StatefulWidget {
  final WidgetBuilder retryScreenBuilder;
  const NoInternetScreen({super.key, required this.retryScreenBuilder});

  @override
  State<NoInternetScreen> createState() => _NoInternetScreenState();
}

class _NoInternetScreenState extends State<NoInternetScreen>
    with TickerProviderStateMixin {
  bool _isRetrying = false;
  late AnimationController _btn;
  late Animation<double> _btnScale;

  @override
  void initState() {
    super.initState();
    _btn = AnimationController(
        vsync: this, duration: const Duration(milliseconds: 120));
    _btnScale = Tween<double>(begin: 1.0, end: 0.94)
        .animate(CurvedAnimation(parent: _btn, curve: Curves.easeOut));
  }

  @override
  void dispose() {
    _btn.dispose();
    super.dispose();
  }

  Future<void> _onRetry() async {
    if (_isRetrying) return;
    await _btn.forward();
    await _btn.reverse();
    setState(() => _isRetrying = true);
    await Future.delayed(const Duration(milliseconds: 800));
    if (!mounted) return;
    Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: widget.retryScreenBuilder));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final isLandscape =
        MediaQuery.of(context).orientation == Orientation.landscape;
    final vp = MediaQuery.of(context).viewPadding;

    // Use project-specific custom no-wifi background screens
    final bgAsset = isLandscape
        ? 'assets/Nowifi/Horizontal_Nowifi_Screen.webp'
        : 'assets/Nowifi/Vertical_Nowifi_Screen.webp';

    return Scaffold(
      backgroundColor: Colors.black,
      body: SizedBox.expand(
        child: Stack(
          fit: StackFit.expand,
          children: [
            // Full-screen custom background
            Image.asset(
              bgAsset,
              fit: BoxFit.cover,
              width: size.width,
              height: size.height,
            ),

            // Retry button — bottom center, respects safe area
            Positioned(
              left: isLandscape ? size.width * 0.34 : size.width * 0.08,
              right: isLandscape ? size.width * 0.34 : size.width * 0.08,
              bottom: (isLandscape ? vp.bottom + 16 : vp.bottom + 40),
              child: ScaleTransition(
                scale: _btnScale,
                child: SizedBox(
                  height: 54,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: _isRetrying
                          ? null
                          : const LinearGradient(
                              colors: [Color(0xFFFFCC00), Color(0xFFFF9900)],
                              begin: Alignment.topLeft,
                              end: Alignment.bottomRight),
                      color: _isRetrying
                          ? Colors.amber.withValues(alpha: 0.3)
                          : null,
                      borderRadius: BorderRadius.circular(16),
                      boxShadow: _isRetrying
                          ? []
                          : [
                              BoxShadow(
                                color: Colors.amber.withValues(alpha: 0.4),
                                blurRadius: 16,
                                offset: const Offset(0, 6),
                              ),
                            ],
                    ),
                    child: Material(
                      color: Colors.transparent,
                      child: InkWell(
                        borderRadius: BorderRadius.circular(16),
                        onTap: _isRetrying ? null : _onRetry,
                        child: Center(
                          child: _isRetrying
                              ? Row(mainAxisSize: MainAxisSize.min, children: [
                                  const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.5,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.amber),
                                    ),
                                  ),
                                  const SizedBox(width: 12),
                                  Text(
                                    'Connecting...',
                                    style: TextStyle(
                                      color: Colors.amber.withValues(alpha: 0.9),
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ])
                              : const Text(
                                  'Retry',
                                  style: TextStyle(
                                    color: Color(0xFF1A0A00),
                                    fontSize: 17,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
