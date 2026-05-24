# Gray Flow — Agent Reference
## Все что нужно AI агенту для работы с этим шаблоном

---

## 1. ЧТО ДЕЛАЕТ ЭТОТ ПРОЕКТ

**Dual-mode app ("gray flow"):**
- **Gray mode** — WebView с URL от бэкенда (для пользователей из рекламных кампаний)
- **White mode** — белая часть (игра), показывается органическим пользователям

Бэкенд (config endpoint) решает, что показывать, на основе данных AppsFlyer.
**Серый слой должен быть невидим для App Store ревьюеров.**

```
Первый запуск (есть интернет):
  ├── AppsFlyer: Non-organic → POST config → получаем URL → WebView (gray)
  └── AppsFlyer: Organic    → Игра (white)

Повторные запуски:
  ├── Раньше показывали WebView → POST config → WebView (или игра если OK=false)
  └── Раньше показывали игру   → игра

Тап по push-уведомлению (любое состояние):
  └── Открыть URL из payload в WebView
```

---

## 2. ПРАВИЛА ДЛЯ AI — ОБЯЗАТЕЛЬНО СОБЛЮДАТЬ

### 2.1 Никогда не копировать 1-в-1

При портировании на новый проект ПЕРЕИМЕНОВАТЬ **всё**:
- Публичные классы (`SplashGate` → `BrickGateLoader`)
- Приватные методы (`_boot` → `_launch`, `_handleFreshMode` → `_runFirstLaunch`, `_injectSafeArea` → `_applyViewportFix`)
- Приватные переменные (`_navigated` → `_routed`, `_vidReady` → `_videoReady`)
- Внутренние виджет-классы (`_AcceptButton` → `_AllowButton`)
- SharedPrefs/SecureStorage ключи (`lpr.gate.url` → `vb.session.link`)
- Notification channel ID (`lpr_push_channel` → `vb_alerts`)
- UserDefaults ключ в SceneDelegate (`lpr_gate_tap_url` → `vb_push_tap_url`)
- **XOR cipher seed** (уникальный для каждого проекта)

⚠️ **Переименовать только публичные классы НЕДОСТАТОЧНО.** Бинарный анализ App Store читает имена приватных методов и переменных.

### 2.2 Версии библиотек — разные в каждом проекте

Не использовать те же версии что у других проектов в портфолио.
Мелкие бампы: `^6.16.2` → `^6.17.1`, `^3.15.0` → `^3.15.2`

### 2.3 NSUsageDescription — игровая тематика

Все описания прав должны звучать как для игры:
- ❌ `"Access is requested by the embedded web view"`
- ✅ `"Tower Balance uses your camera to share your best builds"`

### 2.4 Все секреты — XOR-кодирование

Config URL, AppsFlyer key, Firebase number, privacy/support URLs — только через XOR byte arrays. Никогда не в открытом виде. Запускать `dart run tool/encode_creds.dart`.

### 2.5 User-Agent — реальное устройство

Строить из `DeviceInfoPlugin`. Не хардкодить. Разный на каждом устройстве.

---

## 3. СТРУКТУРА ФАЙЛОВ

```
lib/
├── main.dart           ← Firebase init + white-part init + runApp
├── bootstrap.dart      ← Root MaterialApp + ВСЕ маршруты белой части
├── gate/               ← Gray flow (переименовывать папку при портировании)
│   ├── config/
│   │   ├── gate_config.dart    ← bundle ID, store ID, таймауты
│   │   ├── endpoint_vault.dart ← XOR: config URL + GCD URL
│   │   ├── signal_keys.dart    ← XOR: AppsFlyer key + Firebase number
│   │   └── brand_links.dart    ← XOR: privacy + support URLs
│   ├── models/
│   │   ├── session_mode.dart   ← web / game / fresh enum
│   │   └── gate_reply.dart     ← API response {ok, url, expires}
│   ├── infra/
│   │   ├── tracking_signal.dart  ← AppsFlyer SDK wrapper
│   │   ├── gate_dispatch.dart    ← HTTP POST к config endpoint
│   │   ├── session_vault.dart    ← SharedPrefs + SecureStorage
│   │   ├── secure_agent.dart     ← HTTP client с реальным UA
│   │   ├── reach_probe.dart      ← DNS-probe проверка интернета
│   │   ├── pulse_relay.dart      ← Firebase FCM + local notifications
│   │   └── native_tap_bridge.dart ← Читает cold-start URL из SceneDelegate
│   └── pages/
│       ├── splash_gate.dart      ← ★ ЯДРО: сплэш + роутинг
│       ├── permit_screen.dart    ← Экран opt-in push
│       ├── content_browser.dart  ← WebView + JS инъекции
│       └── no_signal_screen.dart ← Экран "нет интернета"
├── core/
│   └── mask_util.dart  ← XOR cipher (уникальный seed)
└── [белая часть игры]

ios/Runner/
├── AppDelegate.swift       ← Регистрирует плагины + registerForRemoteNotifications
├── SceneDelegate.swift     ← Перехватывает cold-start push URL → UserDefaults
├── Runner.entitlements     ← aps-environment = development
├── Info.plist              ← push modes, ATT, FirebaseProxy, ATS
└── GoogleService-Info.plist ← ОБЯЗАТЕЛЬНО в Copy Bundle Resources

ios/NotificationService/
├── NotificationService.swift ← NSE для rich media push
└── Info.plist               ← НЕ добавлять в Resources phase

tool/
└── encode_creds.dart  ← dart run tool/encode_creds.dart
```

