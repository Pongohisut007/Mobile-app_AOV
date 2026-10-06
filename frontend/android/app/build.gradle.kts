plugins {
    id("com.android.application")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.aovpro.recipy"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        // TODO: Specify your own unique Application ID (https://developer.android.com/studio/build/application-id.html).
        applicationId = "com.aovpro.recipy"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    // debug keystore กลางของทีม (อยู่ใน repo) ทุกเครื่องได้ SHA-1 เดียวกัน
    // Google Sign-In ผูก Android client กับ package + SHA-1 นี้ ไม่ต้องลงทะเบียนทีละเครื่อง
    // รหัสเป็นค่ามาตรฐานของ debug keystore ไม่ใช่ความลับ (ห้ามใช้ key นี้ขึ้น Play Store)
    signingConfigs {
        getByName("debug") {
            storeFile = file("debug.keystore")
            storePassword = "android"
            keyAlias = "androiddebugkey"
            keyPassword = "android"
        }
        val keystorePath = System.getenv("ANDROID_KEYSTORE_PATH")
        val keystorePassword = System.getenv("ANDROID_KEYSTORE_PASSWORD")
        val keyAliasValue = System.getenv("ANDROID_KEY_ALIAS")
        val keyPasswordValue = System.getenv("ANDROID_KEY_PASSWORD")
        if (listOf(keystorePath, keystorePassword, keyAliasValue, keyPasswordValue)
                .all { !it.isNullOrBlank() }) {
            create("release") {
                storeFile = file(keystorePath!!)
                storePassword = keystorePassword!!
                keyAlias = keyAliasValue!!
                keyPassword = keyPasswordValue!!
            }
        }
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.findByName("release")
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
