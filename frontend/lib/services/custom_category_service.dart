import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/constants/categories.dart';

class CustomCategoryModel {
  final String name;
  final String emoji;
  final int colorHex;

  CustomCategoryModel({
    required this.name,
    required this.emoji,
    required this.colorHex,
  });

  Color get color => Color(colorHex);

  Map<String, dynamic> toMap() => {
        'name': name,
        'emoji': emoji,
        'colorHex': colorHex,
      };

  factory CustomCategoryModel.fromMap(Map<String, dynamic> map) {
    return CustomCategoryModel(
      name: map['name'] ?? '',
      emoji: map['emoji'] ?? '🏷️',
      colorHex: map['colorHex'] ?? 0xFF7C3AED,
    );
  }

  ExpenseCategory toExpenseCategory() {
    return ExpenseCategory(
      name: name,
      icon: Icons.category,
      color: color,
      emoji: emoji,
    );
  }
}

class CustomCategoryService {
  static const String _key = "custom_user_categories";

  static Future<List<CustomCategoryModel>> getCustomCategories() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getStringList(_key) ?? [];
    return raw
        .map((item) => CustomCategoryModel.fromMap(jsonDecode(item)))
        .toList();
  }

  static Future<bool> addCustomCategory(CustomCategoryModel cat) async {
    final prefs = await SharedPreferences.getInstance();
    final list = await getCustomCategories();
    // Check duplicate name
    if (list.any((c) => c.name.trim().toLowerCase() == cat.name.trim().toLowerCase())) {
      return false;
    }
    list.add(cat);
    final rawList = list.map((c) => jsonEncode(c.toMap())).toList();
    await prefs.setStringList(_key, rawList);
    await reloadGlobalCategories();
    return true;
  }
}
