import 'package:flutter/material.dart';

import '../data/progress_store.dart';
import '../engine/flow_engine.dart';
import '../ui/painters/flow_painter.dart';
import '../ui/theme.dart';
import '../ui/widgets/common.dart';

/// Lava Flow — the pipe-rotation puzzle mode. A self-contained screen that owns
/// its own [FlowEngine]; tapping a tile rotates it, and connecting the source
/// to the drain clears the level.
class FlowScreen extends StatefulWidget {
  const FlowScreen({super.key});

  @override
  State<FlowScreen> createState() => _FlowScreenState();
}

class _FlowScreenState extends State<FlowScreen> {
  final FlowEngine _engine = FlowEngine();

  @override
  void initState() {
    super.initState();
    _engine.load(ProgressStore.flowLevel);
  }

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  void _next() {
    _engine.load(_engine.level + 1);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BackdropLayer(
              asset: 'assets/Assets/4_bg_asset.webp', darken: 0.66),
          SafeArea(
            child: ListenableBuilder(
              listenable: _engine,
              builder: (context, _) {
                return Column(
                  children: [
                    _header(context),
                    const SizedBox(height: 8),
                    _legend(),
                    const SizedBox(height: 8),
                    Expanded(
                      child: Center(
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: AspectRatio(
                            aspectRatio: 1,
                            child: _board(),
                          ),
                        ),
                      ),
                    ),
                    if (_engine.solved) _solvedBar(context),
                    const SizedBox(height: 14),
                  ],
                );
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _header(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(8, 8, 16, 0),
      child: Row(
        children: [
          RoundIconButton(
            icon: Icons.arrow_back_ios_new,
            onTap: () => Navigator.of(context).pop(),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('LAVA FLOW', style: AppText.display(20)),
                Text('Level ${_engine.level + 1}',
                    style:
                        AppText.label(11, color: Palette.ember, spacing: 1.5)),
              ],
            ),
          ),
          _stat('MOVES', '${_engine.moves}'),
          const SizedBox(width: 10),
          RoundIconButton(
            icon: Icons.refresh,
            size: 38,
            onTap: _engine.reset,
          ),
        ],
      ),
    );
  }

  Widget _stat(String label, String value) {
    return Column(
      children: [
        Text(value, style: AppText.title(18, color: Palette.gold)),
        Text(label, style: AppText.label(8, color: Palette.ember, spacing: 1)),
      ],
    );
  }

  Widget _legend() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Text(
        'Tap pipes to rotate them. Connect the blue source to the gold drain.',
        textAlign: TextAlign.center,
        style: AppText.body(12),
      ),
    );
  }

  Widget _board() {
    final n = _engine.size;
    return Container(
      padding: const EdgeInsets.all(6),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.4),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Palette.ember.withValues(alpha: 0.5)),
      ),
      child: Column(
        children: [
          for (var r = 0; r < n; r++)
            Expanded(
              child: Row(
                children: [
                  for (var c = 0; c < n; c++)
                    Expanded(
                      child: GestureDetector(
                        onTap: () => _engine.rotate(r, c),
                        child: Padding(
                          padding: const EdgeInsets.all(2),
                          child: CustomPaint(
                            painter: FlowTilePainter(
                              mask: _engine.maskAt(r, c),
                              lit: _engine.isLit(r, c),
                              isSource: _engine.isSource(r, c),
                              isDrain: _engine.isDrain(r, c),
                            ),
                          ),
                        ),
                      ),
                    ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _solvedBar(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 20),
      child: GlassPanel(
        glow: true,
        accent: Palette.gold,
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.check_circle, color: Palette.steady),
                const SizedBox(width: 8),
                Text('FLOW RESTORED!', style: AppText.display(20)),
              ],
            ),
            const SizedBox(height: 4),
            Text('Solved in ${_engine.moves} moves',
                style: AppText.body(13)),
            const SizedBox(height: 14),
            EmberButton(
              label: 'NEXT LEVEL',
              icon: Icons.arrow_forward,
              primary: true,
              onTap: _next,
            ),
          ],
        ),
      ),
    );
  }
}
