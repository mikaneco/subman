## 1.0.0

- **Breaking**: Bumped minimum SDK to Dart 3.5 / Flutter 3.24.
- **Breaking**: Removed direct `dart:io` dependency from core; platform detection now uses `defaultTargetPlatform` with optional `platformOverride` for testing.
- Updated `in_app_purchase` to ^3.2.3.
- Updated `in_app_purchase_android` to ^0.4.0+8.
- Updated `flutter_lints` to ^5.0.0.
- Updated `mockito` to ^5.6.3.
- Updated `build_runner` to ^2.12.2.
- Updated `in_app_purchase_platform_interface` to ^1.4.0.
- Added `==` and `hashCode` to `SubscriptionData` for proper equality comparison.
- Exported `SubscriptionServerClient` and `SubmanEnvironment` from public API.
- Fixed `completePurchase` being skipped for invalid receipts (now always acknowledged with the store).
- Added `PurchaseStatus.pending` handling in purchase stream.
- Added comprehensive test suite covering models, core logic, purchase/restore flows, and error handling.
- Improved linting rules in `analysis_options.yaml`.

## 0.1.0

- Initial public release.
- Subscription management for Flutter with in-app purchase support.
- Real-time subscription status stream.
- Unified error handling and server-side validation hooks.
- Easy mocking for tests.
