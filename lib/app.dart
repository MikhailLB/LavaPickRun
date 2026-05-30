import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/game_state.dart';
import 'screens/gray_splash_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_menu_screen.dart';
import 'screens/level_select_screen.dart';
import 'screens/game_screen.dart';
import 'screens/level_complete_screen.dart';
import 'services/app_state_service.dart';
import 'services/connectivity_service.dart';
import 'services/attribution_service.dart';
import 'services/config_service.dart';
import 'services/notif_service.dart';

class LavaPeakRunApp extends StatelessWidget {
  final AppStateService storage;
  final ConnectivityService connectivity;
  final AttributionService attribution;
  final ConfigService configService;
  final NotifService notifService;

  const LavaPeakRunApp({
    super.key,
    required this.storage,
    required this.connectivity,
    required this.attribution,
    required this.configService,
    required this.notifService,
  });

  @override
  Widget build(BuildContext context) {
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
        home: GraySplashScreen(
          storage:       storage,
          connectivity:  connectivity,
          attribution:   attribution,
          configService: configService,
          notifService:  notifService,
        ),
        routes: {
          '/onboarding':    (_) => const OnboardingScreen(),
          '/menu':          (_) => const MainMenuScreen(),
          '/level-select':  (_) => const LevelSelectScreen(),
          '/game':          (_) => const GameScreen(),
          '/level-complete':(_) => const LevelCompleteScreen(),
        },
      ),
    );
  }
}
