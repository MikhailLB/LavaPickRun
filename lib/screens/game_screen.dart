import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/upgrade.dart';
import '../widgets/volcano_widget.dart';
import '../widgets/hp_bar_widget.dart';
import '../widgets/coin_display_widget.dart';
import '../widgets/damage_number_widget.dart';
import '../widgets/shop_overlay.dart';
import '../widgets/settings_overlay.dart';

class GameScreen extends StatefulWidget {
  const GameScreen({super.key});

  @override
  State<GameScreen> createState() => _GameScreenState();
}

class _GameScreenState extends State<GameScreen> {
  bool _levelCompletePushed = false;

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(builder: (ctx, gs, _) {
      if (gs.levelComplete && !_levelCompletePushed) {
        _levelCompletePushed = true;
        WidgetsBinding.instance.addPostFrameCallback((_) {
          Navigator.of(context).pushReplacementNamed('/level-complete');
        });
      }

      final level = gs.currentLevel;

      return Scaffold(
        body: Stack(
          fit: StackFit.expand,
          children: [
            // Background
            Image.asset(level.bgAsset, fit: BoxFit.cover),

            // Dark overlay
            Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [
                    Colors.black.withValues(alpha: 0.2),
                    Colors.black.withValues(alpha: 0.5),
                  ],
                ),
              ),
            ),

            SafeArea(
              child: Column(
                children: [
                  // Top bar
                  _TopBar(levelName: level.name, levelNum: level.level),

                  const SizedBox(height: 4),

                  // HP bar
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 20),
                    child: HpBarWidget(
                      currentHp: gs.currentHp,
                      maxHp: gs.maxHp,
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Volcano
                  Expanded(
                    child: _VolcanoTapArea(volcanoAsset: level.volcanoAsset),
                  ),

                  // Bottom controls
                  _BottomBar(gs: gs),
                  const SizedBox(height: 12),
                ],
              ),
            ),

            // Damage numbers layer
            _DamageNumbersLayer(),

            // Cursed skull overlay
            _CursedSkullOverlay(),
          ],
        ),
      );
    });
  }
}

class _TopBar extends StatelessWidget {
  final String levelName;
  final int levelNum;

  const _TopBar({required this.levelName, required this.levelNum});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          IconButton(
            icon: const Icon(Icons.arrow_back_ios, color: Color(0xFFFFD700)),
            onPressed: () => Navigator.of(context).pop(),
          ),
          Flexible(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'LEVEL $levelNum',
                  style: GoogleFonts.cinzel(
                    fontSize: 11,
                    color: const Color(0xFFFF6D00),
                    fontWeight: FontWeight.bold,
                    letterSpacing: 2,
                  ),
                ),
                Text(
                  levelName,
                  overflow: TextOverflow.ellipsis,
                  style: GoogleFonts.cinzel(
                    fontSize: 16,
                    color: const Color(0xFFFFD700),
                    fontWeight: FontWeight.w900,
                    shadows: const [
                      Shadow(color: Colors.black, blurRadius: 4),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 4),
          Consumer<GameState>(
            builder: (context, gs, child) =>
                CoinDisplayWidget(coins: gs.coins, compact: true),
          ),
          const SizedBox(width: 6),
          _InGameSettingsButton(),
        ],
      ),
    );
  }
}

class _VolcanoTapArea extends StatelessWidget {
  final String volcanoAsset;
  const _VolcanoTapArea({required this.volcanoAsset});

  @override
  Widget build(BuildContext context) {
    final gs = context.read<GameState>();
    return Center(
      child: VolcanoWidget(
        volcanoAsset: volcanoAsset,
        onTapWithPosition: (globalPos) {
          // Convert global position to local coordinates within the game area
          final box = context.findRenderObject() as RenderBox?;
          final localPos = box != null
              ? box.globalToLocal(globalPos)
              : globalPos;
          gs.onTap(localPos);
        },
      ),
    );
  }
}

class _DamageNumbersLayer extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (ctx, gs, _) {
        return Stack(
          fit: StackFit.expand,
          children: gs.damageEvents
              .map(
                (e) => DamageNumberWidget(
                  key: ValueKey(e.id),
                  event: e,
                  onComplete: () => gs.removeDamageEvent(e.id),
                ),
              )
              .toList(),
        );
      },
    );
  }
}

