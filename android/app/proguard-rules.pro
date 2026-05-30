# Flutter
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-dontwarn com.google.android.play.core.**
-keep class com.google.android.play.core.** { *; }

# Firebase
-keep class com.google.firebase.** { *; }
-keep class com.google.android.gms.** { *; }

# AppsFlyer
-keep class com.appsflyer.** { *; }
-dontwarn com.appsflyer.**

# WebView JS interface
-keepattributes JavascriptInterface
-keepattributes *Annotation*

# Keep enums
-keepclassmembers enum * { *; }
