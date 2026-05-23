import 'package:flutter/material.dart';

// ════════════════════════════════════════════════════════════
// ⚠️  WHITE PART PLACEHOLDER — Replace with your actual game
// ════════════════════════════════════════════════════════════
//
// This is the ONLY integration point between the gray flow
// and your game (white part).
//
// HOW TO INTEGRATE:
//   1. Copy your game code into lib/ (screens/, models/, etc.)
//   2. In bootstrap.dart, add your game's MaterialApp routes.
//   3. In splash_gate.dart → _goGame(), navigate to your
//      game's main menu widget instead of WhitePartPlaceholder.
//   4. In main.dart, call your game's init functions if needed.
//   5. Delete this file.
//
// WHAT THE GRAY FLOW PROVIDES:
//   • Firebase init (in main.dart)
//   • AppsFlyer attribution (gate/infra/tracking_signal.dart)
//   • Push notifications (gate/infra/pulse_relay.dart)
//   • Config endpoint dispatch (gate/infra/gate_dispatch.dart)
//   • Cold-start push URL capture (ios/Runner/SceneDelegate.swift)
//   • Session persistence (gate/infra/session_vault.dart)
//
// YOUR GAME CODE SHOULD NOT depend on any gate/ classes.
// The gray flow routes to your game when the backend says
// the user is organic/unattributed (no WebView to show).
// ════════════════════════════════════════════════════════════

class WhitePartPlaceholder extends StatelessWidget {
  const WhitePartPlaceholder({super.key});

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.black,
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.sports_esports_rounded, size: 72, color: Colors.amber),
            SizedBox(height: 24),
            Text(
              'WHITE PART PLACEHOLDER',
              style: TextStyle(
                color: Colors.amber,
                fontSize: 18,
                fontWeight: FontWeight.bold,
                letterSpacing: 1.5,
              ),
            ),
            SizedBox(height: 12),
            Padding(
              padding: EdgeInsets.symmetric(horizontal: 40),
              child: Text(
                'Replace WhitePartPlaceholder in\nlib/core/white_part.dart\nwith your game\'s main widget.',
                textAlign: TextAlign.center,
                style: TextStyle(color: Colors.white54, fontSize: 14),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
