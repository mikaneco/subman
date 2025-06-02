import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';

/// Represents an exception that occurs during subscription operations.
///
/// Provides error codes and human-readable messages that can be shown to users
/// or used for analytics/debugging.
class SubscriptionException implements Exception {
  /// A short string code describing the type of error.
  final String code;

  /// A human-readable message describing the error.
  final String message;

  /// Creates a new [SubscriptionException] with the given code and message.
  SubscriptionException(this.code, this.message);

  @override
  String toString() => 'SubscriptionException(code: $code, message: $message)';

  /// Creates a [SubscriptionException] from a [PlatformException].
  ///
  /// This helps to map Flutter platform errors to unified subscription errors.
  static SubscriptionException fromPlatformException(Object? error) {
    if (error is! PlatformException) {
      return SubscriptionException('unknown', 'An unknown error occurred.');
    }

    switch (error.code) {
      case 'storekit_duplicate_product_object':
        return SubscriptionException(
          error.code,
          'A purchase for this product is already in progress.',
        );
      case 'user_canceled':
        return SubscriptionException(
          error.code,
          'The purchase was cancelled by the user.',
        );
      case 'billing_unavailable':
        return SubscriptionException(
          error.code,
          'Billing is unavailable on this device.',
        );
      default:
        return SubscriptionException(
          error.code,
          error.message ?? 'An unexpected error occurred.',
        );
    }
  }

  /// Creates a [SubscriptionException] from an [IAPError].
  ///
  /// Use this to map plugin errors to unified exceptions for the app.
  static SubscriptionException fromIAPError(Object? error) {
    if (error is! IAPError) {
      return SubscriptionException(
        'unknown',
        'An in-app purchase error occurred.',
      );
    }
    return SubscriptionException(error.code, error.message);
  }
}
