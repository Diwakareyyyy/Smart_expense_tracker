import 'dart:io';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_extensions.dart';
import '../../providers/user_provider.dart';
import '../../services/auth_service.dart';
import '../../widgets/bottom_navbar.dart';
import '../../widgets/profile_avatar.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  final TextEditingController _nameController = TextEditingController();
  final ImagePicker _picker = ImagePicker();
  String userName = '';
  String userEmail = '';
  String? profilePhoto;
  bool _isSaving = false;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> loadData() async {
    final name = await AuthService.instance.getUserName();
    final email = await AuthService.instance.getEmail();
    final photo = await AuthService.instance.getProfilePhoto(email ?? '');

    if (mounted) {
      setState(() {
        userName = name ?? 'User';
        userEmail = email ?? '';
        profilePhoto = photo;
        _nameController.text = userName;
      });
    }
  }

  Future<void> _pickImage(ImageSource source) async {
    final picked = await _picker.pickImage(
      source: source,
      maxWidth: 800,
      maxHeight: 800,
      imageQuality: 85,
    );
    if (picked == null) return;

    final savedPath = await AuthService.instance.saveProfileImageFile(
      userEmail,
      File(picked.path),
    );

    if (!mounted) return;
    await context.read<UserProvider>().updatePhoto(savedPath);

    if (mounted) {
      setState(() => profilePhoto = savedPath);
      await _showSuccessAndRedirect('Profile picture updated successfully');
    }
  }

  Future<void> _removePhoto() async {
    await context.read<UserProvider>().updatePhoto(null);

    if (mounted) {
      setState(() => profilePhoto = null);
      await _showSuccessAndRedirect('Profile picture removed successfully');
    }
  }

  Future<void> _showSuccessAndRedirect(String message) async {
    await showDialog<void>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        Future.delayed(const Duration(milliseconds: 1500), () {
          if (dialogContext.mounted) Navigator.of(dialogContext).pop();
        });
        return Dialog(
          backgroundColor: context.cardBg,
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Container(
                  width: 64,
                  height: 64,
                  decoration: const BoxDecoration(
                    color: Color(0xff7B4DFF),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.check_rounded, color: Colors.white, size: 36),
                ),
                const SizedBox(height: 16),
                Text(
                  message,
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: context.textPrimary,
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (!mounted) return;
    if (Navigator.of(context).canPop()) {
      Navigator.of(context).pop();
    } else {
      context.go('/settings');
    }
  }

  void _showPhotoOptions() {
    showModalBottomSheet(
      context: context,
      backgroundColor: context.cardBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const SizedBox(height: 12),
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: context.divider,
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              const SizedBox(height: 16),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xff7B4DFF),
                  child: Icon(Icons.photo_camera, color: Colors.white),
                ),
                title: Text(
                  'Take Photo',
                  style: TextStyle(color: context.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
              ListTile(
                leading: const CircleAvatar(
                  backgroundColor: Color(0xff7B4DFF),
                  child: Icon(Icons.photo_library, color: Colors.white),
                ),
                title: Text(
                  'Choose from Gallery',
                  style: TextStyle(color: context.textPrimary),
                ),
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              if (profilePhoto != null && profilePhoto!.isNotEmpty)
                ListTile(
                  leading: const CircleAvatar(
                    backgroundColor: Colors.redAccent,
                    child: Icon(Icons.delete_outline, color: Colors.white),
                  ),
                  title: Text(
                    'Remove Photo',
                    style: TextStyle(color: context.textPrimary),
                  ),
                  onTap: () {
                    Navigator.pop(ctx);
                    _removePhoto();
                  },
                ),
              const SizedBox(height: 12),
            ],
          ),
        );
      },
    );
  }

  Future<void> _saveName() async {
    final trimmedName = _nameController.text.trim();
    if (trimmedName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Name cannot be empty')),
      );
      return;
    }

    setState(() => _isSaving = true);

    await context.read<UserProvider>().updateName(trimmedName);

    if (mounted) {
      setState(() {
        userName = trimmedName;
        _isSaving = false;
      });
      await _showSuccessAndRedirect('User name changed successfully');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBg,
      appBar: AppBar(
        backgroundColor: context.appBg,
        elevation: 0,
        title: Text("Edit Profile", style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: context.textPrimary),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentRoute: '/profile'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Center(
              child: Stack(
                children: [
                  ProfileAvatar(
                    photo: profilePhoto,
                    name: userName,
                    radius: 48,
                  ),
                  Positioned(
                    bottom: 0,
                    right: 0,
                    child: GestureDetector(
                      onTap: _showPhotoOptions,
                      child: Container(
                        padding: const EdgeInsets.all(6),
                        decoration: BoxDecoration(
                          color: const Color(0xff7B4DFF),
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: context.appBg,
                            width: 2,
                          ),
                        ),
                        child: const Icon(
                          Icons.camera_alt,
                          color: Colors.white,
                          size: 18,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 12),
            Center(
              child: TextButton.icon(
                onPressed: _showPhotoOptions,
                icon: const Icon(Icons.edit, color: Color(0xff7B4DFF), size: 16),
                label: Text(
                  'Change Profile Picture',
                  style: TextStyle(
                    color: const Color(0xff7B4DFF),
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: context.cardBg,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: context.divider.withValues(alpha: 0.35)),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Name',
                    style: TextStyle(color: context.textSecondary, fontSize: 13),
                  ),
                  const SizedBox(height: 8),
                  TextField(
                    controller: _nameController,
                    style: TextStyle(color: context.textPrimary, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: 'Enter your name',
                      filled: true,
                      fillColor: context.appBg,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    userEmail.isNotEmpty ? userEmail : 'Your email address',
                    style: TextStyle(color: context.textMuted, fontSize: 13),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              height: 52,
              child: ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff7B4DFF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: _isSaving ? null : _saveName,
                icon: _isSaving
                    ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                    : const Icon(Icons.save_alt_rounded, color: Colors.white),
                label: Text(
                  _isSaving ? 'Saving...' : 'Save Name',
                  style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
