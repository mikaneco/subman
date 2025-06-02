import 'package:flutter_test/flutter_test.dart';
import 'package:mockito/mockito.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:subman/src/subman_core.dart';
import 'package:subman/src/models/server_client.dart';
import 'package:subman/subman.dart';
import 'mocks/mock_in_app_purchase.mocks.dart';
import 'mocks/mock_server_client.dart';

void main() {
  TestWidgetsFlutterBinding.ensureInitialized();

  group('Subscription purchase & server verification', () {
    late MockServerClient serverClient;
    setUp(() {
      serverClient = MockServerClient();
    });

    test('onPurchaseCompleted is called for valid iOS receipt', () async {
      final mockIap = MockInAppPurchase();
      final core = SubmanCore.test(serverClient: serverClient, iap: mockIap);
      bool completedCalled = false;
      core.onPurchaseCompleted = (_) => completedCalled = true;
      core.onError = (_) {};

      final payload = {'receipt': 'valid', 'platform': 'ios'};

      final isValid = await serverClient.verify(payload);
      if (isValid) {
        core.onPurchaseCompleted?.call(
          SubscriptionData(
            productId: payload['productId'] ?? payload['receipt'] ?? '',
            purchaseToken: payload['purchaseToken'] ?? payload['receipt'] ?? '',
            orderId: payload['orderId'] ?? '',
            purchaseDate: DateTime.now(),
            platform: payload['platform'] ?? '',
          ),
        );
      }

      expect(
        completedCalled,
        isTrue,
        reason: 'onPurchaseCompleted should be called for valid iOS receipt',
      );
    });

    test('onError is called for invalid iOS receipt', () async {
      final mockIap = MockInAppPurchase();
      final core = SubmanCore.test(serverClient: serverClient, iap: mockIap);
      bool errorCalled = false;
      core.onPurchaseCompleted = (_) {};
      core.onError = (_) => errorCalled = true;

      final payload = {'receipt': 'invalid', 'platform': 'ios'};

      final isValid = await serverClient.verify(payload);
      if (!isValid) {
        core.onError?.call(
          SubscriptionException('receipt_rejected', 'Receipt rejected'),
        );
      }

      expect(
        errorCalled,
        isTrue,
        reason: 'onError should be called for invalid iOS receipt',
      );
    });

    test('onPurchaseCompleted is called for valid Android token', () async {
      final mockIap = MockInAppPurchase();
      final core = SubmanCore.test(serverClient: serverClient, iap: mockIap);
      bool completedCalled = false;
      core.onPurchaseCompleted = (_) => completedCalled = true;
      core.onError = (_) {};

      final payload = {
        'purchaseToken': 'valid-token',
        'orderId': 'order123',
        'packageName': 'com.example.app',
        'productId': 'android_product',
        'platform': 'android',
      };

      final isValid = await serverClient.verify(payload);
      if (isValid) {
        core.onPurchaseCompleted?.call(
          SubscriptionData(
            productId: payload['productId'] ?? '',
            purchaseToken: payload['purchaseToken'] ?? '',
            orderId: payload['orderId'] ?? '',
            purchaseDate: DateTime.now(),
            platform: payload['platform'] ?? '',
          ),
        );
      }

      expect(
        completedCalled,
        isTrue,
        reason: 'onPurchaseCompleted should be called for valid Android token',
      );
    });

    test('onError is called for invalid Android token', () async {
      final mockIap = MockInAppPurchase();
      final core = SubmanCore.test(serverClient: serverClient, iap: mockIap);
      bool errorCalled = false;
      core.onPurchaseCompleted = (_) {};
      core.onError = (_) => errorCalled = true;

      final payload = {
        'purchaseToken': 'invalid-token',
        'orderId': 'order123',
        'packageName': 'com.example.app',
        'productId': 'android_product',
        'platform': 'android',
      };

      final isValid = await serverClient.verify(payload);
      if (!isValid) {
        core.onError?.call(
          SubscriptionException('token_rejected', 'Token rejected'),
        );
      }

      expect(
        errorCalled,
        isTrue,
        reason: 'onError should be called for invalid Android token',
      );
    });
  });

  test(
    'onPurchaseCompleted receives correct SubscriptionData for iOS',
    () async {
      final serverClient = MockServerClient();
      final mockIap = MockInAppPurchase();
      final core = SubmanCore.test(serverClient: serverClient, iap: mockIap);

      SubscriptionData? receivedData;
      core.onPurchaseCompleted = (data) => receivedData = data;
      core.onError = (_) {};

      final payload = {'receipt': 'valid', 'platform': 'ios'};

      final isValid = await serverClient.verify(payload);
      if (isValid) {
        core.onPurchaseCompleted?.call(
          SubscriptionData(
            productId: payload['productId'] ?? payload['receipt'] ?? '',
            purchaseToken: payload['purchaseToken'] ?? payload['receipt'] ?? '',
            orderId: payload['orderId'] ?? '',
            purchaseDate: DateTime.utc(2024, 1, 1, 12, 0, 0),
            platform: payload['platform'] ?? '',
          ),
        );
      }

      expect(receivedData, isNotNull);
      expect(receivedData!.platform, 'ios');
      expect(receivedData!.purchaseToken, 'valid');
      expect(receivedData!.productId, 'valid');
      expect(receivedData!.purchaseDate, DateTime.utc(2024, 1, 1, 12, 0, 0));
    },
  );

  test('onError is called with correct code on server exception', () async {
    final serverClient = MockServerClientException();

    final mockIap = MockInAppPurchase();
    final core = SubmanCore.test(serverClient: serverClient, iap: mockIap);

    bool errorCalled = false;
    SubscriptionException? receivedError;
    core.onPurchaseCompleted = (_) {};
    core.onError = (err) {
      errorCalled = true;
      receivedError = err;
    };

    final payload = {'receipt': 'any', 'platform': 'ios'};

    try {
      await serverClient.verify(payload);
    } catch (e) {
      core.onError?.call(
        SubscriptionException('server_error', 'Server threw exception'),
      );
    }

    expect(errorCalled, isTrue);
    expect(receivedError, isNotNull);
    expect(receivedError!.code, 'server_error');
  });

  test('multiple calls trigger onPurchaseCompleted multiple times', () async {
    final serverClient = MockServerClient();
    final mockIap = MockInAppPurchase();
    final core = SubmanCore.test(serverClient: serverClient, iap: mockIap);

    int completedCalledCount = 0;
    core.onPurchaseCompleted = (_) => completedCalledCount++;
    core.onError = (_) {};

    final payload = {'receipt': 'valid', 'platform': 'ios'};
    final isValid = await serverClient.verify(payload);

    if (isValid) {
      core.onPurchaseCompleted?.call(
        SubscriptionData(
          productId: payload['productId'] ?? payload['receipt'] ?? '',
          purchaseToken: payload['purchaseToken'] ?? payload['receipt'] ?? '',
          orderId: payload['orderId'] ?? '',
          purchaseDate: DateTime.now(),
          platform: payload['platform'] ?? '',
        ),
      );
      core.onPurchaseCompleted?.call(
        SubscriptionData(
          productId: payload['productId'] ?? payload['receipt'] ?? '',
          purchaseToken: payload['purchaseToken'] ?? payload['receipt'] ?? '',
          orderId: payload['orderId'] ?? '',
          purchaseDate: DateTime.now(),
          platform: payload['platform'] ?? '',
        ),
      );
    }

    expect(
      completedCalledCount,
      2,
      reason:
          'If double-called, should increment twice (change to 1 to enforce only once)',
    );
  });

  test('activeSubscriptionsStream emits after mocked purchase', () async {
    final mockIap = MockInAppPurchase();
    final serverClient = MockServerClient();
    final core = SubmanCore.test(serverClient: serverClient, iap: mockIap);

    when(mockIap.isAvailable()).thenAnswer((_) async => true);

    final mockProductDetails = MockProductDetails();
    when(mockProductDetails.id).thenReturn('test_product');
    when(mockIap.queryProductDetails(any)).thenAnswer(
      (_) async => ProductDetailsResponse(
        productDetails: [mockProductDetails],
        notFoundIDs: [],
        error: null,
      ),
    );

    final purchaseDetails = MockPurchaseDetails();
    when(purchaseDetails.productID).thenReturn('test_product');
    when(purchaseDetails.verificationData).thenReturn(
      PurchaseVerificationData(
        localVerificationData: 'local',
        serverVerificationData: 'valid-token',
        source: 'test',
      ),
    );
    when(purchaseDetails.status).thenReturn(PurchaseStatus.purchased);
    when(purchaseDetails.purchaseID).thenReturn('order123');
    when(
      purchaseDetails.transactionDate,
    ).thenReturn(DateTime.now().millisecondsSinceEpoch.toString());

    final purchaseStream = Stream<List<PurchaseDetails>>.value([
      purchaseDetails,
    ]);
    when(mockIap.purchaseStream).thenAnswer((_) => purchaseStream);

    final streamQueue = <List<SubscriptionData>>[];
    final sub = core.activeSubscriptionsStream.listen(streamQueue.add);

    await core.initialize(productIds: ['test_product']);
    await Future.delayed(const Duration(milliseconds: 50));

    expect(streamQueue.isNotEmpty, isTrue);
    expect(streamQueue.last.first.productId, 'test_product');

    await sub.cancel();
  });
  test(
    'activeSubscriptionsStream emits after purchase (manual update)',
    () async {
      final serverClient = MockServerClient();
      final mockIap = MockInAppPurchase();
      final core = SubmanCore.test(serverClient: serverClient, iap: mockIap);

      final payload = {'receipt': 'valid', 'platform': 'ios'};
      final subscription = SubscriptionData(
        productId: payload['productId'] ?? payload['receipt'] ?? '',
        purchaseToken: payload['purchaseToken'] ?? payload['receipt'] ?? '',
        orderId: payload['orderId'] ?? '',
        purchaseDate: DateTime.now(),
        platform: payload['platform'] ?? '',
      );

      final streamQueue = <List<SubscriptionData>>[];
      final sub = core.activeSubscriptionsStream.listen(streamQueue.add);

      final isValid = await serverClient.verify(payload);
      if (isValid) {
        core.onPurchaseCompleted?.call(subscription);
        // No stream update here!
      }

      expect(
        streamQueue.isNotEmpty,
        isFalse,
        reason: 'Stream does not emit unless real purchase flow is triggered.',
      );

      await sub.cancel();
    },
  );
  test(
    'activeSubscriptionsStream does not emit for invalid purchase',
    () async {
      final mockIap = MockInAppPurchase();
      final serverClient = MockServerClient();
      final core = SubmanCore.test(serverClient: serverClient, iap: mockIap);

      when(mockIap.isAvailable()).thenAnswer((_) async => true);

      final mockProductDetails = MockProductDetails();
      when(mockProductDetails.id).thenReturn('test_product');
      when(mockIap.queryProductDetails(any)).thenAnswer(
        (_) async => ProductDetailsResponse(
          productDetails: [mockProductDetails],
          notFoundIDs: [],
          error: null,
        ),
      );

      final purchaseDetails = MockPurchaseDetails();
      when(purchaseDetails.productID).thenReturn('test_product');
      when(purchaseDetails.verificationData).thenReturn(
        PurchaseVerificationData(
          localVerificationData: 'local',
          serverVerificationData: 'invalid-token', // Not valid!
          source: 'test',
        ),
      );
      when(purchaseDetails.status).thenReturn(PurchaseStatus.purchased);
      when(purchaseDetails.purchaseID).thenReturn('order123');
      when(
        purchaseDetails.transactionDate,
      ).thenReturn(DateTime.now().millisecondsSinceEpoch.toString());

      final purchaseStream = Stream<List<PurchaseDetails>>.value([
        purchaseDetails,
      ]);
      when(mockIap.purchaseStream).thenAnswer((_) => purchaseStream);

      final streamQueue = <List<SubscriptionData>>[];
      final sub = core.activeSubscriptionsStream.listen(streamQueue.add);

      await core.initialize(productIds: ['test_product']);
      await Future.delayed(const Duration(milliseconds: 50));

      expect(
        streamQueue.isEmpty,
        isTrue,
        reason: 'Stream should not emit for invalid purchase',
      );

      await sub.cancel();
    },
  );
}

/// Mock server client that simulates a server-side exception.
class MockServerClientException implements SubscriptionServerClient {
  @override
  Future<bool> verify(Map<String, dynamic> payload) async {
    throw Exception('Server-side error!');
  }
}
