# 本番環境トラブルシューティング

**小学コレ！道徳** - よくある問題と対応方法

**最終更新**: 2026年9月1日

---

## 概要

本ドキュメントは、本番環境で発生する一般的な問題と、その診断・対応方法を記載しています。

**利用対象**: QA、オペレーション、サポート、エンジニア

---

## トラブル分類別ガイド

### 1. アプリ安定性に関する問題

#### 1.1 アプリが起動時にクラッシュする

**症状**:
- ユーザーが "アプリが何度も落ちる" と報告
- Firebase Crashlytics でクラッシュレート > 2%

**診断手順**:

```bash
# ステップ 1: 影響範囲を確認
open https://console.firebase.google.com/project/[id]/crashlytics

# 確認項目:
- [ ] どの OS バージョンか（iOS 15.x など）
- [ ] どのアプリバージョンか（v1.0.0 など）
- [ ] クラッシュの再現性（毎回 vs 時々）
```

**スタックトレース確認**:

```
Crashlytics > Issues > (トップクラッシュ)

読むべき情報:
- Exception Type: NullPointerException / EXC_BAD_ACCESS など
- Stack Trace: どのファイルの何行目か
- Breadcrumbs: クラッシュ前のユーザー操作ログ
```

**原因別対応**:

| 原因 | 症状 | 対応 |
|------|------|------|
| 初期化エラー | 起動時に 100% クラッシュ | Firebase 設定確認 |
| メモリ不足 | 古い端末でクラッシュ | メモリ最適化 |
| ネットワーク接続なし | 初回起動時にクラッシュ | オフライン対応改善 |
| 依存パッケージの問題 | 特定 OS バージョンのみ | パッケージ更新 |

**対応例**:

```dart
// Firebase 初期化エラー
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // Firebase 初期化を確認
  try {
    await Firebase.initializeApp(
      options: DefaultFirebaseOptions.currentPlatform,
    );
  } catch (e) {
    // エラーログを記録
    print('Firebase 初期化エラー: $e');
    // ユーザーにエラー画面を表示
    runApp(ErrorApp(error: e.toString()));
    return;
  }
  
  runApp(const MyApp());
}
```

**ホットフィックスが必要か判定**:

```
判定基準:

YES (即ホットフィックス):
- クラッシュレート > 2%
- 影響ユーザー数 > 1,000
- アプリが起動できない

NO (通常リリースで対応):
- クラッシュレート < 0.5%
- 影響ユーザー数 < 100
- 特定機能でのみクラッシュ
```

#### 1.2 特定の画面でクラッシュする

**症状**:
- ストーリー選択画面でクラッシュ
- 親向けレポート表示時にクラッシュ

**診断**:

```
Crashlytics > Issues > (対象クラッシュ) > "Affected Version Installs"

確認:
- [ ] 特定バージョンのみか
- [ ] 特定 OS のみか
- [ ] 特定ユーザーのみか
```

**ローカル再現**:

```bash
# 該当デバイスで再現
flutter run -d ios

# デバッグモードで詳細ログ出力
flutter run -d ios -v

# 音声ナレーション機能を有効化（問題の再現率アップ）
# lib/main.dart で enableAudioNarration = true
```

**よくある原因と対応**:

```
原因 1: List の out-of-bounds
症状: "Exception: List index out of bounds: 5"
対応:
  // 修正前（危険）
  var selectedChoice = choices[index];
  
  // 修正後
  if (index >= 0 && index < choices.length) {
    var selectedChoice = choices[index];
  }

原因 2: Null reference
症状: "NullPointerException" / "EXC_BAD_ACCESS"
対応:
  // 修正前
  var user = currentUser;
  print(user.name);  // user が null だとクラッシュ
  
  // 修正後
  var user = currentUser;
  if (user != null) {
    print(user.name);
  }

原因 3: 非同期処理中の画面遷移
症状: "setState called after dispose"
対応:
  @override
  void dispose() {
    _controller?.dispose();
    super.dispose();
  }
  
  Future<void> _loadData() async {
    if (!mounted) return;  // 画面が破棄されていないか確認
    var data = await api.fetchData();
    if (mounted) {
      setState(() {
        this.data = data;
      });
    }
  }
```

