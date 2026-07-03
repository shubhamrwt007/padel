import java.util.Properties
import java.io.FileInputStream

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
val hasKeystore = keystorePropertiesFile.exists()
if (hasKeystore) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}
plugins {
    id("com.android.application")
    // START: FlutterFire Configuration
    id("com.google.gms.google-services")
    // END: FlutterFire Configuration
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "com.matchacha.app"
    compileSdk = 36
    ndkVersion = "27.0.12077973"

    compileOptions {
        // Enable core library desugaring for flutter_local_notifications
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_11.toString()
    }

    defaultConfig {
        applicationId = "com.matchacha.app"
        minSdk = flutter.minSdkVersion
        targetSdk = 36

        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Enable multidex if needed
        multiDexEnabled = true
    }
    signingConfigs {
        if (hasKeystore) {
            create("release") {
                keyAlias = keystoreProperties["keyAlias"]?.toString()
                    ?: error("keyAlias missing from key.properties")
                keyPassword = keystoreProperties["keyPassword"]?.toString()
                    ?: error("keyPassword missing from key.properties")
                storeFile = keystoreProperties["storeFile"]?.let { file(it) }
                    ?: error("storeFile missing from key.properties")
                storePassword = keystoreProperties["storePassword"]?.toString()
                    ?: error("storePassword missing from key.properties")
            }
        }
    }
    buildTypes {
        release {
            // Fall back to debug signing when no release keystore is provided.
            signingConfig = if (hasKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            
            // Disable minification and resource shrinking to avoid duplicate class issues
            isMinifyEnabled = false
            isShrinkResources = false
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    // Add core library desugaring for flutter_local_notifications
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.1.4")

    // Play Install Referrer for deferred deep links
    implementation("com.android.installreferrer:installreferrer:2.2")

    // Add multidex support if needed
    implementation("androidx.multidex:multidex:2.0.1")

    // Firebase BOM - manages all Firebase library versions
    implementation(platform("com.google.firebase:firebase-bom:32.7.0"))

    // Firebase dependencies
    implementation("com.google.firebase:firebase-messaging")
    implementation("com.google.firebase:firebase-analytics")

    // For notification icons and styling
    implementation("androidx.core:core:1.12.0")
    implementation("androidx.work:work-runtime:2.9.0")

    // For handling notification clicks
    implementation("androidx.localbroadcastmanager:localbroadcastmanager:1.1.0")
}
