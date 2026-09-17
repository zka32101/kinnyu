plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services")
    id("com.google.firebase.crashlytics")
}

android {
    namespace = "com.yourwish.kinnyu"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.yourwish.kinnyu"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        create("release") {
            keyAlias = System.getenv("ANDROID_KEYSTORE_KEY_ALIAS") ?: "release"
            keyPassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
            storeFile = if (System.getenv("ANDROID_KEYSTORE_BASE64") != null) {
                // For CI/CD: decode base64 and create temporary keystore
                val keystoreBase64 = System.getenv("ANDROID_KEYSTORE_BASE64") ?: ""
                if (keystoreBase64.isNotEmpty()) {
                    val keystoreBytes = java.util.Base64.getDecoder().decode(keystoreBase64)
                    val keystoreFile = File(buildDir, "release-keystore.jks")
                    keystoreFile.writeBytes(keystoreBytes)
                    keystoreFile
                } else {
                    null
                }
            } else {
                // For local development: read from gradle.properties
                val keystorePath = project.findProperty("KEYSTORE_PATH") as? String
                if (keystorePath != null) File(keystorePath) else null
            }
            storePassword = System.getenv("ANDROID_KEYSTORE_STORE_PASSWORD")
                ?: (project.findProperty("KEYSTORE_STORE_PASSWORD") as? String)
        }
    }

    buildTypes {
        release {
            signingConfig = if (signingConfigs.getByName("release").storeFile != null) {
                signingConfigs.getByName("release")
            } else {
                // Fallback to debug for local development without keystore
                signingConfigs.getByName("debug")
            }
            minifyEnabled = true
            shrinkResources = true
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

flutter {
    source = "../.."
}
