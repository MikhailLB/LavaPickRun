import '../../core/mask_util.dart';

/// ════════════════════════════════════════════════════════════
/// ⚠️  TEMPLATE — encode your AppsFlyer & Firebase credentials
/// ════════════════════════════════════════════════════════════
///
/// appsflyerDevKey()     → AppsFlyer Dev Key
///                         Dashboard → App Settings → Dev Key
///
/// firebaseProjectNumber() → Firebase Project Number (numeric)
///                           google-services.json → "project_number"
///                           OR Firebase Console → Project Settings → General
///
/// Run tool/encode_creds.dart to get byte arrays for your values.

// TODO: replace with your encoded AppsFlyer dev key bytes
String appsflyerDevKey() {
  const v = <int>[];
  if (v.isEmpty) return '';
  return unmask(v);
}

// TODO: replace with your encoded Firebase project number bytes
String firebaseProjectNumber() {
  const v = <int>[];
  if (v.isEmpty) return '';
  return unmask(v);
}
