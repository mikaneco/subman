/// This is a Flutter example application demonstrating how to use the Subman package
/// for managing in-app subscriptions. It initializes the Subman SDK, listens for
/// subscription changes, and provides UI buttons to purchase or restore subscriptions.
library;

import 'package:flutter/material.dart';
import 'package:subman/subman.dart';

/// A sample implementation of a custom server verification client.
/// Extend SubscriptionServerClient and override methods to verify receipts
/// or subscriptions with your own backend server.
class MyServerClient extends SubscriptionServerClient {
  MyServerClient() : super();

  @override
  Future<bool> verify(Map<String, dynamic> payload) {
    // Implement your server-side verification logic here.
    // For example, send the payload to your backend and return verification status.
    debugPrint('Verifying payload on custom server: $payload');
    // Simulate verification result
    return Future.value(true);
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Subman.init(
    productIds: ['monthly_subscription', 'yearly_subscription'],
    onPurchaseCompleted: (subscription) {
      debugPrint('Purchased: ${subscription.productId}');
    },
    onRestoreCompleted: (subscriptions) {
      debugPrint('Restored: $subscriptions');
    },
    onError: (exception) {
      debugPrint('Error: ${exception.code} / ${exception.message}');
    },
    // To use a custom server verification client, uncomment the following line:
    // serverClient: MyServerClient(),
  );

  runApp(const MyApp());
}

/// Root widget of the application.
class MyApp extends StatelessWidget {
  const MyApp({super.key});
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Subman Example',
      home: Scaffold(
        appBar: AppBar(title: const Text('Subman Example')),
        body: const SubscriptionDemo(),
      ),
    );
  }
}

/// A stateful widget demonstrating subscription status and actions.
class SubscriptionDemo extends StatefulWidget {
  const SubscriptionDemo({super.key});
  @override
  State<SubscriptionDemo> createState() => _SubscriptionDemoState();
}

/// State class that listens for subscription updates and provides UI controls.
class _SubscriptionDemoState extends State<SubscriptionDemo> {
  String _status = '';

  @override
  void initState() {
    super.initState();
    // Listen to active subscription changes and update UI accordingly.
    Subman.activeSubscriptionsStream.listen((subs) {
      setState(() {
        _status = subs.isEmpty
            ? 'No active subscription'
            : 'Active: ${subs.map((s) => s.productId).join(', ')}';
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    final isSubscribed = Subman.isSubscribed;
    final current = Subman.currentSubscription;

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text('Status: $_status'),
          const SizedBox(height: 16),
          ElevatedButton(
            onPressed: () async {
              await Subman.purchase('monthly_subscription');
            },
            child: const Text('Purchase Monthly'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              await Subman.purchase('yearly_subscription');
            },
            child: const Text('Purchase Yearly'),
          ),
          const SizedBox(height: 8),
          ElevatedButton(
            onPressed: () async {
              await Subman.restore();
            },
            child: const Text('Restore'),
          ),
          const SizedBox(height: 24),
          Text('Is Subscribed: $isSubscribed'),
          Text('Current: ${current?.productId ?? "-"}'),
        ],
      ),
    );
  }
}
