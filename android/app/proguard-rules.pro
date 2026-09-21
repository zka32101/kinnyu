# ML Kit text recognition (google_mlkit_text_recognition) dynamically loads
# script-specific recognizer classes at runtime, so R8 strips them as unused
# unless explicitly kept. Without these rules, minifyReleaseWithR8 fails with
# "Missing class com.google.mlkit.vision.text.*.{Chinese,Devanagari,
# Japanese,Korean}TextRecognizerOptions" even though only one script is used
# at runtime — see https://developers.google.com/ml-kit/vision/text-recognition/v2/android
-keep class com.google.mlkit.vision.text.chinese.** { *; }
-keep class com.google.mlkit.vision.text.devanagari.** { *; }
-keep class com.google.mlkit.vision.text.japanese.** { *; }
-keep class com.google.mlkit.vision.text.korean.** { *; }
