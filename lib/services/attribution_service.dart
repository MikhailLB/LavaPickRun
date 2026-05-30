import 'dart:async';
import 'dart:convert';
import 'dart:io';
import 'package:flutter/foundation.dart';
import 'package:appsflyer_sdk/appsflyer_sdk.dart';
import '../config/app_settings.dart';
import '../config/analytics_info.dart';
import 'http_client.dart';

class AttributionService {
  AppsflyerSdk? _sdk;
  Map<String, dynamic>? _attributionData;
  Map<String, dynamic>? _deepLinkData;
  Map<String, dynamic>? _appOpenData;

  final Completer<Map<String, dynamic>> _attrCompleter = Completer();
  final Completer<void> _dlCompleter = Completer();
  bool _initialized = false;

  Future<void> init() async {
    if (_initialized) return;
    _initialized = true;

    final options = AppsFlyerOptions(
      afDevKey: AppSettings.analyticsKey,
      appId:    AppSettings.analyticsAppId,
      showDebug: kDebugMode,
      timeToWaitForATTUserAuthorization: 10,
    );
    _sdk = AppsflyerSdk(options);

    _sdk!.onInstallConversionData((data) async {
      try {
        final payload = (data['payload'] as Map?)?.cast<String, dynamic>() ??
            (data as Map<String, dynamic>);
        if (payload['af_status'] == 'Organic') {
          await Future.delayed(
              Duration(seconds: AppSettings.syncRetrySeconds));
          final retry = await _refreshAttribution();
          _attributionData = retry ?? payload;
        } else {
          _attributionData = payload;
        }
        if (!_attrCompleter.isCompleted) {
          _attrCompleter.complete(_attributionData!);
        }
      } catch (_) {
        if (!_attrCompleter.isCompleted) {
          _attrCompleter.complete(<String, dynamic>{});
        }
      }
    });

    _sdk!.onAppOpenAttribution((data) {
      try {
        _appOpenData = (data['payload'] as Map?)?.cast<String, dynamic>() ??
            (data as Map<String, dynamic>);
      } catch (_) {}
    });

    _sdk!.onDeepLinking((result) {
      try {
        if (result.deepLink != null) {
          _deepLinkData = result.deepLink!.clickEvent;
        }
        if (!_dlCompleter.isCompleted) _dlCompleter.complete();
      } catch (_) {
        if (!_dlCompleter.isCompleted) _dlCompleter.complete();
      }
    });

    await _sdk!.initSdk(
      registerConversionDataCallback: true,
      registerOnAppOpenAttributionCallback: true,
      registerOnDeepLinkingCallback: true,
    );
  }

  Future<Map<String, dynamic>?> _refreshAttribution() async {
    try {
      final uid   = await getAnalyticsUID();
      final appId = Platform.isIOS
          ? AppSettings.analyticsAppId
          : AppSettings.bundleId;
      final url   = resolveGcdEndpoint(appId, uid ?? '');
      if (url.isEmpty) return null;
      final response = await appHttpClient.get(
        Uri.parse(url),
        headers: {'authorization': 'Bearer ${AppSettings.analyticsKey}'},
      ).timeout(const Duration(seconds: 10));
      if (response.statusCode == 200) {
        return jsonDecode(response.body) as Map<String, dynamic>;
      }
    } catch (_) {}
    return null;
  }

  Future<Map<String, dynamic>> waitForAttribution() =>
      _attrCompleter.future.timeout(
        const Duration(seconds: 30),
        onTimeout: () => <String, dynamic>{},
      );

  Future<String?> getAnalyticsUID() async {
    if (_sdk == null) return null;
    try { return await _sdk!.getAppsFlyerUID(); } catch (_) { return null; }
  }

  Future<void> waitForDeepLink() async =>
      _dlCompleter.future.timeout(const Duration(seconds: 5), onTimeout: () {});

  Future<Map<String, dynamic>> buildRequestBody({
    required String locale,
    String? pushToken,
  }) async {
    final body = <String, dynamic>{};
    body.addAll(_attributionData ?? {});
    _deepLinkData?.forEach((k, v) => body.putIfAbsent(k, () => v));
    _appOpenData?.forEach((k, v) => body.putIfAbsent(k, () => v));

    final uid = await getAnalyticsUID();
    body['af_id']    = uid ?? '';
    body['bundle_id'] = AppSettings.bundleId;
    body['os']       = Platform.isAndroid ? 'Android' : 'iOS';
    body['store_id'] = AppSettings.storeId;
    body['locale']   = locale;

    if (pushToken != null && pushToken.isNotEmpty) {
      body['push_token'] = pushToken;
    }
    if (AppSettings.messagingProjectId.isNotEmpty) {
      body['firebase_project_id'] = AppSettings.messagingProjectId;
    }

    if (kDebugMode) {
      debugPrint('[AttributionService] Request body: ${jsonEncode(body)}');
    }
    return body;
  }
}
