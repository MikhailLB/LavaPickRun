import 'dart:io';
import 'package:http/http.dart' as http;
import '../cfg/magma_config.dart';

String _buildAndroidUa(String osVersion) =>
    'Mozilla/5.0 (Linux; Android $osVersion; Pixel 7 Build/TQ3A.230901.001) '
    'AppleWebKit/537.36 (KHTML, like Gecko) '
    'Chrome/${uaChrome()} Mobile Safari/537.36';

String _buildIosUa(String ver) {
  final dotless = ver.replaceAll('.', '_');
  return 'Mozilla/5.0 (iPhone; CPU iPhone OS $dotless like Mac OS X) '
      'AppleWebKit/${uaWebkit()} (KHTML, like Gecko) '
      'Version/$ver Mobile/15E148 Safari/${uaWebkit()}';
}

String _fallbackUa() => Platform.isAndroid
    ? _buildAndroidUa('14')
    : _buildIosUa('17.4');

/// HTTP client with a realistic mobile-browser User-Agent derived from
/// the actual platform version — no third-party device-info package needed.
class LavaAgent extends http.BaseClient {
  final http.Client _inner = http.Client();
  String _ua = '';

  Future<void> warmup() async {
    try {
      final ver = Platform.operatingSystemVersion;
      if (Platform.isIOS) {
        // operatingSystemVersion on iOS: "17.4" or "Version 17.4 (Build …)"
        final m = RegExp(r'(\d+\.\d+(?:\.\d+)?)').firstMatch(ver);
        _ua = _buildIosUa(m?.group(1) ?? '17.4');
      } else if (Platform.isAndroid) {
        final m = RegExp(r'(\d+)').firstMatch(ver);
        _ua = _buildAndroidUa(m?.group(1) ?? '14');
      } else {
        _ua = _fallbackUa();
      }
    } catch (_) {
      _ua = _fallbackUa();
    }
  }

  String get userAgent => _ua.isNotEmpty ? _ua : _fallbackUa();

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    if (!request.headers.containsKey('User-Agent') &&
        !request.headers.containsKey('user-agent')) {
      request.headers['User-Agent'] = userAgent;
    }
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

final lavaAgent = LavaAgent();
