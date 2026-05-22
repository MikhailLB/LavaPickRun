import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'gate/infra/gate_dispatch.dart';
import 'gate/infra/pulse_relay.dart';
import 'gate/infra/reach_probe.dart';
import 'gate/infra/session_vault.dart';
import 'gate/infra/tracking_signal.dart';
import 'gate/pages/splash_gate.dart';
import 'models/game_state.dart';
import 'screens/game_screen.dart';
import 'screens/level_complete_screen.dart';
import 'screens/level_select_screen.dart';
import 'screens/loading_screen.dart';
import 'screens/main_menu_screen.dart';

/// Root widget for LavaPeakRun when the gate flow is active.
/// Wraps the game's Provider + MaterialApp so white-part widgets
/// can still access [GameState] when falling through to the game.
class VolcanoGateApp extends StatelessWidget {
  final SessionVault vault;
  final ReachProbe probe;
  final TrackingSignal signal;
  final GateDispatch dispatch;
  final PulseRelay pulse;
  final bool gateEnabled;

  const VolcanoGateApp({
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
        : const LoadingScreen();

    return ChangeNotifierProvider(
      create: (_) => GameState()..initialize(),
      child: MaterialApp(
        title: 'Lava Peak Run',
        debugShowCheckedModeBanner: false,
        theme: ThemeData(
          colorScheme: ColorScheme.fromSeed(
            seedColor: const Color(0xFFFF6D00),
            brightness: Brightness.dark,
          ),
          scaffoldBackgroundColor: Colors.black,
          useMaterial3: true,
        ),
        home: home,
        // All white-part routes must be registered here so LoadingScreen
        // can navigate to /menu, /game etc. after the splash finishes.
        routes: {
          '/loading':        (_) => const LoadingScreen(),
          '/menu':           (_) => const MainMenuScreen(),
          '/level-select':   (_) => const LevelSelectScreen(),
          '/game':           (_) => const GameScreen(),
          '/level-complete': (_) => const LevelCompleteScreen(),
        },
      ),
    );
  }
}
