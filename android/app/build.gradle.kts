import java.util.Properties
import java.io.FileInputStream

plugins {
    id("com.android.application")
    id("kotlin-android")
    id("dev.flutter.flutter-gradle-plugin")
}

val keystoreProperties = Properties()
val keystorePropertiesFile = rootProject.file("key.properties")
if (keystorePropertiesFile.exists()) {
    keystoreProperties.load(FileInputStream(keystorePropertiesFile))
}

android {
    namespace = "com.barnabas.absorb"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        isCoreLibraryDesugaringEnabled = true
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    signingConfigs {
        create("release") {
            keyAlias = keystoreProperties["keyAlias"] as String?
            keyPassword = keystoreProperties["keyPassword"] as String?
            storeFile = (keystoreProperties["storeFile"] as String?)?.let { file(it) }
            storePassword = keystoreProperties["storePassword"] as String?
        }
    }

    defaultConfig {
        applicationId = "com.barnabas.absorb"
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName
    }

    flavorDimensions += "distribution"
    productFlavors {
        // github + playstore keep the broad Flutter proguard keep. fdroid omits
        // it so R8 can strip Flutter's unused deferred-components manager, which
        // would otherwise drag proprietary Google Play Core class references into
        // the APK and fail F-Droid's scanner.
        create("github") {
            dimension = "distribution"
            proguardFiles("proguard-flutter-keep.pro")
        }
        create("playstore") {
            dimension = "distribution"
            proguardFiles("proguard-flutter-keep.pro")
        }
        // GMS-free build for F-Droid: no Chromecast, Wear bridge, or in-app updater.
        create("fdroid") {
            dimension = "distribution"
        }
        // Android Automotive OS build. Runs natively on the car head unit and is
        // driven by the media browse service, so it has no use for Chromecast or
        // the Wear bridge. Keeps the Flutter proguard keep so the Play-delivered
        // build behaves like playstore.
        create("automotive") {
            dimension = "distribution"
            proguardFiles("proguard-flutter-keep.pro")
        }
    }

    // GMS-touching Kotlin (cast + wear) is shared by github + playstore only.
    // fdroid gets src/fdroid/kotlin instead, which has no Google Play Services.
    // automotive reuses that same no-op PlatformIntegration. Uses java.srcDir
    // (kotlin-android compiles it too) for broad Gradle/Kotlin plugin compatibility.
    sourceSets {
        getByName("github").java.srcDir("src/gms/kotlin")
        getByName("playstore").java.srcDir("src/gms/kotlin")
        getByName("automotive").java.srcDir("src/fdroid/kotlin")
    }

    buildTypes {
    debug {
        signingConfig = signingConfigs.getByName("release")
    }
    release {
        signingConfig = signingConfigs.getByName("release")
        isMinifyEnabled = true
        isShrinkResources = true
        proguardFiles(
            getDefaultProguardFile("proguard-android-optimize.txt"),
            "proguard-rules.pro"
        )
    }
}

    applicationVariants.all {
        outputs.all {
            (this as com.android.build.gradle.internal.api.BaseVariantOutputImpl)
                .outputFileName = "absorb-${versionName}-${versionCode}.apk"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")

    // Google Play Services — Chromecast + Wearable Data Layer (pushes ABS
    // session credentials to the paired Wear OS app so the watch can sign in
    // without typing on the watch keyboard). Scoped to github + playstore so
    // the fdroid flavor links no GMS.
    val gmsImpl = listOf(
        "com.google.android.gms:play-services-cast-framework:21.5.0",
        "com.google.android.gms:play-services-wearable:19.0.0",
        "org.jetbrains.kotlinx:kotlinx-coroutines-play-services:1.9.0",
    )
    gmsImpl.forEach {
        add("githubImplementation", it)
        add("playstoreImplementation", it)
    }
}

// F-Droid build must ship no Google Play Core (proprietary; the Flutter engine
// pulls it in for deferred components, which Absorb doesn't use). Scoped to the
// fdroid flavor so the github/playstore builds are unchanged.
configurations.matching { it.name.startsWith("fdroid") }.configureEach {
    exclude(group = "com.google.android.play")
}