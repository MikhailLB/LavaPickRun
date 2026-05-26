import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/save_service.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final PageController _pageController = PageController();
  int _currentPage = 0;

  static const int _totalPages = 4;

  final List<_OnboardingPage> _pages = const [
    _OnboardingPage(
      bg: 'assets/Assets/1_bg_asset.webp',
      volcano: 'assets/Assets/1_volcano_asset.webp',
      title: 'Welcome to\nLava Peak Run!',
      subtitle: 'A volcanic clicker adventure\nacross 7 deadly peaks.',
      icon: '🌋',
      showTapHint: false,
    ),
    _OnboardingPage(
      bg: 'assets/Assets/2_bg_asset.webp',
      volcano: 'assets/Assets/2_volcano_asset.webp',
      title: 'Tap the Volcano!',
      subtitle: 'Every tap deals damage.\nDrain the volcano\'s HP to advance.',
      icon: '👆',
      showTapHint: true,
    ),
    _OnboardingPage(
      bg: 'assets/Assets/4_bg_asset.webp',
      volcano: 'assets/Assets/4_volcano_asset.webp',
      title: 'Upgrade Your Power',
      subtitle: 'Earn coins with every hit.\nBuy upgrades in the Lava Shop\nto devastate higher levels.',
      icon: '⚡',
      showTapHint: false,
    ),
    _OnboardingPage(
      bg: 'assets/Assets/7_bg_asset.webp',
      volcano: 'assets/Assets/7_volcano_asset.webp',
      title: '7 Epic Levels\nAwait You!',
      subtitle: 'From Ember Peak to Lava Peak.\nCan you conquer them all?',
      icon: '🏆',
      showTapHint: false,
    ),
  ];

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _next() {
    if (_currentPage < _totalPages - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 400),
        curve: Curves.easeInOut,
      );
    } else {
      _finish();
    }
  }

  void _finish() async {
    await SaveService.setOnboardingDone();
    if (mounted) {
      Navigator.of(context).pushReplacementNamed('/menu');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          // Swipeable pages
          PageView.builder(
            controller: _pageController,
            itemCount: _totalPages,
            onPageChanged: (i) => setState(() => _currentPage = i),
            itemBuilder: (ctx, i) => _PageContent(page: _pages[i]),
          ),

          // Persistent UI overlay
          SafeArea(
            child: Column(
              children: [
                // Skip button (top right)
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 12, right: 16),
                    child: _currentPage < _totalPages - 1
                        ? GestureDetector(
                            onTap: _finish,
                            child: Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 16, vertical: 8),
                              decoration: BoxDecoration(
                                color: Colors.black.withValues(alpha: 0.45),
                                borderRadius: BorderRadius.circular(20),
                                border: Border.all(
                                  color: Colors.white.withValues(alpha: 0.3),
                                ),
                              ),
                              child: Text(
                                'Skip',
                                style: GoogleFonts.cinzel(
                                  fontSize: 13,
                                  color: Colors.white70,
                                ),
                              ),
                            ),
                          )
                        : const SizedBox(height: 36),
                  ),
                ),

                const Spacer(),

                // Dot indicators
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_totalPages, (i) {
                    final active = i == _currentPage;
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: active ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: active
                            ? const Color(0xFFFFD700)
                            : Colors.white.withValues(alpha: 0.35),
                        borderRadius: BorderRadius.circular(4),
                        boxShadow: active
                            ? [
                                BoxShadow(
                                  color: const Color(0xFFFF6D00)
                                      .withValues(alpha: 0.7),
                                  blurRadius: 8,
                                )
                              ]
                            : null,
                      ),
                    );
                  }),
                ),

                const SizedBox(height: 24),

                // Next / Start button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 32),
                  child: _NextButton(
                    isLast: _currentPage == _totalPages - 1,
                    onTap: _next,
                  ),
                ),

                const SizedBox(height: 40),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ── Single page content ───────────────────────────────────────────────

class _OnboardingPage {
  final String bg;
  final String volcano;
  final String title;
  final String subtitle;
  final String icon;
  final bool showTapHint;

  const _OnboardingPage({
    required this.bg,
    required this.volcano,
    required this.title,
    required this.subtitle,
    required this.icon,
    required this.showTapHint,
  });
}

