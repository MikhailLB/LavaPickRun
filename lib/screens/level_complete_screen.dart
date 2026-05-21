import 'dart:math';
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/level_config.dart';
import '../widgets/coin_display_widget.dart';

class LevelCompleteScreen extends StatefulWidget {
  const LevelCompleteScreen({super.key});

  @override
  State<LevelCompleteScreen> createState() => _LevelCompleteScreenState();
}

class _LevelCompleteScreenState extends State<LevelCompleteScreen>
    with TickerProviderStateMixin {
  late List<_CoinSprayData> _coins;
  final Random _rng = Random();

  @override
  void initState() {
    super.initState();
    _coins = List.generate(24, (i) => _CoinSprayData(rng: _rng));
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;

    return Consumer<GameState>(builder: (ctx, gs, _) {
      final completedLevel = gs.currentLevelIndex;
      final level = LevelConfig.levels[completedLevel];
      final hasNextLevel = completedLevel < LevelConfig.levels.length - 1;

      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(level.bgAsset, fit: BoxFit.cover),
            Container(color: Colors.black.withValues(alpha: 0.5)),

            // Coin spray animation
            ..._coins.map(
              (c) => SprayCoin(
                startX: size.width / 2,
                startY: size.height * 0.55,
                targetX: c.tx * size.width,
                targetY: c.ty * size.height,
                size: c.size,
              ),
            ),

            SafeArea(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Spacer(),

                  // Victory trophy + title
                  Text('🌋', style: const TextStyle(fontSize: 60))
                      .animate()
                      .scale(
                        begin: const Offset(0.0, 0.0),
                        end: const Offset(1.0, 1.0),
                        duration: 600.ms,
                        curve: Curves.elasticOut,
                      ),
                  const SizedBox(height: 12),
                  Text(
                    'LEVEL CLEARED!',
                    style: GoogleFonts.cinzel(
                      fontSize: 32,
                      fontWeight: FontWeight.w900,
                      color: const Color(0xFFFFD700),
                      shadows: const [
                        Shadow(color: Color(0xFFFF3D00), blurRadius: 12),
                        Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                          offset: Offset(2, 2),
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 300.ms, duration: 500.ms)
                      .slideY(begin: -0.2, end: 0),
                  const SizedBox(height: 6),
                  Text(
                    level.name.toUpperCase(),
                    style: GoogleFonts.cinzel(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: const Color(0xFFFF6D00),
                      letterSpacing: 3,
                    ),
                  ).animate().fadeIn(delay: 500.ms, duration: 400.ms),

                  const SizedBox(height: 32),

                  // Coin total card
                  Container(
                    margin: const EdgeInsets.symmetric(horizontal: 40),
                    padding: const EdgeInsets.symmetric(
                        horizontal: 24, vertical: 16),
                    decoration: BoxDecoration(
                      color: Colors.black.withValues(alpha: 0.6),
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(
                          color: const Color(0xFFFFD700), width: 1.5),
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                          blurRadius: 12,
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const FloatingCoinWidget(size: 36),
                        const SizedBox(width: 12),
                        Column(
                          children: [
                            Text(
                              'TOTAL COINS',
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.white.withValues(alpha: 0.6),
                                letterSpacing: 2,
                              ),
                            ),
                            Text(
                              _formatCoins(gs.coins),
                              style: GoogleFonts.cinzel(
                                fontSize: 28,
                                fontWeight: FontWeight.w900,
                                color: const Color(0xFFFFD700),
                                shadows: const [
                                  Shadow(
                                      color: Color(0xFFFF6D00), blurRadius: 8),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  )
                      .animate()
                      .fadeIn(delay: 600.ms, duration: 500.ms)
                      .scale(
                        begin: const Offset(0.8, 0.8),
                        end: const Offset(1.0, 1.0),
                        delay: 600.ms,
                      ),

                  const Spacer(),

                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 32),
                    child: Column(
                      children: [
                        if (hasNextLevel) ...[
                          _CompleteButton(
                            label: 'NEXT LEVEL',
                            icon: Icons.skip_next,
                            isPrimary: true,
                            onTap: () {
                              gs.startLevel(completedLevel + 1);
                              Navigator.of(context)
                                  .pushReplacementNamed('/game');
                            },
                          ).animate().fadeIn(delay: 800.ms, duration: 400.ms),
                          const SizedBox(height: 12),
                        ],
                        _CompleteButton(
                          label: 'LEVEL SELECT',
                          icon: Icons.map_outlined,
                          isPrimary: false,
                          onTap: () => Navigator.of(context)
                              .pushNamedAndRemoveUntil(
                                  '/level-select', (r) => r.isFirst),
                        ).animate().fadeIn(delay: 900.ms, duration: 400.ms),
                      ],
                    ),
                  ),

                  const SizedBox(height: 32),
                ],
              ),
            ),
          ],
        ),
      );
    });
  }

  String _formatCoins(int c) {
    if (c >= 1000000) return '${(c / 1000000).toStringAsFixed(1)}M';
    if (c >= 1000) return '${(c / 1000).toStringAsFixed(1)}K';
    return c.toString();
  }
}

class _CoinSprayData {
  final double tx;
  final double ty;
  final double size;

  _CoinSprayData({required Random rng})
      : tx = rng.nextDouble(),
        ty = rng.nextDouble() * 0.8,
        size = 16 + rng.nextDouble() * 20;
}

class _CompleteButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final bool isPrimary;
  final VoidCallback onTap;

  const _CompleteButton({
    required this.label,
    required this.icon,
    required this.isPrimary,
    required this.onTap,
  });

  @override
  State<_CompleteButton> createState() => _CompleteButtonState();
}

class _CompleteButtonState extends State<_CompleteButton> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          width: double.infinity,
          padding: const EdgeInsets.symmetric(vertical: 16),
          decoration: BoxDecoration(
            gradient: widget.isPrimary
                ? const LinearGradient(
                    colors: [Color(0xFFFF6D00), Color(0xFFFF3D00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.4),
                    ],
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isPrimary
                  ? const Color(0xFFFFD700)
                  : const Color(0xFFFF6D00).withValues(alpha: 0.5),
              width: 1.5,
            ),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF3D00).withValues(alpha: 0.4),
                      blurRadius: 12,
                    ),
                  ]
                : null,
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(widget.icon, color: const Color(0xFFFFD700), size: 20),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.cinzel(
                  fontSize: 16,
                  fontWeight: FontWeight.w900,
                  color: const Color(0xFFFFD700),
                  letterSpacing: 2,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
