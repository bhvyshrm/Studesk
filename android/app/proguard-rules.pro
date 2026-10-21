# Flutter Plugin and Engine Keep Rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.embedding.** { *; }

# Specific plugins
-keep class io.flutter.plugins.sharedpreferences.** { *; }
-keep class io.flutter.plugins.urllauncher.** { *; }
-keep class com.llfbandit.app_links.** { *; }
-keep class com.github.dart_lang.jni.** { *; }
-keep class com.github.dart_lang.jni_flutter.** { *; }

# Plugin Registrant
-keep public class io.flutter.plugins.GeneratedPluginRegistrant {
    public static void registerWith(io.flutter.embedding.engine.FlutterEngine);
    public static void registerWith(io.flutter.plugin.common.PluginRegistry);
    *;
}

# Kotlin Coroutines, Reflection & Runtime (prevents R8 NoSuchMethodError)
-keep class kotlin.Unit { *; }
-keep class kotlin.Result { *; }
-keep class kotlin.Result$Failure { *; }
-keep class kotlin.coroutines.Continuation { *; }
-keep class kotlin.coroutines.intrinsics.CoroutineSingletons { *; }
-keep class kotlin.coroutines.intrinsics.IntrinsicsKt { *; }
-keepattributes *Annotation*,EnclosingMethod,Signature,InnerClasses

# Suppress warnings
-dontwarn io.flutter.embedding.**
-dontwarn com.google.android.gms.**
