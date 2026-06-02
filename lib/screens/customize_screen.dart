import 'package:flutter/material.dart';

import '../data/skins.dart';
import '../ui/theme.dart';
import '../ui/widgets/common.dart';

/// Customization screen — pick an accent skin. The choice is persisted and
/// applied live across the app via the [appSkin] notifier.
class CustomizeScreen extends StatelessWidget {
  const CustomizeScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        fit: StackFit.expand,
        children: [
          const BackdropLayer(
              asset: 'assets/Assets/7_bg_asset.webp', darken: 0.66),
          SafeArea(
            child: Column(
              children: [
                Padding(
                  padding: const EdgeInsets.fromLTRB(8, 8, 16, 4),
                  child: Row(
                    children: [
                      RoundIconButton(
                        icon: Icons.arrow_back_ios_new,
                        onTap: () => Navigator.of(context).pop(),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                          child: Text('CUSTOMIZE', style: AppText.display(20))),
                    ],
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.fromLTRB(20, 2, 20, 10),
                  child: Text('Choose an accent theme for your ascent.',
                      style: AppText.body(12)),
                ),
                Expanded(
                  child: ValueListenableBuilder<AppSkin>(
                    valueListenable: appSkin,
                    builder: (context, current, _) {
                      return GridView.builder(
                        padding: const EdgeInsets.all(16),
                        gridDelegate:
                            const SliverGridDelegateWithFixedCrossAxisCount(
                          crossAxisCount: 2,
                          mainAxisSpacing: 14,
                          crossAxisSpacing: 14,
                          childAspectRatio: 1.25,
                        ),
                        itemCount: Skins.all.length,
                        itemBuilder: (context, i) {
                          final skin = Skins.all[i];
                          return _SkinCard(
                            skin: skin,
                            selected: skin.id == current.id,
                            onTap: () => selectSkin(skin.id),
                          );
                        },
                      );
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

class _SkinCard extends StatelessWidget {
  const _SkinCard(
      {required this.skin, required this.selected, required this.onTap});

  final AppSkin skin;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 160),
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [skin.accent.withValues(alpha: 0.35), skin.glow.withValues(alpha: 0.55)],
          ),
          borderRadius: BorderRadius.circular(18),
          border: Border.all(
            color: selected ? Palette.gold : Colors.white24,
            width: selected ? 2.4 : 1.2,
          ),
          boxShadow: [
            BoxShadow(color: skin.glow.withValues(alpha: 0.4), blurRadius: 16),
          ],
        ),
        child: Stack(
          children: [
            Center(
              child: Container(
                width: 54,
                height: 54,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: skin.accent,
                  boxShadow: [
                    BoxShadow(color: skin.glow, blurRadius: 14, spreadRadius: 1),
                  ],
                ),
              ),
            ),
            Positioned(
              left: 0,
              right: 0,
              bottom: 10,
              child: Text(skin.name.toUpperCase(),
                  textAlign: TextAlign.center,
                  style: AppText.label(13, color: Colors.white, spacing: 2)),
            ),
            if (selected)
              const Positioned(
                top: 8,
                right: 8,
                child: Icon(Icons.check_circle, color: Palette.gold, size: 22),
              ),
          ],
        ),
      ),
    );
  }
}
