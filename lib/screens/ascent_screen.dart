import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';

import '../app/routes.dart';
import '../engine/ascent_engine.dart';
import '../engine/models.dart';
import '../state/store.dart';
import '../ui/painters/game_canvas.dart';
import '../ui/theme.dart';
import '../ui/widgets/common.dart';
import '../ui/widgets/heat_bar.dart';
import '../ui/widgets/settings_sheet.dart';
import '../ui/widgets/strike_flash.dart';

/// The live climb. Owns the frame ticker that advances the simulation and the
/// per-frame clock that drives the custom-painted overlays.
class AscentScreen extends StatefulWidget {
  const AscentScreen({super.key});

  @override
  State<AscentScreen> createState() => _AscentScreenState();
}

class _AscentScreenState extends State<AscentScreen>
    with TickerProviderStateMixin {
  late final AscentEngine _engine;
  late final Ticker _ticker;
  late final AnimationController _shake;

  final ValueNotifier<double> _clock = ValueNotifier<double>(0);
  Duration _last = Duration.zero;
  bool _routedOut = false;

  @override
  void initState() {
    super.initState();
    _engine = GameScope.read<AscentEngine>(context);
    _shake = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 260),
    );
    _engine.addListener(_onEngine);
    _ticker = createTicker(_onTick)..start();
  }

  void _onTick(Duration elapsed) {
    var dt = (elapsed - _last).inMicroseconds / 1e6;
    _last = elapsed;
    if (dt <= 0) return;
    if (dt > 1 / 30) dt = 1 / 30; // clamp big stalls
    _engine.tick(dt);
    _clock.value = elapsed.inMicroseconds / 1e6;
  }

  void _onEngine() {
    if (_routedOut) return;
    if (_engine.phase == RunPhase.summit ||
        _engine.phase == RunPhase.collapsed) {
      _routedOut = true;
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (mounted) {
          Navigator.of(context).pushReplacementNamed(Routes.summit);
        }
      });
    }
  }

  void _strike() {
    _engine.strike();
    _shake.forward(from: 0);
  }

  @override
  void dispose() {
    _engine.removeListener(_onEngine);
    _ticker.dispose();
    _shake.dispose();
    _clock.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final peak = _engine.peak;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          BackdropLayer(asset: peak.backdrop, darken: 0.42),

          // Per-frame painted overlay: gauge, ascent track, eruption ring.
          IgnorePointer(
            child: CustomPaint(
              size: Size.infinite,
              painter: GameCanvasPainter(engine: _engine, clock: _clock),
            ),
          ),

          SafeArea(
            child: Column(
              children: [
                _TopBar(engine: _engine),
                const SizedBox(height: 6),
                _StabilityRow(engine: _engine),
                const SizedBox(height: 6),
                _ObjectiveStrip(engine: _engine),
                Expanded(
                  child: Listener(
                    behavior: HitTestBehavior.opaque,
                    onPointerDown: (_) => _strike(),
                    child: Center(
                      child: AnimatedBuilder(
                        animation: _shake,
                        builder: (context, child) {
                          final s = _shake.value;
                          final dx = (s < 0.5 ? s : 1 - s) * 10;
                          return Transform.translate(
                            offset: Offset(dx, 0),
                            child: Transform.scale(
                              scale: 1 - (s < 0.4 ? s : 0.4) * 0.06,
                              child: child,
                            ),
                          );
                        },
                        child: Padding(
                          padding: const EdgeInsets.symmetric(horizontal: 56),
                          child: Image.asset(peak.sprite, fit: BoxFit.contain),
                        ),
                      ),
                    ),
                  ),
                ),
                _BottomPanel(engine: _engine, clock: _clock),
              ],
            ),
          ),

          // Floating strike feedback.
          IgnorePointer(
            child: ListenableBuilder(
              listenable: _engine,
              builder: (context, _) {
                return Stack(
                  fit: StackFit.expand,
                  children: [
                    for (final f in _engine.flashes)
                      StrikeFlashView(
                        key: ValueKey(f.id),
                        flash: f,
                        onDone: () => _engine.clearFlash(f.id),
                      ),
                  ],
                );
              },
            ),
          ),

          // Standby prompt.
          IgnorePointer(
            child: ListenableBuilder(
              listenable: _engine,
              builder: (context, _) {
                if (_engine.phase != RunPhase.ready) {
                  return const SizedBox.shrink();
                }
                return Center(
                  child: _TapToBegin(
                    hint: _engine.hasTrial ? _engine.trialHint : null,
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _TopBar extends StatelessWidget {
  const _TopBar({required this.engine});
  final AscentEngine engine;

  @override
  Widget build(BuildContext context) {
    final peak = engine.peak;
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 6, 12, 0),
      child: Row(
        children: [
          RoundIconButton(
            icon: Icons.close,
            size: 38,
            onTap: () {
              engine.abandonRun();
              Navigator.of(context).pop();
            },
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                    'PEAK ${peak.displayNumber} · ${engine.difficulty.label.toUpperCase()}',
                    style: AppText.label(10,
                        color: Palette.ember, spacing: 1.5)),
                Text(peak.name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: AppText.title(17, color: Palette.gold)),
              ],
            ),
          ),
          RoundIconButton(
            icon: Icons.tune,
            size: 38,
            onTap: () => showSettingsSheet(context),
          ),
        ],
      ),
    );
  }
}

class _StabilityRow extends StatelessWidget {
  const _StabilityRow({required this.engine});
  final AscentEngine engine;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: engine,
      builder: (context, _) {
        return Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: List.generate(engine.maxStability, (i) {
            final alive = i < engine.stability;
            return Padding(
              padding: const EdgeInsets.symmetric(horizontal: 3),
              child: Icon(
                alive ? Icons.shield : Icons.shield_outlined,
                size: 20,
                color: alive
                    ? Palette.steady
                    : Colors.white.withValues(alpha: 0.25),
              ),
            );
          }),
        );
      },
    );
  }
}

