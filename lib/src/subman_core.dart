/// Core logic for the Subman package.
///
/// Handles initialization, purchase, restore, subscription state management,
/// error handling, and developer-friendly access to subscription data.
library;

import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:subman/src/models/server_client.dart';
import 'models/subscription_data.dart';
import 'models/subscription_exception.dart';

/// Internal singleton that manages all subscription logic.
class SubmanCore {
  SubmanCore._internal({
    SubscriptionServerClient? serverClient,
    InAppPurchase? iap,
    TargetPlatform? platformOverride,
  })  : _serverClient = serverClient ?? DefaultServerClient(),
        _iap = iap ?? InAppPurchase.instance,
        _platformOverride = platformOverride;

  static SubmanCore instance = SubmanCore._internal();

  /// Factory constructor for testing purposes.
  factory SubmanCore.test({
    required SubscriptionServerClient serverClient,
    InAppPurchase? iap,
    TargetPlatform? platformOverride,
  }) {
    return SubmanCore._internal(
      serverClient: serverClient,
      iap: iap,
      platformOverride: platformOverride,
    );
  }

  final SubscriptionServerClient _serverClient;
  final InAppPurchase _iap;
  final TargetPlatform? _platformOverride;

  bool _isProcessing = false;
  List<ProductDetails> _products = [];

  /// Keeps track of active subscriptions restored or purchased.
  final List<SubscriptionData> _activeSubscriptions = [];

  final StreamController<List<SubscriptionData>>
      _activeSubscriptionsController =
      StreamController<List<SubscriptionData>>.broadcast();

  /// Stream of active subscriptions; emits whenever the subscription list changes.
  Stream<List<SubscriptionData>> get activeSubscriptionsStream =>
      _activeSubscriptionsController.stream;

  /// Returns the list of available products after initialization.
  List<ProductDetails> get availableProducts => _products;

  /// Returns true if there is any active subscription.
  bool get isSubscribed => _activeSubscriptions.isNotEmpty;

  /// Returns the current active subscription, or null if none.
  SubscriptionData? get currentSubscription =>
      _activeSubscriptions.isNotEmpty ? _activeSubscriptions.first : null;

  StreamSubscription<List<PurchaseDetails>>? _subscription;

  /// Callback invoked when a purchase is completed successfully.
  void Function(SubscriptionData)? onPurchaseCompleted;

  /// Callback invoked when purchase restoration completes successfully.
  void Function(List<SubscriptionData>)? onRestoreCompleted;

  /// Callback invoked when an error occurs during purchase or restoration.
  void Function(SubscriptionException)? onError;

  /// Returns the effective platform for this instance.
  TargetPlatform get _effectivePlatform =>
      _platformOverride ?? defaultTargetPlatform;

  /// Returns true if this is running on iOS.
  bool get _isIOS => _effectivePlatform == TargetPlatform.iOS;

  /// Initializes the in-app purchase system with the given product IDs.
  ///
  /// This method queries the store for available products and sets up
  /// listeners for purchase updates. Callbacks for purchase completion,
  /// restoration completion, and errors can be provided.
  Future<void> initialize({
    required List<String> productIds,
    void Function(SubscriptionData)? onPurchaseCompleted,
    void Function(List<SubscriptionData>)? onRestoreCompleted,
    void Function(SubscriptionException)? onError,
  }) async {
    this.onPurchaseCompleted = onPurchaseCompleted;
    this.onRestoreCompleted = (subs) {
      // Keep active subscriptions up to date
      _activeSubscriptions
        ..clear()
        ..addAll(subs);
      _activeSubscriptionsController.add(_activeSubscriptions.toList());
      if (onRestoreCompleted != null) {
        onRestoreCompleted(subs);
      }
    };
    this.onError = onError;

    final isAvailable = await _iap.isAvailable();
    if (!isAvailable) {
      onError?.call(
        SubscriptionException(
          'store_unavailable',
          'The store is unavailable. Please check your internet connection.',
        ),
      );
      return;
    }

    final response = await _iap.queryProductDetails(productIds.toSet());
    _products = response.productDetails.toList();

    if (_products.isEmpty) {
      onError?.call(
        SubscriptionException(
          'no_products',
          'No available products were found.',
        ),
      );
    }

    _subscription = _iap.purchaseStream.listen(
      _handlePurchaseUpdates,
      onError: _handleError,
    );
  }