---

### 2. パフォーマンス問題

#### 2.1 アプリの起動時間が遅い

**症状**:
- ユーザーが "アプリが遅い" と報告
- Firebase Performance Monitoring で Cold Start > 5秒

**診断**:

```bash
# Firebase Performance Monitoring を確認
open https://console.firebase.google.com/project/[id]/performance

# 起動時間の詳細分析
Performance > "App Startup"
- Cold Start (初回起動): 目標 < 3秒
- Hot Start (復帰): 目標 < 1秒

# ローカルで測定
flutter run --profile
# デバッガでブレークポイント設定
```

**起動時間の最適化**:

```dart
// Firebase 初期化の遅延化（必要に応じて）
void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  
  // 必須の初期化のみ実施
  await SharedPreferences.getInstance();
  await _initHive();
  
  // Firebase 初期化は非同期で実施（バックグラウンド）
  Firebase.initializeApp(
    options: DefaultFirebaseOptions.currentPlatform,
  ).then((_) {
    // Firebase Analytics などは別途初期化
  });
  
  runApp(const MyApp());
}

// 遅延読み込み
class HomePage extends StatefulWidget {
  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  late Future<List<Story>> _stories;
  
  @override
  void initState() {
    super.initState();
    // 画面表示後に非同期ロード
    _stories = Future.delayed(Duration(milliseconds: 500), () async {
      return await api.fetchStories();
    });
  }
  
  @override
  Widget build(BuildContext context) {
    return FutureBuilder(
      future: _stories,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return _buildSkeletonScreen();  // スケルトン画面を表示
        }
        return _buildStoryList(snapshot.data);
      },
    );
  }
}
```

#### 2.2 ネットワークが遅い / API が応答しない

**症状**:
- "ストーリーが読み込めない"
- Cloud Logging で 5xx エラーが増加

**診断**:

```bash
# Cloud Logging で API エラーを確認
open https://console.cloud.google.com/logs

# ログクエリ
resource.type="cloud_run_revision"
severity="ERROR"
httpRequest.status >= 500

# API レスポンス時間の確認
resource.type="cloud_run_revision"
httpRequest.latency > "1s"
```

**ネットワークトレース**:

```bash
# ローカルでネットワーク遅延をシミュレート
# macOS の Network Link Conditioner を使用
# または Chrome DevTools で Slow 3G を選択

# API レスポンスを Fiddler で監視
# リクエスト/レスポンスのサイズとタイミングを確認
```

**対応方法**:

```dart
// タイムアウト設定
final dioClient = Dio(
  BaseOptions(
    receiveTimeout: const Duration(seconds: 10),
    connectTimeout: const Duration(seconds: 10),
    sendTimeout: const Duration(seconds: 10),
  ),
);

// リトライロジック
Future<T> _fetchWithRetry<T>({
  required Future<T> Function() request,
  int maxRetries = 3,
}) async {
  for (int i = 0; i < maxRetries; i++) {
    try {
      return await request();
    } on DioException catch (e) {
      if (i == maxRetries - 1) {
        // 最後の試行で失敗
        throw UserFacingException('データの読み込みに失敗しました。');
      }
      // 指数バックオフでリトライ
      await Future.delayed(Duration(seconds: 2 ^ i));
    }
  }
  throw Exception('リトライ失敗');
}

// キャッシング戦略
class StoryRepository {
  final ApiClient _api;
  final LocalStorage _cache;
  
  Future<Story> getStory(String storyId) async {
    // キャッシュから取得
    final cached = await _cache.getStory(storyId);
    if (cached != null) {
      return cached;
    }
    
    // API から取得
    final fresh = await _api.fetchStory(storyId);
    await _cache.cacheStory(fresh);
    return fresh;
  }
}
```