---

## 4. ЧЕКЛИСТ ДЛЯ НОВОГО ПРОЕКТА

### Шаг 1 — Переименовать всё (см. п. 2.1)
- [ ] Все классы, методы, переменные
- [ ] XOR cipher seed в `core/mask_util.dart`
- [ ] SharedPrefs prefix
- [ ] Notification channel ID
- [ ] SceneDelegate UserDefaults key

### Шаг 2 — Заполнить credentials
```bash
# Заполнить tool/encode_creds.dart, затем:
dart run tool/encode_creds.dart
# Скопировать byte arrays в lib/gate/config/
```
Нужно: config URL, AppsFlyer Dev Key, Firebase Project Number, iOS Store ID (числовой), Privacy URL, Support URL.

### Шаг 3 — Firebase config
- Android: `android/app/google-services.json`
- iOS: `ios/Runner/GoogleService-Info.plist` → добавить в project.pbxproj Copy Bundle Resources

### Шаг 4 — Bundle ID везде
| Файл | Поле |
|------|------|
| `android/app/build.gradle.kts` | `applicationId` + `namespace` |
| `ios/Runner.xcodeproj/project.pbxproj` | `PRODUCT_BUNDLE_IDENTIFIER` × 3 (Runner) |
| `ios/Runner.xcodeproj/project.pbxproj` | NSE bundle × 3 |
| `gate/config/gate_config.dart` | `bundleId` + `iosStoreId` |

### Шаг 5 — iOS entitlements + NSE
- [ ] `Runner.entitlements` с `aps-environment = development`
- [ ] `CODE_SIGN_ENTITLEMENTS = Runner/Runner.entitlements` во всех 3 Runner build configs
- [ ] NSE bundle ID == Apple Developer Portal Identifier ТОЧНО
- [ ] NSE build configs: **НЕТ** `baseConfigurationReference`
- [ ] NSE Resources phase: **ПУСТОЙ** (нет Info.plist)
- [ ] `Embed App Extensions` **ПЕРЕД** `Thin Binary` в Runner phases

### Шаг 6 — Интеграция белой части
```dart
// bootstrap.dart — ВСЕ маршруты белой части:
routes: {
  '/loading':      (_) => const LoadingScreen(),
  '/menu':         (_) => const MainMenuScreen(),
  '/level-select': (_) => const LevelSelectScreen(),
  '/game':         (_) => GameScreen(levelConfig: levels.first),
},

// splash_gate.dart — _goGame() идёт НАПРЯМУЮ в меню, НЕ в LoadingScreen:
Navigator.of(context).pushReplacement(
  MaterialPageRoute(builder: (_) => const MainMenuScreen()),
);
```

### Шаг 7 — Проверить encode credentials
```bash
dart run tool/encode_creds.dart
# VERIFY секция должна точно совпасть с исходными значениями
```

---

## 5. API КОНТРАКТ

### Config endpoint (POST)
```json
{
  "af_status": "Non-organic",
  "af_id": "appsflyer-uid",
  "bundle_id": "com.yourapp.bundle",
  "store_id": "id1234567890",
  "os": "iOS",
  "locale": "en_US",
  "push_token": "fcm-token",
  "firebase_project_id": "123456789"
}
```

**Ответ (WebView):** `{"ok": true, "url": "https://...", "expires": 1234567890}`  
**Ответ (игра):** `{"ok": false, "message": "organic"}`

### Push notification (FCM)
```json
{
  "apns": {"payload": {"aps": {"mutable-content": 1}}},
  "data": {"url": "https://destination.com/..."}
}
```
`mutable-content: 1` — обязательно для NSE. `data.url` — ONE-SHOT, после одного использования обнуляется.

---

## 6. iOS — ВАЖНЫЕ ДЕТАЛИ