class _PageContent extends StatelessWidget {
  final _OnboardingPage page;
  const _PageContent({required this.page});

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        // Background
        Image.asset(page.bg, fit: BoxFit.cover),
        // Dark vignette
        Container(
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Color(0x55000000),
                Color(0xCC000000),
              ],
              stops: [0.0, 1.0],
            ),
          ),
        ),

        SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 24),

              // Icon badge
              Container(
                width: 56,
                height: 56,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.black.withValues(alpha: 0.5),
                  border: Border.all(
                      color: const Color(0xFFFF6D00), width: 2),
                  boxShadow: [
                    BoxShadow(
                      color: const Color(0xFFFF3D00).withValues(alpha: 0.5),
                      blurRadius: 14,
                    ),
                  ],
                ),
                child: Center(
                  child: Text(page.icon,
                      style: const TextStyle(fontSize: 26)),
                ),
              )
                  .animate()
                  .scale(
                    begin: const Offset(0.6, 0.6),
                    end: const Offset(1.0, 1.0),
                    duration: 500.ms,
                    curve: Curves.elasticOut,
                  )
                  .fadeIn(duration: 300.ms),

              const SizedBox(height: 16),

              // Title
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 32),
                child: Text(
                  page.title,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    fontSize: 26,
                    fontWeight: FontWeight.w900,
                    color: const Color(0xFFFFD700),
                    height: 1.25,
                    shadows: const [
                      Shadow(
                          color: Color(0xFFFF3D00),
                          blurRadius: 12),
                      Shadow(
                          color: Colors.black,
                          blurRadius: 4,
                          offset: Offset(1, 2)),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 150.ms, duration: 500.ms)
                    .slideY(begin: 0.15, end: 0),
              ),

              const SizedBox(height: 12),

              // Subtitle
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 40),
                child: Text(
                  page.subtitle,
                  textAlign: TextAlign.center,
                  style: GoogleFonts.cinzel(
                    fontSize: 14,
                    color: Colors.white.withValues(alpha: 0.85),
                    height: 1.6,
                    shadows: const [
                      Shadow(color: Colors.black, blurRadius: 6),
                    ],
                  ),
                )
                    .animate()
                    .fadeIn(delay: 300.ms, duration: 500.ms)
                    .slideY(begin: 0.1, end: 0),
              ),

              const Spacer(),

              // Volcano
              Stack(
                alignment: Alignment.center,
                children: [
                  // Glow
                  Container(
                    width: 240,
                    height: 240,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: const Color(0xFFFF3D00).withValues(alpha: 0.35),
                          blurRadius: 60,
                          spreadRadius: 20,
                        ),
                      ],
                    ),
                  ),
                  Image.asset(
                    page.volcano,
                    height: 260,
                    fit: BoxFit.contain,
                  )
                      .animate(
                          onPlay: (c) => c.repeat(reverse: true))
                      .scale(
                        begin: const Offset(1.0, 1.0),
                        end: const Offset(1.03, 1.03),
                        duration: 2000.ms,
                        curve: Curves.easeInOut,
                      ),

                  // Tap hint ripple for page 2
                  if (page.showTapHint)
                    _TapRipple(),
                ],
              ),

              const SizedBox(height: 100),
            ],
          ),
        ),
      ],
    );
  }
}

// ── Tap ripple animation ─────────────────────────────────────────────

class _TapRipple extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Column(
      mainAxisSize: MainAxisSize.min,
      children: [
        const SizedBox(height: 20),
        const Text('👆', style: TextStyle(fontSize: 32))
            .animate(onPlay: (c) => c.repeat(reverse: true))
            .scale(
              begin: const Offset(0.85, 0.85),
              end: const Offset(1.15, 1.15),
              duration: 700.ms,
              curve: Curves.easeInOut,
            )
            .fadeIn(),
      ],
    );
  }
}

// ── Next / Start button ──────────────────────────────────────────────

class _NextButton extends StatefulWidget {
  final bool isLast;
  final VoidCallback onTap;
  const _NextButton({required this.isLast, required this.onTap});

  @override
  State<_NextButton> createState() => _NextButtonState();
}

class _NextButtonState extends State<_NextButton> {
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
          padding: const EdgeInsets.symmetric(vertical: 18),
          decoration: BoxDecoration(
            gradient: widget.isLast
                ? const LinearGradient(
                    colors: [Color(0xFFFFD700), Color(0xFFFF6D00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : const LinearGradient(
                    colors: [Color(0xFFFF6D00), Color(0xFFFF3D00)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: widget.isLast
                  ? const Color(0xFFFFFFFF).withValues(alpha: 0.4)
                  : const Color(0xFFFFD700),
              width: 1.5,
            ),
            boxShadow: [
              BoxShadow(
                color: const Color(0xFFFF3D00).withValues(alpha: 0.5),
                blurRadius: 16,
                spreadRadius: 2,
              ),
            ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                widget.isLast
                    ? '🌋  START PLAYING!'
                    : 'Next  →',
                style: GoogleFonts.cinzel(
                  fontSize: widget.isLast ? 18 : 16,
                  fontWeight: FontWeight.w900,
                  color: Colors.white,
                  letterSpacing: widget.isLast ? 1.5 : 1,
                  shadows: const [
                    Shadow(color: Colors.black, blurRadius: 4),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
