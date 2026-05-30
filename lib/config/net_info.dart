import '../utils/codec.dart';

// Config endpoint URL — XOR-encoded.
// TODO: Fill in when backend endpoint is provided.
// Run tool/encode_keys.dart to encode, then paste arrays below.
String resolveEndpoint() {
  const h = <int>[];
  const p = <int>[];
  if (h.isEmpty) return '';
  return d(h) + d(p);
}
