import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:google_fonts/google_fonts.dart';
import '../services/settings_service.dart';

class SettingsOverlay extends StatefulWidget {
  const SettingsOverlay({super.key});

  @override
  State<SettingsOverlay> createState() => _SettingsOverlayState();
}

class _SettingsOverlayState extends State<SettingsOverlay> {
  late bool _soundOn;
  late bool _vibrationOn;

  @override
  void initState() {
    super.initState();
    _soundOn = SettingsService.soundEnabled;
    _vibrationOn = SettingsService.vibrationEnabled;
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => Navigator.of(context).pop(),
      child: Container(
        color: Colors.black.withValues(alpha: 0.72),
        child: Center(
          child: GestureDetector(
            onTap: () {},
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 40),
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [Color(0xFF1A0A00), Color(0xFF2D0E00)],
                ),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: const Color(0xFFFF6D00), width: 2),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xFFFF3D00).withValues(alpha: 0.4),
                    blurRadius: 24,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Title
                  Row(
                    children: [
                      const Text('⚙️', style: TextStyle(fontSize: 22)),
                      const SizedBox(width: 10),
                      Text(
                        'SETTINGS',
                        style: GoogleFonts.cinzel(
                          fontSize: 20,
                          fontWeight: FontWeight.w900,
                          color: const Color(0xFFFFD700),
                          shadows: const [
                            Shadow(color: Color(0xFFFF6D00), blurRadius: 8),
                          ],
                        ),
                      ),
                      const Spacer(),
                      IconButton(
                        icon: const Icon(Icons.close, color: Color(0xFFFF6D00)),
                        onPressed: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 4),
                  Divider(
                    color: const Color(0xFFFF6D00).withValues(alpha: 0.4),
                    height: 1,
                  ),
                  const SizedBox(height: 16),

                  // Sound toggle
                  _SettingRow(
                    icon: _soundOn ? '🔊' : '🔇',
                    label: 'Sound Effects',
                    value: _soundOn,
                    onChanged: (v) async {
                      setState(() => _soundOn = v);
                      await SettingsService.setSoundEnabled(v);
                    },
                  ),

                  const SizedBox(height: 12),

                  // Vibration toggle
                  _SettingRow(
                    icon: _vibrationOn ? '📳' : '📴',
                    label: 'Vibration',
                    value: _vibrationOn,
                    onChanged: (v) async {
                      setState(() => _vibrationOn = v);
                      await SettingsService.setVibrationEnabled(v);
                    },
                  ),

                  const SizedBox(height: 8),
                ],
              ),
            )
                .animate()
                .scale(
                  begin: const Offset(0.85, 0.85),
                  end: const Offset(1.0, 1.0),
                  duration: 200.ms,
                  curve: Curves.easeOut,
                )
                .fadeIn(duration: 150.ms),
          ),
        ),
      ),
    );
  }
}

class _SettingRow extends StatelessWidget {
  final String icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  const _SettingRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      decoration: BoxDecoration(
        color: Colors.black.withValues(alpha: 0.35),
        borderRadius: BorderRadius.circular(14),
        border: Border.all(
          color: const Color(0xFFFF6D00).withValues(alpha: 0.3),
          width: 1,
        ),
      ),
      child: Row(
        children: [
          Text(icon, style: const TextStyle(fontSize: 22)),
          const SizedBox(width: 12),
          Text(
            label,
            style: GoogleFonts.cinzel(
              fontSize: 14,
              fontWeight: FontWeight.bold,
              color: Colors.white,
            ),
          ),
          const Spacer(),
          _LavaSwitch(value: value, onChanged: onChanged),
        ],
      ),
    );
  }
}

class _LavaSwitch extends StatelessWidget {
  final bool value;
  final ValueChanged<bool> onChanged;

  const _LavaSwitch({required this.value, required this.onChanged});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 200),
        width: 52,
        height: 28,
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(14),
          gradient: value
              ? const LinearGradient(
                  colors: [Color(0xFFFF6D00), Color(0xFFFFD700)],
                )
              : LinearGradient(
                  colors: [
                    Colors.grey.withValues(alpha: 0.3),
                    Colors.grey.withValues(alpha: 0.2),
                  ],
                ),
          border: Border.all(
            color: value
                ? const Color(0xFFFFD700)
                : Colors.grey.withValues(alpha: 0.4),
            width: 1.5,
          ),
          boxShadow: value
              ? [
                  BoxShadow(
                    color: const Color(0xFFFF6D00).withValues(alpha: 0.5),
                    blurRadius: 8,
                  ),
                ]
              : null,
        ),
        child: Stack(
          children: [
            AnimatedPositioned(
              duration: const Duration(milliseconds: 200),
              curve: Curves.easeInOut,
              left: value ? 26 : 2,
              top: 2,
              child: Container(
                width: 22,
                height: 22,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: value ? Colors.white : Colors.grey,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.3),
                      blurRadius: 4,
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
