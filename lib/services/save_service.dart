import 'package:shared_preferences/shared_preferences.dart';
import '../models/upgrade.dart';

class SaveService {
  static const String _coinsKey = 'coins';
  static const String _unlockedLevelsKey = 'unlocked_levels';
  static const String _upgradePrefix = 'upgrade_';

  static Future<int> loadCoins() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_coinsKey) ?? 0;
  }

  static Future<void> saveCoins(int coins) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_coinsKey, coins);
  }

  static Future<int> loadUnlockedLevels() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getInt(_unlockedLevelsKey) ?? 1;
  }

  static Future<void> saveUnlockedLevels(int level) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_unlockedLevelsKey, level);
  }

  static Future<Map<UpgradeId, int>> loadUpgrades() async {
    final prefs = await SharedPreferences.getInstance();
    final map = <UpgradeId, int>{};
    for (final upgrade in UpgradeDefinition.all) {
      final key = '$_upgradePrefix${upgrade.id.name}';
      map[upgrade.id] = prefs.getInt(key) ?? 0;
    }
    return map;
  }

  static Future<void> saveUpgrade(UpgradeId id, int tier) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('$_upgradePrefix${id.name}', tier);
  }

  static Future<void> resetAll() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
  }
}
