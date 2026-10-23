class AppConstants {
  /// IP address of the computer running the backend, as seen from your
  /// phone / emulator.
  ///
  /// - Android emulator: leave as-is, the app auto-uses 10.0.2.2.
  /// - Physical phone on the same Wi-Fi: set this to your PC's LAN IPv4
  ///   (check with `ipconfig` on Windows), e.g. '192.168.1.5'.
  /// - Windows desktop / Chrome: 127.0.0.1 works automatically.
  static const String backendHost = '192.168.29.167';
}
