import 'dart:typed_data';

// XOR deobfuscator. Seed: "lavapeak" → unique per project.
// Re-run tool/encode_keys.dart after any seed change.

Uint8List _deriveKey() {
  const parts = <int>[108, 97, 118, 97, 112, 101, 97, 107]; // "lavapeak"
  final seed = parts.fold<int>(0, (a, b) => (a * 31 + b) & 0xFFFFFFFF);
  final key = Uint8List(16);
  var v = seed;
  for (var i = 0; i < key.length; i++) {
    v = (v * 1103515245 + 12345) & 0x7FFFFFFF;
    key[i] = v & 0xFF;
  }
  return key;
}

final _xk = _deriveKey();

String d(List<int> data) {
  final out = Uint8List(data.length);
  for (var i = 0; i < data.length; i++) {
    out[i] = data[i] ^ _xk[i % _xk.length];
  }
  return String.fromCharCodes(out);
}
