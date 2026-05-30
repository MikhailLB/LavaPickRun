// ignore_for_file: avoid_print
import 'dart:typed_data';
import 'dart:convert';

// Run: dart run tool/encode_keys.dart
// ⚠️ ALWAYS use `dart run` — never PowerShell foreach loops (32-bit overflow).

void main() {
  // Codec seed for lavapeakrun: "lavapeak"
  const seed = <int>[108, 97, 118, 97, 112, 101, 97, 107];
  final key = _deriveKey(seed);

  print('=== ENCODED VALUES (lavapeak seed) ===\n');

  // AppsFlyer Dev Key
  _printEncoded('AppsFlyer key', 'eNUr32hAo7tP4e9iZSarzb', key);

  // Firebase project number (not the project ID string)
  _printEncoded('Firebase project#', '122823729159', key);

  // GCD endpoint host
  _printEncoded('GCD host', 'https://gcdsdk.appsflyer.com', key);

  // GCD endpoint path
  _printEncoded('GCD path', '/install_data/v4.0/', key);

  // Chrome version fragment for User-Agent
  _printEncoded('Chrome version', '130.0.0.0', key);

  // WebKit version fragment for User-Agent
  _printEncoded('WebKit version', '537.36', key);

  // Config endpoint — fill in when available
  // _printEncoded('Config host', 'https://your-endpoint.com', key);
  // _printEncoded('Config path', '/v1/config', key);
}

Uint8List _deriveKey(List<int> parts) {
  final seedVal = parts.fold<int>(0, (a, b) => (a * 31 + b) & 0xFFFFFFFF);
  final key = Uint8List(16);
  var v = seedVal;
  for (var i = 0; i < key.length; i++) {
    v = (v * 1103515245 + 12345) & 0x7FFFFFFF;
    key[i] = v & 0xFF;
  }
  return key;
}

void _printEncoded(String label, String text, Uint8List key) {
  final bytes = utf8.encode(text);
  final out = <int>[];
  for (var i = 0; i < bytes.length; i++) {
    out.add(bytes[i] ^ key[i % key.length]);
  }
  print('// $label: "$text"');
  print('const <int>[${out.join(', ')}]\n');
}
