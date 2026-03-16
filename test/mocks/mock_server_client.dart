import 'package:subman/subman.dart';

/// Mock server client that validates based on receipt/token content.
class MockServerClient implements SubscriptionServerClient {
  @override
  Future<bool> verify(Map<String, dynamic> payload) async {
    if (payload['receipt'] == 'valid') return true; // iOS
    if (payload['purchaseToken'] == 'valid-token') return true; // Android
    return false;
  }
}

/// Mock server client that always returns true.
class MockAlwaysValidServerClient implements SubscriptionServerClient {
  int callCount = 0;
  Map<String, dynamic>? lastPayload;

  @override
  Future<bool> verify(Map<String, dynamic> payload) async {
    callCount++;
    lastPayload = payload;
    return true;
  }
}

/// Mock server client that always returns false.
class MockAlwaysInvalidServerClient implements SubscriptionServerClient {
  int callCount = 0;

  @override
  Future<bool> verify(Map<String, dynamic> payload) async {
    callCount++;
    return false;
  }
}

/// Mock server client that throws an exception.
class MockServerClientException implements SubscriptionServerClient {
  @override
  Future<bool> verify(Map<String, dynamic> payload) async {
    throw Exception('Server-side error!');
  }
}
