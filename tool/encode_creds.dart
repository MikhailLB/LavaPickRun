// ignore_for_file: avoid_print
/// ════════════════════════════════════════════════════════════
/// LavaPeakRun — credential encoder
/// ════════════════════════════════════════════════════════════
///
/// USAGE:
///   dart run tool/encode_creds.dart
///
/// ⚠️  Always run with `dart run`, NOT PowerShell foreach loops.
/// PowerShell overflows 32-bit integers producing wrong byte values
/// (symptom: FormatException in HTTP headers).
///
/// The _seedBytes MUST match lib/core/mask_util.dart exactly.
/// ════════════════════════════════════════════════════════════

import 'dart:typed_data';

// ── MUST match _seedBytes in lib/core/mask_util.dart ─────────
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
  // ════════════════════════════════════════════════════════
  // ⚠️  FILL IN YOUR ACTUAL VALUES BELOW
  // ════════════════════════════════════════════════════════

  // lib/gate/config/endpoint_vault.dart
  // Split URL at domain/path boundary
  const configHost = 'https://TODO_YOUR_DOMAIN.com';  // TODO
  const configPath = '/config.php';                    // TODO

  // AppsFlyer GCD endpoint host (do not change unless AF changes it)
  const gcdHost = 'https://gcdsdk.appsflyer.com/install_data/v4.0/';

  // lib/gate/config/signal_keys.dart
  const appsflyerKey  = 'TODO_APPSFLYER_DEV_KEY';       // TODO
  const firebaseProj  = 'TODO_FIREBASE_PROJECT_NUMBER';  // TODO  (numeric string)

  // lib/gate/config/brand_links.dart
  const privacyUrl = 'https://TODO_YOUR_DOMAIN.com/privacy-policy.html'; // TODO
  const supportUrl = 'https://TODO_YOUR_DOMAIN.com/support.html';        // TODO

  // ════════════════════════════════════════════════════════

  print('// ── endpoint_vault.dart ────────────────────────');
  print('const h = ${fmt(encode(configHost))};   // host');
  print('const p = ${fmt(encode(configPath))};   // path');
  print('');
  print('// ── endpoint_vault.dart — GCD host ─────────────');
  print('const _gcdHostMask = ${fmt(encode(gcdHost))};');
  print('');
  print('// ── signal_keys.dart — AppsFlyer key ────────────');
  print('const v = ${fmt(encode(appsflyerKey))};');
  print('');
  print('// ── signal_keys.dart — Firebase project number ──');
  print('const v = ${fmt(encode(firebaseProj))};');
  print('');
  print('// ── brand_links.dart — privacy URL ──────────────');
  print('const _privacyMask = ${fmt(encode(privacyUrl))};');
  print('');
  print('// ── brand_links.dart — support URL ──────────────');
  print('const _supportMask = ${fmt(encode(supportUrl))};');
  print('');
  print('// ── VERIFICATION ─────────────────────────────────');
  print('// configUrl  : $configHost$configPath');
  print('// appsflyerKey: $appsflyerKey');
  print('// firebaseProj: $firebaseProj');
}
