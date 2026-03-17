# subman

[![pub package](https://img.shields.io/pub/v/subman.svg)](https://pub.dev/packages/subman)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Build](https://github.com/mikaneco/subman/actions/workflows/dart.yml/badge.svg)](https://github.com/mikaneco/subman/actions)
[![GitHub stars](https://img.shields.io/github/stars/mikaneco/subman.svg?style=social&label=Star)](https://github.com/mikaneco/subman)

A simple, developer-friendly subscription management library for Flutter.
Subman makes handling in-app subscriptions, restoration, and server-side validation effortless and robust for any Flutter project.

**[Japanese / 日本語版はこちら](README_ja.md)**

---

## Features

- Simple initialization & purchase API
- One-line restore for past subscriptions
- Real-time subscription status via Stream
- Unified, user-friendly error handling
- Plug-in server-side receipt/token validation (with easy mocking for tests)
- Environment-aware (simulator, TestFlight, production, etc.)
- Platform-independent core (testable without `dart:io`)

---

## Requirements

| Requirement | Version |
|---|---|
| Dart SDK | >= 3.5.0 |
| Flutter | >= 3.24.0 |

---

## Getting Started

Add to your `pubspec.yaml`:

```yaml
dependencies:
  subman: ^1.0.0
```

Then run:

```bash
flutter pub get
```

---

## Usage

### 1. Import

```dart
import 'package:subman/subman.dart';
```

### 2. Initialize

```dart
await Subman.init(
  productIds: ['monthly_subscription', 'yearly_subscription'],
  onPurchaseCompleted: (subscription) {
    print('Purchased: ${subscription.productId}');
  },
  onRestoreCompleted: (subscriptions) {
    print('Restored: ${subscriptions.length} subscriptions');
  },
  onError: (exception) {
    print('Error: ${exception.code} / ${exception.message}');
  },
  // Optional: inject your own server verification client
  // serverClient: MyServerClient(),
);
```

### 3. Purchase a subscription

```dart
await Subman.purchase('monthly_subscription');
```

### 4. Restore previous subscriptions

```dart
await Subman.restore();
```

### 5. Access subscription status

```dart
// Check current state
final isActive = Subman.isSubscribed;
final current = Subman.currentSubscription;

// Listen to real-time updates
Subman.activeSubscriptionsStream.listen((subscriptions) {
  // React to subscription changes
});
```

### 6. Clean up

```dart
Subman.dispose();
```

---

## Server-Side Verification

By default, server validation uses a stub that returns `false`.
To verify receipts/tokens on your own backend, implement `SubscriptionServerClient`:

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

## Architecture

### Overview

`subman` is built around `SubmanCore`, a singleton that manages all subscription logic, state, and communication with the in-app purchase plugins and your server. The public API (`Subman`) is a thin static wrapper around this core.

### Key Concepts

- **Initialization**: `Subman.init(...)` sets up the IAP system, queries available products, and listens for purchase updates.
- **Purchase Flow**: `Subman.purchase(productId)` checks for existing subscriptions, handles upgrades/downgrades, and starts the purchase via the `in_app_purchase` plugin.
- **Restoration**: `Subman.restore()` triggers the plugin's restore mechanism and updates the active subscription list.
- **Server Validation**: After a purchase or restore, the receipt/token is sent to your backend via `SubscriptionServerClient`. The result determines whether the subscription is considered active.
- **State Management**: Active subscriptions are tracked in memory and exposed via `isSubscribed`, `currentSubscription`, and `activeSubscriptionsStream`.
- **Error Handling**: All errors are wrapped in `SubscriptionException` and passed to your `onError` callback.

### Exported Types

| Type | Description |
|---|---|
| `Subman` | Main static API for initialization, purchase, restore, and status |
| `SubscriptionData` | Immutable data class representing a subscription (with JSON serialization) |
| `SubscriptionException` | Unified error class with code and message |
| `SubscriptionServerClient` | Interface for server-side receipt/token verification |
| `SubscriptionState` | Enum for UI state (idle, loading, processing, purchased, restored, error) |
| `SubscriptionStatus` | State container for use with Riverpod/Bloc |
| `SubmanEnvironment` | Environment enum (simulator, deviceDebug, testflight, internalTest, production) |

---

## Testing

`subman` is designed for testability. Platform detection uses `defaultTargetPlatform` instead of `dart:io`, so all logic can be tested without platform-specific workarounds.

### Unit Testing with Mocks

```dart
import 'package:subman/subman.dart';
import 'package:subman/src/subman_core.dart';

// Create a mock server client
class MockServerClient implements SubscriptionServerClient {
  @override
  Future<bool> verify(Map<String, dynamic> payload) async => true;
}

// Inject mocks into SubmanCore
final core = SubmanCore.test(
  serverClient: MockServerClient(),
  iap: mockInAppPurchase,           // Mockito mock of InAppPurchase
  platformOverride: TargetPlatform.iOS, // Override platform for testing
);
```

### Running Tests

```bash
# Run all tests
flutter test

# Run with coverage
flutter test --coverage

# Regenerate mocks (after changing mock annotations)
dart run build_runner build --delete-conflicting-outputs
```

The test suite includes 45 tests covering:
- Model serialization, equality, and copyWith
- Exception conversion from PlatformException and IAPError
- Core initialization (store unavailable, no products, success)
- Purchase flow (valid/invalid receipts, iOS/Android payloads)
- Restore flow and error handling
- Stream emission and dispose behavior
- Static facade API

---

## Integration with Riverpod / Bloc

`subman` exports `SubscriptionState` and `SubscriptionStatus` for easy integration with state management libraries.

**Riverpod example:**

```dart
final subscriptionProvider =
    StateNotifierProvider<SubscriptionNotifier, SubscriptionStatus>(
        (ref) => SubscriptionNotifier());

final status = ref.watch(subscriptionProvider);

if (status.state == SubscriptionState.purchased) {
  // Show premium content
}
```

---

## Example

See [`example/main.dart`](example/lib/main.dart) for a full Flutter integration sample.

---

## Migration from 0.1.0

- **SDK requirement**: Dart >= 3.5.0 / Flutter >= 3.24.0 (was Dart >= 3.0.0 / Flutter >= 3.0.0)
- **Platform detection**: `dart:io` is no longer used internally. If you were relying on `SubmanCore.test()`, it now accepts an optional `platformOverride` parameter.
- **New exports**: `SubscriptionServerClient` and `SubmanEnvironment` are now exported from `package:subman/subman.dart`. Remove any direct imports of `src/models/server_client.dart`.
- **SubscriptionData equality**: `==` and `hashCode` are now implemented, so collections and comparisons work correctly.

---

## Additional Information

- API Reference: [pub.dev/packages/subman](https://pub.dev/packages/subman)
- Issues / Feedback: [GitHub Issues](https://github.com/mikaneco/subman/issues)
- Contributions welcome!

---

(C) 2025 mikaneco
MIT License.