#### 2.3 メモリ使用量が多い / デバイスが熱くなる

**症状**:
- アプリがメモリ不足で再起動
- 古い端末で動作が遅い
- デバイスが熱くなる

**診断**:

```bash
# Firebase Performance で メモリを確認
open https://console.firebase.google.com/project/[id]/performance

# ローカルで Android Studio のProfiler を使用
# iOS の Instruments を使用

# メモリリーク検出
flutter pub add dev:devtools
flutter pub global activate devtools
devtools

# Dart DevTools > Memory タブで監視
```

**メモリ最適化**:

```dart
// 画像キャッシュの制限
imageCache.maximumSize = 100;  // 最大 100 個のイメージ
imageCache.maximumSizeBytes = 50 * 1024 * 1024;  // 50MB まで

// 不要な画像をクリア
imageCache.clear();
imageCache.clearLiveImages();

// StreamBuilder でメモリ管理
StreamBuilder<StoryData>(
  stream: storyStream,
  builder: (context, snapshot) {
    if (snapshot.hasData) {
      return Text(snapshot.data!.title);
    }
    return SizedBox.shrink();  // null render 代わりに SizedBox
  },
);

// ListView でメモリ管理
ListView.builder(
  itemCount: items.length,
  itemBuilder: (context, index) {
    return StoryCard(story: items[index]);
  },
);  // ListView.builder は必須（ListView ではメモリリーク）

// StatefulWidget でメモリ管理
@override
void dispose() {
  _controller.dispose();
  _subscription?.cancel();
  _timer?.cancel();
  super.dispose();
}
```

---

### 3. ネットワーク・API 関連の問題

#### 3.1 "インターネット接続がない" エラーが常に表示される

**症状**:
- オフラインなのに "接続エラー" メッセージが表示される
- Wi-Fi が接続されているのに "インターネットなし" と言われる

**診断**:

```bash
# ネットワーク接続を確認
flutter run -v
# "NETWORK: Connected" を確認

# localhost API への接続テスト
curl -v http://localhost:8080/health
```

**対応**:

```dart
// ネットワーク接続状態を確認
import 'package:connectivity_plus/connectivity_plus.dart';

Future<bool> isInternetConnected() async {
  final connectivityResult = await Connectivity().checkConnectivity();
  return connectivityResult != ConnectivityResult.none;
}

// API クライアントのオンライン判定
class ApiClient {
  Future<T> request<T>(
    String endpoint, {
    required T Function(dynamic) fromJson,
  }) async {
    // 1. インターネット接続確認
    if (!await isInternetConnected()) {
      // キャッシュから取得
      final cached = await _cache.get(endpoint);
      if (cached != null) {
        return fromJson(cached);
      }
      // キャッシュもない場合はエラー
      throw OfflineException('インターネット接続がありません。');
    }
    
    // 2. API リクエスト実行
    try {
      final response = await _dio.get(endpoint);
      final data = fromJson(response.data);
      
      // 3. 結果をキャッシュ
      await _cache.set(endpoint, response.data);
      return data;
    } catch (e) {
      // キャッシュから取得
      final cached = await _cache.get(endpoint);
      if (cached != null) {
        return fromJson(cached);
      }
      rethrow;
    }
  }
}
```

#### 3.2 Cloud Run バックエンド API が応答しない

**症状**:
- API が 504 エラーを返す
- API タイムアウト

**診断**:

```bash
# Cloud Run ログを確認
open https://console.cloud.google.com/logs

# ログクエリ
resource.type="cloud_run_revision"
resource.labels.service_name="shougaku-kore-backend"
severity >= "ERROR"

# Cloud Run のステータスを確認
gcloud run services describe shougaku-kore-backend --region asia-northeast1

# CPU/メモリ使用量を確認
gcloud monitoring time-series list \
  --filter='resource.type="cloud_run_revision"'
```

**対応**:

