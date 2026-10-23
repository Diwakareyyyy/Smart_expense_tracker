import 'dart:io';
import 'package:flutter/material.dart';

/// Circular profile picture that renders a local file path, a remote URL
/// (e.g. the Google account photo) or a fallback with the user's initial.
class ProfileAvatar extends StatelessWidget {
  final String? photo;
  final String name;
  final double radius;
  final Color? backgroundColor;

  const ProfileAvatar({
    super.key,
    this.photo,
    required this.name,
    this.radius = 26,
    this.backgroundColor,
  });

  Widget _fallback(BuildContext context) {
    final initial = name.isNotEmpty ? name[0].toUpperCase() : 'U';
    return CircleAvatar(
      radius: radius,
      backgroundColor: backgroundColor ?? const Color(0xff7B4DFF),
      child: Text(
        initial,
        style: TextStyle(
          color: Colors.white,
          fontSize: radius * 0.85,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _image(BuildContext context, ImageProvider image) {
    return ClipOval(
      child: Image(
        image: image,
        width: radius * 2,
        height: radius * 2,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => _fallback(context),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final value = photo?.trim() ?? '';
    if (value.isEmpty) return _fallback(context);

    if (value.startsWith('http://') || value.startsWith('https://')) {
      return _image(context, NetworkImage(value));
    }

    final file = File(value);
    if (file.existsSync()) {
      return _image(context, FileImage(file));
    }

    return _fallback(context);
  }
}
