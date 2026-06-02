import 'package:flutter/material.dart';

import '../engine/ascent_engine.dart';
import '../screens/achievements_screen.dart';
import '../screens/ascent_screen.dart';
import '../screens/boot_screen.dart';
import '../screens/codex_screen.dart';
import '../screens/customize_screen.dart';
import '../screens/flow_screen.dart';
import '../screens/forge_screen.dart';
import '../screens/home_screen.dart';
import '../screens/peak_map_screen.dart';
import '../screens/stats_screen.dart';
import '../screens/summit_screen.dart';
import '../screens/tutorial_screen.dart';
import '../state/store.dart';
import '../ui/theme.dart';
import 'routes.dart';

/// Root widget. The single [AscentEngine] is created once and exposed to the
/// whole tree through our hand-rolled [GameScope] (no `provider` package).
class EmberApp extends StatefulWidget {
  const EmberApp({super.key});

  @override
  State<EmberApp> createState() => _EmberAppState();
}

class _EmberAppState extends State<EmberApp> {
  late final AscentEngine _engine = AscentEngine()..hydrate();

  @override
  void dispose() {
    _engine.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GameScope<AscentEngine>(
      model: _engine,
      child: MaterialApp(
        title: 'Ember Ascent',
        debugShowCheckedModeBanner: false,
        theme: buildAppTheme(),
        initialRoute: Routes.boot,
        onGenerateRoute: _onGenerateRoute,
      ),
    );
  }

  Route<dynamic> _onGenerateRoute(RouteSettings settings) {
    Widget page;
    switch (settings.name) {
      case Routes.home:
        page = const HomeScreen();
      case Routes.peaks:
        page = const PeakMapScreen();
      case Routes.ascent:
        page = const AscentScreen();
      case Routes.summit:
        page = const SummitScreen();
      case Routes.forge:
        page = const ForgeScreen();
      case Routes.flow:
        page = const FlowScreen();
      case Routes.codex:
        page = const CodexScreen();
      case Routes.achievements:
        page = const AchievementsScreen();
      case Routes.stats:
        page = const StatsScreen();
      case Routes.customize:
        page = const CustomizeScreen();
      case Routes.tutorial:
        page = const TutorialScreen();
      case Routes.boot:
      default:
        page = const BootScreen();
    }
    return MaterialPageRoute(builder: (_) => page, settings: settings);
  }
}
