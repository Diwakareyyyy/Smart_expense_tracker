import 'dart:convert';
import 'dart:io';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/auth_config.dart';
import 'api_client.dart';

class AuthService {
  AuthService._();
  static final AuthService instance = AuthService._();

  late final GoogleSignIn _googleSignIn = GoogleSignIn(
    clientId: AuthConfig.googleAndroidClientId,
    serverClientId: AuthConfig.googleWebClientId,
  );

  static const String _loginKey = "isLoggedIn";
  static const String _tokenKey = "token";
  static const String _emailKey = "email";
  static const String _usernameKey = "userName";

  static const String defaultEmail = "buddy@example.com";
  static const String defaultPassword = "Buddy@12345";
  static const String defaultName = "Buddy";

  static String? validatePassword(String password) {
    if (password.length < 8) {
      return "Password must be at least 8 characters long";
    }
    if (!RegExp(r'[A-Z]').hasMatch(password)) {
      return "Password must contain at least 1 uppercase letter (A-Z)";
    }
    if (!RegExp(r'[0-9]').hasMatch(password)) {
      return "Password must contain at least 1 numerical digit (0-9)";
    }
    if (!RegExp(r'[!@#$%^&*(),.?":{}|<>]').hasMatch(password)) {
      return r"Password must contain at least 1 special character (@, #, $, !, etc.)";
    }
    return null;
  }

  Future<bool> isLoggedIn() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_loginKey) ?? false;
  }

  Future<String?> getEmail() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_emailKey);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    final email = await getEmail();
    if (email != null && email.isNotEmpty) {
      final custom = prefs.getString(_displayNameKey(email));
      if (custom != null && custom.isNotEmpty) return custom;
    }
    return prefs.getString(_usernameKey) ?? defaultName;
  }

  Future<void> saveUserName(String name) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_usernameKey, name);
    final email = await getEmail();
    if (email != null && email.isNotEmpty) {
      await prefs.setString(_displayNameKey(email), name);
    }
  }

  /// Stores the name the user explicitly chose, per account. This survives
  /// logout/login so an updated name stays until the user changes it again.
  static String _displayNameKey(String email) =>
      "displayName_${email.trim().toLowerCase()}";

  /// Profile photo is stored per account so each user keeps their own picture.
  /// The value is either a local file path (custom image picked by the user)
  /// or a remote URL (Google account photo).
  static String _photoKey(String email) =>
      "profilePhoto_${email.trim().toLowerCase()}";

  String _sanitizeEmail(String email) =>
      email.trim().toLowerCase().replaceAll(RegExp(r'[^a-z0-9]'), '_');

  Future<String?> getProfilePhoto(String email) async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_photoKey(email));
  }

  Future<void> saveProfilePhoto(String email, String? photo) async {
    final prefs = await SharedPreferences.getInstance();
    if (photo == null || photo.isEmpty) {
      await prefs.remove(_photoKey(email));
    } else {
      await prefs.setString(_photoKey(email), photo);
    }
  }

  /// Copies a picked image to a per-account file so different users never
  /// overwrite each other's pictures. Each save uses a fresh file name so
  /// Flutter's image cache (keyed by file path) is invalidated and the new
  /// picture appears immediately everywhere in the app.
  Future<String> saveProfileImageFile(String email, File source) async {
    final dir = await getApplicationDocumentsDirectory();
    final prefix = 'profile_photo_${_sanitizeEmail(email)}_';
    final file = File(
      '${dir.path}/$prefix${DateTime.now().millisecondsSinceEpoch}.jpg',
    );
    await source.copy(file.path);

    try {
      for (final entity in dir.listSync()) {
        if (entity is File &&
            entity.path.contains(prefix) &&
            entity.path != file.path) {
          entity.deleteSync();
        }
      }
    } catch (_) {}

    return file.path;
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString(_tokenKey);
  }

  Future<void> _saveSession(String token, String email, String username) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_loginKey, true);
    await prefs.setString(_tokenKey, token);
    await prefs.setString(_emailKey, email);
    await prefs.setString(_usernameKey, username);
  }

  /// LOGIN
  Future<String?> signInWithEmail(String email, String password) async {
    try {
      final response = await ApiClient.instance.post(
        "/api/auth/login",
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email.trim(),
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        await _saveSession(
          data["access_token"],
          data["user"]["email"],
          data["user"]["username"],
        );
        return null;
      }

      return data["message"] ?? "Login failed. Invalid email or password.";
    } catch (e) {
      return e.toString();
    }
  }

  /// SIGNUP
  Future<String?> signUpWithEmail({
    required String name,
    required String email,
    required String password,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        "/api/auth/signup",
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "username": name.trim(),
          "email": email.trim(),
          "password": password,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        // Automatically sign in the user after successful sign up
        return await signInWithEmail(email, password);
      }

      return data["message"] ?? "Sign up failed.";
    } catch (e) {
      return e.toString();
    }
  }

  /// GOOGLE SIGN IN
  Future<String?> signInWithGoogle() async {
    try {
      final googleUser = await _googleSignIn.signIn();
      if (googleUser == null) return "Sign in cancelled";

      final response = await ApiClient.instance.post(
        "/api/auth/google",
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": googleUser.email,
          "username": googleUser.displayName ?? googleUser.email.split('@').first,
          "google_id": googleUser.id,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        final email = data["user"]["email"] as String;
        await _saveSession(
          data["access_token"],
          email,
          data["user"]["username"],
        );
        // Use the Google account photo only when this account has no picture
        // yet, so a custom picture the user chose later stays across logins.
        final existing = await getProfilePhoto(email);
        if (existing == null || existing.isEmpty) {
          await saveProfilePhoto(email, googleUser.photoUrl);
        }
        return null;
      }

      return data["message"] ?? "Google sign in failed on server.";
    } catch (e) {
      return e.toString();
    }
  }

  /// FORGOT PASSWORD (OTP Request)
  /// Returns (errorMessage, devOtp). When SMTP is not configured on the server
  /// the OTP is returned directly so the flow can be completed during testing.
  Future<(String?, String?)> sendPasswordResetEmail(String email) async {
    try {
      final response = await ApiClient.instance.post(
        "/api/auth/forgot-password",
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email.trim(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        return (null, data["dev_otp"] as String?); // Success
      }

      return (data["message"] as String? ?? "Failed to request password reset.", null);
    } catch (e) {
      return (e.toString(), null);
    }
  }

  /// VERIFY & RESET PASSWORD
  Future<String?> verifyAndResetPassword({
    required String email,
    required String otp,
    required String newPassword,
  }) async {
    try {
      final response = await ApiClient.instance.post(
        "/api/auth/reset-password",
        headers: {
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "email": email.trim(),
          "otp": otp.trim(),
          "password": newPassword,
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["success"] == true) {
        return null; // Success
      }

      return data["message"] ?? "Failed to reset password.";
    } catch (e) {
      return e.toString();
    }
  }

  /// LOGOUT
  Future<void> logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_loginKey);
    await prefs.remove(_tokenKey);
    await prefs.remove(_emailKey);
    await prefs.remove(_usernameKey);

    try {
      await _googleSignIn.signOut();
    } catch (_) {}
  }
}