// ignore_for_file: avoid_print
import 'dart:typed_data';

const _seedBytes = <int>[
  0x6C, 0x61, 0x76, 0x61, 0x72, 0x75, 0x6E, 0x2E,
  0x67, 0x61, 0x74, 0x65, 0x2E, 0x76, 0x31,
];

Uint8List _deriveKeyStream(int size) {
  var hash = 0x811C9DC5;
  for (final b in _seedBytes) {
    hash = ((hash ^ b) * 0x01000193) & 0xFFFFFFFF;
  }
  final out = Uint8List(size);
  var state = hash == 0 ? 0xDEADBEEF : hash;
  for (var i = 0; i < size; i++) {
    state = (state * 1103515245 + 12345) & 0x7FFFFFFF;
    out[i] = (state >> 7) & 0xFF;
  }
  return out;
}

final _stream = _deriveKeyStream(64);

List<int> encode(String s) {
  final out = <int>[];
  for (var i = 0; i < s.length; i++) {
    out.add(s.codeUnitAt(i) ^ _stream[i % _stream.length]);
  }
  return out;
}

String fmt(List<int> v) => '[${v.join(', ')}]';

void main() {
  const configHost   = 'https://lavapeakrun.com';
  const configPath   = '/config.php';
  const privacyUrl   = 'https://lavapeakrun.com/privacy-policy.html';
  const supportUrl   = 'https://lavapeakrun.com/support.html';
  const gcdHost      = 'https://gcdsdk.appsflyer.com/install_data/v4.0/';

  print('HOST : ${fmt(encode(configHost))}');
  print('PATH : ${fmt(encode(configPath))}');
  print('PRIV : ${fmt(encode(privacyUrl))}');
  print('SUPP : ${fmt(encode(supportUrl))}');
  print('GCD  : ${fmt(encode(gcdHost))}');
}
