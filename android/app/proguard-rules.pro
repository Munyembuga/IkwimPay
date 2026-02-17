# Please add these rules to your existing keep rules in order to suppress warnings.
# This is generated automatically by the Android Gradle plugin.
-dontwarn org.tensorflow.lite.gpu.GpuDelegateFactory$Options

# Flutter wrapper
-keep class io.flutter.app.** { *; }
-keep class io.flutter.plugin.** { *; }
-keep class io.flutter.util.** { *; }
-keep class io.flutter.view.** { *; }
-keep class io.flutter.** { *; }
-keep class io.flutter.plugins.** { *; }

# Google ML Kit
-keep class com.google.mlkit.** { *; }
-keep class com.google.android.gms.** { *; }
-dontwarn com.google.android.gms.**

# TensorFlow Lite
-keep class org.tensorflow.lite.** { *; }
-dontwarn org.tensorflow.lite.**

# Sunmi Printer
-keep class com.sunmi.** { *; }
-dontwarn com.sunmi.**

# Blue Thermal Printer
-keep class com.thermal.** { *; }
-dontwarn com.thermal.**

# NFC
-keep class android.nfc.** { *; }

# Gson (if used)
-keepattributes Signature
-keepattributes *Annotation*
-dontwarn sun.misc.**
-keep class * implements com.google.gson.TypeAdapter
-keep class * implements com.google.gson.TypeAdapterFactory
-keep class * implements com.google.gson.JsonSerializer
-keep class * implements com.google.gson.JsonDeserializer

# Keep custom model classes - update with your actual model package
-keep class com.itec.ikwimpays.models.** { *; }

# General Android rules
-keepclassmembers class * implements android.os.Parcelable {
    public static final ** CREATOR;
}