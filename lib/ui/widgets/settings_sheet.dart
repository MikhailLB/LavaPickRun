import 'package:flutter/material.dart';
import '../../app/routes.dart';
import '../../engine/ascent_engine.dart';
import '../../state/store.dart';
import '../theme.dart';
import 'common.dart';

Future<void> showSettingsSheet(BuildContext context) {
  return showDialog(
    context: context,
    barrierColor: Colors.black.withValues(alpha: 0.7),
    builder: (_) => GameScope<AscentEngine>(
      model: context.read<AscentEngine>(),
      child: const _SettingsSheet(),
    ),
  );
}

class _SettingsSheet extends StatelessWidget {
  const _SettingsSheet();

  @override
  Widget build(BuildContext context) {
    final engine = context.read<AscentEngine>();
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32),
        child: GlassPanel(
          glow: true,
          padding: const EdgeInsets.all(22),
          child: ListenableBuilder(
            listenable: engine,
            builder: (context, _) {
              return Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text('Settings', style: AppText.display(22)),
                      const Spacer(),
                      RoundIconButton(
                        icon: Icons.close,
                        size: 36,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  _ToggleRow(
                    icon: Icons.vibration,
                    label: 'Haptics',
                    value: engine.hapticsEnabled,
                    onChanged: engine.setHaptics,
                  ),
                  const SizedBox(height: 10),
                  _ToggleRow(
                    icon: Icons.volume_up_rounded,
                    label: 'Sound',
                    value: engine.soundEnabled,
                    onChanged: engine.setSound,
                  ),
                  const SizedBox(height: 16),
                  EmberButton(
                    label: 'How to Play',
                    icon: Icons.help_outline_rounded,
                    compact: true,
                    onTap: () {
                      final nav = Navigator.of(context);
                      nav.pop();
                      nav.pushNamed(Routes.tutorial);
                    },
                  ),
                ],
              );
            },
          ),
        ),
      ),
    );
  }
}

class _ToggleRow extends StatelessWidget {
  const _ToggleRow({
    required this.icon,
    required this.label,
    required this.value,
    required this.onChanged,
  });

  final IconData icon;
  final String label;
  final bool value;
  final ValueChanged<bool> onChanged;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => onChanged(!value),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.35),
          borderRadius: BorderRadius.circular(14),
          border:
              Border.all(color: Palette.ember.withValues(alpha: 0.3)),
        ),
        child: Row(
          children: [
            Icon(icon, color: Palette.gold, size: 20),
            const SizedBox(width: 12),
            Text(label, style: AppText.label(15, color: Colors.white)),
            const Spacer(),
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              width: 52,
              height: 28,
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(14),
                gradient: value
                    ? const LinearGradient(
                        colors: [Palette.ember, Palette.gold])
                    : null,
                color: value ? null : Colors.grey.withValues(alpha: 0.3),
                border: Border.all(
                  color: value ? Palette.gold : Colors.grey.withValues(alpha: 0.4),
                  width: 1.5,
                ),
              ),
              child: Stack(
                children: [
                  AnimatedAlign(
                    duration: const Duration(milliseconds: 180),
                    alignment:
                        value ? Alignment.centerRight : Alignment.centerLeft,
                    child: Container(
                      margin: const EdgeInsets.all(2),
                      width: 22,
                      height: 22,
                      decoration: BoxDecoration(
                        shape: BoxShape.circle,
                        color: value ? Colors.white : Colors.grey,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
