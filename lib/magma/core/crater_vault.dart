import 'package:flutter_secure_storage/flutter_secure_storage.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../types/flow_models.dart';

class CraterVault {
  static const _kMode        = 'ea.mode';
  static const _kPushCooldown = 'ea.push.cd';
  static const _kPushConsent  = 'ea.push.ok';
  static const _kSavedUrl    = 'ea.url';
  static const _kUrlTtl      = 'ea.url.ts';
  static const _kOneShotUrl  = 'ea.push.shot';

  late SharedPreferences _prefs;
  final FlutterSecureStorage _safe = const FlutterSecureStorage();

  Future<void> init() async {
    _prefs = await SharedPreferences.getInstance();
  }

  CraterMode readMode() => CraterMode.fromKey(_prefs.getString(_kMode));

  Future<void> writeMode(CraterMode m) async =>
      _prefs.setString(_kMode, m.toKey());

  Future<String?> readSavedUrl() async {
    try { return await _safe.read(key: _kSavedUrl); } catch (_) { return null; }
  }

  Future<void> writeSavedUrl(String url) async {
    try { await _safe.write(key: _kSavedUrl, value: url); } catch (_) {}
  }

  Future<void> writeSavedTtl(int epochSeconds) async =>
      _prefs.setInt(_kUrlTtl, epochSeconds);

  bool isSavedUrlExpired() {
    final ttl = _prefs.getInt(_kUrlTtl);
    if (ttl == null) return true;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= ttl;
  }

  bool readPushConsent() => _prefs.getBool(_kPushConsent) ?? false;

  Future<void> writePushConsent(bool ok) async =>
      _prefs.setBool(_kPushConsent, ok);

  int? readPushCooldown() => _prefs.getInt(_kPushCooldown);

  Future<void> writePushCooldown(int epochSeconds) async =>
      _prefs.setInt(_kPushCooldown, epochSeconds);

  bool needsPushPrompt() {
    if (readPushConsent()) return false;
    final until = readPushCooldown();
    if (until == null) return true;
    return DateTime.now().millisecondsSinceEpoch ~/ 1000 >= until;
  }

  Future<void> stashOneShotUrl(String url) async {
    if (url.isEmpty) return;
    try { await _safe.write(key: _kOneShotUrl, value: url); } catch (_) {}
  }

  Future<String?> consumeOneShotUrl() async {
    try {
      final v = await _safe.read(key: _kOneShotUrl);
      if (v != null) await _safe.delete(key: _kOneShotUrl);
      return v;
    } catch (_) {
      return null;
    }
  }
}
