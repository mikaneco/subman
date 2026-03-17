# subman

[![pub package](https://img.shields.io/pub/v/subman.svg)](https://pub.dev/packages/subman)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Build](https://github.com/mikaneco/subman/actions/workflows/dart.yml/badge.svg)](https://github.com/mikaneco/subman/actions)
[![GitHub stars](https://img.shields.io/github/stars/mikaneco/subman.svg?style=social&label=Star)](https://github.com/mikaneco/subman)

Flutter向けのシンプルで開発者フレンドリーなサブスクリプション管理ライブラリです。
アプリ内課金の購入・復元・サーバーサイド検証を簡単かつ堅牢に実装できます。

**[English version](README.md)**

---

## 特徴

- シンプルな初期化・購入API
- ワンラインで過去の購入を復元
- Streamによるリアルタイムのサブスクリプション状態管理
- 統一されたユーザーフレンドリーなエラーハンドリング
- サーバーサイドのレシート/トークン検証をプラグイン可能（テスト用モック対応）
- 環境対応（シミュレータ、TestFlight、本番など）
- プラットフォーム非依存のコアロジック（`dart:io` 不使用でテスト可能）

---

## 動作要件

| 要件 | バージョン |
|---|---|
| Dart SDK | >= 3.5.0 |
| Flutter | >= 3.24.0 |

---

## セットアップ

`pubspec.yaml` に追加:

```yaml
dependencies:
  subman: ^1.0.0
```

インストール:

```bash
flutter pub get
```

---

## 使い方

### 1. インポート

```dart
import 'package:subman/subman.dart';
```

### 2. 初期化

```dart
await Subman.init(
  productIds: ['monthly_subscription', 'yearly_subscription'],
  onPurchaseCompleted: (subscription) {
    print('購入完了: ${subscription.productId}');
  },
  onRestoreCompleted: (subscriptions) {
    print('復元完了: ${subscriptions.length} 件');
  },
  onError: (exception) {
    print('エラー: ${exception.code} / ${exception.message}');
  },
  // オプション: サーバー検証クライアントを注入
  // serverClient: MyServerClient(),
);
```

### 3. サブスクリプションの購入

```dart
await Subman.purchase('monthly_subscription');
```

### 4. 過去の購入を復元

```dart
await Subman.restore();
```

### 5. サブスクリプション状態の取得

```dart
// 現在の状態を確認
final isActive = Subman.isSubscribed;
final current = Subman.currentSubscription;

// リアルタイムで更新を監視
Subman.activeSubscriptionsStream.listen((subscriptions) {
  // サブスクリプションの変更に反応
});
```

### 6. リソースの解放

```dart
Subman.dispose();
```

---

## サーバーサイド検証

デフォルトでは、サーバー検証は `false` を返すスタブが使われます。
独自のバックエンドでレシート/トークンを検証するには、`SubscriptionServerClient` を実装します:

```dart
class MyServerClient implements SubscriptionServerClient {
  @override
  Future<bool> verify(Map<String, dynamic> payload) async {
    // iOS payload:  { 'receipt': '...', 'platform': 'ios' }
    // Android payload: { 'purchaseToken': '...', 'orderId': '...', 'productId': '...', 'platform': 'android' }
    final response = await http.post(Uri.parse('https://api.example.com/verify'), body: payload);
    return response.statusCode == 200;
  }
}

await Subman.init(
  productIds: ['monthly', 'yearly'],
  serverClient: MyServerClient(),
  onPurchaseCompleted: (data) { /* ... */ },
);
```

---

## アーキテクチャ

### 概要

`subman` は `SubmanCore` シングルトンを中心に構築されています。すべてのサブスクリプションロジック、状態管理、IAP プラグインおよびサーバーとの通信を管理します。公開API（`Subman`）はこのコアの薄い静的ラッパーです。

### 主要な概念

- **初期化**: `Subman.init(...)` でIAPシステムのセットアップ、利用可能な商品の問い合わせ、購入更新のリスニングを行います。
- **購入フロー**: `Subman.purchase(productId)` は既存のサブスクリプションを確認し、アップグレード/ダウングレードを処理し、`in_app_purchase` プラグイン経由で購入を開始します。
- **復元**: `Subman.restore()` はプラグインの復元メカニズムを起動し、アクティブなサブスクリプションリストを更新します。
- **サーバー検証**: 購入または復元後、レシート/トークンが `SubscriptionServerClient` 経由でバックエンドに送信されます。結果に基づいてサブスクリプションが有効かどうかが判定されます。
- **状態管理**: アクティブなサブスクリプションはメモリ内で追跡され、`isSubscribed`、`currentSubscription`、`activeSubscriptionsStream` で公開されます。
- **エラーハンドリング**: すべてのエラーは `SubscriptionException` にラップされ、`onError` コールバックに渡されます。

### エクスポートされる型

| 型 | 説明 |
|---|---|
| `Subman` | 初期化・購入・復元・状態取得のメイン静的API |
| `SubscriptionData` | サブスクリプションを表す不変データクラス（JSON シリアライズ対応） |
| `SubscriptionException` | コードとメッセージを持つ統一エラークラス |
| `SubscriptionServerClient` | サーバーサイドのレシート/トークン検証用インターフェース |
| `SubscriptionState` | UI状態の列挙型（idle, loading, processing, purchased, restored, error） |
| `SubscriptionStatus` | Riverpod/Bloc連携用の状態コンテナ |
| `SubmanEnvironment` | 環境の列挙型（simulator, deviceDebug, testflight, internalTest, production） |

---

## テスト

`subman` はテスタビリティを重視して設計されています。プラットフォーム検出には `dart:io` ではなく `defaultTargetPlatform` を使用しているため、プラットフォーム固有の回避策なしですべてのロジックをテストできます。

### モックを使ったユニットテスト

```dart
import 'package:subman/subman.dart';
import 'package:subman/src/subman_core.dart';

// モックサーバークライアントを作成
class MockServerClient implements SubscriptionServerClient {
  @override
  Future<bool> verify(Map<String, dynamic> payload) async => true;
}

// SubmanCoreにモックを注入
final core = SubmanCore.test(
  serverClient: MockServerClient(),
  iap: mockInAppPurchase,               // MockitoによるInAppPurchaseのモック
  platformOverride: TargetPlatform.iOS,  // テスト用にプラットフォームをオーバーライド
);
```

### テストの実行

```bash
# 全テストを実行
flutter test

# カバレッジ付きで実行
flutter test --coverage

# モックの再生成（モックアノテーション変更後）
dart run build_runner build --delete-conflicting-outputs
```

テストスイートには以下をカバーする45のテストが含まれています:
- モデルのシリアライズ・等値性・copyWith
- PlatformExceptionおよびIAPErrorからの例外変換
- コアの初期化（ストア不可、商品なし、成功）
- 購入フロー（有効/無効なレシート、iOS/Android ペイロード）
- 復元フローとエラーハンドリング
- Streamの発行とdispose動作
- 静的ファサードAPI

---

## Riverpod / Bloc との連携

`subman` は `SubscriptionState` と `SubscriptionStatus` をエクスポートしており、状態管理ライブラリとの連携が容易です。

**Riverpod の例:**

```dart
final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionStatus>(
        (ref) => SubscriptionNotifier());

final status = ref.watch(subscriptionProvider);

if (status.state == SubscriptionState.purchased) {
  // プレミアムコンテンツを表示
}
```

---

## サンプルアプリ

完全なFlutter連携サンプルは [`example/main.dart`](example/lib/main.dart) を参照してください。

---

## 0.1.0 からの移行ガイド

- **SDK要件**: Dart >= 3.5.0 / Flutter >= 3.24.0（旧: Dart >= 3.0.0 / Flutter >= 3.0.0）
- **プラットフォーム検出**: 内部で `dart:io` を使用しなくなりました。`SubmanCore.test()` を使用していた場合、オプションの `platformOverride` パラメータが追加されています。
- **新規エクスポート**: `SubscriptionServerClient` と `SubmanEnvironment` が `package:subman/subman.dart` からエクスポートされるようになりました。`src/models/server_client.dart` の直接インポートは不要です。
- **SubscriptionData の等値性**: `==` と `hashCode` が実装され、コレクションや比較が正しく動作するようになりました。

---

## その他の情報

- APIリファレンス: [pub.dev/packages/subman](https://pub.dev/packages/subman)
- Issue / フィードバック: [GitHub Issues](https://github.com/mikaneco/subman/issues)
- コントリビューション歓迎!

---

(C) 2025 mikaneco
MIT License.