class _ObjectiveStrip extends StatelessWidget {
  const _ObjectiveStrip({required this.engine});
  final AscentEngine engine;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: engine,
      builder: (context, _) {
        final comboDone = engine.maxCombo >= engine.comboGoal;
        final flawless = engine.burns == 0;
        return Column(
          children: [
            if (engine.hasTrial)
              Padding(
                padding: const EdgeInsets.only(bottom: 6),
                child: _TrialPill(
                  label: engine.trialLabel,
                ),
              ),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _ObjPill(
                  icon: Icons.bolt,
                  label: 'COMBO ${engine.maxCombo}/${engine.comboGoal}',
                  done: comboDone,
                ),
                const SizedBox(width: 8),
                _ObjPill(
                  icon: Icons.shield_moon,
                  label: 'FLAWLESS',
                  done: flawless,
                ),
              ],
            ),
          ],
        );
      },
    );
  }
}

class _TrialPill extends StatelessWidget {
  const _TrialPill({required this.label});
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        gradient: LinearGradient(colors: [
          Palette.emberHot.withValues(alpha: 0.85),
          Palette.emberDeep.withValues(alpha: 0.85),
        ]),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Palette.gold, width: 1.2),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(Icons.whatshot_rounded, size: 14, color: Palette.gold),
          const SizedBox(width: 6),
          Text('TRIAL · ${label.toUpperCase()}',
              style: AppText.label(10, color: Colors.white, spacing: 1.2)),
        ],
      ),
    );
  }
}

class _ObjPill extends StatelessWidget {
  const _ObjPill({
    required this.icon,
    required this.label,
    required this.done,
  });

  final IconData icon;
  final String label;
  final bool done;

  @override
  Widget build(BuildContext context) {
    final color = done ? Palette.steady : Colors.white.withValues(alpha: 0.45);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.5), width: 1),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 13, color: color),
          const SizedBox(width: 5),
          Text(label, style: AppText.label(10, color: color, spacing: 1)),
        ],
      ),
    );
  }
}

class _BottomPanel extends StatelessWidget {
  const _BottomPanel({required this.engine, required this.clock});
  final AscentEngine engine;
  final ValueNotifier<double> clock;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(24, 4, 24, 16),
      child: Column(
        children: [
          ListenableBuilder(
            listenable: engine,
            builder: (context, _) => _StatusBanner(engine: engine),
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Icon(Icons.thermostat,
                  size: 16, color: Palette.ember.withValues(alpha: 0.8)),
              const SizedBox(width: 6),
              Expanded(child: HeatBar(engine: engine, frame: clock)),
            ],
          ),
        ],
      ),
    );
  }
}

class _StatusBanner extends StatelessWidget {
  const _StatusBanner({required this.engine});
  final AscentEngine engine;

  @override
  Widget build(BuildContext context) {
    String text;
    Color color;
    if (engine.overheated || engine.isVenting) {
      text = 'OVERHEAT · VENTING';
      color = Palette.cool;
    } else if (engine.isDanger) {
      text = 'ERUPTING · HOLD!';
      color = Palette.danger;
    } else if (engine.isTelegraph) {
      text = 'WARNING · STEADY';
      color = Palette.gold;
    } else if (engine.momentum > 1) {
      text =
          '×${engine.momentumMultiplier.toStringAsFixed(1)} · ${engine.momentum} COMBO';
      color = Palette.steady;
    } else {
      text = 'STRIKE ON THE GOLD BAND';
      color = Palette.cream.withValues(alpha: 0.7);
    }
    return AnimatedSwitcher(
      duration: const Duration(milliseconds: 160),
      child: Text(
        text,
        key: ValueKey(text),
        style: AppText.label(13, color: color, spacing: 2),
      ),
    );
  }
}

class _TapToBegin extends StatelessWidget {
  const _TapToBegin({this.hint});
  final String? hint;

  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 22, vertical: 12),
          decoration: BoxDecoration(
            color: Colors.black.withValues(alpha: 0.5),
            borderRadius: BorderRadius.circular(30),
            border: Border.all(color: Palette.gold.withValues(alpha: 0.7)),
          ),
          child: Text('TAP TO BEGIN', style: AppText.display(20)),
        ),
        if (hint != null) ...[
          const SizedBox(height: 14),
          Container(
            margin: const EdgeInsets.symmetric(horizontal: 36),
            padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
            decoration: BoxDecoration(
              color: Colors.black.withValues(alpha: 0.55),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: Palette.emberHot.withValues(alpha: 0.6)),
            ),
            child: Text(
              hint!,
              textAlign: TextAlign.center,
              style: AppText.body(13, color: Palette.cream),
            ),
          ),
        ],
      ],
    );
  }
}
