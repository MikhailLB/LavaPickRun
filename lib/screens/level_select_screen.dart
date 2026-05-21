import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/level_config.dart';

class LevelSelectScreen extends StatelessWidget {
  const LevelSelectScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset('assets/Assets/1_bg_asset.webp', fit: BoxFit.cover),
          Container(color: Colors.black.withValues(alpha: 0.55)),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.all(16),
                  child: Row(
                    children: [
                      IconButton(
                        icon: const Icon(Icons.arrow_back_ios,
                            color: Color(0xFFFFD700)),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                      Expanded(
                        child: Text(
                          'SELECT LEVEL',
                          textAlign: TextAlign.center,
                          style: GoogleFonts.cinzel(
                            fontSize: 22,
                            fontWeight: FontWeight.w900,
                            color: const Color(0xFFFFD700),
                            shadows: [
                              const Shadow(
                                  color: Color(0xFFFF6D00), blurRadius: 10),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(width: 48),
                    ],
                  ),
                ),
                Expanded(
                  child: Consumer<GameState>(
                    builder: (ctx, gs, _) {
                      return GridView.builder(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 16, vertical: 8),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 16,
                          crossAxisSpacing: 16,
                          childAspectRatio: 0.8,
                        ),
                        itemCount: LevelConfig.levels.length,
                        itemBuilder: (ctx, i) {
                          final level = LevelConfig.levels[i];
                          final unlocked = (i + 1) <= gs.unlockedLevels;
                          return _LevelCard(
                            level: level,
                            index: i,
                            unlocked: unlocked,
                          )
                              .animate()
                              .fadeIn(
                                delay: Duration(milliseconds: i * 80),
                                duration: 400.ms,
                              )
                              .slideY(begin: 0.15, end: 0);
                        },
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LevelCard extends StatefulWidget {
  final LevelConfig level;
  final int index;
  final bool unlocked;

  const _LevelCard({
    required this.level,
    required this.index,
    required this.unlocked,
  });

  @override
  State<_LevelCard> createState() => _LevelCardState();
}

class _LevelCardState extends State<_LevelCard> {
  bool _pressed = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: widget.unlocked ? (_) => setState(() => _pressed = true) : null,
      onTapUp: widget.unlocked
          ? (_) {
              setState(() => _pressed = false);
              _startLevel(context);
            }
          : null,
      onTapCancel:
          widget.unlocked ? () => setState(() => _pressed = false) : null,
      child: AnimatedScale(
        scale: _pressed ? 0.95 : 1.0,
        duration: const Duration(milliseconds: 80),
        child: Container(
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.unlocked
                  ? const Color(0xFFFF6D00)
                  : Colors.grey.withValues(alpha: 0.3),
              width: 2,
            ),
            boxShadow: widget.unlocked
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF3D00).withValues(alpha: 0.4),
                      blurRadius: 12,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: Stack(
              fit: StackFit.expand,
              children: [
                // Background
                Image.asset(
                  widget.level.bgAsset,
                  fit: BoxFit.cover,
                ),
                // Volcano centered
                Positioned(
                  bottom: 0,
                  left: 0,
                  right: 0,
                  child: Image.asset(
                    widget.level.volcanoAsset,
                    fit: BoxFit.contain,
                    height: 110,
                  ),
                ),
                // Gradient overlay
                Positioned.fill(
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      gradient: LinearGradient(
                        begin: Alignment.topCenter,
                        end: Alignment.bottomCenter,
                        colors: [
                          Colors.transparent,
                          Colors.black.withValues(alpha: 0.6),
                        ],
                      ),
                    ),
                  ),
                ),
                // Level info
                Positioned(
                  bottom: 8,
                  left: 8,
                  right: 8,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'LEVEL ${widget.level.level}',
                        style: GoogleFonts.cinzel(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFFF6D00),
                          letterSpacing: 1,
                        ),
                      ),
                      Text(
                        widget.level.name,
                        style: GoogleFonts.cinzel(
                          fontSize: 13,
                          fontWeight: FontWeight.w900,
                          color: Colors.white,
                        ),
                      ),
                    ],
                  ),
                ),
                // Locked overlay
                if (!widget.unlocked)
                  Positioned.fill(
                    child: Container(
                      color: Colors.black.withValues(alpha: 0.65),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.lock,
                            color: Colors.white.withValues(alpha: 0.6),
                            size: 36,
                          ),
                          const SizedBox(height: 8),
                          Container(
                            padding: const EdgeInsets.symmetric(
                                horizontal: 10, vertical: 4),
                            decoration: BoxDecoration(
                              color: const Color(0xFFFF3D00).withValues(alpha: 0.8),
                              borderRadius: BorderRadius.circular(20),
                              border: Border.all(
                                  color: const Color(0xFFFFD700), width: 1),
                            ),
                            child: Text(
                              'COMING SOON',
                              style: GoogleFonts.cinzel(
                                fontSize: 9,
                                fontWeight: FontWeight.bold,
                                color: const Color(0xFFFFD700),
                                letterSpacing: 1,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                // Play button overlay for unlocked
                if (widget.unlocked)
                  Positioned(
                    top: 8,
                    right: 8,
                    child: Container(
                      width: 32,
                      height: 32,
                      decoration: BoxDecoration(
                        color: const Color(0xFFFF3D00).withValues(alpha: 0.85),
                        shape: BoxShape.circle,
                        border: Border.all(
                            color: const Color(0xFFFFD700), width: 1.5),
                      ),
                      child: const Icon(Icons.play_arrow,
                          color: Colors.white, size: 20),
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  void _startLevel(BuildContext context) {
    final gs = context.read<GameState>();
    gs.startLevel(widget.index);
    Navigator.of(context).pushNamed('/game');
  }
}
