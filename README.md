# subman

[![pub package](https://img.shields.io/pub/v/subman.svg)](https://pub.dev/packages/subman)
[![License: MIT](https://img.shields.io/badge/license-MIT-blue.svg)](LICENSE)
[![Build](https://github.com/mikaneco/subman/actions/workflows/dart.yml/badge.svg)](https://github.com/mikaneco/subman/actions)  
[![GitHub stars](https://img.shields.io/github/stars/mikaneco/subman.svg?style=social&label=Star)](https://github.com/mikaneco/subman)

A simple, developer-friendly subscription management library for Flutter.  
Subman makes handling in-app subscriptions, restoration, and server-side validation effortless and robust for any Flutter project.

---

## ✨ Features

- 🪄 Simple initialization & purchase
- 🔄 One-line restore for past subscriptions
- 🟢 Real-time subscription status (via Stream)
- ❗ Unified, user-friendly error handling
- 🛠️ Plug-in server-side validation (with easy mocking for tests)
- ⚡ Environment-aware (simulator, TestFlight, production…)

---

## 🚀 Getting Started

Add to your `pubspec.yaml`:

```yaml
dependencies:
  subman: ^0.1.0
```

---

## 🛠️ Usage

### 1. Import

```dart
import 'package:subman/subman.dart';
```

---

### 2. Initialize Subman

```dart
await Subman.init(
  productIds: ['monthly_subscription', 'yearly_subscription'],
  onPurchaseCompleted: (subscription) {
    // Handle successful purchase
    print('Purchased: ${subscription.productId}');
  },
  onRestoreCompleted: (subscriptions) {
    // Handle restored subscriptions
    print('Restored: $subscriptions');
  },
  onError: (exception) {
    // Handle errors
    print('Error: ${exception.code} / ${exception.message}');
  },
  // Optional: inject your own server verification client
  // serverClient: MyServerClient(), // implements SubscriptionServerClient
);
```

---

### 3. Purchase a subscription

```dart
await Subman.purchase('monthly_subscription');
```

---

### 4. Restore previous subscriptions

```dart
await Subman.restore();
```

---

### 5. Access subscription status (for UI, business logic, etc.)

```dart
final isActive = Subman.isSubscribed;
final current = Subman.currentSubscription;

Subman.activeSubscriptionsStream.listen((subscriptions) {
  // React to subscription updates!
});
```

---

### 6. Advanced: Server-side verification

By default, server validation does nothing.  
To verify receipts/tokens on your own backend, implement `SubscriptionServerClient` and inject it:

```dart
class MyServerClient implements SubscriptionServerClient {
  @override
  Future<bool> verify(Map<String, dynamic> payload) async {
    // Send payload to your server, get validation result.
    // return true if valid, false if not.
  }
}

// Usage:
await Subman.init(
  productIds: [...],
  onPurchaseCompleted: ...,
  serverClient: MyServerClient(),
);
```

---

## 🏗️ Architecture & Core Logic

### Overview

`subman` is built around a single core class, `SubmanCore`, which manages all subscription logic, state, and communication with both the in-app purchase plugins and your server. The public API (`Subman`) is a thin wrapper around this core.

### Key Concepts

- **Initialization**:  
  `SubmanCore.initialize` sets up the in-app purchase system, queries available products, and listens for purchase updates.  
  You must call `Subman.init(...)` before making purchases or restoring.

- **Purchase Flow**:  
  When you call `Subman.purchase(productId)`, the core checks for existing subscriptions, handles upgrades/downgrades, and starts the purchase flow using the in_app_purchase plugin.

- **Restoration**:  
  `Subman.restore()` triggers the plugin’s restore mechanism and updates the active subscription list.

- **Server Validation**:  
  After a purchase or restore, `subman` sends the receipt/token to your backend (via a `SubscriptionServerClient`) for validation.  
  The result determines whether the subscription is considered active.

- **State Management**:  
  All active subscriptions are tracked in memory and exposed via:

  - `Subman.isSubscribed`
  - `Subman.currentSubscription`
  - `Subman.activeSubscriptionsStream` (for real-time UI updates)

- **Callbacks**:  
  You can provide callbacks for:

  - `onPurchaseCompleted`
  - `onRestoreCompleted`
  - `onError`
    These are invoked at the appropriate time in the purchase/restore lifecycle.

- **Error Handling**:  
  All errors are wrapped in a `SubscriptionException` and passed to your `onError` callback.

### Extensibility & Testing

- **Server Validation**:  
  You can inject your own server client by implementing `SubscriptionServerClient` and passing it to `Subman.init(serverClient: ...)`.  
  This makes it easy to mock server responses in tests.

- **Dependency Injection**:  
  For testing, you can inject a mock `InAppPurchase` instance into `SubmanCore` using the `SubmanCore.test(...)` factory.

- **Platform Awareness**:  
  The core logic automatically detects the platform (iOS/Android) and builds the correct payload for server validation.

### Example: Custom Server Validation

```dart
class MyServerClient implements SubscriptionServerClient {
  @override
  Future<bool> verify(Map<String, dynamic> payload) async {
    // Send payload to your server, get validation result.
    // return true if valid, false if not.
  }
}

await Subman.init(
  productIds: ['monthly', 'yearly'],
  onPurchaseCompleted: ...,
  serverClient: MyServerClient(),
);
```

### Example: Listening to Subscription Changes

```dart
Subman.activeSubscriptionsStream.listen((subscriptions) {
  // Update your UI or business logic
});
```

### Example: Testing with Mocks

```dart
final mockIap = MockInAppPurchase();
final mockServer = MockServerClient();
final core = SubmanCore.test(serverClient: mockServer, iap: mockIap);

// Now you can stub/mock plugin and server responses for unit tests!
```

---

## 🧑‍💻 Example

See [`example/main.dart`](example/lib/main.dart) for a full Flutter integration sample.

---

## ⚡️ Integration with Riverpod, Bloc, etc.

`subman` exports simple state classes (`SubscriptionState`, `SubscriptionStatus`)  
so you can easily use them with Riverpod or Bloc for app-wide reactive subscription state management.

**Riverpod usage example:**

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

## 📚 Additional Information

- API Reference: [pub.dev/packages/subman]
- Issues / Feedback: [GitHub Issues](https://github.com/mikaneco/subman/issues)
- Contributions welcome!

---

© 2025 mikaneco  
MIT License.
