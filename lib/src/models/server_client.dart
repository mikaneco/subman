/// Represents an API client for verifying subscriptions with your server.
abstract class SubscriptionServerClient {
  /// Verifies subscription data with the server.
  /// The [payload] contains platform-dependent keys and values such as:
  /// - iOS: {'receipt': ..., 'platform': 'ios'}
  /// - Android: {'purchaseToken': ..., 'orderId': ..., 'packageName': ..., 'productId': ..., 'platform': 'android'}
  /// Returns true if the subscription is valid. Returns false if invalid or expired.
  Future<bool> verify(Map<String, dynamic> payload);
}

/// Dummy default implementation for users to override with their own backend.
/// For production, replace this with your real server implementation!
class DefaultServerClient implements SubscriptionServerClient {
  @override
  Future<bool> verify(Map<String, dynamic> payload) async {
    // For now, always returns false.
    return false;
  }
}
