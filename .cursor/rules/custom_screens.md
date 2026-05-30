# LavaPeakRun — Custom Screen Assets (HIGH PRIORITY)

## ⚠️ MANDATORY: Always use project-specific custom background assets

This project has custom-designed full-screen background images for two gray-flow
screens. **Never use generic Flutter widgets or video placeholders for these.**
Always locate and use the actual asset files from the project.

---

## Push Notification Permission Screen

**File:** `lib/screens/push_promo_screen.dart`

**Background assets (orientation-aware — BOTH must exist):**
- Portrait:  `assets/Notifications/Vertical_Notifications_Screen.webp`
- Landscape: `assets/Notifications/Horizontal_Notifications_Screen.webp`

**Implementation pattern:**
```dart
final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
final bgAsset = isLandscape
    ? 'assets/Notifications/Horizontal_Notifications_Screen.webp'
    : 'assets/Notifications/Vertical_Notifications_Screen.webp';

Image.asset(bgAsset, fit: BoxFit.cover, width: size.width, height: size.height)
```

Overlay the Accept/Skip buttons on top of this image as `Positioned` widgets.

---

## No Internet / No WiFi Screen

**File:** `lib/screens/no_internet_screen.dart`

**Background assets (orientation-aware — BOTH must exist):**
- Portrait:  `assets/Nowifi/Vertical_Nowifi_Screen.webp`
- Landscape: `assets/Nowifi/Horizontal_Nowifi_Screen.webp`

**Implementation pattern:**
```dart
final isLandscape = MediaQuery.of(context).orientation == Orientation.landscape;
final bgAsset = isLandscape
    ? 'assets/Nowifi/Horizontal_Nowifi_Screen.webp'
    : 'assets/Nowifi/Vertical_Nowifi_Screen.webp';

Image.asset(bgAsset, fit: BoxFit.cover, width: size.width, height: size.height)
```

Overlay the Retry button as a `Positioned` widget at the bottom.

---

## No-Internet Detection in WebView (ContentScreen)

**File:** `lib/screens/content_screen.dart`

When connectivity drops, show `NoInternetScreen` **immediately** — do NOT wait
for a DNS probe. Use the connectivity stream directly:

```dart
_connSub = widget.connectivity.onConnectivityChanged.listen((results) {
  if (results.every((r) => r == ConnectivityResult.none)) {
    _showNoInternetImmediate(); // no async DNS check — fires instantly
  }
});
```

The `_showNoInternetImmediate()` method navigates without `await hasInternet()`.

---

## Landscape Safe Area (Camera Notch)

**File:** `lib/screens/content_screen.dart`

In landscape mode, apply `viewPadding.left` and `viewPadding.right` to the
WebView padding (for devices with camera notch on the side):

```dart
padding: isLandscape
    ? EdgeInsets.only(
        left:  MediaQuery.of(context).viewPadding.left,
        right: MediaQuery.of(context).viewPadding.right,
      )
    : EdgeInsets.only(top: MediaQuery.of(context).viewPadding.top),
```

---

## Asset Registration

All assets are declared in `pubspec.yaml`. If you add new assets, register them:
```yaml
assets:
  - assets/Notifications/Vertical_Notifications_Screen.webp
  - assets/Notifications/Horizontal_Notifications_Screen.webp
  - assets/Nowifi/Vertical_Nowifi_Screen.webp
  - assets/Nowifi/Horizontal_Nowifi_Screen.webp
```