```bash
# リソース増加
gcloud run services update shougaku-kore-backend \
  --memory=1Gi \
  --cpu=2 \
  --max-instances=100 \
  --region=asia-northeast1

# ログの詳細出力
gcloud run services update shougaku-kore-backend \
  --update-env-vars=LOG_LEVEL=DEBUG \
  --region=asia-northeast1

# サービスを再デプロイ
gcloud run deploy shougaku-kore-backend \
  --image=gcr.io/[project]/shougaku-kore-backend:latest \
  --region=asia-northeast1 \
  --platform=managed
```

---

### 4. Firebase Firestore 関連の問題

#### 4.1 データが同期されない

**症状**:
- 子どもの進捗が保存されない
- 親向けレポートが更新されない

**診断**:

```bash
# Firebase Console で確認
open https://console.firebase.google.com/project/[id]/firestore

# ユーザードキュメント確認
Collections > users > [user_id]

# リアルタイムリスナーが動作しているか確認
db.collection('users').doc(userId).onSnapshot(...)

# Firestore Rules が正しいか確認
Firebase Console > Firestore Database > Rules
```

**対応**:

```dart
// ユーザー認証確認
if (FirebaseAuth.instance.currentUser == null) {
  // ログインしていない
  throw Exception('ログインが必要です。');
}

// Firestore 書き込み
try {
  await FirebaseFirestore.instance
    .collection('users')
    .doc(userId)
    .set({
      'name': childName,
      'grade': grade,
      'lastUpdated': FieldValue.serverTimestamp(),
    });
} catch (e) {
  print('Firestore エラー: $e');
  // ローカルキャッシュに保存
  await _cache.saveUser(userData);
}

// リアルタイムリスナー
final userRef = FirebaseFirestore.instance
  .collection('users')
  .doc(userId);

userRef.snapshots().listen(
  (doc) {
    // データ更新
    setState(() {
      userData = User.fromFirestore(doc);
    });
  },
  onError: (e) {
    print('リアルタイムリスナーエラー: $e');
  },
);
```

#### 4.2 Firestore Storage の容量超過

**症状**:
- ユーザーレポートの PDF 生成に失敗
- 画像のアップロードに失敗

**診断**:

```bash
# Firestore 使用量を確認
open https://console.firebase.google.com/project/[id]/firestore

# Storage 使用量を確認
open https://console.firebase.google.com/project/[id]/storage
```

**対応**:

```bash
# ドキュメント削除（不要な古いデータ）
gcloud firestore bulk-delete-operations \
  --collection=reports \
  --field=createdAt \
  --older-than=90d

# インデックスの最適化
# Firebase Console > Firestore Database > Indexes
```

---

### 5. 認証・支払い関連の問題

#### 5.1 ログイン画面で " Google ログイン " ボタンが表示されない

**症状**:
- Google Sign-in ボタンが表示されない
- " ログイン " を選択できない

**診断**:

```bash
# Google Sign-in 設定を確認
open https://console.firebase.google.com/project/[id]/authentication

# OAuth 2.0 設定
Authentication > Sign-in method > Google

確認事項:
- [ ] Google が有効か
- [ ] 認証済みドメインが正しいか
```

**対応**:

```dart
// Google Sign-in 初期化
final GoogleSignIn googleSignIn = GoogleSignIn(
  clientId: Platform.isIOS
      ? 'YOUR_IOS_CLIENT_ID.apps.googleusercontent.com'
      : null,  // Android は自動検出
);

// ログインボタン処理
ElevatedButton(
  onPressed: () async {
    try {
      final GoogleSignInAccount? googleUser = await googleSignIn.signIn();
      if (googleUser != null) {
        final GoogleSignInAuthentication googleAuth = await googleUser.authentication;
        final credential = GoogleAuthProvider.credential(
          accessToken: googleAuth.accessToken,
          idToken: googleAuth.idToken,
        );
        await FirebaseAuth.instance.signInWithCredential(credential);
      }
    } catch (e) {
      print('Google Sign-in エラー: $e');
      // ユーザーに エラー メッセージ表示
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('ログインに失敗しました: $e')),
      );
    }
  },
  child: Text('Google でログイン'),
)
```

