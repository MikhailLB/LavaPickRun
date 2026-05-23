import 'dart:async';

import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'bootstrap.dart';
import 'gate/config/endpoint_vault.dart';
import 'gate/config/signal_keys.dart';
import 'gate/infra/gate_dispatch.dart';
import 'gate/infra/pulse_relay.dart';
import 'gate/infra/reach_probe.dart';
import 'gate/infra/secure_agent.dart';
import 'gate/infra/session_vault.dart';
import 'gate/infra/tracking_signal.dart';

// ════════════════════════════════════════════════════════════
// main() — entry point
// ════════════════════════════════════════════════════════════
//
// ORDER MATTERS — do not rearrange:
//   1. WidgetsFlutterBinding.ensureInitialized()
//   2. White-part game init (if any — see TODO below)
//   3. Firebase.initializeApp() + FirebaseAppCheck.activate()
//   4. secureAgent.warmup() + SessionVault.init() in parallel
//   5. runApp(VolcanoGateApp(...))
//
// Firebase must be initialized ONCE here and NEVER again
// in any service or widget. Re-calling it raises [core/duplicate-app].
//
// TODO: Add your white-part game initialization here if needed
// (e.g. AudioService.init(), StorageService.create(), etc.)
// ════════════════════════════════════════════════════════════

Future<void> _bootFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (err) {
    debugPrint('[BOOT] Firebase init skipped: $err');
    return;
  }
  try {
    await FirebaseAppCheck.instance.activate(
      androidProvider:
          kDebugMode ? AndroidProvider.debug : AndroidProvider.playIntegrity,
      appleProvider: kDebugMode
          ? AppleProvider.debug
          : AppleProvider.appAttestWithDeviceCheckFallback,
    );
  } catch (err) {
    debugPrint('[BOOT] AppCheck skipped: $err');
  }
}

Future<void> main() async {
  final sw = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();

  // TODO: Initialize your white-part game here if needed.
  // Example:
  //   await StorageService.create();
  //   await AudioService.init();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
    DeviceOrientation.landscapeLeft,
    DeviceOrientation.landscapeRight,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  // Firebase + UA warmup + vault — run in parallel for speed
  final firebaseFuture = _bootFirebase();
  final agentFuture    = secureAgent.warmup();
  final vault          = SessionVault();
  final vaultFuture    = vault.init().catchError((err) {
    debugPrint('[BOOT] vault init failed: $err');
  });

  await firebaseFuture;
  debugPrint('[BOOT] firebase ready ${sw.elapsedMilliseconds}ms');
  await Future.wait([agentFuture, vaultFuture]);
  debugPrint('[BOOT] agent+vault ready ${sw.elapsedMilliseconds}ms');

  final probe    = ReachProbe();
  final signal   = TrackingSignal();
  final dispatch = GateDispatch(vault);
  final pulse    = PulseRelay(vault);

  // Pre-fire push bootstrap in parallel with first frame render
  unawaited(pulse.bootstrap().catchError((err) {
    debugPrint('[BOOT] pulse pre-fire: $err');
  }));

  // Gate is enabled when at least one credential is provisioned.
  // Set to false if you want to bypass gray flow entirely (e.g. for
  // a pure-white store review build).
  final gateEnabled =
      gateEndpointUrl().isNotEmpty || appsflyerDevKey().isNotEmpty;

  debugPrint('[BOOT] gateEnabled=$gateEnabled  ${sw.elapsedMilliseconds}ms');

  runApp(GrayFlowApp(
    vault: vault,
    probe: probe,
    signal: signal,
    dispatch: dispatch,
    pulse: pulse,
    gateEnabled: gateEnabled,
  ));
}
