plugins {
    id("com.android.application")
    id("kotlin-android")
    // The Flutter Gradle Plugin must be applied after the Android and Kotlin Gradle plugins.
    id("dev.flutter.flutter-gradle-plugin")
}

android {
    namespace = "jp.petitworks.shougaku_kore_doutoku"
    compileSdk = flutter.compileSdkVersion
    ndkVersion = flutter.ndkVersion

    compileOptions {
        sourceCompatibility = JavaVersion.VERSION_17
        targetCompatibility = JavaVersion.VERSION_17
    }

    kotlinOptions {
        jvmTarget = JavaVersion.VERSION_17.toString()
    }

    // ========================================
    // リリース署名設定
    // 環境変数またはlocal.propertiesから読み込み
    // ========================================
    signingConfigs {
        // リリース用署名設定
        // GitHub Actions では環境変数から読み込み
        // ローカルビルドでは gradle.properties から読み込み
        create("release") {
            // キーストアファイルパス
            // 環境変数: KEYSTORE_PATH (デフォルト: ~/.shougaku-kore-release.jks)
            val keystorePath = System.getenv("KEYSTORE_PATH")
                ?: file("${System.getProperty("user.home")}/.shougaku-kore-release.jks").absolutePath

            // キーストアの詳細情報
            storeFile = file(keystorePath)
            storePassword = System.getenv("KEYSTORE_PASSWORD") ?: ""
            keyAlias = System.getenv("KEYSTORE_ALIAS") ?: "shougaku-kore-key"
            keyPassword = System.getenv("KEYSTORE_KEY_PASSWORD") ?: ""

            // ストアタイプ
            storeType = "jks"
        }
    }

    defaultConfig {
        // アプリケーション ID
        applicationId = "jp.petitworks.shougaku_kore_doutoku"
        // You can update the following values to match your application needs.
        // For more information, see: https://flutter.dev/to/review-gradle-config.
        minSdk = flutter.minSdkVersion
        targetSdk = flutter.targetSdkVersion
        versionCode = flutter.versionCode
        versionName = flutter.versionName

        // Flutter v2 embedding
        // Required for compatibility with modern Flutter plugins
        manifestPlaceholders += mapOf(
            "flutterEmbedding" to "2"
        )
    }

    buildTypes {
        // ========================================
        // Debug ビルド設定
        // ========================================
        debug {
            // デバッグビルドは既存のデバッグ署名を使用
            signingConfig = signingConfigs.getByName("debug")
            isMinifyEnabled = false
        }

        // ========================================
        // Release ビルド設定
        // ========================================
        release {
            // リリースビルドはリリース署名を使用
            // 本番環境に公開するビルドには必須
            signingConfig = signingConfigs.getByName("release")
            isMinifyEnabled = true
            isShrinkResources = true

            // ProGuard/R8 ルールファイル
            proguardFiles(
                getDefaultProguardFile("proguard-android-optimize.txt"),
                "proguard-rules.pro"
            )
        }
    }
}

flutter {
    source = "../.."
}