#### 5.2 In-App Purchase が処理されない

**症状**:
- 課金ボタンをタップしても何も起きない
- " 購入ありがとうございます " メッセージが表示されない

**診断**:

```bash
# In-App Purchase 設定を確認
# Google Play Console > アプリ内製品
# App Store Connect > In-App Purchases

# 推奨購入テスト
# Android: testflight アカウント
# iOS: Sandbox テストユーザー
```

**対応**:

```dart
// In-App Purchase 初期化
import 'package:in_app_purchase/in_app_purchase.dart';

Future<void> initInAppPurchase() async {
  final iap = InAppPurchase.instance;
  
  // 利用可能か確認
  if (!await iap.isAvailable()) {
    print('In-App Purchase は利用できません');
    return;
  }
  
  // 製品情報を取得
  final ProductDetailsResponse response =
    await iap.queryProductDetails({'monthly_plan'});
  
  if (response.error != null) {
    print('製品取得エラー: ${response.error}');
  }
  
  for (var product in response.productDetails) {
    print('製品: ${product.title} - ${product.price}');
  }
}

// 購入処理
Future<void> purchaseSubscription(ProductDetails product) async {
  final iap = InAppPurchase.instance;
  
  final PurchaseParam purchaseParam = PurchaseParam(
    productDetails: product,
  );
  
  await iap.buyConsumable(
    purchaseParam: purchaseParam,
    autoConsume: true,
  );
}

// 購入結果リスナー
InAppPurchase.instance.purchaseStream.listen(
  (List<PurchaseDetails> purchaseDetailsList) {
    for (var purchase in purchaseDetailsList) {
      if (purchase.status == PurchaseStatus.pending) {
        // 保留中
      } else if (purchase.status == PurchaseStatus.error) {
        // エラー
        print('購入エラー: ${purchase.error}');
      } else if (purchase.status == PurchaseStatus.purchased) {
        // 成功
        _verifyAndDeliverPurchase(purchase);
      }
      
      if (purchase.pendingCompletePurchase) {
        await InAppPurchase.instance.completePurchase(purchase);
      }
    }
  },
);
```

---

### 6. データ・キャッシュ関連の問題

#### 6.1 ローカルストレージが破損している

**症状**:
- アプリが起動時にクラッシュ
- 以前保存したデータが見えない

**診断**:

```bash
# ローカルストレージファイルを確認
# Android: ~/.android/avd/[emulator]/data/data/jp.petitworks.shougaku_kore_doutoku/
# iOS: Simulator > 右クリック > Show in Finder > Library/Developer/CoreSimulator/Devices/[device]/data/

# Hive ボックスの再作成
dart run lib/main.dart --reset-storage
```

**対応**:

```dart
// Hive ボックスの初期化（エラーハンドリング）
Future<void> initHive() async {
  try {
    await Hive.initFlutter();
    Hive.registerAdapter(UserAdapter());
    Hive.registerAdapter(StoryProgressAdapter());
    
    // ボックスを開く
    await Hive.openBox<User>('users');
    await Hive.openBox<StoryProgress>('story_progress');
  } catch (e) {
    print('Hive 初期化エラー: $e');
    
    // ボックス削除 & リセット
    try {
      await Hive.deleteBoxFromDisk('users');
      await Hive.deleteBoxFromDisk('story_progress');
      // 再度初期化
      await initHive();
    } catch (deleteError) {
      print('ボックス削除エラー: $deleteError');
      // ユーザーに設定リセットを促す
      runApp(ResetApp());
    }
  }
}

// SharedPreferences でのデータ復旧
Future<void> recoverUserData() async {
  final prefs = await SharedPreferences.getInstance();
  
  // 保存されていたデータを復旧
  final savedUserJson = prefs.getString('user_backup');
  if (savedUserJson != null) {
    final userData = User.fromJson(jsonDecode(savedUserJson));
    await Hive.box<User>('users').put('current_user', userData);
  }
}
```

