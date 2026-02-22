-keepattributes *Annotation*
-keepclassmembers class * {
    @android.webkit.JavascriptInterface <methods>;
}
-keep class com.razorpay.** {*;}
-dontwarn com.razorpay.**
-keep class com.microsoft.appcenter.** { *; }
-dontwarn com.microsoft.appcenter.**
