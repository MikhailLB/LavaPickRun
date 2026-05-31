// ignore_for_file: avoid_print
import 'dart:typed_data';

const _seed = <int>[
  0x65, 0x6D, 0x62, 0x65, 0x72, 0x2F, 0x61, 0x73, 0x63, 0x65,
  0x6E, 0x74, 0x2F, 0x76, 0x32, 0x23, 0x68, 0x65, 0x61, 0x74,
];

int _mix() {
  var h = 5381;
  for (final b in _seed) {
    h = ((h * 33) ^ b) & 0xFFFFFFFF;
  }
  return h == 0 ? 0x1A2B3C4D : h;
}

int _step(int s) {
  s &= 0xFFFFFFFF;
  s ^= (s << 13) & 0xFFFFFFFF;
  s ^= s >> 17;
  s ^= (s << 5) & 0xFFFFFFFF;
  return s & 0xFFFFFFFF;
}

List<int> encode(String s) {
  final n = s.length;
  final a = Uint8List(n);
  final b = Uint8List(n);
  var st = _mix();
  for (var i = 0; i < n; i++) {
    st = _step(st);
    a[i] = st & 0xFF;
    st = _step(st);
    b[i] = (st >> 8) & 0xFF;
  }
  final out = <int>[];
  for (var i = 0; i < n; i++) {
    out.add((((s.codeUnitAt(i) ^ a[i]) + b[i]) & 0xFF));
  }
  return out;
}

String fmt(List<int> v) => '[${v.join(', ')}]';

void main() {
  const configHost = 'https://lavapeakrun.com';
  const configPath = '/config.php';
  const privacyUrl = 'https://lavapeakrun.com/privacy-policy.html';
  const supportUrl = 'https://lavapeakrun.com/support.html';
  const gcdHost = 'https://gcdsdk.appsflyer.com/install_data/v4.0/';

  print('HOST : ${fmt(encode(configHost))}');
  print('PATH : ${fmt(encode(configPath))}');
  print('PRIV : ${fmt(encode(privacyUrl))}');
  print('SUPP : ${fmt(encode(supportUrl))}');
  print('GCD  : ${fmt(encode(gcdHost))}');
}
