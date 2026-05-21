import 'dart:math';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class CoinPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final center = Offset(size.width / 2, size.height / 2);
    final radius = size.width / 2;

    // Outer glow
    final glowPaint = Paint()
      ..shader = RadialGradient(
        colors: [
          const Color(0xFFFFD700).withValues(alpha: 0.6),
          Colors.transparent,
        ],
      ).createShader(Rect.fromCircle(center: center, radius: radius * 1.3))
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 4);
    canvas.drawCircle(center, radius * 1.2, glowPaint);

    // Main coin body gradient
    final bodyPaint = Paint()
      ..shader = RadialGradient(
        center: const Alignment(-0.3, -0.4),
        radius: 0.9,
        colors: const [
          Color(0xFFFFF176),
          Color(0xFFFFD700),
          Color(0xFFFF8F00),
          Color(0xFFE65100),
        ],
        stops: [0.0, 0.4, 0.75, 1.0],
      ).createShader(Rect.fromCircle(center: center, radius: radius));
    canvas.drawCircle(center, radius, bodyPaint);

    // Inner ring
    final ringPaint = Paint()
      ..color = const Color(0xFFFF6F00)
      ..style = PaintingStyle.stroke
      ..strokeWidth = radius * 0.08;
    canvas.drawCircle(center, radius * 0.72, ringPaint);

    // Flame shape inside coin
    final flamePath = Path();
    final fx = center.dx;
    final fy = center.dy + radius * 0.15;
    final fw = radius * 0.4;
    final fh = radius * 0.55;

    flamePath.moveTo(fx, fy - fh);
    flamePath.cubicTo(
      fx + fw * 0.8, fy - fh * 0.6,
      fx + fw, fy - fh * 0.1,
      fx + fw * 0.4, fy,
    );
    flamePath.cubicTo(
      fx + fw * 0.6, fy - fh * 0.3,
      fx + fw * 0.2, fy - fh * 0.4,
      fx, fy - fh * 0.15,
    );
    flamePath.cubicTo(
      fx - fw * 0.2, fy - fh * 0.4,
      fx - fw * 0.6, fy - fh * 0.3,
      fx - fw * 0.4, fy,
    );
    flamePath.cubicTo(
      fx - fw, fy - fh * 0.1,
      fx - fw * 0.8, fy - fh * 0.6,
      fx, fy - fh,
    );

    final flamePaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: const [Color(0xFFFFFFFF), Color(0xFFFFEB3B), Color(0xFFFF5722)],
      ).createShader(Rect.fromCenter(center: Offset(fx, fy - fh / 2), width: fw * 2, height: fh));
    canvas.drawPath(flamePath, flamePaint);

    // Highlight shine
    final shinePaint = Paint()
      ..color = Colors.white.withValues(alpha: 0.5)
      ..style = PaintingStyle.fill;
    canvas.drawOval(
      Rect.fromCenter(
        center: Offset(center.dx - radius * 0.28, center.dy - radius * 0.3),
        width: radius * 0.35,
        height: radius * 0.22,
      ),
      shinePaint,
    );
  }

  @override
  bool shouldRepaint(CoinPainter oldDelegate) => false;
}

class CoinDisplayWidget extends StatefulWidget {
  final int coins;
  final bool compact;

  const CoinDisplayWidget({super.key, required this.coins, this.compact = false});

  @override
  State<CoinDisplayWidget> createState() => _CoinDisplayWidgetState();
}

