import 'package:flutter/material.dart';

import 'core/white_part.dart';
import 'gate/infra/gate_dispatch.dart';
import 'gate/infra/pulse_relay.dart';
import 'gate/infra/reach_probe.dart';
import 'gate/infra/session_vault.dart';
import 'gate/infra/tracking_signal.dart';
import 'gate/pages/splash_gate.dart';

// ════════════════════════════════════════════════════════════
// GrayFlowApp — root widget
// ════════════════════════════════════════════════════════════
//
// ⚠️  IMPORTANT: All white-part game routes MUST be registered
// in the routes: map below. If your game uses named routes
// (e.g. Navigator.pushNamed(context, '/menu')), they must exist
// here or the app will crash with:
//   "Could not find route RouteSettings('/menu', null)"
//
// TODO:
//   1. Rename GrayFlowApp to something unique for your project.
//   2. Update title to your app's display name.
//   3. Update scaffoldBackgroundColor to match your splash.
//   4. Add your game routes (see example comments below).
//   5. Wrap with your game's Provider/InheritedWidget if needed.
// ════════════════════════════════════════════════════════════
class GrayFlowApp extends StatelessWidget {
  final SessionVault vault;
  final ReachProbe probe;
  final TrackingSignal signal;
  final GateDispatch dispatch;
  final PulseRelay pulse;
  final bool gateEnabled;

  const GrayFlowApp({
    super.key,
    required this.vault,
    required this.probe,
    required this.signal,
    required this.dispatch,
    required this.pulse,
    required this.gateEnabled,
  });

  @override
  Widget build(BuildContext context) {
    final Widget home = gateEnabled
        ? SplashGate(
            vault: vault,
            probe: probe,
            signal: signal,
            dispatch: dispatch,
            pulse: pulse,
          )
        : const WhitePartPlaceholder();

    // TODO: If your game uses Provider, wrap MaterialApp here:
    // return ChangeNotifierProvider(
    //   create: (_) => YourGameState(),
    //   child: MaterialApp(...),
    // );

    return MaterialApp(
      // TODO: Change title to your app name
      title: 'TODO_APP_NAME',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        // TODO: Change to your app's background color
        scaffoldBackgroundColor: Colors.black,
        colorScheme: ColorScheme.fromSeed(
          seedColor: Colors.amber,
          brightness: Brightness.dark,
        ),
        useMaterial3: true,
      ),
      home: home,
      routes: {
        // ── TODO: Add your white-part game routes here ──────
        // These must match whatever named routes your game
        // screens push to. Example:
        //
        // '/menu':           (_) => const MainMenuScreen(),
        // '/game':           (_) => const GameScreen(),
        // '/level-select':   (_) => const LevelSelectScreen(),
        // '/level-complete': (_) => const LevelCompleteScreen(),
        //
        // White-part placeholder (remove when integrating game):
        '/game': (_) => const WhitePartPlaceholder(),
      },
    );
  }
}
