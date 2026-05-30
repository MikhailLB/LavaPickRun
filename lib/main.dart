import 'package:firebase_app_check/firebase_app_check.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'models/upgrade.dart';
import 'services/settings_service.dart';
import 'services/app_state_service.dart';
import 'services/connectivity_service.dart';
import 'services/attribution_service.dart';
import 'services/config_service.dart';
import 'services/notif_service.dart';
import 'services/http_client.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Game services
  UpgradeDefinition.init();
  await SettingsService.initialize();

  // Firebase
  try {
    await Firebase.initializeApp();
    await FirebaseAppCheck.instance.activate(
      androidProvider: kDebugMode
          ? AndroidProvider.debug
          : AndroidProvider.playIntegrity,
    );
  } catch (_) {}

  // HTTP client (real device UA)
  await appHttpClient.init();

  // Gray flow services
  final storage     = AppStateService();
  await storage.init();
  final connectivity = ConnectivityService();
  final attribution  = AttributionService();
  final configSvc    = ConfigService(storage);
  final notifSvc     = NotifService(storage);

  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.light,
  ));

  runApp(LavaPeakRunApp(
    storage:       storage,
    connectivity:  connectivity,
    attribution:   attribution,
    configService: configSvc,
    notifService:  notifSvc,
  ));
}
