plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
    id("com.google.gms.google-services") // ✅ Firebase plugin added
}

android {
    namespace = "com.example.medibot"
    compileSdk = flutter.compileSdkVersion

    // ✅ Required NDK version for flutter_native_splash compatibility
    ndkVersion = "27.0.12077973"

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.medibot"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug") // Replace with release config for production
        }
    }
}

flutter {
    source = "../.."
}

// ✅ Ensure this is at the bottom of the file if you ever switch to Groovy
// apply(plugin = "com.google.gms.google-services") ← only needed in Groovy-based builds
