import '../../core/mask_util.dart';

String gateEndpointUrl() {
  const h = [196, 77, 153, 21, 209, 128, 26, 231, 228, 85, 193, 225, 165, 164, 204, 13, 240, 131, 161, 255, 100, 130, 57];
  const p = [131, 90, 130, 11, 196, 211, 82, 230, 248, 92, 199];
  return unmask(h) + unmask(p);
}

const List<int> _gcdHostMask = [196, 77, 153, 21, 209, 128, 26, 231, 239, 87, 211, 243, 177, 170, 131, 7, 242, 134, 188, 183, 107, 148, 49, 232, 117, 93, 154, 117, 217, 105, 135, 87, 165, 173, 133, 121, 59, 221, 77, 176, 199, 112, 29, 189, 33, 231, 242];

String gcdUrl(String appId, String deviceId) {
  final host = unmask(_gcdHostMask);
  if (host.isEmpty) return '';
  final sep = host.contains('?') ? '&' : '?';
  return '$host${sep}app_id=$appId&device_id=$deviceId';
}

String uaChromeBuild() => '136.0.7103.93';
String uaSafariBuild() => '605.1.15';
