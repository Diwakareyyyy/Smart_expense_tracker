import 'package:flutter/foundation.dart';
import '../services/auth_service.dart';

class UserProvider extends ChangeNotifier {
  String _userName = 'User';
  String _userEmail = '';
  String? _profilePhoto;

  String get userName => _userName;
  String get userEmail => _userEmail;
  String? get profilePhoto => _profilePhoto;

  Future<void> loadFromStorage() async {
    final name = await AuthService.instance.getUserName();
    final email = await AuthService.instance.getEmail();
    final photo = await AuthService.instance.getProfilePhoto(email ?? '');

    _userName = name ?? 'User';
    _userEmail = email ?? '';
    _profilePhoto = photo;
    notifyListeners();
  }

  Future<void> updateName(String name) async {
    await AuthService.instance.saveUserName(name);
    _userName = name;
    notifyListeners();
  }

  Future<void> updatePhoto(String? photo) async {
    await AuthService.instance.saveProfilePhoto(_userEmail, photo);
    _profilePhoto = photo;
    notifyListeners();
  }
}
