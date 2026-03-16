/// Subman package.
///
/// Handles initialization, purchase, restore, subscription state management,
/// error handling, and developer-friendly access to subscription data.
library;

import 'src/subman_core.dart';
import 'src/models/subscription_data.dart';
import 'src/models/subscription_exception.dart';
import 'src/models/server_client.dart';

export 'src/models/server_client.dart';
export 'src/models/subman_environment.dart';
export 'src/models/subscription_data.dart';
export 'src/models/subscription_exception.dart';
export 'src/models/subscription_state.dart';

class Subman {
  /// Initializes the subscription core with product IDs and callbacks.
  static Future<void> init({
    required List<String> productIds,
    void Function(SubscriptionData)? onPurchaseCompleted,
    void Function(List<SubscriptionData>)? onRestoreCompleted,
    void Function(SubscriptionException)? onError,
    SubscriptionServerClient? serverClient,
  }) async {
    if (serverClient != null) {
      SubmanCore.instance = SubmanCore.test(serverClient: serverClient);
    }
    await SubmanCore.instance.initialize(
      productIds: productIds,
      onPurchaseCompleted: onPurchaseCompleted,
      onRestoreCompleted: onRestoreCompleted,
      onError: onError,
    );
  }

  /// Starts a purchase for the specified productId.
  static Future<void> purchase(String productId) async {
    await SubmanCore.instance.purchase(productId);
  }

  /// Restores previous purchases.
  static Future<void> restore() async {
    await SubmanCore.instance.restore();
  }

  /// Sets the purchase completed handler.
  static void setOnPurchaseCompleted(void Function(SubscriptionData) handler) {
    SubmanCore.instance.onPurchaseCompleted = handler;
  }

  /// Sets the restore completed handler.
  static void setOnRestoreCompleted(
    void Function(List<SubscriptionData>) handler,
  ) {
    SubmanCore.instance.onRestoreCompleted = handler;
  }

  /// Sets the error handler.
  static void setOnError(void Function(SubscriptionException) handler) {
    SubmanCore.instance.onError = handler;
  }

  /// Returns current subscription status (if any).
  static SubscriptionData? get currentSubscription =>
      SubmanCore.instance.currentSubscription;

  /// Returns true if user has any valid subscription.
  static bool get isSubscribed => SubmanCore.instance.isSubscribed;

  /// Returns a stream of active subscriptions (for UI updates).
  static Stream<List<SubscriptionData>> get activeSubscriptionsStream =>
      SubmanCore.instance.activeSubscriptionsStream;

  /// Returns the list of available products after initialization.
  static List get availableProducts => SubmanCore.instance.availableProducts;

  /// Disposes internal resources and cancels purchase stream subscription.
  static void dispose() {
    SubmanCore.instance.dispose();
  }
}
