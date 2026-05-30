import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import 'package:http/http.dart' as http;
import '../utils/codec.dart';

// XOR-encoded Chrome / WebKit version fragments
String get _cv => d(const <int>[189, 230, 218, 245, 72, 127, 134, 153, 20]); // "130.0.0.0"
String get _sv => d(const <int>[185, 230, 221, 245, 75, 103]);               // "537.36"

class AppHttpClient extends http.BaseClient {
  final http.Client _inner = http.Client();
  String? _userAgent;

  Future<void> init() async {
    try {
      final info = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final a = await info.androidInfo;
        final sdk   = a.version.sdkInt;
        final model = a.model;
        final brand = a.brand;
        final build = a.display.isNotEmpty ? a.display : a.id;
        final cv    = _cv.isNotEmpty ? _cv : '130.0.0.0';
        _userAgent  = 'Mozilla/5.0 (Linux; Android $sdk; $brand $model '
            'Build/$build) AppleWebKit/537.36 (KHTML, like Gecko) '
            'Chrome/$cv Mobile Safari/537.36';
      } else {
        final i   = await info.iosInfo;
        final ver = i.systemVersion.replaceAll('.', '_');
        final sv  = _sv.isNotEmpty ? _sv : '537.36';
        _userAgent = 'Mozilla/5.0 (iPhone; CPU iPhone OS $ver like Mac OS X) '
            'AppleWebKit/$sv (KHTML, like Gecko) '
            'Version/${i.systemVersion} Mobile/15E148 Safari/$sv';
      }
    } catch (_) {
      final cv = _cv.isNotEmpty ? _cv : '130.0.0.0';
      final sv = _sv.isNotEmpty ? _sv : '537.36';
      _userAgent = Platform.isAndroid
          ? 'Mozilla/5.0 (Linux; Android 14; Pixel 8) '
              'AppleWebKit/537.36 (KHTML, like Gecko) '
              'Chrome/$cv Mobile Safari/537.36'
          : 'Mozilla/5.0 (iPhone; CPU iPhone OS 17_0 like Mac OS X) '
              'AppleWebKit/$sv (KHTML, like Gecko) '
              'Version/17.0 Mobile/15E148 Safari/$sv';
    }
  }

  String get userAgent => _userAgent ?? 'Mozilla/5.0';

  @override
  Future<http.StreamedResponse> send(http.BaseRequest request) {
    request.headers.putIfAbsent('User-Agent', () => userAgent);
    return _inner.send(request);
  }

  @override
  void close() => _inner.close();
}

final appHttpClient = AppHttpClient();
