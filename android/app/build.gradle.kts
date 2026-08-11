plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.mxbn.resonance"
    // Pinned explicitly rather than `flutter.compileSdkVersion` - that
    // expression's resolved value depends on exactly which Flutter version
    // is installed on the build machine (local or CI), and isar_flutter_libs
    // bundles resources referencing android:attr/lStar (added in API 31).
    // A too-low or inconsistently-resolved compileSdk causes AAPT to fail
    // resource linking with "resource android:attr/lStar not found" - this
    // pin makes the build deterministic across every machine/CI runner
    // regardless of which Flutter version happens to be installed there.
    compileSdk = 35
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mxbn.appresonance"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 35
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}
