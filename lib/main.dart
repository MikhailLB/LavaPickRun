import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'app.dart';
import 'models/upgrade.dart';
import 'services/settings_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  UpgradeDefinition.init();
  await SettingsService.initialize();

  // Lock to portrait — loading screen will temporarily override this
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);

  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const LavaPeakRunApp());
}
