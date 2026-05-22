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
  const configHost    = 'https://TODO_YOUR_DOMAIN.com';
  const configPath    = '/config.php';
  const gcdHost       = 'https://gcdsdk.appsflyer.com/install_data/v4.0/';
  const appsflyerKey  = 'TLmgdCgnfW39wUPLbuV5Yo';
  const firebaseProj  = '721834879486';
  const privacyUrl    = 'https://TODO_YOUR_DOMAIN.com/privacy-policy.html';
  const supportUrl    = 'https://TODO_YOUR_DOMAIN.com/support.html';

  print('AF  : ${fmt(encode(appsflyerKey))}');
  print('FB  : ${fmt(encode(firebaseProj))}');
  print('HOST: ${fmt(encode(configHost))}');
  print('PATH: ${fmt(encode(configPath))}');
  print('GCD : ${fmt(encode(gcdHost))}');
  print('PRIV: ${fmt(encode(privacyUrl))}');
  print('SUPP: ${fmt(encode(supportUrl))}');

  // Verification
  final stream = _deriveKeyStream(64);
  String dec(List<int> v) {
    final o = Uint8List(v.length);
    for (var i = 0; i < v.length; i++) o[i] = v[i] ^ stream[i % 64];
    return String.fromCharCodes(o);
  }
  print('');
  print('VERIFY AF  : ${dec(encode(appsflyerKey))}');
  print('VERIFY FB  : ${dec(encode(firebaseProj))}');
}
