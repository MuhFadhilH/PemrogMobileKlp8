// android/build.gradle.kts

buildscript {
    repositories {
        google()
        mavenCentral()
    }
    dependencies {
        // Add the dependency for the Google services Gradle plugin
        classpath("com.google.gms:google-services:4.4.4")
        // Add Android Gradle Plugin (Ensure version matches your AGP version)
        classpath("com.android.tools.build:gradle:8.2.0") // Check your project for the correct version
    }
}

allprojects {
    repositories {
        google()
        mavenCentral()
    }
}

val newBuildDir: Directory = rootProject.layout.buildDirectory.dir("../../build").get()
rootProject.layout.buildDirectory.value(newBuildDir)

subprojects {
    val newSubprojectBuildDir: Directory = newBuildDir.dir(project.name)
    project.layout.buildDirectory.value(newSubprojectBuildDir)
}
subprojects {
    project.evaluationDependsOn(":app")
}

// This task is safe here because we removed the Application plugin from this file
tasks.register<Delete>("clean") {
    delete(rootProject.layout.buildDirectory)
}