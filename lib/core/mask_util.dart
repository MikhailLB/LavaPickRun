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

void _fill(int n, Uint8List a, Uint8List b) {
  var s = _mix();
  for (var i = 0; i < n; i++) {
    s = _step(s);
    a[i] = s & 0xFF;
    s = _step(s);
    b[i] = (s >> 8) & 0xFF;
  }
}

String unmask(List<int> raw) {
  final n = raw.length;
  if (n == 0) return '';
  final a = Uint8List(n);
  final b = Uint8List(n);
  _fill(n, a, b);
  final out = Uint8List(n);
  for (var i = 0; i < n; i++) {
    out[i] = (((raw[i] - b[i]) & 0xFF) ^ a[i]) & 0xFF;
  }
  return String.fromCharCodes(out);
}
