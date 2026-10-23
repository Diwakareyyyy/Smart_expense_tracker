import 'package:flutter/material.dart';
import '../../services/custom_category_service.dart';

class ExpenseCategory {
  final String name;
  final IconData icon;
  final Color color;
  final String? emoji;

  const ExpenseCategory({
    required this.name,
    required this.icon,
    required this.color,
    this.emoji,
  });
}

const List<ExpenseCategory> defaultExpenseCategories = [
  ExpenseCategory(name: "Food", icon: Icons.restaurant, color: Color(0xFFD32F2F), emoji: "🍔"),
  ExpenseCategory(name: "Health", icon: Icons.health_and_safety, color: Color(0xFF43A047), emoji: "🏥"),
  ExpenseCategory(name: "Medicine", icon: Icons.medical_services, color: Color(0xFF00897B), emoji: "💊"),
  ExpenseCategory(name: "Education", icon: Icons.school, color: Color(0xFF1976D2), emoji: "📚"),
  ExpenseCategory(name: "Shopping", icon: Icons.shopping_bag, color: Color(0xFFF57C00), emoji: "🛍️"),
  ExpenseCategory(name: "Fuel", icon: Icons.local_gas_station, color: Color(0xFF5E35B1), emoji: "⛽"),
  ExpenseCategory(name: "Recharge", icon: Icons.phone_android, color: Color(0xFF3949AB), emoji: "📱"),
  ExpenseCategory(name: "Electricity", icon: Icons.electric_bolt, color: Color(0xFFFBC02D), emoji: "⚡"),
  ExpenseCategory(name: "Transport", icon: Icons.directions_bus, color: Color(0xFF0097A7), emoji: "🚌"),
  ExpenseCategory(name: "Entertainment", icon: Icons.movie, color: Color(0xFFE64A19), emoji: "🎬"),
  ExpenseCategory(name: "Gadgets", icon: Icons.devices, color: Color(0xFF039BE5), emoji: "💻"),
  ExpenseCategory(name: "Juice", icon: Icons.local_cafe, color: Color(0xFF7CB342), emoji: "🥤"),
  ExpenseCategory(name: "Bills", icon: Icons.receipt_long, color: Color(0xFF8E24AA), emoji: "📄"),
  ExpenseCategory(name: "Rent", icon: Icons.home, color: Color(0xFF6D4C41), emoji: "🏠"),
  ExpenseCategory(name: "Groceries", icon: Icons.shopping_cart, color: Color(0xFF26A69A), emoji: "🛒"),
  ExpenseCategory(name: "Travel", icon: Icons.flight, color: Color(0xFF546E7A), emoji: "✈️"),
  ExpenseCategory(name: "Insurance", icon: Icons.security, color: Color(0xFF5D4037), emoji: "🛡️"),
  ExpenseCategory(name: "Gift", icon: Icons.card_giftcard, color: Color(0xFFC0CA33), emoji: "🎁"),
  ExpenseCategory(name: "Business", icon: Icons.business_center, color: Color(0xFF37474F), emoji: "💼"),
  ExpenseCategory(name: "Others", icon: Icons.more_horiz, color: Color(0xFF757575), emoji: "📦"),
];

List<ExpenseCategory> _dynamicCategories = List.from(defaultExpenseCategories);

List<ExpenseCategory> get expenseCategories => _dynamicCategories;

Future<void> reloadGlobalCategories() async {
  final customList = await CustomCategoryService.getCustomCategories();
  final list = List<ExpenseCategory>.from(defaultExpenseCategories);
  for (var custom in customList) {
    list.add(custom.toExpenseCategory());
  }
  _dynamicCategories = list;
}

List<String> get categories =>
    expenseCategories.map((c) => c.name).toList();

ExpenseCategory getCategoryByName(String name) {
  return expenseCategories.firstWhere(
    (c) => c.name.trim().toLowerCase() == name.trim().toLowerCase(),
    orElse: () => expenseCategories.last,
  );
}
