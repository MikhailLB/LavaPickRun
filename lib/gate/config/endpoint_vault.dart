import '../../core/mask_util.dart';

/// ════════════════════════════════════════════════════════════
/// ⚠️  TEMPLATE — encode your config endpoint URL
/// ════════════════════════════════════════════════════════════
///
/// HOW TO ENCODE:
///   1. Fill in values in tool/encode_creds.dart
///   2. Run: dart run tool/encode_creds.dart
///   3. Paste the printed byte arrays below.
///
/// URL format: https://yourdomain.com/config.php
/// Split at the domain/path boundary for extra obfuscation.

// TODO: replace h and p with your encoded config URL bytes after provisioning
// Run: dart run tool/encode_creds.dart
String gateEndpointUrl() {
  const h = <int>[];  // encoded host  e.g. https://yourdomain.com
  const p = <int>[];  // encoded path  e.g. /config.php
  if (h.isEmpty) return '';
  return unmask(h) + unmask(p);
}

/// AppsFlyer GCD backup endpoint (encoded).
const List<int> _gcdHostMask = [196, 77, 153, 21, 209, 128, 26, 231, 239, 87, 211, 243, 177, 170, 131, 7, 242, 134, 188, 183, 107, 148, 49, 232, 117, 93, 154, 117, 217, 105, 135, 87, 165, 173, 133, 121, 59, 221, 77, 176, 199, 112, 29, 189, 33, 231, 242];

String gcdUrl(String appId, String deviceId) {
  final host = unmask(_gcdHostMask);
  if (host.isEmpty) return '';
  final sep = host.contains('?') ? '&' : '?';
  return '$host${sep}app_id=$appId&device_id=$deviceId';
}

/// Chrome version fragment for the Android User-Agent string.
String uaChromeBuild() => '136.0.7103.93';

/// WebKit version fragment for the iOS User-Agent string.
String uaSafariBuild() => '605.1.15';
