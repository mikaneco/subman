/// Represents the result of a subscription purchase or restoration.
///
/// This class contains relevant data such as the product ID, purchase token,
/// order ID, purchase date, and platform.
class SubscriptionData {
  /// The product ID of the subscription.
  final String productId;

  /// The purchase token (for Google Play).
  final String? purchaseToken;

  /// The order ID of the purchase.
  final String? orderId;

  /// The date and time the purchase was made.
  final DateTime purchaseDate;

  /// The platform on which the purchase occurred, e.g., 'ios' or 'android'.
  final String platform;

  /// Creates a [SubscriptionData] instance.
  const SubscriptionData({
    required this.productId,
    required this.purchaseDate,
    required this.platform,
    this.purchaseToken,
    this.orderId,
  });

  @override
  String toString() {
    return 'SubscriptionData(productId: $productId, purchaseDate: $purchaseDate, platform: $platform)';
  }

  /// Converts this object to JSON for storage or network transmission.
  Map<String, dynamic> toJson() {
    return {
      'productId': productId,
      'purchaseToken': purchaseToken,
      'orderId': orderId,
      'purchaseDate': purchaseDate.toIso8601String(),
      'platform': platform,
    };
  }

  /// Creates a [SubscriptionData] instance from JSON.
  factory SubscriptionData.fromJson(Map<String, dynamic> json) {
    return SubscriptionData(
      productId: json['productId'] as String,
      purchaseToken: json['purchaseToken'] as String?,
      orderId: json['orderId'] as String?,
      purchaseDate: DateTime.parse(json['purchaseDate'] as String),
      platform: json['platform'] as String,
    );
  }

  /// Returns a copy of this object with the given fields replaced.
  SubscriptionData copyWith({
    String? productId,
    String? purchaseToken,
    String? orderId,
    DateTime? purchaseDate,
    String? platform,
  }) {
    return SubscriptionData(
      productId: productId ?? this.productId,
      purchaseToken: purchaseToken ?? this.purchaseToken,
      orderId: orderId ?? this.orderId,
      purchaseDate: purchaseDate ?? this.purchaseDate,
      platform: platform ?? this.platform,
    );
  }
}
