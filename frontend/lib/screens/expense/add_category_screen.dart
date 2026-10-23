import 'package:flutter/material.dart';

import '../../services/custom_category_service.dart';
import '../../core/constants/categories.dart';

class AddCategoryScreen extends StatefulWidget {
  const AddCategoryScreen({super.key});

  @override
  State<AddCategoryScreen> createState() => _AddCategoryScreenState();
}

class _AddCategoryScreenState extends State<AddCategoryScreen> {
  final TextEditingController _nameController = TextEditingController();
  String _categoryType = "Expense"; // Expense or Income
  
  IconData _selectedIcon = Icons.sports_esports;
  String _selectedEmoji = "🎮";
  int _selectedColorHex = 0xFFF57C00; // Orange default

  final List<int> _colorPalette = [
    0xFFD32F2F, 0xFFE64A19, 0xFFF57C00, 0xFFFFA000, 0xFFFBC02D,
    0xFFC0CA33, 0xFF7CB342, 0xFF43A047, 0xFF00897B, 0xFF0097A7,
    0xFF039BE5, 0xFF1976D2, 0xFF3949AB, 0xFF5E35B1, 0xFF8E24AA,
    0xFF7B1FA2, 0xFF6D4C41, 0xFF546E7A, 0xFF37474F, 0xFF757575,
  ];

