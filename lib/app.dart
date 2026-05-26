import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'models/game_state.dart';
import 'screens/loading_screen.dart';
import 'screens/onboarding_screen.dart';
import 'screens/main_menu_screen.dart';
import 'screens/level_select_screen.dart';
import 'screens/game_screen.dart';
import 'screens/level_complete_screen.dart';

class LavaPeakRunApp extends StatelessWidget {
  const LavaPeakRunApp({super.key});

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
        initialRoute: '/loading',
        routes: {
          '/loading': (_) => const LoadingScreen(),
          '/onboarding': (_) => const OnboardingScreen(),
          '/menu': (_) => const MainMenuScreen(),
          '/level-select': (_) => const LevelSelectScreen(),
          '/game': (_) => const GameScreen(),
          '/level-complete': (_) => const LevelCompleteScreen(),
        },
      ),
    );
  }
}
