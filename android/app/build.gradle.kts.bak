plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.tari_app"
    compileSdk = 36
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    defaultConfig {
        applicationId = "com.example.tari_app"
        minSdk = 24
        targetSdk = 36
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

kotlin {
    compilerOptions {
        jvmTarget.set(org.jetbrains.kotlin.gradle.dsl.JvmTarget.JVM_17)
    }
}

dependencies {
    // MediaPipe — pake versi stabil yang gak konflik protobuf
    implementation("com.google.mediapipe:tasks-vision:0.10.14")

    // Force protobuf ke versi kompatibel (javalite, bukan java)
    implementation("com.google.protobuf:protobuf-javalite:3.21.12")

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")
}

// Force ALL protobuf variants ke satu versi — fix NoSuchMethodError
configurations.all {
    resolutionStrategy {
        force("com.google.protobuf:protobuf-java:3.21.12")
        force("com.google.protobuf:protobuf-javalite:3.21.12")
        force("com.google.protobuf:protobuf-kotlin:3.21.12")
        force("com.google.protobuf:protobuf-kotlin-lite:3.21.12")
    }
}

flutter {
    source = "../.."
}