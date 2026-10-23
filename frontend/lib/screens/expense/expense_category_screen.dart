import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../core/constants/categories.dart';
import 'add_category_screen.dart';

class ExpenseCategoryScreen extends StatefulWidget {
  const ExpenseCategoryScreen({super.key});

  @override
  State<ExpenseCategoryScreen> createState() => _ExpenseCategoryScreenState();
}

class _ExpenseCategoryScreenState extends State<ExpenseCategoryScreen> {
  @override
  void initState() {
    super.initState();
    reloadGlobalCategories().then((_) {
      if (mounted) setState(() {});
    });
  }

  Future<void> _openAddCategoryScreen() async {
    final newCatName = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (ctx) => const AddCategoryScreen()),
    );
    if (newCatName != null && newCatName.isNotEmpty) {
      await reloadGlobalCategories();
      if (!mounted) return;
      final res = await context.push('/add-expense-form', extra: newCatName);
      if (!mounted) return;
      if (res == true) Navigator.pop(context, true);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xff121212) : const Color(0xffF8FAFC);
    final textColor = isDark ? Colors.white : Colors.black87;
    final allCats = expenseCategories;

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
          "Select Category",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: GridView.builder(
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount: 4,
            mainAxisSpacing: 18,
            crossAxisSpacing: 14,
            childAspectRatio: 0.8,
          ),
          itemCount: allCats.length + 1,
          itemBuilder: (ctx, index) {
            if (index == allCats.length) {
              return InkWell(
                onTap: _openAddCategoryScreen,
                borderRadius: BorderRadius.circular(20),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Container(
                      width: 56,
                      height: 56,
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xff2A2A3C) : Colors.grey.shade300,
                        shape: BoxShape.circle,
                      ),
                      child: Icon(Icons.add, color: textColor, size: 28),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      "Add Category",
                      textAlign: TextAlign.center,
                      style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w600),
                    ),
                  ],
                ),
              );
            }

            final cat = allCats[index];
            return InkWell(
              onTap: () async {
                final res = await context.push('/add-expense-form', extra: cat.name);
                if (!mounted) return;
                if (res == true) Navigator.pop(context, true);
              },
              borderRadius: BorderRadius.circular(20),
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 56,
                    height: 56,
                    decoration: BoxDecoration(
                      color: cat.color.withValues(alpha: 0.18),
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: Text(cat.emoji ?? "\u{1F3F7}\u{FE0F}", style: const TextStyle(fontSize: 24)),
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    cat.name,
                    textAlign: TextAlign.center,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: TextStyle(color: textColor, fontSize: 11, fontWeight: FontWeight.w500),
                  ),
                ],
              ),
            );
          },
        ),
      ),
    );
  }
}