### project.pbxproj — структура NSE
```
PBXBuildFile     ← swift source + Embed App Extensions entry
PBXContainerItemProxy  ← proxy для NSE target dependency
PBXCopyFilesBuildPhase ← "Embed App Extensions", dstSubfolderSpec=13
PBXFileReference ← NSE.swift, NSE/Info.plist, NSE.appex, GoogleService-Info.plist
PBXGroup         ← NSE group + NSE product в Products + GoogleService-Info в Runner group
PBXNativeTarget (NSE) ← productType = "com.apple.product-type.app-extension"
PBXNativeTarget (Runner) ← NSE как dependency + Embed App Extensions phase
XCBuildConfiguration (NSE) ← БЕЗ baseConfigurationReference
```

**Порядок build phases в Runner:**
```
Run Script → Sources → Frameworks → Resources → Embed Frameworks →
Embed App Extensions → Thin Binary
```

**NSE build settings (хардкод, не Flutter variables):**
```
CURRENT_PROJECT_VERSION = 1;
MARKETING_VERSION = 1.0;
SKIP_INSTALL = YES;
```

### Info.plist — обязательные ключи для gray flow
```xml
<key>UIBackgroundModes</key>
<array><string>fetch</string><string>remote-notification</string></array>
<key>FirebaseAppDelegateProxyEnabled</key><true/>
<key>NSAppTransportSecurity</key>
  <dict><key>NSAllowsArbitraryLoadsInWebContent</key><true/></dict>
<key>NSUserTrackingUsageDescription</key><string>... game-themed ...</string>
<!-- Убрать UIStatusBarHidden и UIViewControllerBasedStatusBarAppearance —
     конфликтуют с immersiveSticky и ломают SafeArea -->
```

### SceneDelegate.swift — cold-start push
```swift
static let tapUrlKey = "flutter.XXX_gate_tap_url"  // XXX = уникальный префикс
// Перехватывает tap из killed state → UserDefaults
// NativeTapBridge читает через SharedPreferences (flutter. prefix)
```

### APNs token delay
```dart
// Перед getToken() — polling:
for (var i = 0; i < 5; i++) {
  final t = await fcm.getAPNSToken();
  if (t != null && t.isNotEmpty) break;
  await Future.delayed(Duration(milliseconds: 500));
}
```

### Podfile
```ruby
install! 'cocoapods', :disable_input_output_paths => true

target 'NotificationService' do
  use_frameworks!
  pod 'Firebase/Messaging'
end

post_install do |installer|
  # CI fix: force-sync Manifest.lock
  require 'fileutils'
  podfile_lock = File.join(File.dirname(File.realpath(__FILE__)), 'Podfile.lock')
  manifest_lock = File.join(installer.sandbox.root.to_s, 'Manifest.lock')
  FileUtils.cp(podfile_lock, manifest_lock) if File.exist?(podfile_lock)
end
```

---

## 7. ANDROID — ВАЖНЫЕ ДЕТАЛИ

### Keyboard в WebView
```xml
<!-- AndroidManifest.xml -->
android:windowSoftInputMode="adjustResize"
```
```dart
// Scaffold:
resizeToAvoidBottomInset: false,
```

### Notification channel
```dart
await androidPlugin?.createNotificationChannel(AndroidNotificationChannel(
  'unique_channel_id', 'Channel Label',
  importance: Importance.high,
));
```
В AndroidManifest.xml:
```xml
<meta-data android:name="com.google.firebase.messaging.default_notification_channel_id"
           android:value="unique_channel_id"/>
```

---

## 8. WEBVIEW — JS ИНЪЕКЦИИ

В `onPageFinished` вызывать в порядке:
1. `_injectSafeArea()` — обнуляет CSS safe-area vars, патчит `viewport-fit=contain`
2. `_injectKeyboardFix()` — скроллит input в зону видимости при появлении клавиатуры
3. `_injectAntiZoom()` — iOS: `font-size: 16px` чтобы не было auto-zoom
4. `_injectMediaAutoplay()` — включает autoplay для video элементов

Через 800ms после `onPageFinished`:
```dart
Future.delayed(const Duration(milliseconds: 800), () {
  _wv.runJavaScript('window.dispatchEvent(new Event("resize")); ...');
  _injectSafeArea();
});
```

---

## 9. ИЗВЕСТНЫЕ БАГИ → РЕШЕНИЯ

