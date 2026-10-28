plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

// Reuse the existing MyLui keystore without android/key.properties.
// Keep passwords out of this public repository: set BYELUI_KEY_PASSWORD
// and BYELUI_STORE_PASSWORD in the environment before release builds.
val releaseKeyPassword = System.getenv("BYELUI_KEY_PASSWORD") ?: ""
val releaseStorePassword = System.getenv("BYELUI_STORE_PASSWORD") ?: ""

android {
    namespace = "com.cloudfullstack.byelui"
    compileSdk = 37
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
        isCoreLibraryDesugaringEnabled = true
    }

    signingConfigs {
        create("release") {
            keyAlias = "my-key-alias"
            keyPassword = releaseKeyPassword
            storeFile = file("/Users/wynnteo/my-release-key.jks")
            storePassword = releaseStorePassword
        }
    }

    defaultConfig {
        applicationId = "com.cloudfullstack.byelui"
        // Android 8.0+ while retaining current compile/target SDK levels.
        minSdk = 26
        targetSdk = 37
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        multiDexEnabled = true
    }

    buildTypes {
        release {
            isMinifyEnabled = false
            isShrinkResources = false
            // Always sign with release key; missing credentials fail the build.
            signingConfig = signingConfigs.getByName("release")
        }

        debug {
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.5")
    implementation("androidx.work:work-runtime:2.10.0")
    implementation("androidx.core:core:1.15.0")
    implementation("com.google.android.gms:play-services-ads:24.5.0")
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

flutter {
    source = "../.."
}
