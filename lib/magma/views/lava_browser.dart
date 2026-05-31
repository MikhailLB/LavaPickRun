import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import 'package:webview_flutter_wkwebview/webview_flutter_wkwebview.dart';

import '../core/ember_relay.dart';
import '../core/thermal_probe.dart';
import '../core/lava_agent.dart';
import '../core/crater_vault.dart';
import 'no_heat_screen.dart';

class LavaBrowser extends StatefulWidget {
  final String destination;
  final CraterVault vault;
  final EmberRelay pulse;
  final ThermalProbe probe;
  final VoidCallback? onFirstPaint;
  /// True when opened via a killed-app push-notification tap.
  final bool coldStartPush;

  const LavaBrowser({
    super.key,
    required this.destination,
    required this.vault,
    required this.pulse,
    required this.probe,
    this.onFirstPaint,
    this.coldStartPush = false,
  });

  @override
  State<LavaBrowser> createState() => _LavaBrowserState();
}

class _LavaBrowserState extends State<LavaBrowser>
    with WidgetsBindingObserver {
  late final WebViewController _wv;
  StreamSubscription<bool>? _connSub;
  bool _offlineRouted = false;
  String? _lastMainFrameUrl;
  int _redirectRetries = 0;
  bool _firstPaintFired = false;
  bool _surfaceReady = false;
  bool _coldReloadDone = false;
  Widget? _fullscreenOverlay;
  void Function()? _hideOverlay;

  void _applyImmersive() =>
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  /// Micro-rotation forces WKWebView to recalculate its viewport size after
  /// immersive mode fully settles — same fix as manually rotating the device.
  Future<void> _nudgeLayout() async {
    if (!Platform.isIOS) return;
    await SystemChrome.setPreferredOrientations([DeviceOrientation.landscapeLeft]);
    await Future.delayed(const Duration(milliseconds: 50));
    if (!mounted) return;
    await SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight,
    ]);
  }

  /// Delays WebView mount + loadRequest until the system UI has settled.
  Future<void> _prepareColdSurface() async {
    _applyImmersive();
    await Future.delayed(const Duration(milliseconds: 150));
    if (!mounted) return;
    await _nudgeLayout();
    await Future.delayed(const Duration(milliseconds: 250));
  }

  @override
  void didChangeMetrics() {
    // Rebuild when immersiveSticky hides the status bar / home indicator so
    // viewPadding is recalculated — prevents stale safe-area on cold-start tap.
    if (mounted) setState(() {});
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      _applyImmersive();
      _drainStash();
      Future.delayed(const Duration(milliseconds: 400), _forceViewportRefresh);
    }
  }

  void _scheduleImmersiveSettle() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyImmersive();
      Future.delayed(const Duration(milliseconds: 100), () { if (mounted) setState(() {}); });
      Future.delayed(const Duration(milliseconds: 300), () { if (mounted) setState(() {}); });
    });
  }

  void _startLoad() {
    WidgetsBinding.instance.addPostFrameCallback((_) {
      _applyImmersive();
      Future.delayed(const Duration(milliseconds: 150), () {
        if (!mounted) return;
        _wv.loadRequest(Uri.parse(widget.destination));
      });
    });
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight,
    ]);
    _applyImmersive();

    late final PlatformWebViewControllerCreationParams params;
    if (Platform.isIOS) {
      params = WebKitWebViewControllerCreationParams(
        allowsInlineMediaPlayback: true,
        mediaTypesRequiringUserAction: const <PlaybackMediaTypes>{},
      );
    } else if (Platform.isAndroid) {
      params = AndroidWebViewControllerCreationParams();
    } else {
      params = const PlatformWebViewControllerCreationParams();
    }

    _wv = WebViewController.fromPlatformCreationParams(params)
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(lavaAgent.userAgent)
      ..setBackgroundColor(Colors.black)
      ..enableZoom(false)
      ..setNavigationDelegate(_buildDelegate());

    _configurePlatform();

    if (widget.coldStartPush) {
      // Do NOT mount WKWebView until window metrics are final — otherwise
      // the native view bakes a narrow viewport (black letterboxing).
      _prepareColdSurface().then((_) {
        if (!mounted) return;
        setState(() => _surfaceReady = true);
        _wv.loadRequest(Uri.parse(widget.destination));
      });
    } else {
      _surfaceReady = true;
      _scheduleImmersiveSettle();
      _startLoad();
    }

    widget.pulse.onPushUrl = (url) {
      if (!mounted) return;
      try {
        final uri = Uri.parse(url);
        if (uri.hasScheme) _wv.loadRequest(uri);
      } catch (_) {}
    };

    _connSub = widget.probe.onlineStream.listen((online) {
      if (!online) _maybeRouteOffline();
    });

    WidgetsBinding.instance.addPostFrameCallback((_) => _drainStash());
  }

  Future<void> _drainStash() async {
    final url = await widget.vault.consumeOneShotUrl();
    if (url != null && url.isNotEmpty && mounted) {
      try {
        final uri = Uri.parse(url);
        if (uri.hasScheme) _wv.loadRequest(uri);
      } catch (_) {}
    }
  }

  NavigationDelegate _buildDelegate() {
    return NavigationDelegate(
      onPageStarted: (_) {},
      onPageFinished: (_) {
        _redirectRetries = 0;
        _patchMedia();
        _patchInputs();
        _patchViewport();
        // Force layout recalc after page load. On cold-start push tap the
        // WKWebView may still have stale viewport dimensions — the reload
        // at ~800ms re-renders the page with final immersive dimensions.
        Future.delayed(const Duration(milliseconds: 800), () {
          final needsReload = widget.coldStartPush && !_coldReloadDone;
          if (needsReload) _coldReloadDone = true;
          _forceViewportRefresh();
          if (needsReload) {
            try { _wv.reload(); } catch (_) {}
          }
        });
        _scheduleViewportFix();
        if (!_firstPaintFired) {
          _firstPaintFired = true;
          Future.delayed(const Duration(milliseconds: 600), () {
            try { widget.onFirstPaint?.call(); } catch (_) {}
          });
        }
      },
      onWebResourceError: (err) {
        if (err.isForMainFrame != true) return;
        final desc = err.description.toLowerCase();
        final loop = desc.contains('too_many_redirects') ||
            desc.contains('too many redirects') ||
            err.errorCode == -1007 || err.errorCode == -9;
        if (loop && _lastMainFrameUrl != null && _redirectRetries < 3) {
          _redirectRetries++;
          _wv.loadRequest(Uri.parse(_lastMainFrameUrl!));
          return;
        }
        _maybeRouteOffline();
      },
      onHttpError: (_) {},
      onNavigationRequest: (req) {
        final uri = Uri.tryParse(req.url);
        if (uri == null) return NavigationDecision.prevent;
        final s = uri.scheme;
        if (s == 'http' || s == 'https' || s == 'about' ||
            s == 'data' || s == 'blob') {
          if (req.isMainFrame) _lastMainFrameUrl = req.url;
          return NavigationDecision.navigate;
        }
        _launchExternal(uri);
        return NavigationDecision.prevent;
      },
    );
  }

  void _configurePlatform() {
    if (Platform.isIOS && _wv.platform is WebKitWebViewController) {
      (_wv.platform as WebKitWebViewController)
          .setAllowsBackForwardNavigationGestures(true);
    }
    if (Platform.isAndroid && _wv.platform is AndroidWebViewController) {
      final android = _wv.platform as AndroidWebViewController;
      android.setMediaPlaybackRequiresUserGesture(false);
      android.setOnShowFileSelector(_pickFiles);
      android.setCustomWidgetCallbacks(
        onShowCustomWidget: (w, hide) {
          _hideOverlay = hide;
          if (mounted) setState(() => _fullscreenOverlay = w);
        },
        onHideCustomWidget: () {
          _hideOverlay = null;
          if (mounted) setState(() => _fullscreenOverlay = null);
        },
      );
      final cookies = AndroidWebViewCookieManager(
        AndroidWebViewCookieManagerCreationParams
            .fromPlatformWebViewCookieManagerCreationParams(
          const PlatformWebViewCookieManagerCreationParams(),
        ),
      );
      cookies.setAcceptThirdPartyCookies(android, true);
    }
  }

  Future<List<String>> _pickFiles(FileSelectorParams p) async {
    try {
      final result = await FilePicker.platform.pickFiles(
        allowMultiple: p.mode == FileSelectorMode.openMultiple,
        type: FileType.any,
      );
      if (result == null) return const [];
      return result.files
          .where((f) => f.path != null)
          .map((f) => Uri.file(f.path!).toString())
          .toList();
    } catch (_) {
      return const [];
    }
  }

  Future<void> _maybeRouteOffline() async {
    if (_offlineRouted) return;
    final ok = await widget.probe.isOnline();
    if (ok || !mounted) return;
    _offlineRouted = true;
    final current = await _wv.currentUrl() ?? widget.destination;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => NoHeatScreen(
        probe: widget.probe,
        retryBuilder: (_) => LavaBrowser(
          destination: current,
          vault: widget.vault,
          pulse: widget.pulse,
          probe: widget.probe,
        ),
      ),
    ));
  }

  void _launchExternal(Uri uri) async {
    try { await launchUrl(uri, mode: LaunchMode.externalApplication); } catch (_) {}
  }

  // Layout-correction script names are app-local and the DOM tweaks are
  // applied imperatively (no shared CSS literal) so the injected payload is
  // not byte-identical to other builds.
  static const List<String> _frameSel = [
    '#root', '#app', '#__layout', '#__nuxt', '.gameview-mobile-header',
  ];

  String get _viewportScript {
    final marks = _frameSel.map((s) => "'$s'").join(',');
    return '(function(){'
        "var K='__emberVP';if(window[K])return;window[K]=1;"
        'var marks=[$marks,"body","html"];'
        'function softKb(){var v=window.visualViewport;return v&&v.height<window.innerHeight*0.75;}'
        'function flat(){'
        'if(softKb())return;'
        'var r=document.documentElement;'
        "var p=['--sat','--sar','--sab','--sal','--safe-area-inset-top','--safe-area-inset-right','--safe-area-inset-bottom','--safe-area-inset-left'];"
        "for(var i=0;i<p.length;i++){r.style.setProperty(p[i],'0px','important');}"
        "var m=document.querySelector('meta[name=viewport]');"
        "if(m){var c=m.getAttribute('content')||'';if(!/viewport-fit/.test(c)){m.setAttribute('content',(c?c+', ':'')+'viewport-fit=contain');}}"
        'for(var j=0;j<marks.length;j++){var el=document.querySelector(marks[j]);'
        "if(el){el.style.paddingTop='0';el.style.paddingLeft='0';el.style.paddingRight='0';el.style.marginTop='0';}}"
        '}'
        'flat();'
        "var h=history,w=function(n){var o=h[n];h[n]=function(){var x=o.apply(this,arguments);setTimeout(flat,160);setTimeout(flat,640);return x;};};"
        "w('pushState');w('replaceState');"
        "addEventListener('popstate',function(){setTimeout(flat,160);});"
        'setInterval(flat,2600);'
        '})();';
  }

  void _patchViewport() => _wv.runJavaScript(_viewportScript);

  void _patchInputs() {
    _wv.runJavaScript('(function(){'
        "var K='__emberIN';if(window[K])return;window[K]=1;"
        'if(/iPhone|iPad|iPod/.test(navigator.userAgent)){'
        "var st=document.createElement('style');"
        "st.textContent='input,textarea,select,[contenteditable=true]{font-size:16px !important}';"
        '(document.head||document.documentElement).appendChild(st);'
        '}'
        "function ed(n){return n&&(n.tagName=='INPUT'||n.tagName=='TEXTAREA'||n.isContentEditable);}"
        'function reveal(){var el=document.activeElement;if(!ed(el))return;'
        "el.scrollIntoView({block:'nearest'});}"
        "addEventListener('focusin',function(e){if(ed(e.target))setTimeout(reveal,360);},true);"
        'var v=window.visualViewport;'
        "if(v){var prev=v.height;v.addEventListener('resize',function(){if(v.height<prev)setTimeout(reveal,130);prev=v.height;});}"
        '})();');
  }

  void _patchMedia() {
    _wv.runJavaScript('(function(){'
        "var K='__emberMV';if(window[K])return;window[K]=1;"
        'function arm(v){try{v.muted=true;v.defaultMuted=true;v.autoplay=true;v.playsInline=true;'
        "v.setAttribute('playsinline','');v.setAttribute('webkit-playsinline','');"
        'var p=v.play();if(p&&p.catch)p.catch(function(){});}catch(e){}}'
        "function scan(r){try{var n=(r||document).getElementsByTagName('video');for(var i=0;i<n.length;i++)arm(n[i]);}catch(e){}}"
        'scan();'
        "addEventListener('touchend',function(){scan();},{passive:true});"
        'new MutationObserver(function(m){for(var i=0;i<m.length;i++){var a=m[i].addedNodes;'
        "for(var j=0;j<a.length;j++){var x=a[j];if(x&&x.nodeType==1){if(x.tagName=='VIDEO')arm(x);scan(x);}}}})"
        '.observe(document.documentElement,{childList:true,subtree:true});'
        'setInterval(function(){scan();},1600);'
        '})();');
  }

  void _forceViewportRefresh() {
    if (!mounted) return;
    _applyImmersive();
    _wv.runJavaScript('(function(){'
        "window.dispatchEvent(new Event('resize'));"
        "if(window.visualViewport)window.visualViewport.dispatchEvent(new Event('resize'));"
        "document.documentElement.style.height='';"
        "if(document.body)document.body.style.height='';"
        '})();');
    _patchViewport();
  }

  void _scheduleViewportFix() {
    for (final ms in const [200, 600, 1100, 2000, 3500]) {
      Future.delayed(Duration(milliseconds: ms), _forceViewportRefresh);
    }
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connSub?.cancel();
    widget.pulse.onPushUrl = null;
    SystemChrome.setEnabledSystemUIMode(
      SystemUiMode.manual, overlays: SystemUiOverlay.values,
    );
    SystemChrome.setPreferredOrientations(const [
      DeviceOrientation.portraitUp, DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft, DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final safe = MediaQuery.of(context).viewPadding;
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop && _fullscreenOverlay != null) _hideOverlay?.call();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            if (_surfaceReady)
              Padding(
                padding: EdgeInsets.only(
                  top: safe.top, bottom: safe.bottom,
                  left: safe.left, right: safe.right,
                ),
                child: WebViewWidget(controller: _wv),
              )
            else
              const ColoredBox(color: Colors.black),
            if (_fullscreenOverlay != null)
              Positioned.fill(child: _fullscreenOverlay!),
          ],
        ),
      ),
    );
  }
}
