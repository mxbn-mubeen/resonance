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
    //
    // Bumped 35 -> 36: androidx.core:core:1.18.0 (a transitive dependency)
    // requires compileSdk 36+. If a future dependency bump demands a
    // higher number again, the Gradle error will say "requires ... compile
    // against version N or later" - match compileSdk/targetSdk to N.
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    // Kotlin jvmTarget is set for every subproject (including :app) by the
    // root android/build.gradle.kts's compilerOptions block - no need to
    // duplicate it here.

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.mxbn.appresonance"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = 36
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