  final Map<String, List<Map<String, dynamic>>> _iconGroups = {
    "Entertainment": [
      {"icon": Icons.sports_esports, "emoji": "🎮"},
      {"icon": Icons.movie_outlined, "emoji": "🎬"},
      {"icon": Icons.music_note, "emoji": "🎵"},
      {"icon": Icons.mic, "emoji": "🎤"},
      {"icon": Icons.extension, "emoji": "🧩"},
      {"icon": Icons.flag, "emoji": "🚩"},
      {"icon": Icons.radio, "emoji": "📻"},
      {"icon": Icons.headset, "emoji": "🎧"},
      {"icon": Icons.send, "emoji": "✈️"},
      {"icon": Icons.psychology, "emoji": "🧠"},
      {"icon": Icons.sports_basketball, "emoji": "🏀"},
    ],
    "Food & Drink": [
      {"icon": Icons.bakery_dining, "emoji": "🍞"},
      {"icon": Icons.local_pizza, "emoji": "🍕"},
      {"icon": Icons.fastfood, "emoji": "🍔"},
      {"icon": Icons.coffee, "emoji": "☕"},
      {"icon": Icons.local_bar, "emoji": "🍸"},
      {"icon": Icons.ramen_dining, "emoji": "🍜"},
      {"icon": Icons.icecream, "emoji": "🍦"},
      {"icon": Icons.lunch_dining, "emoji": "🥪"},
      {"icon": Icons.restaurant, "emoji": "🍽️"},
      {"icon": Icons.apple, "emoji": "🍎"},
    ],
    "Shopping & Lifestyle": [
      {"icon": Icons.shopping_bag, "emoji": "🛍️"},
      {"icon": Icons.shopping_cart, "emoji": "🛒"},
      {"icon": Icons.checkroom, "emoji": "👕"},
      {"icon": Icons.dry_cleaning, "emoji": "👔"},
      {"icon": Icons.watch, "emoji": "⌚"},
      {"icon": Icons.diamond, "emoji": "💎"},
      {"icon": Icons.card_giftcard, "emoji": "🎁"},
    ],
    "Transport & Travel": [
      {"icon": Icons.directions_bus, "emoji": "🚌"},
      {"icon": Icons.directions_car, "emoji": "🚗"},
      {"icon": Icons.local_taxi, "emoji": "🚕"},
      {"icon": Icons.flight, "emoji": "✈️"},
      {"icon": Icons.directions_bike, "emoji": "🚲"},
      {"icon": Icons.local_gas_station, "emoji": "⛽"},
      {"icon": Icons.train, "emoji": "🚆"},
    ],
    "Health & Home": [
      {"icon": Icons.health_and_safety, "emoji": "🏥"},
      {"icon": Icons.medical_services, "emoji": "💊"},
      {"icon": Icons.fitness_center, "emoji": "🏋️"},
      {"icon": Icons.home, "emoji": "🏠"},
      {"icon": Icons.pets, "emoji": "🐶"},
      {"icon": Icons.child_care, "emoji": "👶"},
      {"icon": Icons.build, "emoji": "🔧"},
    ],
  };

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveCategory() async {
    final name = _nameController.text.trim();
    if (name.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please enter a category name"),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final customCat = CustomCategoryModel(
      name: name,
      emoji: _selectedEmoji,
      colorHex: _selectedColorHex,
    );

    final success = await CustomCategoryService.addCustomCategory(customCat);
    if (!mounted) return;

    if (success) {
      await reloadGlobalCategories();
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Category '$name' created successfully!"),
          backgroundColor: Colors.green,
        ),
      );
      Navigator.pop(context, name);
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Category already exists"),
          backgroundColor: Colors.orange,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xff121212) : const Color(0xffF8FAFC);
    final cardColor = isDark ? const Color(0xff1E1E2C) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        leading: TextButton(
          onPressed: () => Navigator.pop(context),
          child: const Text("Cancel", style: TextStyle(color: Colors.grey, fontSize: 16)),
        ),
        leadingWidth: 80,
        title: Text(
          "Add category",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 18),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: _saveCategory,
            icon: const Icon(Icons.check, color: Color(0xff7B4DFF), size: 28),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Expense / Income Radio Selector
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                GestureDetector(
                  onTap: () => setState(() => _categoryType = "Expense"),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: "Expense",
                        groupValue: _categoryType,
                        activeColor: const Color(0xFFFFD700),
                        onChanged: (val) => setState(() => _categoryType = val!),
                      ),
                      Text("Expense", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(width: 30),
                GestureDetector(
                  onTap: () => setState(() => _categoryType = "Income"),
                  child: Row(
                    children: [
                      Radio<String>(
                        value: "Income",
                        groupValue: _categoryType,
                        activeColor: const Color(0xFFFFD700),
                        onChanged: (val) => setState(() => _categoryType = val!),
                      ),
                      Text("Income", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),

            // Icon Preview + Name Input Field
            Row(
              children: [
                Container(
                  width: 54,
                  height: 54,
                  decoration: BoxDecoration(
                    color: Color(_selectedColorHex),
                    shape: BoxShape.circle,
                  ),
                  child: Center(
                    child: Text(_selectedEmoji, style: const TextStyle(fontSize: 26)),
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: TextField(
                    controller: _nameController,
                    style: TextStyle(color: textColor, fontSize: 16),
                    decoration: InputDecoration(
                      hintText: "Please enter the category name",
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 14),
                      filled: true,
                      fillColor: cardColor,
                      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 16),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),

            // Color Palette Selector
            Wrap(
              spacing: 12,
              runSpacing: 12,
              alignment: WrapAlignment.center,
              children: _colorPalette.map((hex) {
                final isSelected = _selectedColorHex == hex;
                return GestureDetector(
                  onTap: () => setState(() => _selectedColorHex = hex),
                  child: Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: Color(hex),
                      shape: BoxShape.circle,
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: Color(hex).withValues(alpha: 0.5),
                                blurRadius: 8,
                                spreadRadius: 2,
                              )
                            ]
                          : null,
                    ),
                    child: isSelected
                        ? const Icon(Icons.check, color: Colors.white, size: 22)
                        : null,
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 30),

            // Icon Grid Groups
            ..._iconGroups.entries.map((entry) {
              final groupTitle = entry.key;
              final items = entry.value;

              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(
                    child: Text(
                      groupTitle,
                      style: TextStyle(
                        color: isDark ? Colors.white70 : Colors.grey.shade600,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  GridView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                      crossAxisCount: 6,
                      mainAxisSpacing: 12,
                      crossAxisSpacing: 12,
                      childAspectRatio: 1.0,
                    ),
                    itemCount: items.length,
                    itemBuilder: (ctx, idx) {
                      final item = items[idx];
                      final iconData = item["icon"] as IconData;
                      final emoji = item["emoji"] as String;
                      final isSelected = _selectedEmoji == emoji;

                      return GestureDetector(
                        onTap: () {
                          setState(() {
                            _selectedIcon = iconData;
                            _selectedEmoji = emoji;
                          });
                        },
                        child: Container(
                          decoration: BoxDecoration(
                            color: isSelected
                                ? Color(_selectedColorHex)
                                : isDark
                                    ? const Color(0xff2A2A3C)
                                    : Colors.grey.shade200,
                            shape: BoxShape.circle,
                          ),
                          child: Center(
                            child: Text(
                              emoji,
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                        ),
                      );
                    },
                  ),
                  const SizedBox(height: 24),
                ],
              );
            }),
          ],
        ),
      ),
    );
  }
}
