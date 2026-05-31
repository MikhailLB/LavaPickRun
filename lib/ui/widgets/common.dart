import 'package:flutter/material.dart';
import '../theme.dart';

/// Full-screen backdrop: the peak's radial-glow art plus a legibility veil.
class BackdropLayer extends StatelessWidget {
  const BackdropLayer({super.key, required this.asset, this.darken = 0.45});

  final String asset;
  final double darken;

  @override
  Widget build(BuildContext context) {
    return Stack(
      fit: StackFit.expand,
      children: [
        Image.asset(asset, fit: BoxFit.cover),
        DecoratedBox(
          decoration: BoxDecoration(
            gradient: LinearGradient(
              begin: Alignment.topCenter,
              end: Alignment.bottomCenter,
              colors: [
                Colors.black.withValues(alpha: darken * 0.6),
                Colors.black.withValues(alpha: darken),
                Palette.ink.withValues(alpha: darken + 0.25),
              ],
            ),
          ),
        ),
      ],
    );
  }
}

/// A bordered, slightly translucent ember panel used for menus and overlays.
class GlassPanel extends StatelessWidget {
  const GlassPanel({
    super.key,
    required this.child,
    this.padding = const EdgeInsets.all(16),
    this.glow = false,
    this.accent = Palette.ember,
    this.radius = 20,
  });

  final Widget child;
  final EdgeInsetsGeometry padding;
  final bool glow;
  final Color accent;
  final double radius;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: padding,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [Palette.charcoal, Palette.ink],
        ),
        borderRadius: BorderRadius.circular(radius),
        border: Border.all(color: accent.withValues(alpha: 0.7), width: 1.5),
        boxShadow: glow
            ? [
                BoxShadow(
                  color: accent.withValues(alpha: 0.35),
                  blurRadius: 22,
                  spreadRadius: 1,
                ),
              ]
            : null,
      ),
      child: child,
    );
  }
}

/// Section header used inside panels.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key});
  final String text;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(top: 12, bottom: 6),
      child: Text(text.toUpperCase(),
          style: AppText.label(11, color: Palette.ember, spacing: 2.5)),
    );
  }
}

/// The single pressable button style for the whole app.
class EmberButton extends StatefulWidget {
  const EmberButton({
    super.key,
    required this.label,
    required this.onTap,
    this.icon,
    this.primary = false,
    this.compact = false,
    this.enabled = true,
  });

  final String label;
  final VoidCallback onTap;
  final IconData? icon;
  final bool primary;
  final bool compact;
  final bool enabled;

  @override
  State<EmberButton> createState() => _EmberButtonState();
}

class _EmberButtonState extends State<EmberButton> {
  bool _down = false;

  @override
  Widget build(BuildContext context) {
    final enabled = widget.enabled;
    return GestureDetector(
      onTapDown: enabled ? (_) => setState(() => _down = true) : null,
      onTapCancel: enabled ? () => setState(() => _down = false) : null,
      onTapUp: enabled
          ? (_) {
              setState(() => _down = false);
              widget.onTap();
            }
          : null,
      child: AnimatedScale(
        scale: _down ? 0.96 : 1.0,
        duration: const Duration(milliseconds: 90),
        child: Container(
          width: double.infinity,
          padding: EdgeInsets.symmetric(
              vertical: widget.compact ? 12 : 17, horizontal: 18),
          decoration: BoxDecoration(
            gradient: widget.primary && enabled
                ? const LinearGradient(
                    colors: [Palette.ember, Palette.emberHot, Palette.emberDeep],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  )
                : LinearGradient(
                    colors: [
                      Colors.black.withValues(alpha: 0.55),
                      Colors.black.withValues(alpha: 0.35),
                    ],
                  ),
            borderRadius: BorderRadius.circular(widget.primary ? 18 : 14),
            border: Border.all(
              color: enabled
                  ? (widget.primary
                      ? Palette.gold
                      : Palette.ember.withValues(alpha: 0.55))
                  : Colors.grey.withValues(alpha: 0.3),
              width: widget.primary ? 2 : 1.4,
            ),
            boxShadow: widget.primary && enabled
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
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              if (widget.icon != null) ...[
                Icon(widget.icon,
                    size: widget.compact ? 18 : 22,
                    color: widget.primary ? Colors.white : Palette.ember),
                const SizedBox(width: 8),
              ],
              Flexible(
                child: Text(
                  widget.label,
                  overflow: TextOverflow.ellipsis,
                  style: AppText.title(
                    widget.compact ? 14 : 19,
                    color: enabled
                        ? (widget.primary ? Colors.white : Palette.gold)
                        : Colors.grey,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

/// Three-star rating row.
class StarRow extends StatelessWidget {
  const StarRow({
    super.key,
    required this.stars,
    this.size = 16,
    this.spacing = 1.5,
  });

  final int stars;
  final double size;
  final double spacing;

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(3, (i) {
        final filled = i < stars;
        return Padding(
          padding: EdgeInsets.symmetric(horizontal: spacing),
          child: Icon(
            filled ? Icons.star_rounded : Icons.star_outline_rounded,
            size: size,
            color: filled ? Palette.gold : Colors.white.withValues(alpha: 0.25),
          ),
        );
      }),
    );
  }
}

/// Circular icon button (settings, back, pause).
class RoundIconButton extends StatelessWidget {
  const RoundIconButton({
    super.key,
    required this.icon,
    required this.onTap,
    this.size = 42,
  });

  final IconData icon;
  final VoidCallback onTap;
  final double size;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.black.withValues(alpha: 0.5),
          shape: BoxShape.circle,
          border: Border.all(
              color: Palette.ember.withValues(alpha: 0.65), width: 1.5),
        ),
        child: Icon(icon, color: Palette.gold, size: size * 0.48),
      ),
    );
  }
}
