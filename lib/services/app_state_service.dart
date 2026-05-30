import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/app_mode.dart';

class AppStateService {
  static const _keyAppMode               = 'app_mode';
  static const _keySavedUrl              = 'sv_u';
  static const _keyUrlExpires            = 'url_expires';
  static const _keyNotifSkipUntil        = 'notification_skip_until';
  static const _keyNotifGranted          = 'notification_granted';
  static const _keyPushUrl               = 'psh_u';

  late SharedPreferences _prefs;
  final FlutterSecureStorage _secure = const FlutterSecureStorage();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  // -- App Mode --
  AppMode getAppMode() => AppMode.fromString(_prefs.getString(_keyAppMode));
  Future<void> setAppMode(AppMode mode) async =>
      _prefs.setString(_keyAppMode, mode.toStorageString());

  // -- Saved URL (secure) --
  Future<String?> getSavedUrl()           async => _secure.read(key: _keySavedUrl);
  Future<void>    setSavedUrl(String url) async => _secure.write(key: _keySavedUrl, value: url);

  // -- URL Expiry --
  int?            getUrlExpires()                => _prefs.getInt(_keyUrlExpires);
  Future<void>    setUrlExpires(int exp)   async => _prefs.setInt(_keyUrlExpires, exp);
  bool isUrlExpired() {
    final exp = getUrlExpires();
    if (exp == null) return true;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= exp;
  }

  // -- Notification --
  bool isNotificationGranted() => _prefs.getBool(_keyNotifGranted) ?? false;
  Future<void> setNotificationGranted(bool g) async =>
      _prefs.setBool(_keyNotifGranted, g);
  int? getNotificationSkipUntil() => _prefs.getInt(_keyNotifSkipUntil);
  Future<void> setNotificationSkipUntil(int ts) async =>
      _prefs.setInt(_keyNotifSkipUntil, ts);
  bool shouldShowNotificationScreen() {
    if (isNotificationGranted()) return false;
    final skip = getNotificationSkipUntil();
    if (skip == null) return true;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= skip;
  }

  // -- Push URL (one-time, secure) --
  Future<String?> getPushUrl()              async => _secure.read(key: _keyPushUrl);
  Future<void>    setPushUrl(String? url)   async {
    if (url == null) {
      await _secure.delete(key: _keyPushUrl);
    } else {
      await _secure.write(key: _keyPushUrl, value: url);
    }
  }
  Future<String?> consumePushUrl() async {
    final url = await getPushUrl();
    if (url != null) await _secure.delete(key: _keyPushUrl);
    return url;
  }
}
