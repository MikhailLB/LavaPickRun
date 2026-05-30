import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'package:webview_flutter_android/webview_flutter_android.dart';
import '../services/connectivity_service.dart';
import '../services/http_client.dart';
import '../services/notif_service.dart';
import '../services/app_state_service.dart';
import 'no_internet_screen.dart';

Future<void> prepareContentEngine() async {}

class ContentScreen extends StatefulWidget {
  final String url;
  final AppStateService storage;
  final NotifService notifService;
  final ConnectivityService connectivity;

  const ContentScreen({
    super.key,
    required this.url,
    required this.storage,
    required this.notifService,
    required this.connectivity,
  });

  @override
  State<ContentScreen> createState() => _ContentScreenState();
}

class _ContentScreenState extends State<ContentScreen>
    with WidgetsBindingObserver {
  late final WebViewController _controller;
  bool _isLoading = true;
  StreamSubscription<List<ConnectivityResult>>? _connSub;
  bool _showingNoInternet = false;
  String? _lastRedirectUrl;
  int _redirectRetries = 0;

  void _applyUI() =>
      SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) _applyUI();
  }

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    _applyUI();

    _controller = WebViewController()
      ..setJavaScriptMode(JavaScriptMode.unrestricted)
      ..setUserAgent(appHttpClient.userAgent)
      ..setBackgroundColor(Colors.black)
      ..setNavigationDelegate(NavigationDelegate(
        onPageStarted: (_) {
          if (mounted) setState(() => _isLoading = true);
        },
        onPageFinished: (_) {
          if (mounted) setState(() => _isLoading = false);
          _redirectRetries = 0;
          _injectSiteAreaKill();
          _injectKeyboardScrollFix();
        },
        onWebResourceError: (e) {
          if (e.isForMainFrame != true) return;
          final desc = e.description.toLowerCase();
          final tooMany = desc.contains('too_many_redirects') ||
              desc.contains('too many redirects') ||
              e.errorCode == -1007 || e.errorCode == -9;
          if (tooMany && _lastRedirectUrl != null && _redirectRetries < 3) {
            _redirectRetries++;
            _controller.loadRequest(Uri.parse(_lastRedirectUrl!));
            return;
          }
          _checkAndShowNoInternet();
        },
        onHttpError: (_) {},
        onNavigationRequest: (req) {
          final uri = Uri.tryParse(req.url);
          if (uri == null) return NavigationDecision.prevent;
          final s = uri.scheme;
          if (s == 'http' || s == 'https' || s == 'about' ||
              s == 'data' || s == 'blob') {
            if (req.isMainFrame) _lastRedirectUrl = req.url;
            return NavigationDecision.navigate;
          }
          _launchExternal(uri);
          return NavigationDecision.prevent;
        },
      ))
      ..enableZoom(false);

    _configurePlatform();
    _controller.loadRequest(Uri.parse(widget.url));

    widget.notifService.onNotificationUrl = (url) {
      if (mounted) _controller.loadRequest(Uri.parse(url));
    };

    _connSub = widget.connectivity.onConnectivityChanged.listen((results) {
      if (results.every((r) => r == ConnectivityResult.none)) {
        _checkAndShowNoInternet();
      }
    });
  }

  Future<void> _checkAndShowNoInternet() async {
    if (_showingNoInternet) return;
    if (!await widget.connectivity.hasInternet()) return;
    if (!mounted) return;
    _showingNoInternet = true;
    final cur = await _controller.currentUrl() ?? widget.url;
    if (!mounted) return;
    Navigator.of(context).pushReplacement(MaterialPageRoute(
      builder: (_) => NoInternetScreen(
        retryScreenBuilder: (_) => ContentScreen(
          url: cur, storage: widget.storage,
          notifService: widget.notifService,
          connectivity: widget.connectivity,
        ),
      ),
    ));
  }

  void _configurePlatform() {
    if (Platform.isAndroid &&
        _controller.platform is AndroidWebViewController) {
      final ctrl = _controller.platform as AndroidWebViewController;
      ctrl.setMediaPlaybackRequiresUserGesture(false);
      ctrl.setOnShowFileSelector(_handleFileSelector);
      final cookieMgr = AndroidWebViewCookieManager(
        AndroidWebViewCookieManagerCreationParams
            .fromPlatformWebViewCookieManagerCreationParams(
          const PlatformWebViewCookieManagerCreationParams(),
        ),
      );
      cookieMgr.setAcceptThirdPartyCookies(ctrl, true);
    }
  }

  Future<List<String>> _handleFileSelector(FileSelectorParams p) async {
    try {
      final r = await FilePicker.pickFiles(
        allowMultiple: p.mode == FileSelectorMode.openMultiple,
        type: FileType.any,
      );
      if (r != null && r.files.isNotEmpty) {
        return r.files.where((f) => f.path != null)
            .map((f) => Uri.file(f.path!).toString()).toList();
      }
    } catch (_) {}
    return [];
  }

  void _injectKeyboardScrollFix() {
    _controller.runJavaScript('''
(function(){
  if(window.__kbf)return;window.__kbf=true;
  function isIn(el){return el&&(el.tagName==='INPUT'||el.tagName==='TEXTAREA'||el.isContentEditable);}
  function doScroll(){var el=document.activeElement;if(!isIn(el))return;var vp=window.visualViewport;if(vp){var r=el.getBoundingClientRect();var b=vp.offsetTop+vp.height;if(r.bottom>b-20||r.top<vp.offsetTop)el.scrollIntoView({behavior:'auto',block:'nearest'});}else{el.scrollIntoView({behavior:'auto',block:'nearest'});}}
  document.addEventListener('focusin',function(e){if(isIn(e.target))setTimeout(doScroll,350);});
  if(window.visualViewport){var ph=window.visualViewport.height;window.visualViewport.addEventListener('resize',function(){var h=window.visualViewport.height;if(h<ph)setTimeout(doScroll,120);ph=h;});}
})();
''');
  }

  void _injectSiteAreaKill() {
    _controller.runJavaScript(r'''
(function(){
  if(window.__flsa)return;window.__flsa=true;
  var ID='__flsacss';
  var CSS=':root{--safe-area-inset-top:0px!important;--safe-area-inset-right:0px!important;--safe-area-inset-bottom:0px!important;--safe-area-inset-left:0px!important;--sat:0px!important;--sar:0px!important;--sab:0px!important;--sal:0px!important;}html,body,#__nuxt,#app,#root{padding-top:0!important;margin-top:0!important;}';
  function apply(){
    var h=document.head||document.documentElement;if(!h)return;
    var m=document.querySelector('meta[name="viewport"]');
    if(m&&!/viewport-fit\s*=\s*contain/i.test(m.getAttribute('content')||'')){
      var c=(m.getAttribute('content')||'').replace(/,?\s*viewport-fit\s*=\s*\w+/ig,'').trim();
      m.setAttribute('content',c+(c?', ':'')+'viewport-fit=contain');
    }
    var s=document.getElementById(ID);
    if(!s){s=document.createElement('style');s.id=ID;h.appendChild(s);}
    if(s.textContent!==CSS)s.textContent=CSS;
    if(h.lastElementChild!==s)h.appendChild(s);
  }
  apply();
  ['pushState','replaceState'].forEach(function(fn){var o=history[fn];history[fn]=function(){var r=o.apply(this,arguments);setTimeout(apply,80);setTimeout(apply,400);return r;};});
  window.addEventListener('popstate',function(){setTimeout(apply,80);});
  setInterval(apply,2500);
})();
''');
  }

  Future<void> _launchExternal(Uri uri) async {
    try { await launchUrl(uri, mode: LaunchMode.externalApplication); }
    catch (_) {}
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    _connSub?.cancel();
    widget.notifService.onNotificationUrl = null;
    SystemChrome.setEnabledSystemUIMode(
        SystemUiMode.manual, overlays: SystemUiOverlay.values);
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);
    super.dispose();
  }

  Future<bool> _onWillPop() async {
    if (await _controller.canGoBack()) await _controller.goBack();
    return false;
  }

  @override
  Widget build(BuildContext context) {
    return PopScope(
      canPop: false,
      onPopInvokedWithResult: (didPop, _) async {
        if (!didPop) await _onWillPop();
      },
      child: Scaffold(
        backgroundColor: Colors.black,
        resizeToAvoidBottomInset: false,
        body: Stack(
          fit: StackFit.expand,
          children: [
            Padding(
              padding: EdgeInsets.only(
                top: MediaQuery.of(context).orientation == Orientation.landscape
                    ? 0
                    : MediaQuery.of(context).viewPadding.top,
              ),
              child: WebViewWidget(controller: _controller),
            ),
            if (_isLoading)
              Container(
                color: Colors.black.withValues(alpha: 0.5),
                child: const Center(
                  child: CircularProgressIndicator(
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.amber)),
                ),
              ),
          ],
        ),
      ),
    );
  }
}
