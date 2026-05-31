import 'dart:io';
import '../../core/mask_util.dart';

const List<int> _hostBlob = [123, 121, 212, 7, 97, 218, 19, 180, 31, 255, 185, 68, 248, 90, 144, 41, 195, 165, 56, 191, 115, 227, 142];
const List<int> _pathBlob = [184, 104, 223, 29, 118, 11, 203, 181, 59, 248, 187];
const List<int> _privacyBlob = [123, 121, 212, 7, 97, 218, 19, 180, 31, 255, 185, 68, 248, 90, 144, 41, 195, 165, 56, 191, 115, 227, 142, 216, 103, 184, 126, 2, 15, 24, 193, 108, 193, 227, 192, 97, 89, 208, 65, 124, 64, 145, 252];
const List<int> _supportBlob = [123, 121, 212, 7, 97, 218, 19, 180, 31, 255, 185, 68, 248, 90, 144, 41, 195, 165, 56, 191, 115, 227, 142, 216, 100, 185, 133, 4, 13, 7, 206, 105, 185, 222, 193, 100];
const List<int> _gcdBlob = [123, 121, 212, 7, 97, 218, 19, 180, 40, 1, 199, 86, 228, 104, 77, 51, 197, 168, 43, 247, 116, 241, 150, 149, 185, 167, 120, 23, 77, 30, 216, 174, 197, 233, 192, 100, 85, 229, 122, 136, 85, 211, 242, 135, 82, 13, 8];
const List<int> _afBlob = [143, 129, 221, 20, 116, 225, 203, 117, 41, 213, 126, 140, 241, 42, 95, 16, 211, 165, 80, 166, 105, 227];
const List<int> _fbBlob = [176, 55, 25, 207, 33, 216, 36, 172, 242, 52, 131, 145];

String resolveFlowEndpoint() => unmask(_hostBlob) + unmask(_pathBlob);

String resolveGcdUrl(String appId, String deviceId) {
  final host = unmask(_gcdBlob);
  if (host.isEmpty) return '';
  final sep = host.contains('?') ? '&' : '?';
  return '$host${sep}app_id=$appId&device_id=$deviceId';
}

String uaChrome() => '136.0.7103.93';
String uaWebkit() => '605.1.15';

abstract final class MagmaConfig {
  static const String iosStoreId = '6771216641';
  static const String bundleId = 'com.lavaplay.lava.peak.run';
  static const String appTitle = 'Lava Peak Run';

  static const int pushCooldownSeconds = 259200;
  static const int organicRetrySeconds = 6;
  static const int bootBudgetSeconds = 20;

  static String get configEndpoint     => resolveFlowEndpoint();
  static String get installKey         => unmask(_afBlob);
  static String get firebaseProjectNum => unmask(_fbBlob);
  static String get privacyUrl         => unmask(_privacyBlob);
  static String get supportUrl         => unmask(_supportBlob);
  static String get analyticsAppId     =>
      Platform.isIOS ? iosStoreId : bundleId;
  static String get platformStoreId    =>
      Platform.isIOS ? 'id$iosStoreId' : bundleId;
}
