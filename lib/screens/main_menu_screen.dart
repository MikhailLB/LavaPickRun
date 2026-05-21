import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../widgets/webview_screen.dart';
import '../widgets/settings_overlay.dart';

class MainMenuScreen extends StatelessWidget {
  const MainMenuScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          // Background
          Image.asset(
            'assets/Assets/1_bg_asset.webp',
            fit: BoxFit.cover,
          ),
          // Dark overlay for readability
          Container(
            decoration: BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [
                  Colors.black.withValues(alpha: 0.3),
                  Colors.black.withValues(alpha: 0.6),
                ],
              ),
            ),
          ),
          // Content
          SafeArea(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                // Settings gear top-right
                Align(
                  alignment: Alignment.topRight,
                  child: Padding(
                    padding: const EdgeInsets.only(top: 8, right: 12),
                    child: _SettingsButton(),
                  ),
                ),
                const Spacer(flex: 1),
                // Game name logo
                Image.asset(
                  'assets/Game_Name.png',
                  width: MediaQuery.of(context).size.width * 0.85,
                  fit: BoxFit.contain,
                )
                    .animate(onPlay: (c) => c.repeat(reverse: true))
                    .scale(
                      begin: const Offset(1.0, 1.0),
                      end: const Offset(1.04, 1.04),
                      duration: 2000.ms,
                      curve: Curves.easeInOut,
                    )
                    .shimmer(
                      duration: 3000.ms,
                      color: const Color(0xFFFFD700).withValues(alpha: 0.3),
                    ),
                const Spacer(flex: 1),
                // Buttons
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 40),
                  child: Column(
                    children: [
                      _LavaButton(
                        label: 'PLAY',
                        icon: Icons.local_fire_department,
                        onTap: () =>
                            Navigator.of(context).pushNamed('/level-select'),
                        isPrimary: true,
                      ),
                      const SizedBox(height: 16),
                      Row(
                        children: [
                          Expanded(
                            child: _LavaButton(
                              label: 'Privacy',
                              icon: Icons.privacy_tip_outlined,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const WebViewScreen(
                                    url:
                                        'https://lavapeakrun.com/privacy-policy.html',
                                    title: 'Privacy Policy',
                                  ),
                                ),
                              ),
                              isPrimary: false,
                              small: true,
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: _LavaButton(
                              label: 'Support',
                              icon: Icons.support_agent_outlined,
                              onTap: () => Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (_) => const WebViewScreen(
                                    url:
                                        'https://lavapeakrun.com/support.html',
                                    title: 'Support',
                                  ),
                                ),
                              ),
                              isPrimary: false,
                              small: true,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const Spacer(flex: 1),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _LavaButton extends StatefulWidget {
  final String label;
  final IconData icon;
  final VoidCallback onTap;
  final bool isPrimary;
  final bool small;

  const _LavaButton({
    required this.label,
    required this.icon,
    required this.onTap,
    this.isPrimary = false,
    this.small = false,
  });

  @override
  State<_LavaButton> createState() => _LavaButtonState();
}

class _LavaButtonState extends State<_LavaButton> {
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
          padding: EdgeInsets.symmetric(
            vertical: widget.small ? 12 : 18,
            horizontal: 20,
          ),
          decoration: BoxDecoration(
            gradient: widget.isPrimary
                ? const LinearGradient(
                    colors: [Color(0xFFFF6D00), Color(0xFFFF3D00), Color(0xFFB71C1C)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.6),
                      Colors.black.withValues(alpha: 0.4),
                    ],
                  ),
            borderRadius: BorderRadius.circular(widget.isPrimary ? 16 : 12),
            border: Border.all(
              color: widget.isPrimary
                  ? const Color(0xFFFFD700)
                  : const Color(0xFFFF6D00).withValues(alpha: 0.5),
              width: widget.isPrimary ? 2 : 1,
            ),
            boxShadow: widget.isPrimary
                ? [
                    BoxShadow(
                      color: const Color(0xFFFF3D00).withValues(alpha: 0.5),
                      blurRadius: 15,
                      spreadRadius: 2,
                    ),
                    BoxShadow(
                      color: const Color(0xFFFFD700).withValues(alpha: 0.2),
                      blurRadius: 8,
                    ),
                  ]
                : [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.4),
                      blurRadius: 8,
                    ),
                  ],
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                widget.icon,
                color: widget.isPrimary
                    ? Colors.white
                    : const Color(0xFFFF6D00),
                size: widget.small ? 18 : 22,
              ),
              const SizedBox(width: 8),
              Text(
                widget.label,
                style: GoogleFonts.cinzel(
                  fontSize: widget.small ? 13 : 20,
                  fontWeight: FontWeight.w900,
                  color: widget.isPrimary
                      ? Colors.white
                      : const Color(0xFFFFD700),
                  letterSpacing: 2,
                  shadows: [
                    const Shadow(color: Colors.black, blurRadius: 4),
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

class _SettingsButton extends StatelessWidget {
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
        width: 44,
        height: 44,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.55),
          shape: BoxShape.circle,
          border: Border.all(
            color: const Color(0xFFFF6D00).withValues(alpha: 0.7),
            width: 1.5,
          ),
          boxShadow: [
            BoxShadow(
              color: const Color(0xFFFF6D00).withValues(alpha: 0.3),
              blurRadius: 8,
            ),
          ],
        ),
        child: const Icon(
          Icons.settings,
          color: Color(0xFFFFD700),
          size: 22,
        ),
      ),
    );
  }
}
