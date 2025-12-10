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
<<<<<<< HEAD
        // 2. TAMBAHKAN BARIS INI (Mengaktifkan Desugaring)
        isCoreLibraryDesugaringEnabled = true
        
=======
        isCoreLibraryDesugaringEnabled = true

>>>>>>> 71de3c5bb23d261c25e217088207113ddcc25795
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

<<<<<<< HEAD
=======
dependencies {
    // Import the Firebase BoM
    implementation(platform("com.google.firebase:firebase-bom:34.6.0"))

    // Add the dependencies for Firebase products you want to use
    // When using the BoM, don't specify versions in Firebase dependencies
    // implementation("com.google.firebase:firebase-analytics")

    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.2")
}

>>>>>>> 71de3c5bb23d261c25e217088207113ddcc25795
flutter {
    source = "../.."
}

// 3. TAMBAHKAN BLOK DEPENDENCIES INI DI BAGIAN PALING BAWAH
dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
}