class _BottomBar extends StatelessWidget {
  final GameState gs;
  const _BottomBar({required this.gs});

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (ctx, gs, _) {
        final frenzyTier = gs.getUpgradeTier(UpgradeId.tapFrenzy);
        final autoTier = gs.getUpgradeTier(UpgradeId.lavaSurge);
        final goldRushTier = gs.getUpgradeTier(UpgradeId.goldRush);
        final apocalypseTier = gs.getUpgradeTier(UpgradeId.apocalypse);

        return Padding(
          padding: const EdgeInsets.symmetric(horizontal: 10),
          child: Row(
            children: [
              // Auto tap indicator
              if (autoTier > 0)
                _StatBadge(
                  icon: '🌋',
                  label: 'Auto',
                  sublabel: gs.autoTapLabel,
                ),

              const Spacer(),

              // Active skill buttons
              if (goldRushTier > 0) ...[
                _ActiveSkillButton(
                  icon: '🪙',
                  label: 'RUSH',
                  secondsLeft: gs.goldRushSecondsLeft,
                  cooldownLeft: gs.goldRushCooldownLeft,
                  active: gs.goldRushActive,
                  onTap: gs.activateGoldRush,
                ),
                const SizedBox(width: 6),
              ],
              if (frenzyTier > 0) ...[
                _ActiveSkillButton(
                  icon: '🔥',
                  label: 'FRENZY',
                  secondsLeft: gs.frenzySecondsLeft,
                  cooldownLeft: gs.frenzyCooldownLeft,
                  active: gs.frenzyActive,
                  onTap: gs.activateFrenzy,
                ),
                const SizedBox(width: 6),
              ],
              if (apocalypseTier > 0) ...[
                _ActiveSkillButton(
                  icon: '☄️',
                  label: 'APOC',
                  secondsLeft: 0,
                  cooldownLeft: gs.apocalypseCooldownLeft,
                  active: false,
                  onTap: gs.activateApocalypse,
                  isPowerful: true,
                ),
                const SizedBox(width: 6),
              ],

              _ShopButton(),
            ],
          ),
        );
      },
    );
  }
}

class _StatBadge extends StatelessWidget {
  final String icon;
  final String label;
  final String sublabel;

  const _StatBadge({
    required this.icon,
    required this.label,
    required this.sublabel,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: const Color(0xFFFF6D00).withValues(alpha: 0.5),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(icon, style: const TextStyle(fontSize: 16)),
          const SizedBox(width: 4),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.white.withValues(alpha: 0.7),
                ),
              ),
              Text(
                sublabel,
                style: GoogleFonts.cinzel(
                  fontSize: 11,
                  color: const Color(0xFFFFD700),
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _ActiveSkillButton extends StatelessWidget {
  final String icon;
  final String label;
  final int secondsLeft;
  final int cooldownLeft;
  final bool active;
  final VoidCallback onTap;
  final bool isPowerful;

  const _ActiveSkillButton({
    required this.icon,
    required this.label,
    required this.secondsLeft,
    required this.cooldownLeft,
    required this.active,
    required this.onTap,
    this.isPowerful = false,
  });

  @override
  Widget build(BuildContext context) {
        final onCooldown = cooldownLeft > 0;
        final available = !active && !onCooldown;

        return GestureDetector(
          onTap: available ? onTap : null,
          child: AnimatedContainer(
            duration: const Duration(milliseconds: 200),
            padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
            decoration: BoxDecoration(
              gradient: active
                  ? const LinearGradient(colors: [Color(0xFFFF6D00), Color(0xFFFFD700)])
                  : available
                      ? LinearGradient(colors: isPowerful
                          ? const [Color(0xFF4A0000), Color(0xFFB71C1C)]
                          : const [Color(0xFF8B0000), Color(0xFFFF3D00)])
                      : null,
              color: available || active ? null : Colors.black.withValues(alpha: 0.4),
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: active
                    ? const Color(0xFFFFD700)
                    : available
                        ? isPowerful ? const Color(0xFFFF1744) : const Color(0xFFFF6D00)
                        : Colors.grey.withValues(alpha: 0.3),
                width: 1.5,
              ),
              boxShadow: active
                  ? [
                      BoxShadow(
                        color: const Color(0xFFFFD700).withValues(alpha: 0.5),
                        blurRadius: 12, spreadRadius: 2,
                      ),
                    ]
                  : null,
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  onCooldown ? '⏳' : icon,
                  style: const TextStyle(fontSize: 16),
                ),
                const SizedBox(width: 5),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Text(
                      label,
                      style: GoogleFonts.cinzel(
                        fontSize: 10,
                        fontWeight: FontWeight.bold,
                        color: active ? Colors.black : available ? Colors.white : Colors.grey,
                        letterSpacing: 1,
                      ),
                    ),
                    if (active && secondsLeft > 0)
                      Text('${secondsLeft}s',
                          style: GoogleFonts.cinzel(fontSize: 9, color: Colors.black87, fontWeight: FontWeight.bold))
                    else if (onCooldown)
                      Text('${cooldownLeft}s',
                          style: const TextStyle(fontSize: 9, color: Colors.grey)),
                  ],
                ),
              ],
            ),
          ),
        );
  }
}

