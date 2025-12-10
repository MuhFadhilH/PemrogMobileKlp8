plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.example.biblio"
    compileSdk = flutter.compileSdkVersion
    
    // 1. UBAH BAGIAN INI (Mengatur versi NDK secara manual)
    ndkVersion = "27.0.12077973"

    compileOptions {
        // 2. TAMBAHKAN BARIS INI (Mengaktifkan Desugaring)
        isCoreLibraryDesugaringEnabled = true
        
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.example.contoh" // Pastikan ID ini sesuai keinginanmu
        minSdk = 33
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
        
        // Opsional: Jika error multidex muncul nanti, tambahkan ini:
        // multiDexEnabled = true 
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

// 3. TAMBAHKAN BLOK DEPENDENCIES INI DI BAGIAN PALING BAWAH
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}