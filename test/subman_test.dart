import 'dart:async';

import 'package:flutter/services.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:mockito/mockito.dart';
import 'package:subman/src/subman_core.dart';
import 'package:subman/subman.dart';
import 'mocks/mock_in_app_purchase.mocks.dart';
import 'mocks/mock_server_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  // ──────────────────────────────────────────────────────────────────────────
  // Helpers
  // ──────────────────────────────────────────────────────────────────────────

  MockPurchaseDetails createMockPurchaseDetails({
    String productId = 'test_product',
    String serverVerificationData = 'valid-token',
    PurchaseStatus status = PurchaseStatus.purchased,
    String? purchaseId = 'order123',
    String? transactionDate,
  }) {
    final mock = MockPurchaseDetails();
    when(mock.productID).thenReturn(productId);
    when(mock.verificationData).thenReturn(
      PurchaseVerificationData(
        localVerificationData: 'local',
        serverVerificationData: serverVerificationData,
        source: 'test',
      ),
    );
    when(mock.status).thenReturn(status);
    when(mock.purchaseID).thenReturn(purchaseId);
    when(mock.transactionDate).thenReturn(
      transactionDate ?? DateTime.now().millisecondsSinceEpoch.toString(),
    );
    when(mock.pendingCompletePurchase).thenReturn(true);
    return mock;
  }

  MockInAppPurchase createMockIap({
    bool isAvailable = true,
    List<MockProductDetails>? products,
    Stream<List<PurchaseDetails>>? purchaseStream,
  }) {
    final mockIap = MockInAppPurchase();
    when(mockIap.isAvailable()).thenAnswer((_) async => isAvailable);

    final productList = products ?? [];
    when(mockIap.queryProductDetails(any)).thenAnswer(
      (_) async => ProductDetailsResponse(
        productDetails: productList,
        notFoundIDs: [],
        error: null,
      ),
    );

    when(mockIap.purchaseStream).thenAnswer(
      (_) => purchaseStream ?? const Stream.empty(),
    );

    when(mockIap.completePurchase(any)).thenAnswer((_) async {});

    return mockIap;
  }

  MockProductDetails createMockProductDetails({String id = 'test_product'}) {
    final mock = MockProductDetails();
    when(mock.id).thenReturn(id);
    return mock;
  }

  // ──────────────────────────────────────────────────────────────────────────
  // SubscriptionData tests
  // ──────────────────────────────────────────────────────────────────────────

  group('SubscriptionData', () {
    final date = DateTime.utc(2025, 6, 15, 12, 0, 0);
    final data = SubscriptionData(
      productId: 'monthly',
      purchaseToken: 'token123',
      orderId: 'order456',
      purchaseDate: date,
      platform: 'ios',
    );

    test('toJson produces correct map', () {
      final json = data.toJson();
      expect(json['productId'], 'monthly');
      expect(json['purchaseToken'], 'token123');
      expect(json['orderId'], 'order456');
      expect(json['purchaseDate'], date.toIso8601String());
      expect(json['platform'], 'ios');
    });

    test('fromJson round-trips correctly', () {
      final json = data.toJson();
      final restored = SubscriptionData.fromJson(json);
      expect(restored, equals(data));
    });

    test('copyWith replaces only specified fields', () {
      final copy = data.copyWith(productId: 'yearly', platform: 'android');
      expect(copy.productId, 'yearly');
      expect(copy.platform, 'android');
      expect(copy.purchaseToken, data.purchaseToken);
      expect(copy.orderId, data.orderId);
      expect(copy.purchaseDate, data.purchaseDate);
    });

    test('equality and hashCode', () {
      final same = SubscriptionData(
        productId: 'monthly',
        purchaseToken: 'token123',
        orderId: 'order456',
        purchaseDate: date,
        platform: 'ios',
      );
      final different = data.copyWith(productId: 'yearly');

      expect(data, equals(same));
      expect(data.hashCode, same.hashCode);
      expect(data, isNot(equals(different)));
    });

    test('toString contains productId', () {
      expect(data.toString(), contains('monthly'));
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // SubscriptionException tests
  // ──────────────────────────────────────────────────────────────────────────

  group('SubscriptionException', () {
    test('toString contains code and message', () {
      final exception = SubscriptionException('test_code', 'Test message');
      expect(exception.toString(), contains('test_code'));
      expect(exception.toString(), contains('Test message'));
    });

    test('fromPlatformException handles known codes', () {
      final exception = SubscriptionException.fromPlatformException(
        PlatformException(code: 'user_canceled'),
      );
      expect(exception.code, 'user_canceled');
      expect(exception.message, contains('cancelled'));
    });

    test('fromPlatformException handles unknown types', () {
      final exception =
          SubscriptionException.fromPlatformException('not a platform error');
      expect(exception.code, 'unknown');
    });

    test('fromIAPError wraps IAPError', () {
      final error = IAPError(
        source: 'test',
        code: 'iap_error',
        message: 'IAP failed',
      );
      final exception = SubscriptionException.fromIAPError(error);
      expect(exception.code, 'iap_error');
      expect(exception.message, 'IAP failed');
    });

    test('fromIAPError handles unknown types', () {
      final exception = SubscriptionException.fromIAPError('not an IAP error');
      expect(exception.code, 'unknown');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // SubscriptionState / SubscriptionStatus tests
  // ──────────────────────────────────────────────────────────────────────────

  group('SubscriptionState & SubscriptionStatus', () {
    test('SubscriptionState has all expected values', () {
      expect(SubscriptionState.values, containsAll([
        SubscriptionState.idle,
        SubscriptionState.loading,
        SubscriptionState.processing,
        SubscriptionState.purchased,
        SubscriptionState.restored,
        SubscriptionState.error,
      ]));
    });

    test('SubscriptionStatus holds state and optional fields', () {
      const status = SubscriptionStatus(
        state: SubscriptionState.error,
        errorMessage: 'Something went wrong',
      );
      expect(status.state, SubscriptionState.error);
      expect(status.errorMessage, 'Something went wrong');
      expect(status.currentSubscription, isNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // SubmanEnvironment tests
  // ──────────────────────────────────────────────────────────────────────────

  group('SubmanEnvironment', () {
    test('isProduction returns true only for production', () {
      expect(SubmanEnvironment.production.isProduction, isTrue);
      expect(SubmanEnvironment.simulator.isProduction, isFalse);
    });

    test('isTest returns true for non-production', () {
      expect(SubmanEnvironment.simulator.isTest, isTrue);
      expect(SubmanEnvironment.production.isTest, isFalse);
    });

    test('isDebug returns true for simulator and deviceDebug', () {
      expect(SubmanEnvironment.simulator.isDebug, isTrue);
      expect(SubmanEnvironment.deviceDebug.isDebug, isTrue);
      expect(SubmanEnvironment.testflight.isDebug, isFalse);
    });

    test('isBeta returns true for testflight and internalTest', () {
      expect(SubmanEnvironment.testflight.isBeta, isTrue);
      expect(SubmanEnvironment.internalTest.isBeta, isTrue);
      expect(SubmanEnvironment.production.isBeta, isFalse);
    });

    test('isSimulator and isDeviceDebug', () {
      expect(SubmanEnvironment.simulator.isSimulator, isTrue);
      expect(SubmanEnvironment.deviceDebug.isDeviceDebug, isTrue);
      expect(SubmanEnvironment.simulator.isDeviceDebug, isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // DefaultServerClient tests
  // ──────────────────────────────────────────────────────────────────────────

  group('DefaultServerClient', () {
    test('verify always returns false', () async {
      final client = DefaultServerClient();
      expect(await client.verify({'receipt': 'anything'}), isFalse);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // SubmanCore initialization tests
  // ──────────────────────────────────────────────────────────────────────────

  group('SubmanCore initialization', () {
    test('calls onError when store is unavailable', () async {
      final mockIap = createMockIap(isAvailable: false);
      final core = SubmanCore.test(
        serverClient: MockServerClient(),
        iap: mockIap,
        platformOverride: TargetPlatform.android,
      );

      SubscriptionException? receivedError;
      await core.initialize(
        productIds: ['test'],
        onError: (e) => receivedError = e,
      );

      expect(receivedError, isNotNull);
      expect(receivedError!.code, 'store_unavailable');
    });

    test('calls onError when no products are found', () async {
      final mockIap = createMockIap();
      final core = SubmanCore.test(
        serverClient: MockServerClient(),
        iap: mockIap,
        platformOverride: TargetPlatform.android,
      );

      SubscriptionException? receivedError;
      await core.initialize(
        productIds: ['nonexistent'],
        onError: (e) => receivedError = e,
      );

      expect(receivedError, isNotNull);
      expect(receivedError!.code, 'no_products');
    });

    test('populates availableProducts on success', () async {
      final product = createMockProductDetails(id: 'premium');
      final mockIap = createMockIap(products: [product]);
      final core = SubmanCore.test(
        serverClient: MockServerClient(),
        iap: mockIap,
        platformOverride: TargetPlatform.android,
      );

      await core.initialize(productIds: ['premium']);

      expect(core.availableProducts.length, 1);
      expect(core.availableProducts.first.id, 'premium');
    });

    test('isSubscribed is false initially', () {
      final core = SubmanCore.test(
        serverClient: MockServerClient(),
        iap: createMockIap(),
        platformOverride: TargetPlatform.android,
      );
      expect(core.isSubscribed, isFalse);
      expect(core.currentSubscription, isNull);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // SubmanCore purchase flow tests (via purchaseStream)
  // ──────────────────────────────────────────────────────────────────────────

  group('SubmanCore purchase flow via stream', () {
    test('valid Android purchase triggers onPurchaseCompleted and stream',
        () async {
      final serverClient = MockAlwaysValidServerClient();
      final purchaseDetails = createMockPurchaseDetails(
        serverVerificationData: 'valid-token',
      );
      final purchaseStream = Stream<List<PurchaseDetails>>.value([
        purchaseDetails,
      ]);
      final product = createMockProductDetails();
      final mockIap =
          createMockIap(products: [product], purchaseStream: purchaseStream);

      final core = SubmanCore.test(
        serverClient: serverClient,
        iap: mockIap,
        platformOverride: TargetPlatform.android,
      );

      SubscriptionData? receivedData;
      final streamQueue = <List<SubscriptionData>>[];
      final sub = core.activeSubscriptionsStream.listen(streamQueue.add);

      await core.initialize(
        productIds: ['test_product'],
        onPurchaseCompleted: (data) => receivedData = data,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(receivedData, isNotNull);
      expect(receivedData!.productId, 'test_product');
      expect(receivedData!.platform, 'android');
      expect(core.isSubscribed, isTrue);
      expect(core.currentSubscription, isNotNull);
      expect(streamQueue.isNotEmpty, isTrue);
      expect(streamQueue.last.first.productId, 'test_product');

      // Verify completePurchase was called
      verify(mockIap.completePurchase(purchaseDetails)).called(1);

      await sub.cancel();
    });

    test('valid iOS purchase sets platform to ios', () async {
      final serverClient = MockAlwaysValidServerClient();
      final purchaseDetails = createMockPurchaseDetails(
        serverVerificationData: 'valid',
      );
      final purchaseStream = Stream<List<PurchaseDetails>>.value([
        purchaseDetails,
      ]);
      final product = createMockProductDetails();
      final mockIap =
          createMockIap(products: [product], purchaseStream: purchaseStream);

      final core = SubmanCore.test(
        serverClient: serverClient,
        iap: mockIap,
        platformOverride: TargetPlatform.iOS,
      );

      SubscriptionData? receivedData;
      await core.initialize(
        productIds: ['test_product'],
        onPurchaseCompleted: (data) => receivedData = data,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(receivedData, isNotNull);
      expect(receivedData!.platform, 'ios');

      // Verify the iOS payload format was used
      expect(serverClient.lastPayload, isNotNull);
      expect(serverClient.lastPayload!['platform'], 'ios');
      expect(serverClient.lastPayload!.containsKey('receipt'), isTrue);
    });

    test('Android purchase sends correct payload format', () async {
      final serverClient = MockAlwaysValidServerClient();
      final purchaseDetails = createMockPurchaseDetails(
        serverVerificationData: 'valid-token',
      );
      final purchaseStream = Stream<List<PurchaseDetails>>.value([
        purchaseDetails,
      ]);
      final product = createMockProductDetails();
      final mockIap =
          createMockIap(products: [product], purchaseStream: purchaseStream);

      final core = SubmanCore.test(
        serverClient: serverClient,
        iap: mockIap,
        platformOverride: TargetPlatform.android,
      );

      await core.initialize(productIds: ['test_product']);
      await Future.delayed(const Duration(milliseconds: 100));

      expect(serverClient.lastPayload, isNotNull);
      expect(serverClient.lastPayload!['platform'], 'android');
      expect(serverClient.lastPayload!['purchaseToken'], 'valid-token');
      expect(serverClient.lastPayload!['productId'], 'test_product');
      expect(serverClient.lastPayload!.containsKey('orderId'), isTrue);
    });

    test('invalid purchase triggers onError and does not update stream',
        () async {
      final serverClient = MockAlwaysInvalidServerClient();
      final purchaseDetails = createMockPurchaseDetails(
        serverVerificationData: 'invalid-token',
      );
      final purchaseStream = Stream<List<PurchaseDetails>>.value([
        purchaseDetails,
      ]);
      final product = createMockProductDetails();
      final mockIap =
          createMockIap(products: [product], purchaseStream: purchaseStream);

      final core = SubmanCore.test(
        serverClient: serverClient,
        iap: mockIap,
        platformOverride: TargetPlatform.android,
      );

      SubscriptionException? receivedError;
      final streamQueue = <List<SubscriptionData>>[];
      final sub = core.activeSubscriptionsStream.listen(streamQueue.add);

      await core.initialize(
        productIds: ['test_product'],
        onError: (e) => receivedError = e,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(receivedError, isNotNull);
      expect(receivedError!.code, 'receipt_verification_failed');
      expect(streamQueue.isEmpty, isTrue);
      expect(core.isSubscribed, isFalse);

      // completePurchase should still be called even for invalid receipts
      verify(mockIap.completePurchase(purchaseDetails)).called(1);

      await sub.cancel();
    });

    test('restored purchase triggers onRestoreCompleted', () async {
      final serverClient = MockAlwaysValidServerClient();
      final purchaseDetails = createMockPurchaseDetails(
        status: PurchaseStatus.restored,
      );
      final purchaseStream = Stream<List<PurchaseDetails>>.value([
        purchaseDetails,
      ]);
      final product = createMockProductDetails();
      final mockIap =
          createMockIap(products: [product], purchaseStream: purchaseStream);

      final core = SubmanCore.test(
        serverClient: serverClient,
        iap: mockIap,
        platformOverride: TargetPlatform.android,
      );

      List<SubscriptionData>? restoredData;
      await core.initialize(
        productIds: ['test_product'],
        onRestoreCompleted: (data) => restoredData = data,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(restoredData, isNotNull);
      expect(restoredData!.length, 1);
      expect(restoredData!.first.productId, 'test_product');
    });

    test('error purchase status triggers onError', () async {
      final purchaseDetails = MockPurchaseDetails();
      when(purchaseDetails.status).thenReturn(PurchaseStatus.error);
      when(purchaseDetails.error).thenReturn(
        IAPError(source: 'test', code: 'purchase_failed', message: 'Failed'),
      );
      when(purchaseDetails.pendingCompletePurchase).thenReturn(true);

      final purchaseStream = Stream<List<PurchaseDetails>>.value([
        purchaseDetails,
      ]);
      final product = createMockProductDetails();
      final mockIap =
          createMockIap(products: [product], purchaseStream: purchaseStream);

      final core = SubmanCore.test(
        serverClient: MockServerClient(),
        iap: mockIap,
        platformOverride: TargetPlatform.android,
      );

      SubscriptionException? receivedError;
      await core.initialize(
        productIds: ['test_product'],
        onError: (e) => receivedError = e,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(receivedError, isNotNull);
      expect(receivedError!.code, 'purchase_failed');
    });

    test('handles null transactionDate gracefully', () async {
      final serverClient = MockAlwaysValidServerClient();
      final purchaseDetails = createMockPurchaseDetails();
      when(purchaseDetails.transactionDate).thenReturn(null);

      final purchaseStream = Stream<List<PurchaseDetails>>.value([
        purchaseDetails,
      ]);
      final product = createMockProductDetails();
      final mockIap =
          createMockIap(products: [product], purchaseStream: purchaseStream);

      final core = SubmanCore.test(
        serverClient: serverClient,
        iap: mockIap,
        platformOverride: TargetPlatform.android,
      );

      SubscriptionData? receivedData;
      await core.initialize(
        productIds: ['test_product'],
        onPurchaseCompleted: (data) => receivedData = data,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(receivedData, isNotNull);
      // purchaseDate should default to DateTime.now()
      expect(
        receivedData!.purchaseDate
            .isAfter(DateTime.now().subtract(const Duration(seconds: 5))),
        isTrue,
      );
    });

    test('handles non-numeric transactionDate gracefully', () async {
      final serverClient = MockAlwaysValidServerClient();
      final purchaseDetails = createMockPurchaseDetails();
      when(purchaseDetails.transactionDate).thenReturn('not-a-number');

      final purchaseStream = Stream<List<PurchaseDetails>>.value([
        purchaseDetails,
      ]);
      final product = createMockProductDetails();
      final mockIap =
          createMockIap(products: [product], purchaseStream: purchaseStream);

      final core = SubmanCore.test(
        serverClient: serverClient,
        iap: mockIap,
        platformOverride: TargetPlatform.android,
      );

      SubscriptionData? receivedData;
      await core.initialize(
        productIds: ['test_product'],
        onPurchaseCompleted: (data) => receivedData = data,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(receivedData, isNotNull);
    });

    test('multiple purchases on stream are handled sequentially', () async {
      final serverClient = MockAlwaysValidServerClient();

      final purchase1 = createMockPurchaseDetails(
        productId: 'product_a',
        purchaseId: 'order_a',
      );
      final purchase2 = createMockPurchaseDetails(
        productId: 'product_b',
        purchaseId: 'order_b',
      );

      final purchaseStream = Stream<List<PurchaseDetails>>.value([
        purchase1,
        purchase2,
      ]);
      final productA = createMockProductDetails(id: 'product_a');
      final productB = createMockProductDetails(id: 'product_b');
      final mockIap = createMockIap(
        products: [productA, productB],
        purchaseStream: purchaseStream,
      );

      final core = SubmanCore.test(
        serverClient: serverClient,
        iap: mockIap,
        platformOverride: TargetPlatform.android,
      );

      int completedCount = 0;
      await core.initialize(
        productIds: ['product_a', 'product_b'],
        onPurchaseCompleted: (_) => completedCount++,
      );

      await Future.delayed(const Duration(milliseconds: 100));

      expect(completedCount, 2);
      // Last purchase wins (clears and replaces)
      expect(core.currentSubscription!.productId, 'product_b');
      expect(serverClient.callCount, 2);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // SubmanCore purchase method tests
  // ──────────────────────────────────────────────────────────────────────────

  group('SubmanCore.purchase()', () {
    test('calls buyNonConsumable for valid product', () async {
      final product = createMockProductDetails(id: 'premium');
      final mockIap = createMockIap(products: [product]);
      when(mockIap.buyNonConsumable(purchaseParam: anyNamed('purchaseParam')))
          .thenAnswer((_) async => true);

      final core = SubmanCore.test(
        serverClient: MockServerClient(),
        iap: mockIap,
        platformOverride: TargetPlatform.android,
      );

      await core.initialize(productIds: ['premium']);
      await core.purchase('premium');

      verify(
        mockIap.buyNonConsumable(purchaseParam: anyNamed('purchaseParam')),
      ).called(1);
    });

    test('calls onError when product not found', () async {
      final mockIap = createMockIap(products: []);
      final core = SubmanCore.test(
        serverClient: MockServerClient(),
        iap: mockIap,
        platformOverride: TargetPlatform.android,
      );

      SubscriptionException? receivedError;
      await core.initialize(
        productIds: [],
        onError: (e) => receivedError = e,
      );

      // Reset to capture purchase-specific error
      receivedError = null;
      await core.purchase('nonexistent');

      expect(receivedError, isNotNull);
      expect(receivedError!.code, 'unknown');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // SubmanCore restore tests
  // ──────────────────────────────────────────────────────────────────────────

  group('SubmanCore.restore()', () {
    test('calls restorePurchases', () async {
      final mockIap = createMockIap();
      when(mockIap.restorePurchases()).thenAnswer((_) async {});

      final core = SubmanCore.test(
        serverClient: MockServerClient(),
        iap: mockIap,
        platformOverride: TargetPlatform.android,
      );

      await core.initialize(productIds: []);
      await core.restore();

      verify(mockIap.restorePurchases()).called(1);
    });

    test('calls onError when restorePurchases throws', () async {
      final mockIap = createMockIap();
      when(mockIap.restorePurchases()).thenThrow(
        PlatformException(code: 'restore_failed'),
      );

      final core = SubmanCore.test(
        serverClient: MockServerClient(),
        iap: mockIap,
        platformOverride: TargetPlatform.android,
      );

      SubscriptionException? receivedError;
      await core.initialize(
        productIds: [],
        onError: (e) => receivedError = e,
      );

      await core.restore();

      expect(receivedError, isNotNull);
      expect(receivedError!.code, 'restore_failed');
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // SubmanCore dispose tests
  // ──────────────────────────────────────────────────────────────────────────

  group('SubmanCore.dispose()', () {
    test('closes stream controller and marks it done', () async {
      final core = SubmanCore.test(
        serverClient: MockServerClient(),
        iap: createMockIap(),
        platformOverride: TargetPlatform.android,
      );

      await core.initialize(productIds: []);

      bool streamDone = false;
      core.activeSubscriptionsStream.listen(
        (_) {},
        onDone: () => streamDone = true,
      );

      core.dispose();

      // Allow microtask to complete
      await Future.delayed(const Duration(milliseconds: 50));
      expect(streamDone, isTrue);
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Mock server client tests
  // ──────────────────────────────────────────────────────────────────────────

  group('MockServerClient verification logic', () {
    test('validates iOS receipt with "valid"', () async {
      final client = MockServerClient();
      expect(
        await client.verify({'receipt': 'valid', 'platform': 'ios'}),
        isTrue,
      );
    });

    test('rejects iOS receipt with "invalid"', () async {
      final client = MockServerClient();
      expect(
        await client.verify({'receipt': 'invalid', 'platform': 'ios'}),
        isFalse,
      );
    });

    test('validates Android token with "valid-token"', () async {
      final client = MockServerClient();
      expect(
        await client.verify({
          'purchaseToken': 'valid-token',
          'platform': 'android',
        }),
        isTrue,
      );
    });

    test('rejects Android token with "invalid-token"', () async {
      final client = MockServerClient();
      expect(
        await client.verify({
          'purchaseToken': 'invalid-token',
          'platform': 'android',
        }),
        isFalse,
      );
    });

    test('MockServerClientException throws', () async {
      final client = MockServerClientException();
      expect(
        () => client.verify({'receipt': 'any', 'platform': 'ios'}),
        throwsException,
      );
    });
  });

  // ──────────────────────────────────────────────────────────────────────────
  // Subman static facade tests
  // ──────────────────────────────────────────────────────────────────────────

  group('Subman static API', () {
    test('init sets up core with server client', () async {
      final serverClient = MockAlwaysValidServerClient();
      final mockIap = createMockIap();

      // Manually set the core instance for testing
      SubmanCore.instance = SubmanCore.test(
        serverClient: serverClient,
        iap: mockIap,
        platformOverride: TargetPlatform.android,
      );

      await SubmanCore.instance.initialize(productIds: ['test']);

      expect(Subman.isSubscribed, isFalse);
      expect(Subman.currentSubscription, isNull);
      expect(Subman.availableProducts, isEmpty);
    });

    test('setOnPurchaseCompleted updates handler', () {
      final serverClient = MockServerClient();
      SubmanCore.instance = SubmanCore.test(
        serverClient: serverClient,
        iap: createMockIap(),
        platformOverride: TargetPlatform.android,
      );

      bool called = false;
      Subman.setOnPurchaseCompleted((_) => called = true);

      SubmanCore.instance.onPurchaseCompleted?.call(
        SubscriptionData(
          productId: 'test',
          purchaseDate: DateTime.now(),
          platform: 'android',
        ),
      );

      expect(called, isTrue);
    });

    test('setOnError updates handler', () {
      final serverClient = MockServerClient();
      SubmanCore.instance = SubmanCore.test(
        serverClient: serverClient,
        iap: createMockIap(),
        platformOverride: TargetPlatform.android,
      );

      bool called = false;
      Subman.setOnError((_) => called = true);

      SubmanCore.instance.onError?.call(
        SubscriptionException('test', 'test'),
      );

      expect(called, isTrue);
    });

    test('setOnRestoreCompleted updates handler', () {
      final serverClient = MockServerClient();
      SubmanCore.instance = SubmanCore.test(
        serverClient: serverClient,
        iap: createMockIap(),
        platformOverride: TargetPlatform.android,
      );

      bool called = false;
      Subman.setOnRestoreCompleted((_) => called = true);

      SubmanCore.instance.onRestoreCompleted?.call([]);

      expect(called, isTrue);
    });
  });
}