class _ShopButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          barrierColor: Colors.transparent,
          builder: (_) => ChangeNotifierProvider.value(
            value: context.read<GameState>(),
            child: const ShopOverlay(),
          ),
        );
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 18, vertical: 12),
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFF1A0A00), Color(0xFF3D1A00)],
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
          ),
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: const Color(0xFFFFD700), width: 1.5),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6D00).withValues(alpha: 0.4),
              blurRadius: 10,
              spreadRadius: 1,
            ),
          ],
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text('🏪', style: TextStyle(fontSize: 20)),
            const SizedBox(width: 6),
            Text(
              'SHOP',
              style: GoogleFonts.cinzel(
                fontSize: 14,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFFD700),
                letterSpacing: 1,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InGameSettingsButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () {
        showDialog(
          context: context,
          barrierColor: Colors.transparent,
          builder: (_) => const SettingsOverlay(),
        );
      },
      child: Container(
        width: 38,
        height: 38,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFFF6D00).withValues(alpha: 0.6),
            width: 1.5,
          ),
        ),
        child: const Icon(Icons.settings, color: Color(0xFFFFD700), size: 20),
      ),
    );
  }
}

// ── Cursed Skull overlay ─────────────────────────────────────────────

class _CursedSkullOverlay extends StatefulWidget {
  @override
  State<_CursedSkullOverlay> createState() => _CursedSkullOverlayState();
}

class _CursedSkullOverlayState extends State<_CursedSkullOverlay>
    with SingleTickerProviderStateMixin {
  late AnimationController _pulseController;

  @override
  void initState() {
    super.initState();
    _pulseController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 900),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Consumer<GameState>(
      builder: (ctx, gs, _) {
        if (!gs.hasCursedSkull) return const SizedBox.shrink();

        final size = MediaQuery.of(context).size;
        final curseActive = gs.skullCurseActive;

        return Positioned(
          right: 16,
          top: size.height * 0.38,
          child: AnimatedBuilder(
            animation: _pulseController,
            builder: (context, child) {
              final glow = curseActive
                  ? 18.0 + _pulseController.value * 14
                  : 6.0 + _pulseController.value * 4;
              final glowColor = curseActive
                  ? const Color(0xFF9C27B0)
                  : const Color(0xFF4A0072);

              return Column(
                children: [
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: Colors.black.withValues(alpha: 0.6),
                      border: Border.all(
                        color: curseActive
                            ? const Color(0xFFE040FB)
                            : const Color(0xFF7B1FA2),
                        width: curseActive ? 2.5 : 1.5,
                      ),
                      boxShadow: [
                        BoxShadow(color: glowColor, blurRadius: glow, spreadRadius: 2),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        '💀',
                        style: TextStyle(
                          fontSize: curseActive ? 26 : 22,
                        ),
                      ),
                    ),
                  ),
                  if (curseActive)
                    Padding(
                      padding: const EdgeInsets.only(top: 3),
                      child: Text(
                        'CURSED!',
                        style: GoogleFonts.cinzel(
                          fontSize: 9,
                          fontWeight: FontWeight.bold,
                          color: const Color(0xFFE040FB),
                          shadows: const [Shadow(color: Colors.black, blurRadius: 3)],
                        ),
                      ),
                    ),
                ],
              );
            },
          ),
        );
      },
    );
  }
}
