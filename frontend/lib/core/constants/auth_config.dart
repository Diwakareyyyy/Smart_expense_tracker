import 'package:flutter_dotenv/flutter_dotenv.dart';

/// Google Sign-In configuration.
///
/// The client IDs are loaded from the project root `.env` file:
///   GOOGLE_WEB_CLIENT_ID      (OAuth 2.0 "Web application" client ID)
///   GOOGLE_ANDROID_CLIENT_ID  (OAuth 2.0 "Android" client ID)
///
/// Create / verify these credentials in Google Cloud Console:
///   https://console.cloud.google.com/apis/credentials
///
/// 1) Android client ID -> OAuth 2.0 Client IDs -> "Android"
///    Package name : com.example.chatgpt
/// 2) Web client ID  -> OAuth 2.0 Client IDs -> "Web application"
class AuthConfig {
  static const String _defaultAndroidClientId =
      '983512280725-tlfg9b1n18pcea7f83hth4onsl7eje86.apps.googleusercontent.com';

  static const String _defaultWebClientId =
      '983512280725-aqsd8u74cqaueq6j31jg1v6ma10dpdom.apps.googleusercontent.com';

  static String get googleAndroidClientId {
    final value = dotenv.env['GOOGLE_ANDROID_CLIENT_ID']?.trim() ?? '';
    return value.isNotEmpty ? value : _defaultAndroidClientId;
  }

  static String get googleWebClientId {
    final value = dotenv.env['GOOGLE_WEB_CLIENT_ID']?.trim() ?? '';
    return value.isNotEmpty ? value : _defaultWebClientId;
  }
}