#### 6.2 キャッシュが古いデータを表示している

**症状**:
- 更新したストーリーが古い内容で表示される
- 修正したバグがまだ表示される

**対応**:

```dart
// キャッシュの有効期限を設定
class CachedStoryRepository {
  static const Duration _cacheValidity = Duration(hours: 24);
  
  Future<Story> getStory(String storyId) async {
    // キャッシュから取得
    final cached = await _cache.getStory(storyId);
    if (cached != null && !_isCacheExpired(cached.timestamp)) {
      return cached;
    }
    
    // API から新規取得
    final fresh = await _api.fetchStory(storyId);
    await _cache.cacheStory(fresh);
    return fresh;
  }
  
  bool _isCacheExpired(DateTime timestamp) {
    return DateTime.now().difference(timestamp) > _cacheValidity;
  }
}

// アプリ更新後のキャッシュクリア
void main() async {
  // アプリバージョンを確認
  final packageInfo = await PackageInfo.fromPlatform();
  final prefs = await SharedPreferences.getInstance();
  
  final lastVersion = prefs.getString('app_version');
  if (lastVersion != packageInfo.version) {
    // バージョンが異なる = アップデートされた
    // キャッシュをクリア
    await _clearAllCaches();
    await prefs.setString('app_version', packageInfo.version);
  }
  
  runApp(const MyApp());
}

Future<void> _clearAllCaches() async {
  await Hive.box('cache').clear();
  await imageCache.clear();
  imageCache.clearLiveImages();
}
```

---

### 7. ユーザーサポート関連の問題

#### 7.1 "アプリを削除・再インストールしてください" と案内する場合

**ユーザー向けガイド**:

```
【アプリをリセットする方法】

【Android】
1. 設定 > アプリ > 小学コレ！道徳
2. ストレージ > キャッシュを削除
3. Google Play ストア > 小学コレ！道徳 > 削除
4. 再度インストール

【iOS】
1. ホーム画面 > 小学コレ！道徳を長押し
2. "アプリを削除" > "削除"
3. App Store から再度インストール
```

#### 7.2 ログイン・パスワード・購入に関するお問い合わせ

**対応フロー**:

```
ユーザーからの問い合わせ
  ↓
1. ユーザーの メールアドレス と Google アカウント を確認
2. Firebase Console で ユーザーレコード を検索
3. 状態を確認:
   - ログイン可能か
   - In-App Purchase 購入履歴があるか
   - トライアル有効期限は切れていないか
4. 問題を特定
5. サポート対応
```

---

## トラブルシューティング チェックリスト

### P1 問題（即座に対応）

```
[ ] クラッシュレート > 2% → ホットフィックス対応
[ ] API 完全に応答しない → インフラ復旧
[ ] ユーザー認証できない → Firebase Auth 確認
[ ] 購入が処理されない → In-App Purchase 確認
```

### P2 問題（24時間以内）

```
[ ] パフォーマンス著しく低下 → キャッシング・最適化
[ ] 特定 OS でのみクラッシュ → OS 互換性修正
[ ] 特定機能が動作しない → 機能テスト & デバッグ
```

### P3 問題（通常リリースで対応）

```
[ ] UI 表示がわずかに崩れている → UI 調整
[ ] エラーメッセージが不適切 → メッセージ修正
[ ] ドキュメント・ヘルプが不正確 → ドキュメント更新
```

---

## 参考資料

- [docs/PRODUCTION_MONITORING_SETUP.md](PRODUCTION_MONITORING_SETUP.md)
- [docs/HOTFIX_RESPONSE_PLAN.md](HOTFIX_RESPONSE_PLAN.md)
- [Firebase Documentation](https://firebase.google.com/docs)
- [Flutter Performance Profiling](https://flutter.dev/docs/development/tools/devtools/performance)
