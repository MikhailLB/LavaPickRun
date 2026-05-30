import '../utils/codec.dart';

// Config endpoint URL — XOR-encoded with seed "lavapeak".
// Plaintext: https://lavapeakkrun.com/config.php
// Re-encode via tool/encode_keys.dart if codec seed ever changes.
String resolveEndpoint() {
  const h = <int>[228, 161, 158, 171, 11, 107, 153, 152, 72, 236, 52, 50, 224, 236, 239, 196, 231, 167, 159, 181, 86, 50, 217, 218];
  const p = <int>[163, 182, 133, 181, 30, 56, 209, 153, 84, 229, 50];
  return d(h) + d(p);
}
