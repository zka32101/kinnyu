# google_mlkit_text_recognition's TextRecognizer.initialize() references all
# four script-specific recognizer option classes (Chinese/Devanagari/
# Japanese/Korean). Each ships as an OPTIONAL separate Maven artifact
# (com.google.mlkit:text-recognition-<script>); this app only adds the
# Japanese one (see app/build.gradle.kts) since that's the only script it
# uses (TextRecognitionScript.japanese), so tell R8 the other three's
# missing classes are fine - those code paths never execute here.
-dontwarn com.google.mlkit.vision.text.chinese.**
-dontwarn com.google.mlkit.vision.text.devanagari.**
-dontwarn com.google.mlkit.vision.text.korean.**