  /// Initiates a purchase flow for the specified product ID.
  ///
  /// If a purchase is already in progress, this method returns immediately.
  /// If a different subscription is already active, notifies via onError.
  Future<void> purchase(String productId, {String? offerToken}) async {
    if (_isProcessing) return;
    _isProcessing = true;

    try {
      final product = _products.firstWhere((p) => p.id == productId);

      // Check for existing active subscription (simple logic)
      final alreadySubscribed = _activeSubscriptions.any(
        (sub) => sub.productId == productId,
      );

      // If changing plan, fire a notification
      if (!alreadySubscribed && _activeSubscriptions.isNotEmpty) {
        onError?.call(
          SubscriptionException(
            'change_subscription_detected',
            'User is changing from ${_activeSubscriptions.first.productId} to $productId',
          ),
        );
        if (_activeSubscriptions.length > 1) {
          onError?.call(
            SubscriptionException(
              'multiple_active_subscriptions',
              'Multiple active subscriptions detected. Please manage your subscriptions.',
            ),
          );
          _isProcessing = false;
          return;
        }
      }

      final purchaseParam = PurchaseParam(productDetails: product);
      await _iap.buyNonConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      _handleError(e);
    } finally {
      _isProcessing = false;
    }
  }

  /// Restores previous purchases.
  ///
  /// If a restore operation is already in progress, this method returns immediately.
  Future<void> restore() async {
    if (_isProcessing) return;
    _isProcessing = true;
    try {
      await _iap.restorePurchases();
    } catch (e) {
      _handleError(e);
    } finally {
      _isProcessing = false;
    }
  }

  /// Disposes internal resources and cancels purchase stream subscription.
  void dispose() {
    _subscription?.cancel();
    _activeSubscriptionsController.close();
  }

  Future<void> _handlePurchaseUpdates(List<PurchaseDetails> purchases) async {
    for (final purchase in purchases) {
      if (purchase.status == PurchaseStatus.purchased ||
          purchase.status == PurchaseStatus.restored) {
        // Parse purchase date robustly
        DateTime purchaseDate;
        if (purchase.transactionDate != null) {
          try {
            purchaseDate = DateTime.fromMillisecondsSinceEpoch(
              int.parse(purchase.transactionDate!),
            );
          } catch (_) {
            purchaseDate = DateTime.now();
          }
        } else {
          purchaseDate = DateTime.now();
        }

        final data = SubscriptionData(
          productId: purchase.productID,
          purchaseToken: purchase.verificationData.serverVerificationData,
          orderId: purchase.purchaseID ?? purchase.transactionDate ?? '',
          purchaseDate: purchaseDate,
          platform: _isIOS ? 'ios' : 'android',
        );

        Map<String, dynamic> payload;
        if (_isIOS) {
          payload = {'receipt': data.purchaseToken ?? '', 'platform': 'ios'};
        } else {
          payload = {
            'purchaseToken': data.purchaseToken,
            'orderId': data.orderId,
            'productId': data.productId,
            'platform': 'android',
          };
        }

        final isValid = await _serverClient.verify(payload);

        if (isValid) {
          _activeSubscriptions
            ..clear()
            ..add(data);
          _activeSubscriptionsController.add(_activeSubscriptions.toList());

          if (purchase.status == PurchaseStatus.restored) {
            onRestoreCompleted?.call([data]);
          } else if (purchase.status == PurchaseStatus.purchased) {
            onPurchaseCompleted?.call(data);
          }
        } else {
          onError?.call(
            SubscriptionException(
              'receipt_verification_failed',
              'Receipt validation failed on the server.',
            ),
          );
        }

        // Always complete the purchase to acknowledge it with the store
        await _iap.completePurchase(purchase);
      } else if (purchase.status == PurchaseStatus.pending) {
        // Pending purchases are waiting for user action; do nothing
      } else if (purchase.status == PurchaseStatus.error) {
        _handleError(purchase.error);
        // Complete the purchase to clear the error state from the store
        await _iap.completePurchase(purchase);
      }
    }
  }

  void _handleError(Object? error) {
    SubscriptionException exception;

    if (error is PlatformException) {
      exception = SubscriptionException.fromPlatformException(error);
    } else if (error is IAPError) {
      exception = SubscriptionException.fromIAPError(error);
    } else {
      exception = SubscriptionException(
        'unknown',
        'An unknown error occurred.',
      );
    }

    onError?.call(exception);
  }
}