class _CoinDisplayWidgetState extends State<CoinDisplayWidget>
    with SingleTickerProviderStateMixin {
  late AnimationController _bounceController;
  late Animation<double> _scaleAnim;
  int _prevCoins = 0;

  @override
  void initState() {
    super.initState();
    _prevCoins = widget.coins;
    _bounceController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 180),
    );
    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 1.0, end: 1.25), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.25, end: 1.0), weight: 1),
    ]).animate(CurvedAnimation(parent: _bounceController, curve: Curves.easeOut));
  }

  @override
  void didUpdateWidget(CoinDisplayWidget oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.coins != _prevCoins) {
      _prevCoins = widget.coins;
      _bounceController.forward(from: 0);
    }
  }

  @override
  void dispose() {
    _bounceController.dispose();
    super.dispose();
  }

  String _formatCoins(int c) {
    if (c >= 1000000) return '${(c / 1000000).toStringAsFixed(1)}M';
    if (c >= 1000) return '${(c / 1000).toStringAsFixed(1)}K';
    return c.toString();
  }

  @override
  Widget build(BuildContext context) {
    final iconSize = widget.compact ? 22.0 : 32.0;
    final fontSize = widget.compact ? 15.0 : 20.0;
    final hPad = widget.compact ? 10.0 : 14.0;
    final vPad = widget.compact ? 6.0 : 8.0;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: hPad, vertical: vPad),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(color: const Color(0xFFFFD700).withValues(alpha: 0.7), width: 1.5),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFFFFD700).withValues(alpha: 0.3),
            blurRadius: 8,
            spreadRadius: 1,
          ),
        ],
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          AnimatedBuilder(
            animation: _scaleAnim,
            builder: (context, child) => Transform.scale(
              scale: _scaleAnim.value,
              child: SizedBox(
                width: iconSize,
                height: iconSize,
                child: CustomPaint(painter: CoinPainter()),
              ),
            ),
          ),
          const SizedBox(width: 6),
          AnimatedBuilder(
            animation: _scaleAnim,
            builder: (context, _) => Transform.scale(
              scale: _scaleAnim.value,
              child: Text(
                _formatCoins(widget.coins),
                style: GoogleFonts.cinzel(
                  fontSize: fontSize,
                  fontWeight: FontWeight.bold,
                  color: const Color(0xFFFFD700),
                  shadows: [
                    const Shadow(
                      color: Color(0xFFFF6600),
                      blurRadius: 6,
                    ),
                    Shadow(
                      color: Colors.black.withValues(alpha: 0.8),
                      blurRadius: 2,
                      offset: const Offset(1, 1),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class FloatingCoinWidget extends StatelessWidget {
  final double size;
  const FloatingCoinWidget({super.key, this.size = 24});

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: size,
      height: size,
      child: CustomPaint(painter: CoinPainter()),
    );
  }
}

class SprayCoin extends StatefulWidget {
  final double startX;
  final double startY;
  final double targetX;
  final double targetY;
  final double size;

  const SprayCoin({
    super.key,
    required this.startX,
    required this.startY,
    required this.targetX,
    required this.targetY,
    this.size = 28,
  });

  @override
  State<SprayCoin> createState() => _SprayCoinState();
}

class _SprayCoinState extends State<SprayCoin>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _xAnim;
  late Animation<double> _yAnim;
  late Animation<double> _opacityAnim;
  late Animation<double> _scaleAnim;

  @override
  void initState() {
    super.initState();
    final rng = Random();
    final delay = rng.nextDouble() * 0.3;

    _controller = AnimationController(
      vsync: this,
      duration: Duration(milliseconds: 600 + rng.nextInt(400)),
    )..forward();

    _xAnim = Tween(begin: widget.startX, end: widget.targetX).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(delay, 1.0, curve: Curves.easeOut),
      ),
    );
    _yAnim = Tween(begin: widget.startY, end: widget.targetY).animate(
      CurvedAnimation(
        parent: _controller,
        curve: Interval(delay, 1.0, curve: Curves.easeIn),
      ),
    );
    _opacityAnim = Tween(begin: 0.0, end: 1.0).animate(
      CurvedAnimation(
        parent: _controller,
        curve: const Interval(0.0, 0.2, curve: Curves.easeIn),
      ),
    );
    _scaleAnim = TweenSequence([
      TweenSequenceItem(tween: Tween(begin: 0.3, end: 1.2), weight: 1),
      TweenSequenceItem(tween: Tween(begin: 1.2, end: 0.8), weight: 1),
    ]).animate(_controller);
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: _controller,
      builder: (context, _) => Positioned(
        left: _xAnim.value - widget.size / 2,
        top: _yAnim.value - widget.size / 2,
        child: Opacity(
          opacity: _opacityAnim.value,
          child: Transform.scale(
            scale: _scaleAnim.value,
            child: FloatingCoinWidget(size: widget.size),
          ),
        ),
      ),
    );
  }
}
