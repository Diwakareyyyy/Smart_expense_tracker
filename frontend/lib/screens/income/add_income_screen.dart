import 'package:flutter/material.dart';

import '../../core/theme/theme_extensions.dart';
import '../../core/constants/income_categories.dart';
import '../../core/constants/payment_methods.dart';
import '../../models/transaction_model.dart';
import '../../services/database_service.dart';
import '../../widgets/bottom_navbar.dart';

class AddIncomeScreen extends StatefulWidget {
  const AddIncomeScreen({super.key});

  @override
  State<AddIncomeScreen> createState() => _AddIncomeScreenState();
}

class _AddIncomeScreenState extends State<AddIncomeScreen> {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  String selectedCategory = incomeCategories.first;
  String selectedPayment = paymentMethods.first;

  DateTime selectedDate = DateTime.now();

  String _incomeCategoryEmoji(String category) {
    const emojis = {
      "Salary": "\u{1F4B0}",
      "Business": "\u{1F4BC}",
      "Freelancing": "\u{1F4BB}",
      "Investment": "\u{1F4C8}",
      "Gift": "\u{1F381}",
      "Bonus": "\u{1F3C6}",
      "Interest": "\u{1F4B9}",
      "Other": "\u{1F4E6}",
    };
    return emojis[category] ?? "\u{1F4B0}";
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> saveIncome() async {
    if (amountController.text.isEmpty ||
        descriptionController.text.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Please fill all fields"),
        ),
      );
      return;
    }

    final income = TransactionModel(
      amount: double.parse(amountController.text),
      description: descriptionController.text,
      category: selectedCategory,
      paymentMethod: selectedPayment,
      date: selectedDate.toIso8601String(),
      type: "Income",
    );

    await DatabaseService.instance.insertTransaction(income);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Income Added Successfully"),
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBg,
      appBar: AppBar(
        backgroundColor: context.appBg,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text("Add Income", style: TextStyle(color: context.textPrimary)),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentRoute: '/add-income'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            TextField(
              controller: amountController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: context.textPrimary),
              decoration: _inputDecoration(context, "Amount", Icons.currency_rupee),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: descriptionController,
              style: TextStyle(color: context.textPrimary),
              decoration: _inputDecoration(context, "Description", Icons.description),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: context.inputFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.isDarkTheme ? Colors.white12 : Colors.grey.shade200),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String>(
                  value: selectedCategory,
                  dropdownColor: context.inputFill,
                  isExpanded: true,
                  style: TextStyle(color: context.textPrimary),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: "Income Category",
                    prefixIcon: Icon(Icons.category, color: Color(0xff7B4DFF)),
                  ),
                  items: incomeCategories.map((e) {
                    return DropdownMenuItem(
                      value: e,
                      child: Row(
                        children: [
                          Text(_incomeCategoryEmoji(e), style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Text(e, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedCategory = value!),
                ),
              ),
            ),
            const SizedBox(height: 20),
            Container(
              decoration: BoxDecoration(
                color: context.inputFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.isDarkTheme ? Colors.white12 : Colors.grey.shade200),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String>(
                  value: selectedPayment,
                  dropdownColor: context.inputFill,
                  isExpanded: true,
                  style: TextStyle(color: context.textPrimary),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: "Payment Method",
                    prefixIcon: Icon(Icons.account_balance_wallet, color: Color(0xff7B4DFF)),
                  ),
                  items: paymentMethods.map((e) {
                    return DropdownMenuItem(
                      value: e,
                      child: Row(
                        children: [
                          Text(paymentMethodEmojis[e] ?? "\u{1F4B0}", style: const TextStyle(fontSize: 20)),
                          const SizedBox(width: 10),
                          Text(e, style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w500)),
                        ],
                      ),
                    );
                  }).toList(),
                  onChanged: (value) => setState(() => selectedPayment = value!),
                ),
              ),
            ),
            const SizedBox(height: 20),
            ListTile(
              tileColor: context.inputFill,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
              title: Text(
                "${selectedDate.day}/${selectedDate.month}/${selectedDate.year}",
                style: TextStyle(color: context.textPrimary),
              ),
              trailing: Icon(Icons.calendar_month, color: context.textSecondary),
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: selectedDate,
                  firstDate: DateTime(2023),
                  lastDate: DateTime(2035),
                );
                if (picked != null) setState(() => selectedDate = picked);
              },
            ),
            const SizedBox(height: 35),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                onPressed: saveIncome,
                child: const Text("SAVE INCOME", style: TextStyle(fontSize: 18)),
              ),
            ),
          ],
        ),
      ),
    );
  }

  InputDecoration _inputDecoration(BuildContext context, String hint, IconData icon) {
    return InputDecoration(
      filled: true,
      fillColor: context.inputFill,
      hintText: hint,
      hintStyle: TextStyle(color: context.textMuted),
      prefixIcon: Icon(icon, color: context.textSecondary),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
    );
  }
}