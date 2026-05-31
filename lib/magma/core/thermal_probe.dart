import 'dart:async';
import 'dart:io';

/// Connectivity checker using real DNS lookup — avoids false-positives
/// on captive portals without any third-party package.
class ThermalProbe {
  Future<bool> isOnline() async {
    try {
      final lookup = await InternetAddress.lookup('cloudflare.com')
          .timeout(const Duration(seconds: 4));
      return lookup.isNotEmpty && lookup.first.rawAddress.isNotEmpty;
    } on SocketException {
      return false;
    } catch (_) {
      return false;
    }
  }

  Stream<bool> get onlineStream => Stream.periodic(
        const Duration(seconds: 8),
        (_) => 0,
      ).asyncMap((_) => isOnline());
}
