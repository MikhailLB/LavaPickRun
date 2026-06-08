import 'package:flutter/material.dart';

import '../app/routes.dart';
import '../data/progress_store.dart';
import '../ui/theme.dart';
import '../ui/widgets/common.dart';

@immutable
class _Page {
  const _Page({
    required this.icon,
    required this.title,
    required this.body,
    required this.accent,
  });
  final IconData icon;
  final String title;
  final String body;
  final Color accent;
}

/// Onboarding carousel. Shown automatically on first launch (before the menu)
/// and re-openable any time from Settings / the menu as "How to Play".
class TutorialScreen extends StatefulWidget {
  const TutorialScreen({super.key, this.onDone});

  /// When provided (first-run flow) it is called instead of popping.
  final VoidCallback? onDone;

  @override
  State<TutorialScreen> createState() => _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pc = PageController();
  int _page = 0;

  static const List<_Page> _pages = [
    _Page(
      icon: Icons.touch_app_rounded,
      title: 'Strike the Band',
      body:
          'A marker sweeps up and down the gauge. Tap exactly when it crosses '
          'the gold band to land a PERFECT strike and climb faster.',
      accent: Palette.gold,
    ),
    _Page(
      icon: Icons.bolt_rounded,
      title: 'Build Momentum',
      body:
          'Consecutive perfect strikes build a combo that multiplies your '
          'ascent and the embers you earn. Break the rhythm and it resets.',
      accent: Palette.ember,
    ),
    _Page(
      icon: Icons.thermostat_rounded,
      title: 'Mind the Heat',
      body:
          'Every strike heats the core. Let it max out and you overheat and '
          'must wait while it vents. Pace yourself \u2014 don\u2019t mash.',
      accent: Palette.emberHot,
    ),
    _Page(
      icon: Icons.warning_amber_rounded,
      title: 'Never Strike an Eruption',
      body:
          'When the ring flares red the volcano is erupting. Striking then '
          'burns you and costs stability. Lose all stability and the climb ends.',
      accent: Palette.danger,
    ),
    _Page(
      icon: Icons.water_drop_rounded,
      title: 'More to Explore',
      body:
          'Spend embers in the Forge, solve Lava Flow pipe puzzles, unlock the '
          'Volcano Codex and chase achievements. Good luck, climber!',
      accent: Palette.cool,
    ),
  ];

  @override
  void dispose() {
    _pc.dispose();
    super.dispose();
  }

  void _finish() {
    ProgressStore.setTutorialSeen();
    if (widget.onDone != null) {
      widget.onDone!();
      return;
    }
    final nav = Navigator.of(context);
    // "How to Play" (pushed over the menu) pops back; first-run (replaced the
    // boot route, nothing beneath) hands off to the home menu instead.
    if (nav.canPop()) {
      nav.pop();
    } else {
      nav.pushReplacementNamed(Routes.home);
    }
  }

  @override
  Widget build(BuildContext context) {
    final last = _page == _pages.length - 1;
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BackdropLayer(
              asset: 'assets/Assets/1_bg_asset.webp', darken: 0.6),
          SafeArea(
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: TextButton(
                      onPressed: _finish,
                      child: Text('Skip',
                          style: AppText.label(13, color: Colors.white70)),
                    ),
                  ),
                ),
                Expanded(
                  child: PageView.builder(
                    controller: _pc,
                    onPageChanged: (i) => setState(() => _page = i),
                    itemCount: _pages.length,
                    itemBuilder: (context, i) => _PageView(page: _pages[i]),
                  ),
                ),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) {
                    final active = i == _page;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 200),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 22 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active ? Palette.gold : Colors.white30,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
                Padding(
                  padding: const EdgeInsets.all(20),
                  child: EmberButton(
                    label: last ? 'START CLIMBING' : 'NEXT',
                    icon: last ? Icons.local_fire_department : Icons.arrow_forward,
                    primary: true,
                    onTap: () {
                      if (last) {
                        _finish();
                      } else {
                        _pc.nextPage(
                          duration: const Duration(milliseconds: 280),
                          curve: Curves.easeOut,
                        );
                      }
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

class _PageView extends StatelessWidget {
  const _PageView({required this.page});
  final _Page page;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 110,
            height: 110,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: Colors.black.withValues(alpha: 0.4),
              border: Border.all(color: page.accent, width: 2),
              boxShadow: [
                BoxShadow(
                    color: page.accent.withValues(alpha: 0.4), blurRadius: 24),
              ],
            ),
            child: Icon(page.icon, color: page.accent, size: 54),
          ),
          const SizedBox(height: 28),
          Text(page.title, textAlign: TextAlign.center, style: AppText.display(28)),
          const SizedBox(height: 14),
          Text(page.body,
              textAlign: TextAlign.center, style: AppText.body(15)),
        ],
      ),
    );
  }
}
