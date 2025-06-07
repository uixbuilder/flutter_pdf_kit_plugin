-keep class com.tom_roush.pdfbox.** { *; }
-keep class org.apache.commons.logging.** { *; }
-keep class com.tom_roush.harmony.awt.** { *; }
-keepattributes Signature
-keepattributes *Annotation*

# Keep PDFBox resource files
-keep class com.tom_roush.pdfbox.resources.** { *; }