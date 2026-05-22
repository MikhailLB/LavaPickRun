import '../../core/mask_util.dart';

/// ════════════════════════════════════════════════════════════
/// ⚠️  TEMPLATE — set your privacy policy and support URLs
/// ════════════════════════════════════════════════════════════
///
/// These are shown in the game's main menu and may be checked
/// by App Store reviewers. Encode them to avoid plaintext in
/// the binary.
///
/// TODO: run tool/encode_creds.dart and paste byte arrays below.

// TODO: encoded https://yourdomain.com/privacy-policy.html
const List<int> _privacyMask = <int>[];

// TODO: encoded https://yourdomain.com/support.html
const List<int> _supportMask = <int>[];

String get brandPrivacyPageUrl =>
    _privacyMask.isEmpty ? '' : unmask(_privacyMask);

String get brandSupportPageUrl =>
    _supportMask.isEmpty ? '' : unmask(_supportMask);
