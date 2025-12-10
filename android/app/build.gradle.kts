plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.biblio"
    compileSdk = flutter.compileSdkVersion
    
    // Pastikan versi NDK ini sudah terinstall di Android Studio kamu
    ndkVersion = "27.0.12077973"

    compileOptions {
        // --- INI BAGIAN YANG SEBELUMNYA KURANG ---
        isCoreLibraryDesugaringEnabled = true
        // -----------------------------------------

        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.contoh" 
        
        // Catatan: minSdk 33 berarti aplikasi hanya jalan di Android 13 ke atas.
        // Jika ingin support HP lama, ubah ke 21 atau 23.
        minSdk = 33 
        
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    buildTypes {
        release {
            signingConfig = signingConfigs.getByName("debug")
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Dependency ini wajib ada untuk desugaring
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}