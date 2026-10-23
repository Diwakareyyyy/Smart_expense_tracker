import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

import '../../models/transaction_model.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../core/constants/categories.dart';
import '../../core/constants/payment_methods.dart';
import '../../widgets/bottom_navbar.dart';
import 'add_category_screen.dart';

class AddExpenseScreen extends StatefulWidget {
  final String? preSelectedCategory;

  const AddExpenseScreen({super.key, this.preSelectedCategory});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  String transactionType = "Expense"; // "Expense", "Income", "Transfer"
  late String selectedCategory;
  String selectedPayment = paymentMethods.first;
  String transferToAccount = paymentMethods.length > 1 ? paymentMethods[1] : paymentMethods.first;

  DateTime selectedDate = DateTime.now();

  @override
  void initState() {
    super.initState();
    reloadGlobalCategories().then((_) {
      if (mounted) setState(() {});
    });
    selectedCategory = widget.preSelectedCategory ?? (categories.isNotEmpty ? categories.first : "Food");
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _openAddCategoryScreen() async {
    final newCatName = await Navigator.push<String>(
      context,
      MaterialPageRoute(builder: (ctx) => const AddCategoryScreen()),
    );

    if (newCatName != null && newCatName.isNotEmpty) {
      await reloadGlobalCategories();
      setState(() {
        selectedCategory = newCatName;
      });
    }
  }

  Future<void> _saveTransaction() async {
    if (amountController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter an amount"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    final amount = double.tryParse(amountController.text.trim()) ?? 0;
    if (amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter a valid positive amount"), backgroundColor: Colors.redAccent),
      );
      return;
    }

    // Description is OPTIONAL!
    String rawDesc = descriptionController.text.trim();
    String finalDesc = rawDesc.isNotEmpty ? rawDesc : selectedCategory;
    String finalCategory = selectedCategory;

    if (transactionType == "Transfer") {
      finalDesc = rawDesc.isNotEmpty 
          ? "Transfer ($selectedPayment → $transferToAccount): $rawDesc" 
          : "Transfer ($selectedPayment → $transferToAccount)";
      finalCategory = "Transfer";
    }

    final transaction = TransactionModel(
      amount: amount,
      description: finalDesc,
      category: finalCategory,
      paymentMethod: selectedPayment,
      date: selectedDate.toIso8601String(),
      type: transactionType,
    );

    await DatabaseService.instance.insertTransaction(transaction);
    if (transactionType == "Expense") {
      await NotificationService.instance.notifyExpenseAdded(finalCategory, amount);
    }

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("$transactionType Saved Successfully (₹${amount.toStringAsFixed(0)})"),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xff121212) : const Color(0xffF8FAFC);
    final cardColor = isDark ? const Color(0xff1E1E2C) : Colors.white;
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
          "Add",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.assignment_outlined, color: Colors.grey),
            onPressed: () => context.push('/history'),
          ),
        ],
      ),
      bottomNavigationBar: const AppBottomNavBar(currentRoute: '/add-expense'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Segmented Header Bar (Expense | Income | Transfer)
            Container(
              height: 48,
              decoration: BoxDecoration(
                color: isDark ? const Color(0xff2A2A3C) : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Row(
                children: [
                  _tabSegment("Expense", isDark),
                  _tabSegment("Income", isDark),
                  _tabSegment("Transfer", isDark),
                ],
              ),
            ),
            const SizedBox(height: 24),

            // Category Selection Grid (Image 1 design)
            if (transactionType != "Transfer") ...[
              GridView.builder(
                shrinkWrap: true,
                physics: const NeverScrollableScrollPhysics(),
                gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: 4,
                  mainAxisSpacing: 18,
                  crossAxisSpacing: 14,
                  childAspectRatio: 0.8,
                ),
                itemCount: allCats.length + 1, // +1 for Settings/Add category
                itemBuilder: (ctx, index) {
                  if (index == allCats.length) {
                    // Add Category / Settings button
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
                            style: TextStyle(
                              color: textColor,
                              fontSize: 11,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    );
                  }

                  final cat = allCats[index];
                  final isSelected = selectedCategory == cat.name;

                  return InkWell(
                    onTap: () {
                      setState(() {
                        selectedCategory = cat.name;
                      });
                    },
                    borderRadius: BorderRadius.circular(20),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Container(
                          width: 56,
                          height: 56,
                          decoration: BoxDecoration(
                            color: isSelected
                                ? const Color(0xff7B4DFF)
                                : cat.color.withValues(alpha: 0.18),
                            shape: BoxShape.circle,
                            border: isSelected
                                ? Border.all(color: Colors.white, width: 2)
                                : null,
                            boxShadow: isSelected
                                ? [
                                    BoxShadow(
                                      color: const Color(0xff7B4DFF).withValues(alpha: 0.4),
                                      blurRadius: 8,
                                    )
                                  ]
                                : null,
                          ),
                          child: Center(
                            child: Text(
                              cat.emoji ?? "🏷️",
                              style: const TextStyle(fontSize: 24),
                            ),
                          ),
                        ),
                        const SizedBox(height: 8),
                        Text(
                          cat.name,
                          textAlign: TextAlign.center,
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style: TextStyle(
                            color: isSelected
                                ? const Color(0xff7B4DFF)
                                : textColor,
                            fontSize: 11,
                            fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  );
                },
              ),
              const SizedBox(height: 25),
            ],

            // Transaction Detail Entry Card (Amount, Payment Method, Description optional)
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isDark
                    ? null
                    : [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.05),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Text(
                        "Selected: ",
                        style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 13),
                      ),
                      Text(
                        selectedCategory,
                        style: TextStyle(
                          color: const Color(0xff7B4DFF),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),

                  // Amount Field
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: "Enter Amount (e.g. ₹250)",
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 16),
                      prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xff7B4DFF)),
                      filled: true,
                      fillColor: isDark ? const Color(0xff121212) : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Payment Method Dropdown
                  Container(
                    decoration: BoxDecoration(
                      color: isDark ? const Color(0xff121212) : Colors.grey.shade100,
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                    ),
                    padding: const EdgeInsets.symmetric(horizontal: 14),
                    child: DropdownButtonHideUnderline(
                      child: DropdownButtonFormField<String>(
                        dropdownColor: cardColor,
                        value: selectedPayment,
                        isExpanded: true,
                        style: TextStyle(color: textColor, fontSize: 15),
                        decoration: const InputDecoration(
                          border: InputBorder.none,
                          labelText: "Payment Method",
                          prefixIcon: Icon(Icons.account_balance_wallet_outlined, color: Color(0xff7B4DFF)),
                        ),
                        items: paymentMethods
                            .map((e) => DropdownMenuItem(
                              value: e,
                              child: Row(
                                children: [
                                  Text(paymentMethodEmojis[e] ?? "\u{1F4B0}", style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 10),
                                  Text(e, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            ))
                            .toList(),
                        onChanged: (val) => setState(() => selectedPayment = val!),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Optional Description Field
                  TextField(
                    controller: descriptionController,
                    style: TextStyle(color: textColor, fontSize: 15),
                    decoration: InputDecoration(
                      hintText: "Description / Notes (Optional)",
                      hintStyle: TextStyle(color: isDark ? Colors.white38 : Colors.grey.shade400, fontSize: 14),
                      prefixIcon: const Icon(Icons.notes_outlined, color: Color(0xff7B4DFF)),
                      filled: true,
                      fillColor: isDark ? const Color(0xff121212) : Colors.grey.shade100,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(14),
                        borderSide: BorderSide.none,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),

                  // Date Picker Row
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: selectedDate,
                        firstDate: DateTime(2023),
                        lastDate: DateTime(2035),
                      );
                      if (picked != null) setState(() => selectedDate = picked);
                    },
                    borderRadius: BorderRadius.circular(14),
                    child: Container(
                      padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
                      decoration: BoxDecoration(
                        color: isDark ? const Color(0xff121212) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Row(
                        children: [
                          const Icon(Icons.calendar_month, color: Color(0xff7B4DFF)),
                          const SizedBox(width: 12),
                          Text(
                            "Date: ${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                            style: TextStyle(color: textColor, fontSize: 15, fontWeight: FontWeight.w500),
                          ),
                          const Spacer(),
                          Icon(Icons.arrow_drop_down, color: textColor),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Save Button
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saveTransaction,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff7B4DFF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: Text(
                        "SAVE ${transactionType.toUpperCase()}",
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
          ],
        ),
      ),
    );
  }

  Widget _tabSegment(String type, bool isDark) {
    final isSelected = transactionType == type;
    return Expanded(
      child: GestureDetector(
        onTap: () => setState(() => transactionType = type),
        child: Container(
          decoration: BoxDecoration(
            color: isSelected ? Colors.white : Colors.transparent,
            borderRadius: BorderRadius.circular(10),
            boxShadow: isSelected
                ? [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.1),
                      blurRadius: 4,
                    )
                  ]
                : null,
          ),
          child: Center(
            child: Text(
              type,
              style: TextStyle(
                color: isSelected
                    ? Colors.black87
                    : isDark
                        ? Colors.white60
                        : Colors.black54,
                fontWeight: isSelected ? FontWeight.bold : FontWeight.w500,
                fontSize: 14,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
