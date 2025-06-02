import 'package:flutter/services.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:mockito/annotations.dart';

@GenerateMocks([
  InAppPurchase,
  InAppPurchaseAndroidPlatform,
  PurchaseDetails,
  ProductDetails,
  PlatformException,
])
void main() {}
