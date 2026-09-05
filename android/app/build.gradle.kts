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

    buildFeatures {
        buildConfig = true
    }

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
        resValue("string", "app_name", "Absorb")
        buildConfigField(
            "int",
            "ABSORB_BASE_VERSION_CODE",
            flutter.versionCode.toString()
        )
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
        // Local testing build that installs beside the stable app: its own
        // application id, name and icon tint, otherwise the github build.
        create("dev") {
            dimension = "distribution"
            applicationIdSuffix = ".dev"
            resValue("string", "app_name", "Absorb Dev")
            proguardFiles("proguard-flutter-keep.pro")
        }
        // GMS-free build for F-Droid: no Chromecast, Wear bridge, or in-app updater.
        create("fdroid") {
            dimension = "distribution"
        }
    }

    // GMS-touching Kotlin (cast + wear) is shared by github + playstore only.
    // fdroid gets src/fdroid/kotlin instead, which has no Google Play Services.
    // Uses java.srcDir (kotlin-android compiles it too) for broad Gradle/Kotlin
    // plugin compatibility.
    sourceSets {
        getByName("github").java.srcDir("src/gms/kotlin")
        getByName("playstore").java.srcDir("src/gms/kotlin")
        getByName("dev").java.srcDir("src/gms/kotlin")
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

    // F-Droid builds one APK per ABI and its recipe declares each build's code
    // as versionCode * 10 + abiCode, so that scheme has to stay exactly as it
    // is: flattening it would fail F-Droid's build and strand everyone already
    // installed on a higher code, since F-Droid never offers a lower one.
    // (Flutter's own split scheme puts the ABI in the highest digit, which
    // breaks F-Droid's update ordering, hence the override in the first place.)
    //
    // Everywhere else every APK keeps the plain build number, so the universal
    // APK and the per-ABI ones install over each other in either direction.
    val abiCodes = mapOf("armeabi-v7a" to 1, "arm64-v8a" to 2, "x86_64" to 3)
    applicationVariants.all {
        val variant = this
        outputs.all {
            val output = this as com.android.build.gradle.internal.api.ApkVariantOutputImpl
            val abi = output.filters.find { it.filterType == "ABI" }?.identifier
            val abiCode = abiCodes[abi]
            if (abiCode != null) {
                output.versionCodeOverride = if (variant.flavorName == "fdroid") {
                    variant.versionCode * 10 + abiCode
                } else {
                    // Flutter's split plugin already set abi * 1000 + code here,
                    // so the plain build number has to be written back over it.
                    variant.versionCode
                }
            }
            // "all-universal" rather than "universal" so the every-ABI APK sorts
            // above arm64-v8a/armeabi-v7a in the release asset list. Updaters
            // built before 1.9.3+228 just take the first .apk they find, so the
            // one that installs anywhere has to be the one they land on. The
            // word "universal" stays in the name because newer updaters match it
            // as a token when no per-ABI build fits.
            val packageKind = abi ?: "all-universal"
            val flavorTag = if (variant.flavorName == "dev") "-dev" else ""
            output.outputFileName =
                "absorb-${variant.versionName}-${variant.versionCode}$flavorTag-$packageKind.apk"
        }
    }
}

flutter {
    source = "../.."
}

dependencies {
    coreLibraryDesugaring("com.android.tools:desugar_jdk_libs:2.0.4")
    testImplementation("junit:junit:4.13.2")

    // SAF document moves for custom download folders (MainActivity.moveBookToSaf).
    implementation("androidx.documentfile:documentfile:1.0.1")

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
        add("devImplementation", it)
    }
}

// F-Droid build must ship no Google Play Core (proprietary; the Flutter engine
// pulls it in for deferred components, which Absorb doesn't use). Scoped to the
// fdroid flavor so the github/playstore builds are unchanged.
configurations.matching { it.name.startsWith("fdroid") }.configureEach {
    exclude(group = "com.google.android.play")
}
