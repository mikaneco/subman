/// Defines the possible environments where the Subman package might be running.
///
/// This allows Subman and your app to adjust behavior based on the deployment context,
/// such as enabling debug logs, switching API endpoints, or using test product IDs.
enum SubmanEnvironment {
  /// Running in a simulator or emulator (e.g., iOS Simulator, Android Emulator).
  simulator,

  /// Running on a physical device in debug/development mode.
  deviceDebug,

  /// Running via iOS TestFlight beta testing.
  testflight,

  /// Running via Android internal testing (e.g., internal test track) or similar.
  internalTest,

  /// Running as a production release (live on the App Store/Google Play).
  production,
}

/// Extension methods for [SubmanEnvironment] to simplify common environment checks.
extension SubmanEnvironmentExtension on SubmanEnvironment {
  /// Returns true if this environment is [production].
  bool get isProduction => this == SubmanEnvironment.production;

  /// Returns true if this environment is not [production].
  bool get isTest => this != SubmanEnvironment.production;

  /// Returns true if this environment is [simulator] or [deviceDebug].
  bool get isDebug =>
      this == SubmanEnvironment.simulator ||
      this == SubmanEnvironment.deviceDebug;

  /// Returns true if this environment is [testflight] or [internalTest].
  bool get isBeta =>
      this == SubmanEnvironment.testflight ||
      this == SubmanEnvironment.internalTest;

  /// Returns true if this environment is [simulator].
  bool get isSimulator => this == SubmanEnvironment.simulator;

  /// Returns true if this environment is [deviceDebug].
  bool get isDeviceDebug => this == SubmanEnvironment.deviceDebug;
}
