import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../models/game_state.dart';
import '../models/upgrade.dart';
import 'coin_display_widget.dart';

class ShopOverlay extends StatelessWidget {
  const ShopOverlay({super.key});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Colors.black.withValues(alpha: 0.7),
        child: GestureDetector(
          onTap: () {},
          child: Center(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: Container(
                margin: const EdgeInsets.symmetric(horizontal: 14, vertical: 36),
                decoration: BoxDecoration(
                  gradient: const LinearGradient(
                    begin: Alignment.topCenter,
                    end: Alignment.bottomCenter,
                    colors: [Color(0xFF1A0A00), Color(0xFF2D0E00), Color(0xFF1A0A00)],
                  ),
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFFF6D00), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF3D00).withValues(alpha: 0.4),
                      blurRadius: 20, spreadRadius: 2,
                    ),
                  ],
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    _buildHeader(context),
                    const Divider(color: Color(0xFFFF6D00), thickness: 1, height: 1),
                    Flexible(
                      child: Consumer<GameState>(
                        builder: (ctx, gs, _) {
                          final unlocked = gs.unlockedLevels;
                          final sections = _buildSections(gs, unlocked);
                          return ListView.builder(
                            shrinkWrap: true,
                            padding: const EdgeInsets.fromLTRB(12, 8, 12, 12),
                            itemCount: sections.length,
                            itemBuilder: (ctx, i) => sections[i],
                          );
                        },
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  List<Widget> _buildSections(GameState gs, int unlockedLevels) {
    final sections = <Widget>[];

    // Core upgrades (always visible)
    final coreIds = [
      UpgradeId.damageUp, UpgradeId.doubleTap, UpgradeId.critChance,
      UpgradeId.critMultiplier, UpgradeId.tapFrenzy, UpgradeId.lavaSurge,
    ];

    sections.add(_sectionLabel('⚡ CORE UPGRADES'));
    for (final id in coreIds) {
      final def = UpgradeDefinition.all.firstWhere((d) => d.id == id);
      sections.add(_UpgradeTile(def: def));
    }

    // Level-locked perks
    final lockedDefs = UpgradeDefinition.all
        .where((d) => d.requiredLevel > 1 && !d.isEasterEgg)
        .toList();

    if (lockedDefs.isNotEmpty) {
      sections.add(_sectionLabel('🔓 SPECIAL PERKS'));
      for (final def in lockedDefs) {
        sections.add(_UpgradeTile(
          def: def,
          locked: unlockedLevels < def.requiredLevel,
        ));
      }
    }

    // Easter egg section
    final eggDef = UpgradeDefinition.all.firstWhere((d) => d.isEasterEgg);
    sections.add(_sectionLabel('🗝️ SECRET'));
    sections.add(_UpgradeTile(def: eggDef, isEasterEgg: true));

    return sections;
  }

  Widget _sectionLabel(String label) {
    return Padding(
      padding: const EdgeInsets.only(top: 10, bottom: 4, left: 4),
      child: Text(
        label,
        style: GoogleFonts.cinzel(
          fontSize: 11,
          fontWeight: FontWeight.bold,
          color: const Color(0xFFFF6D00),
          letterSpacing: 2,
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(12, 12, 4, 8),
      child: Row(
        children: [
          Flexible(
            child: Text(
              '🏪  LAVA SHOP',
              overflow: TextOverflow.ellipsis,
              style: GoogleFonts.cinzel(
                fontSize: 18,
                fontWeight: FontWeight.w900,
                color: const Color(0xFFFFD700),
                shadows: const [Shadow(color: Color(0xFFFF6D00), blurRadius: 8)],
              ),
            ),
          ),
          const SizedBox(width: 8),
          Consumer<GameState>(
            builder: (ctx, gs, _) =>
                CoinDisplayWidget(coins: gs.coins, compact: true),
          ),
          const SizedBox(width: 2),
          IconButton(
            icon: const Icon(Icons.close, color: Color(0xFFFF6D00)),
            onPressed: () => Navigator.of(context).pop(),
          ),
        ],
      ),
    );
  }
}

// ── Upgrade tile ─────────────────────────────────────────────────────

class _UpgradeTile extends StatefulWidget {
  final UpgradeDefinition def;
  final bool locked;
  final bool isEasterEgg;

  const _UpgradeTile({
    required this.def,
    this.locked = false,
    this.isEasterEgg = false,
  });

  @override
  State<_UpgradeTile> createState() => _UpgradeTileState();
}

class _UpgradeTileState extends State<_UpgradeTile> {
  bool _buying = false;

  @override
  Widget build(BuildContext context) {
    if (widget.locked) return _buildLocked();

    return Consumer<GameState>(builder: (ctx, gs, _) {
      final tier = gs.getUpgradeTier(widget.def.id);
      final maxTier = widget.def.tiers.length;
      final isMaxed = tier >= maxTier;
      final currentTierData = isMaxed ? null : widget.def.tiers[tier];
      final canAfford = !isMaxed && gs.coins >= (currentTierData?.cost ?? 0);

      final borderColor = widget.isEasterEgg
          ? const Color(0xFF9C27B0)
          : isMaxed
              ? const Color(0xFFFFD700)
              : const Color(0xFFFF6D00).withValues(alpha: 0.4);

      return Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: widget.isEasterEgg
            ? BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: const Color(0xFF9C27B0), width: 1.5),
                gradient: LinearGradient(
                  colors: [
                    const Color(0xFF4A0070).withValues(alpha: 0.4),
                    const Color(0xFF1A0A00).withValues(alpha: 0.4),
                  ],
                ),
              )
            : null,
        child: Row(
          children: [
            // Icon
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.black.withValues(alpha: 0.4),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: borderColor, width: 1.5),
              ),
              child: Center(
                child: Text(widget.def.icon, style: const TextStyle(fontSize: 22)),
              ),
            ),
            const SizedBox(width: 10),
            // Name + description
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Flexible(
                        child: Text(
                          widget.def.name,
                          overflow: TextOverflow.ellipsis,
                          style: GoogleFonts.cinzel(
                            fontSize: 13,
                            fontWeight: FontWeight.bold,
                            color: widget.isEasterEgg
                                ? const Color(0xFFE040FB)
                                : const Color(0xFFFFD700),
                          ),
                        ),
                      ),
                      if (widget.def.isActive) ...[
                        const SizedBox(width: 4),
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 1),
                          decoration: BoxDecoration(
                            color: const Color(0xFF0D47A1),
                            borderRadius: BorderRadius.circular(4),
                          ),
                          child: const Text(
                            'ACTIVE',
                            style: TextStyle(fontSize: 8, color: Colors.lightBlue, letterSpacing: 1),
                          ),
                        ),
                      ],
                      const SizedBox(width: 4),
                      if (!widget.isEasterEgg)
                        _TierDots(current: tier, max: maxTier),
                    ],
                  ),
                  const SizedBox(height: 2),
                  Text(
                    isMaxed
                        ? '${widget.def.tiers.last.description}  ✓ MAX'
                        : currentTierData!.description,
                    style: TextStyle(
                      fontSize: 11,
                      color: isMaxed
                          ? const Color(0xFFFFD700).withValues(alpha: 0.6)
                          : Colors.white60,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            // Buy / maxed button
            if (isMaxed)
              _badge('MAX', const Color(0xFFFFD700))
            else
              _buyButton(currentTierData!.cost, canAfford, gs),
          ],
        ),
      );
    });
  }

  Widget _buildLocked() {
    return Opacity(
      opacity: 0.45,
      child: Container(
        margin: const EdgeInsets.symmetric(vertical: 4),
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        child: Row(
          children: [
            Container(
              width: 44,
              height: 44,
              decoration: BoxDecoration(
                color: Colors.grey.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(10),
                border: Border.all(color: Colors.grey.withValues(alpha: 0.3)),
              ),
              child: const Center(child: Icon(Icons.lock, color: Colors.grey, size: 20)),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    widget.def.name,
                    style: GoogleFonts.cinzel(
                      fontSize: 13, fontWeight: FontWeight.bold, color: Colors.grey,
                    ),
                  ),
                  const SizedBox(height: 2),
                  Text(
                    'Unlocks at Level ${widget.def.requiredLevel}',
                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                  ),
                ],
              ),
            ),
            _badge('LVL ${widget.def.requiredLevel}', Colors.grey),
          ],
        ),
      ),
    );
  }

  Widget _badge(String text, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.15),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color, width: 1),
      ),
      child: Text(
        text,
        style: GoogleFonts.cinzel(fontSize: 11, fontWeight: FontWeight.bold, color: color),
      ),
    );
  }

  Widget _buyButton(int cost, bool canAfford, GameState gs) {
    return GestureDetector(
      onTap: _buying || !canAfford
          ? null
          : () async {
              setState(() => _buying = true);
              await gs.buyUpgrade(widget.def.id);
              if (mounted) setState(() => _buying = false);
            },
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 150),
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 7),
        decoration: BoxDecoration(
          gradient: canAfford
              ? const LinearGradient(
                  colors: [Color(0xFFFF6D00), Color(0xFFFF3D00)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                )
              : null,
          color: canAfford ? null : Colors.grey.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(
            color: canAfford ? const Color(0xFFFFD700) : Colors.grey.withValues(alpha: 0.3),
            width: 1.5,
          ),
          boxShadow: canAfford
              ? [BoxShadow(color: const Color(0xFFFF6D00).withValues(alpha: 0.4), blurRadius: 6)]
              : null,
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            SizedBox(width: 14, height: 14, child: CustomPaint(painter: CoinPainter())),
            const SizedBox(width: 3),
            Text(
              _fmt(cost),
              style: GoogleFonts.cinzel(
                fontSize: 12,
                fontWeight: FontWeight.bold,
                color: canAfford ? Colors.white : Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _fmt(int c) {
    if (c >= 1000000000) return '${(c / 1000000000).toStringAsFixed(1)}B';
    if (c >= 1000000) return '${(c / 1000000).toStringAsFixed(1)}M';
    if (c >= 1000) return '${(c / 1000).toStringAsFixed(1)}K';
    return c.toString();
  }
}

class _TierDots extends StatelessWidget {
  final int current;
  final int max;
  const _TierDots({required this.current, required this.max});

  @override
  Widget build(BuildContext context) {
    // Show at most 10 dots; after that show "X/N"
    if (max > 10) {
      return Text(
        '$current/$max',
        style: TextStyle(
          fontSize: 10,
          color: current > 0
              ? const Color(0xFFFFD700)
              : Colors.grey.withValues(alpha: 0.5),
        ),
      );
    }
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(max, (i) {
        final filled = i < current;
        return Container(
          width: 5,
          height: 5,
          margin: const EdgeInsets.symmetric(horizontal: 1),
          decoration: BoxDecoration(
            shape: BoxShape.circle,
            color: filled ? const Color(0xFFFFD700) : Colors.grey.withValues(alpha: 0.3),
          ),
        );
      }),
    );
  }
}
