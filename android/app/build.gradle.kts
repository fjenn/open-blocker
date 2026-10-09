plugins {
    id("com.android.application")
    id("org.jetbrains.kotlin.android")
    id("app.cash.paparazzi") version "1.3.4"
}

val keystorePathEnv = System.getenv("OPENBLOCKER_KEYSTORE_PATH")
val keystorePasswordEnv = System.getenv("OPENBLOCKER_KEYSTORE_PASSWORD")
val keyAliasEnv = System.getenv("OPENBLOCKER_KEY_ALIAS")
val keyPasswordEnv = System.getenv("OPENBLOCKER_KEY_PASSWORD")
val keystoreFile = keystorePathEnv?.let { file(it) }
val hasReleaseKeystore = keystoreFile != null &&
    keystoreFile.isFile &&
    !keystorePasswordEnv.isNullOrBlank() &&
    !keyAliasEnv.isNullOrBlank() &&
    !keyPasswordEnv.isNullOrBlank()
val anyKeystoreEnvSet = !keystorePathEnv.isNullOrBlank() ||
    !keystorePasswordEnv.isNullOrBlank() ||
    !keyAliasEnv.isNullOrBlank() ||
    !keyPasswordEnv.isNullOrBlank()
if (anyKeystoreEnvSet && !hasReleaseKeystore) {
    throw org.gradle.api.GradleException(
        "OPENBLOCKER_KEYSTORE_* is incomplete or the keystore file is missing at " +
            "${keystorePathEnv ?: "(unset)"}. Set PATH, PASSWORD, KEY_ALIAS, and KEY_PASSWORD together, " +
            "or unset all of them to produce a debug-signed APK."
    )
}

android {
    namespace = "app.openblocker.android"
    compileSdk = 34

    defaultConfig {
        applicationId = "app.openblocker.android"
        minSdk = 24
        targetSdk = 34
        versionCode = 1
        versionName = "0.1.0-alpha"

        testInstrumentationRunner = "androidx.test.runner.AndroidJUnitRunner"
        vectorDrawables {
            useSupportLibrary = true
        }
        
        val countUrl = System.getenv("OPENBLOCKER_COUNT_URL") ?: ""
        val countKey = System.getenv("OPENBLOCKER_COUNT_KEY") ?: ""
        
        buildConfigField("String", "COUNT_URL", "\"$countUrl\"")
        buildConfigField("String", "COUNT_KEY", "\"$countKey\"")
        buildConfigField("boolean", "COUNT_ENABLED", "${countUrl.isNotEmpty() && countKey.isNotEmpty()}")
        
        val testMode = System.getenv("OPENBLOCKER_TEST_MODE") == "1"
        buildConfigField("boolean", "TEST_MODE", "$testMode")

    }

    signingConfigs {
        create("release") {
            if (hasReleaseKeystore) {
                storeFile = keystoreFile
                storePassword = keystorePasswordEnv
                this.keyAlias = keyAliasEnv
                this.keyPassword = keyPasswordEnv
            }
        }
    }
    
    buildTypes {
        debug {
            ndk {
                abiFilters += listOf("armeabi-v7a", "arm64-v8a", "x86_64")
            }
        }
        release {
            isMinifyEnabled = false
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
            signingConfig = if (hasReleaseKeystore) {
                signingConfigs.getByName("release")
            } else {
                signingConfigs.getByName("debug")
            }
            ndk {
                abiFilters += listOf("armeabi-v7a", "arm64-v8a")
            }
        }
    }
    
    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_11
        targetCompatibility = JavaVersion.VERSION_11
    }
    
    kotlinOptions {
        jvmTarget = "11"
    }
    
    buildFeatures {
        compose = true
        buildConfig = true
    }
    
    composeOptions {
        kotlinCompilerExtensionVersion = "1.5.4"
    }
    
    packaging {
        resources {
            excludes += "/META-INF/{AL2.0,LGPL2.1}"
        }
    }
}

dependencies {
    implementation("androidx.core:core-ktx:1.12.0")
    implementation("androidx.lifecycle:lifecycle-runtime-ktx:2.6.2")
    implementation("androidx.activity:activity-compose:1.8.1")
    implementation(platform("androidx.compose:compose-bom:2023.10.01"))
    implementation("androidx.compose.ui:ui")
    implementation("androidx.compose.ui:ui-graphics")
    implementation("androidx.compose.ui:ui-tooling-preview")
    implementation("androidx.compose.material3:material3")
    implementation("androidx.navigation:navigation-compose:2.7.5")
    implementation("androidx.lifecycle:lifecycle-viewmodel-compose:2.6.2")
    implementation("androidx.appcompat:appcompat:1.6.1")
    implementation("com.journeyapps:zxing-android-embedded:4.3.0")
    implementation("androidx.security:security-crypto:1.1.0-alpha06")
    implementation("com.google.android.filament:filament-android:1.51.2")
    implementation("com.google.android.filament:filament-utils-android:1.51.2")
    implementation("com.google.android.filament:gltfio-android:1.51.2")
    
    testImplementation("junit:junit:4.13.2")
    androidTestImplementation("androidx.test.ext:junit:1.1.5")
    androidTestImplementation("androidx.test.espresso:espresso-core:3.5.1")
    androidTestImplementation(platform("androidx.compose:compose-bom:2023.10.01"))
    androidTestImplementation("androidx.compose.ui:ui-test-junit4")
    debugImplementation("androidx.compose.ui:ui-tooling")
    debugImplementation("androidx.compose.ui:ui-test-manifest")
}
