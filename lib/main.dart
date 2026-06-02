import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'app/ember_app.dart';
import 'data/progress_store.dart';
import 'data/skins.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await ProgressStore.init();
  initSkin();

  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
  ]);
  SystemChrome.setSystemUIOverlayStyle(
    const SystemUiOverlayStyle(
      statusBarColor: Colors.transparent,
      statusBarIconBrightness: Brightness.light,
    ),
  );

  runApp(const EmberApp());
}