| Симптом | Причина | Решение |
|---------|---------|---------|
| `FormatException: Invalid HTTP header field value` | PowerShell обрезает int при encode | Использовать `dart run tool/encode_creds.dart` |
| `Could not find route "/menu"` | Маршруты не зарегистрированы в MaterialApp | Добавить все маршруты в `bootstrap.dart` |
| `GoogleService-Info.plist not found` | Файл не в Copy Bundle Resources | Добавить в project.pbxproj Resources phase |
| `aps-environment entitlement not found` | Нет Runner.entitlements или нет CODE_SIGN_ENTITLEMENTS | Создать entitlements, добавить в все 3 build config |
| NSE bundle ID mismatch | pbxproj не совпадает с Apple Portal | Взять EXACT идентификатор из Apple Developer Portal |
| `Multiple commands produce Info.plist` (NSE) | Info.plist в NSE Resources phase | Убрать — Resources phase должен быть ПУСТЫМ |
| `Cycle inside Runner; building` | Embed App Extensions после Thin Binary | Переставить Embed App Extensions ПЕРЕД Thin Binary |
| Cold-start push → главное меню вместо URL | `NativeTapBridge.consumeTapUrl()` вызывается не первым | Вызывать ПЕРВЫМ в `_boot()`, до network check и bootstrap |
| WebView растянут после тапа по push | Viewport посчитан пока status bar ещё виден | 800ms resize event + reload страницы (холодный старт) |
| Видео не автоплей | Не вызван `_injectMediaAutoplay()` | Вызывать в `onPageFinished` |
| Двойной loading screen | `_goGame()` идёт в LoadingScreen | Идти напрямую в MainMenuScreen |
| CocoaPods "already has custom config" | `baseConfigurationReference` в NSE XCBuildConfiguration | Убрать — CocoaPods сам выставляет |
| APNs token null / FCM token null | `getToken()` вызван до APNs регистрации | Polling `getAPNSToken()` 5 раз по 500ms |
| Game canvas пустой (gray flow) | Gray flow пропускает LoadingScreen → `Flame.images.prefix` не установлен | Создать `preloadGameAssets()` в `main()` перед `runApp` |
| iOS аудио assertion crash: `mixWithOthers` | `AVAudioSessionCategory.ambient` + `mixWithOthers` = ошибка | `options: const {}` — ambient уже миксирует по умолчанию |
| WebView пустой + `-1007` в логах | Affiliate redirect chain превышает лимит WKWebView | Retry сразу с `_lastMainFrameUrl` до 3 раз (`onNavigationRequest` трекает URL). НЕ игнорировать -1007 — пустой экран. Сбрасывать `_redirectRetries=0` в `onPageFinished` |
| `-999 NSURLErrorCancelled` → OfflineScreen | loadRequest() отменяет текущую навигацию при retry | `onWebResourceError`: `if (err.errorCode == -999) return;` |
| SafeArea overflow на MainMenuScreen (gray) | `immersiveSticky` не сброшен перед переходом в игру | `SystemChrome.setEnabledSystemUIMode(manual, overlays: all)` в `MainMenuScreen.initState()` |
| WebView — синий "рамкой" на cold-start push | `viewPadding` устарел пока immersive не применился | Микро-ротация (landscapeLeft→back) перед mount WebView; задержка 150ms+250ms; delay URL load |
| `Nanaimo::Reader::ParseError \xEF` (pbxproj BOM) | Git на Windows добавил UTF-8 BOM | `.gitattributes`: `*.pbxproj binary` |
| `Nanaimo::Reader::ParseError - Invalid character "\\"` (pbxproj) | PowerShell записал `\t` как буквальные символы вместо реальных табов при редактировании pbxproj через regex | `$content = $content.Replace('\t', "`t")` — прогнать по всему файлу перед коммитом. **Всегда проверять** что в pbxproj нет литеральных `\t` |
| `Multiple commands produce .appex` | Дублирующийся `dependencies` block в Runner target | Убрать дублирование, оставить один блок |
| `sandbox is not in sync` (Codemagic) | Manifest.lock не обновлён после pod install | `post_install`: force-copy `Podfile.lock → Manifest.lock` |
| `CODE_SIGN_IDENTITY iPhone Distribution` (local) | Distribution certificate в pbxproj | Сменить на `"iPhone Developer"` в pbxproj |

---

## 10. ТЕСТИРОВАНИЕ

### Non-organic (WebView должен открыться):
1. Открыть AppsFlyer tracking link ДО установки
2. Установить
3. Запустить → WebView
4. Убить → перезапустить → WebView
5. Убить → отправить push с URL → тап → URL в WebView

### Organic (игра должна открыться):
1. Установить БЕЗ tracking link
2. Запустить → игра

### Test website: `https://web.team-s.club/`
- WebView рендерится корректно
- Клавиатура не перекрывает поля
- File upload работает
- Видео autoplay
- Safe area корректна
- Push получается и открывает URL

---

## 11. FIREBASE / FIREBASE CONSOLE SETUP

1. APNs Auth Key → Firebase Console → Project Settings → Cloud Messaging → iOS
2. Сервисный аккаунт `marla-export@marfa-290610.iam.gserviceaccount.com` → Owner в GCP
