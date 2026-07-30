import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Real release signing, read from android/key.properties (gitignored — see
// android/.gitignore). Required for release builds — see the check() in the
// release buildType below; debug builds are unaffected either way.
val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "tn.sahali.sahali"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        // Required by flutter_local_notifications for core-library desugaring.
        isCoreLibraryDesugaringEnabled = true
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "tn.sahali.sahali"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        // Always create the config object (so buildTypes.release below can
        // reference it during configuration without failing) but only
        // populate it when the properties file actually exists.
        create("release") {
            if (keystorePropertiesFile.exists()) {
                keyAlias = keystoreProperties["keyAlias"] as String
                keyPassword = keystoreProperties["keyPassword"] as String
                storeFile = file(keystoreProperties["storeFile"] as String)
                storePassword = keystoreProperties["storePassword"] as String
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("release")
        }
    }
}

// Fail loudly rather than silently shipping a debug-signed release artifact
// if key.properties is missing (e.g. a misconfigured CI secret) — but only
// when a release variant is actually being built, so debug/profile builds
// and plain Gradle syncs still work without a keystore. Matches broadly on
// "Release" (not just assembleRelease/bundleRelease) because the actual
// signing happens in an earlier task (packageRelease) — a check placed only
// on the umbrella task never runs, since packaging fails first with AGP's
// own (less clear) error.
tasks.matching { it.name.contains("Release") }.configureEach {
    doFirst {
        check(keystorePropertiesFile.exists()) {
            "Missing android/key.properties — release builds require a real signing config."
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}
