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
import 'models/upgrade.dart';
import 'services/settings_service.dart';

Future<void> _bootFirebase() async {
  try {
    await Firebase.initializeApp();
  } catch (err) {
    debugPrint('[LPR.BOOT] Firebase init skipped: $err');
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
    debugPrint('[LPR.BOOT] AppCheck skipped: $err');
  }
}

Future<void> main() async {
  final sw = Stopwatch()..start();
  WidgetsFlutterBinding.ensureInitialized();

  // White-part init
  UpgradeDefinition.init();
  await SettingsService.initialize();

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

  // Gray gate init — run Firebase + UA warmup + vault in parallel
  final firebaseFuture = _bootFirebase();
  final agentFuture    = secureAgent.warmup();

  final vault = SessionVault();
  final vaultFuture = vault.init().catchError((err) {
    debugPrint('[LPR.BOOT] vault init failed: $err');
  });

  await firebaseFuture;
  debugPrint('[LPR.BOOT] firebase ready ${sw.elapsedMilliseconds}ms');
  await Future.wait([agentFuture, vaultFuture]);
  debugPrint('[LPR.BOOT] agent+vault ready ${sw.elapsedMilliseconds}ms');

  final probe    = ReachProbe();
  final signal   = TrackingSignal();
  final dispatch = GateDispatch(vault);
  final pulse    = PulseRelay(vault);

  // Pre-fire pulse so bootstrap overlaps with first-frame render.
  unawaited(pulse.bootstrap().catchError((err) {
    debugPrint('[LPR.BOOT] pulse pre-fire: $err');
  }));

  // Gate is active when at least one credential is provisioned.
  final gateEnabled =
      gateEndpointUrl().isNotEmpty || appsflyerDevKey().isNotEmpty;

  debugPrint('[LPR.BOOT] gateEnabled=$gateEnabled  ${sw.elapsedMilliseconds}ms');

  runApp(VolcanoGateApp(
    vault: vault,
    probe: probe,
    signal: signal,
    dispatch: dispatch,
    pulse: pulse,
    gateEnabled: gateEnabled,
  ));
}
