import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/peaks.dart';
import '../data/progress_store.dart';
import '../engine/ascent_engine.dart';
import '../engine/models.dart';
import '../state/store.dart';
import '../ui/painters/ember_icon.dart';
import '../ui/theme.dart';
import '../ui/widgets/common.dart';
import '../ui/widgets/ember_chip.dart';
import '../ui/widgets/settings_sheet.dart';
import 'info_web_screen.dart';

/// Home / start screen — a bold hero layout with a glowing summit, a live
/// progress strip, and a stacked menu of rich action rows.
class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _glow;

  @override
  void initState() {
    super.initState();
    _glow = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 3200),
    )..repeat(reverse: true);
  }

  @override
  void dispose() {
    _glow.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final engine = context.read<AscentEngine>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BackdropLayer(
              asset: 'assets/Assets/7_bg_asset.webp', darken: 0.58),
          SafeArea(
            child: ListenableBuilder(
              listenable: engine,
              builder: (context, _) {
                return Column(
                  children: [
                    // ── Header ──────────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.fromLTRB(20, 10, 12, 0),
                      child: Row(
                        children: [
                          Text('EMBER ASCENT',
                              style: AppText.label(13,
                                  color: Palette.gold, spacing: 4)),
                          const Spacer(),
                          RoundIconButton(
                            icon: Icons.settings,
                            onTap: () => showSettingsSheet(context),
                          ),
                        ],
                      ),
                    ),

                    // ── Hero summit ─────────────────────────────────
                    Expanded(
                      child: Center(
                        child: AnimatedBuilder(
                          animation: _glow,
                          builder: (context, child) {
                            final t = _glow.value;
                            return Container(
                              width: size.width * 0.78,
                              decoration: BoxDecoration(
                                shape: BoxShape.circle,
                                boxShadow: [
                                  BoxShadow(
                                    color: Palette.emberHot
                                        .withValues(alpha: 0.25 + t * 0.2),
                                    blurRadius: 60 + t * 30,
                                    spreadRadius: 8,
                                  ),
                                ],
                              ),
                              child: child,
                            );
                          },
                          child: Image.asset(
                            Peaks.all.last.sprite,
                            width: size.width * 0.66,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                    ),

                    // ── Progress strip ──────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: _StatCard(
                              icon: Icons.star_rounded,
                              value: '${ProgressStore.totalStars()}',
                              suffix: '/ ${Peaks.count * 3 * 3}',
                              label: 'STARS',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              icon: Icons.terrain,
                              value:
                                  '${ProgressStore.peaksClearedOn(Difficulty.normal)}',
                              suffix: '/ ${Peaks.count}',
                              label: 'PEAKS',
                            ),
                          ),
                          const SizedBox(width: 10),
                          Expanded(
                            child: _StatCard(
                              iconWidget: const EmberIcon(size: 18),
                              value: EmberChip.format(engine.embers),
                              label: 'EMBERS',
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 14),

                    // ── Menu rows ───────────────────────────────────
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Column(
                        children: [
                          _MenuRow(
                            icon: Icons.play_arrow_rounded,
                            title: 'CLIMB',
                            subtitle: 'Pick a route and begin the ascent',
                            primary: true,
                            onTap: () =>
                                Navigator.of(context).pushNamed(Routes.peaks),
                          ),
                          const SizedBox(height: 10),
                          _MenuRow(
                            icon: Icons.handyman,
                            title: 'FORGE',
                            subtitle: 'Spend embers to sharpen your gear',
                            onTap: () =>
                                Navigator.of(context).pushNamed(Routes.forge),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 12),
                    Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 20),
                      child: Row(
                        children: [
                          Expanded(
                            child: EmberButton(
                              label: 'Privacy',
                              icon: Icons.privacy_tip_outlined,
                              compact: true,
                              onTap: () => _openWeb(
                                context,
                                'https://lavapeakrun.com/privacy-policy.html',
                                'Privacy Policy',
                              ),
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: EmberButton(
                              label: 'Support',
                              icon: Icons.support_agent_outlined,
                              compact: true,
                              onTap: () => _openWeb(
                                context,
                                'https://lavapeakrun.com/support.html',
                                'Support',
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                    const SizedBox(height: 16),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  void _openWeb(BuildContext context, String url, String title) {
    Navigator.of(context).push(
      MaterialPageRoute(builder: (_) => InfoWebScreen(url: url, title: title)),
    );
  }
}

class _StatCard extends StatelessWidget {
  const _StatCard({
    this.icon,
    this.iconWidget,
    required this.value,
    this.suffix,
    required this.label,
  });

  final IconData? icon;
  final Widget? iconWidget;
  final String value;
  final String? suffix;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 10, horizontal: 8),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.45),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: Palette.ember.withValues(alpha: 0.4)),
      ),
      child: Column(
        children: [
          iconWidget ?? Icon(icon, color: Palette.gold, size: 18),
          const SizedBox(height: 4),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.baseline,
            textBaseline: TextBaseline.alphabetic,
            children: [
              Flexible(
                child: Text(value,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title(16, color: Palette.gold)),
              ),
              if (suffix != null)
                Text(' $suffix',
                    style: AppText.label(9, color: Colors.white54, spacing: 0)),
            ],
          ),
          const SizedBox(height: 2),
          Text(label,
              style: AppText.label(9, color: Palette.ember, spacing: 1.5)),
        ],
      ),
    );
  }
}

class _MenuRow extends StatefulWidget {
  const _MenuRow({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.primary = false,
  });

  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final bool primary;

  @override
  State<_MenuRow> createState() => _MenuRowState();
}

class _MenuRowState extends State<_MenuRow> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _down = true),
      onTapCancel: () => setState(() => _down = false),
      onTapUp: (_) {
        setState(() => _down = false);
        widget.onTap();
      },
      child: AnimatedScale(
        scale: _down ? 0.97 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          decoration: BoxDecoration(
            gradient: widget.primary
                ? const LinearGradient(
                    colors: [Palette.ember, Palette.emberHot, Palette.emberDeep],
                    begin: Alignment.centerLeft,
                    end: Alignment.centerRight,
                  )
                : LinearGradient(colors: [
                    Colors.black.withValues(alpha: 0.55),
                    Colors.black.withValues(alpha: 0.4),
                  ]),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.primary
                  ? Palette.gold
                  : Palette.ember.withValues(alpha: 0.5),
              width: widget.primary ? 2 : 1.4,
            ),
            boxShadow: widget.primary
                ? [
                    BoxShadow(
                      color: Palette.emberHot.withValues(alpha: 0.45),
                      blurRadius: 16,
                      spreadRadius: 1,
                    ),
                  ]
                : null,
          ),
          child: Row(
            children: [
              Container(
                width: 44,
                height: 44,
                alignment: Alignment.center,
                decoration: BoxDecoration(
                  color: Colors.black.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(widget.icon,
                    color: widget.primary ? Colors.white : Palette.gold,
                    size: 26),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(widget.title,
                        style: AppText.title(20,
                            color: widget.primary
                                ? Colors.white
                                : Palette.gold)),
                    const SizedBox(height: 2),
                    Text(widget.subtitle,
                        style: AppText.body(12,
                            color: widget.primary
                                ? Colors.white.withValues(alpha: 0.85)
                                : null)),
                  ],
                ),
              ),
              Icon(Icons.chevron_right,
                  color: widget.primary
                      ? Colors.white
                      : Palette.ember.withValues(alpha: 0.7)),
            ],
          ),
        ),
      ),
    );
  }
}
