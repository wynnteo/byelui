# Flutter Local Notifications ProGuard Rules

# Keep notification classes
-keep class com.dexterous.** { *; }
-keep class androidx.core.app.NotificationCompat** { *; }
-keep class androidx.work.** { *; }

# Keep timezone data
-keep class org.threeten.bp.** { *; }
-keep class org.joda.time.** { *; }

# Keep JSON serialization classes
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**

# Gson specific classes
-keep class * extends com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Prevent R8 from leaving Data object members always null
-keepclassmembers,allowobfuscation class * {
  @com.google.gson.annotations.SerializedName <fields>;
}

# Retain generic signatures of TypeToken and its subclasses with R8 version 3.0 and higher.
-keep,allowobfuscation,allowshrinking class com.google.gson.reflect.TypeToken
-keep,allowobfuscation,allowshrinking class * extends com.google.gson.reflect.TypeToken

# Keep notification receiver classes
-keep class * extends android.content.BroadcastReceiver
-keep class * extends android.app.Service

# Keep Flutter plugin classes
-keep class io.flutter.plugins.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.embedding.** { *; }

# Keep notification scheduling classes
-keep class androidx.work.impl.** { *; }
-keep class androidx.work.WorkManager { *; }

# Keep alarm manager classes
-keep class android.app.AlarmManager { *; }
-keep class android.app.PendingIntent { *; }

# Additional rules for flutter_local_notifications
-keep class com.dexterous.flutterlocalnotifications.** { *; }
-keep class androidx.core.app.NotificationManagerCompat { *; }
-keep class androidx.core.app.NotificationCompat$* { *; }

# Keep notification channels
-keep class android.app.NotificationChannel { *; }
-keep class android.app.NotificationManager { *; }

# Keep scheduled notification classes
-keep class androidx.work.Data { *; }
-keep class androidx.work.Data$Builder { *; }
-keep class androidx.work.OneTimeWorkRequest { *; }
-keep class androidx.work.PeriodicWorkRequest { *; }
-keep class androidx.work.Worker { *; }
-keep class androidx.work.ListenableWorker { *; }

# Keep timezone classes
-keep class java.time.** { *; }
-keep class java.time.zone.** { *; }
-dontwarn java.time.**

# Google Play Core library rules
-dontwarn com.google.android.play.core.splitcompat.SplitCompatApplication
-dontwarn com.google.android.play.core.splitinstall.**
-dontwarn com.google.android.play.core.tasks.**
-dontwarn com.google.android.play.core.**

# Keep Google Play Core classes if they exist
-keep class com.google.android.play.core.** { *; }

# Flutter deferred components
-keep class io.flutter.embedding.engine.deferredcomponents.** { *; }
-dontwarn io.flutter.embedding.engine.deferredcomponents.PlayStoreDeferredComponentManager

# Additional Flutter rules
-keep class io.flutter.app.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.embedding.android.** { *; }
-keep class io.flutter.embedding.engine.** { *; }

# Keep all native method classes
-keepclasseswithmembernames,includedescriptorclasses class * {
    native <methods>;
}

# Keep all classes that have @Keep annotation
-keep @androidx.annotation.Keep class *
-keep class * {
    @androidx.annotation.Keep *;
}

# =========================
# Google Ads / Play Services Ads Rules
# =========================

# Keep Google Ads classes
-keep class com.google.android.gms.internal.ads.** { *; }
-dontwarn com.google.android.gms.internal.ads.**
-keep class com.google.android.gms.ads.** { *; }
-keep class com.google.ads.** { *; }

# Fix SafeAtomicHelper reflection issues (for the error you're seeing)
-keep class com.google.android.gms.internal.ads.zzgah { *; }
-keep class com.google.android.gms.internal.ads.zzgae { *; }
-keepclassmembers class com.google.android.gms.internal.ads.zzgah {
    private volatile <fields>;
}
-keepclassmembers class com.google.android.gms.internal.ads.zzgae {
    private volatile <fields>;
}

# General Google Play Services rules
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# Keep Google Mobile Ads classes
-keep class com.google.android.gms.ads.identifier.** { *; }
-keep class * extends java.util.ListResourceBundle {
    protected java.lang.Object[][] getContents();
}

# Google Ads mediation
-keep class com.google.ads.mediation.** { *; }
-keep class com.google.android.gms.ads.mediation.** { *; }

# =========================
# General Android/Java Compatibility Rules
# =========================

# Fix reflection issues in newer Android versions
-keepattributes RuntimeVisibleAnnotations
-keepattributes RuntimeInvisibleAnnotations
-keepattributes RuntimeVisibleParameterAnnotations
-keepattributes RuntimeInvisibleParameterAnnotations
-keepattributes AnnotationDefault
-keepattributes EnclosingMethod
-keepattributes InnerClasses

# Keep all reflection-based classes
-keepclassmembers class * {
    @java.lang.reflect.* <methods>;
}

# Suppress warnings for missing classes that are optional
-dontwarn java.lang.ClassValue
-dontwarn sun.misc.Unsafe
-dontwarn java.nio.file.Path
-dontwarn java.nio.file.OpenOption
-dontwarn org.codehaus.mojo.animal_sniffer.IgnoreJRERequirement
-dontwarn javax.annotation.**
-dontwarn javax.inject.**
-dontwarn sun.misc.Signal
-dontwarn sun.misc.SignalHandler

# =========================
# Additional Flutter/Dart Rules
# =========================

# Keep Dart VM service classes
-keep class io.flutter.view.FlutterMain { *; }
-keep class io.flutter.view.FlutterView { *; }
-keep class io.flutter.app.FlutterApplication { *; }

# Keep Flutter Engine classes
-keep class io.flutter.embedding.engine.FlutterEngine { *; }
-keep class io.flutter.embedding.engine.dart.DartExecutor { *; }

# Keep method channels
-keep class io.flutter.plugin.common.MethodChannel { *; }
-keep class io.flutter.plugin.common.EventChannel { *; }
-keep class io.flutter.plugin.common.BasicMessageChannel { *; }

# Keep platform views
-keep class io.flutter.plugin.platform.** { *; }

# =========================
# WebView Rules (if using webview)
# =========================

-keep class android.webkit.** { *; }
-keep class androidx.webkit.** { *; }
-dontwarn android.webkit.**

# =========================
# Kotlin Rules (if using Kotlin)
# =========================

-keep class kotlin.** { *; }
-keep class kotlin.Metadata { *; }
-dontwarn kotlin.**
-keepclassmembers class **$WhenMappings {
    <fields>;
}

# =========================
# General Optimization Rules
# =========================

# Keep line numbers for debugging stack traces
-keepattributes SourceFile,LineNumberTable

# Keep generic signatures for Gson
-keepattributes Signature

# Preserve some attributes that may be required by runtime
-keepattributes *Annotation*,Signature,InnerClasses,EnclosingMethod

# Don't preverify
-dontpreverify

# Allow optimization
-optimizations !code/simplification/cast,!field/*,!class/merging/*

# Keep crash reporting info
-keepattributes SourceFile,LineNumberTable
-keep public class * extends java.lang.Exception