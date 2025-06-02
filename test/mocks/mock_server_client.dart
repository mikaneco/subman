import 'package:subman/src/models/server_client.dart';

class MockServerClient implements SubscriptionServerClient {
  @override
  Future<bool> verify(Map<String, dynamic> payload) async {
    // Simulate server verification logic for tests
    if (payload['receipt'] == 'valid') return true; // iOS
    if (payload['purchaseToken'] == 'valid-token') return true; // Android
    return false;
  }
}
