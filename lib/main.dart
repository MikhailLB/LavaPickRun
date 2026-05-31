import 'dart:async';

import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'data/progress_store.dart';
import 'magma/core/crater_vault.dart';
import 'magma/core/ember_relay.dart';
import 'magma/core/eruption_signal.dart';
import 'magma/core/lava_agent.dart';
import 'magma/core/thermal_probe.dart';
import 'magma/views/crater_boot.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Init white-game persistence (needed even when gray routes to game later)
  await ProgressStore.init();

  // Firebase must be initialised before any gray-flow service starts
  await Firebase.initializeApp();

  // Build gray-flow services
  final vault = CraterVault();
  await vault.init();
  final probe    = ThermalProbe();
  final relay    = EmberRelay(vault);
  final signal   = EruptionSignal(vault);

  // Warm up realistic UA string (non-blocking — best effort)
  unawaited(lavaAgent.warmup());

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(_FlowRoot(
    vault: vault,
    probe: probe,
    pulse: relay,
    signal: signal,
  ));
}

class _FlowRoot extends StatelessWidget {
  final CraterVault vault;
  final ThermalProbe probe;
  final EmberRelay pulse;
  final EruptionSignal signal;

  const _FlowRoot({
    required this.vault,
    required this.probe,
    required this.pulse,
    required this.signal,
  });

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      theme: ThemeData(scaffoldBackgroundColor: Colors.black),
      home: CraterBoot(
        vault: vault,
        probe: probe,
        signal: signal,
        pulse: pulse,
      ),
    );
  }
}
