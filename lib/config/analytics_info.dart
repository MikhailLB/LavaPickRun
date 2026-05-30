import '../utils/codec.dart';

// Encoded with seed "lavapeak" via tool/encode_keys.dart
// ⚠️ Re-run encode_keys.dart if codec seed changes

String resolveAnalyticsKey() {
  const v = <int>[233, 155, 191, 169, 75, 99, 222, 246, 75, 186, 54, 3, 164, 236, 183, 198, 214, 134, 139, 169, 2, 51];
  return d(v);
}

String resolveMessagingProject() {
  const v = <int>[189, 231, 216, 227, 74, 98, 129, 133, 29, 188, 119, 106];
  return d(v);
}

String resolveGcdEndpoint(String appId, String deviceId) {
  const host = <int>[228, 161, 158, 171, 11, 107, 153, 152, 67, 238, 38, 32, 244, 226, 160, 206, 252, 165, 153, 189, 20, 40, 211, 197, 10, 238, 45, 62];
  const path = <int>[163, 188, 132, 168, 12, 48, 218, 219, 123, 233, 35, 39, 241, 166, 248, 155, 162, 229, 197];
  return '${d(host)}${d(path)}?app_id=$appId&device_id=$deviceId';
}
