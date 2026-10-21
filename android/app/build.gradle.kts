plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

// Shared debug signing key for the whole team (docs/guides/firebase-setup.md,
// "Team setup"). The owner stores the debug keystore, base64-encoded, in the
// untracked .env as DEBUG_KEYSTORE_BASE64. Every teammate's debug build is
// then signed with the same key, so only one SHA-1 / SHA-256 has to be
// registered in Firebase for Google Sign-In. Without the value, Gradle uses
// the default ~/.android/debug.keystore. Keystores are never committed.
val sharedDebugKeystore: File? = run {
    val env = rootProject.file("../.env")
    if (!env.isFile) return@run null
    val encoded = env.readLines()
        .map { it.trim() }
        .firstOrNull { it.startsWith("DEBUG_KEYSTORE_BASE64=") }
        ?.substringAfter("=")
        ?.trim()
        ?.trim('"', '\'')
    if (encoded.isNullOrEmpty()) return@run null
    val keystore = layout.buildDirectory.file("shared-debug.keystore").get().asFile
    keystore.parentFile.mkdirs()
    keystore.writeBytes(java.util.Base64.getDecoder().decode(encoded))
    keystore
}

android {
    namespace = "com.group3.internly"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.group3.internly"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        // Uses the version code from pubspec.yaml. When using split APKs, 1000 * ABI_VERSION
        // is added automatically by Flutter. (https://developer.android.com/studio/build/configure-apk-splits#configure-APK-versions)
        // You can force using the value of versionCode by specifying the `-P force-version-code-ignoring-abi=true`
        // flag during build.
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    signingConfigs {
        getByName("debug") {
            sharedDebugKeystore?.let {
                storeFile = it
                storePassword = "android"
                keyAlias = "androiddebugkey"
                keyPassword = "android"
            }
        }
    }

    buildTypes {
        release {
            // TODO: Add your own signing config for the release build.
            // Signing with the debug keys for now, so `flutter run --release` works.
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget = org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17
    }
}

flutter {
    source = "../.."
}
