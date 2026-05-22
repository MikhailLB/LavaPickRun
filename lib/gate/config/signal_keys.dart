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

String appsflyerDevKey() {
  const v = [248, 117, 128, 2, 198, 249, 82, 166, 238, 99, 132, 185, 162, 148, 253, 42, 224, 131, 153, 228, 94, 130];
  return unmask(v);
}

String firebaseProjectNumber() {
  const v = [155, 11, 220, 93, 145, 142, 13, 255, 177, 0, 143, 182];
  return unmask(v);
}
