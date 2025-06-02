import 'package:subman/subman.dart';

/// Represents the state of the subscription workflow.
enum SubscriptionState {
  /// No active operation.
  idle,

  /// Fetching products from the store.
  loading,

  /// Purchase or restore process is ongoing.
  processing,

  /// Purchase completed successfully.
  purchased,

  /// Purchases restored successfully.
  restored,

  /// An error occurred during the subscription process.
  error,
}

/// Optionally, a class to hold detailed state (if you want to use it with Riverpod etc.)
class SubscriptionStatus {
  /// The current state.
  final SubscriptionState state;

  /// Optional error details (e.g. for error UI).
  final String? errorMessage;

  /// Optionally, current active subscription (for UI).
  final SubscriptionData? currentSubscription;

  const SubscriptionStatus({
    required this.state,
    this.errorMessage,
    this.currentSubscription,
  });
}
