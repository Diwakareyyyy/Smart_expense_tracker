import 'package:flutter/material.dart';
import '../../models/transaction_model.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../core/constants/payment_methods.dart';

class ExpenseFormScreen extends StatefulWidget {
  final String category;

  const ExpenseFormScreen({super.key, required this.category});

  @override
  State<ExpenseFormScreen> createState() => _ExpenseFormScreenState();
}

class _ExpenseFormScreenState extends State<ExpenseFormScreen> {
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();
  String selectedPayment = paymentMethods.first;
  DateTime selectedDate = DateTime.now();

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _saveExpense() async {
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

    String rawDesc = descriptionController.text.trim();
    String finalDesc = rawDesc.isNotEmpty ? rawDesc : widget.category;

    final transaction = TransactionModel(
      amount: amount,
      description: finalDesc,
      category: widget.category,
      paymentMethod: selectedPayment,
      date: selectedDate.toIso8601String(),
      type: "Expense",
    );

    await DatabaseService.instance.insertTransaction(transaction);
    await NotificationService.instance.notifyExpenseAdded(widget.category, amount);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text("Expense Saved Successfully (\u20b9${amount.toStringAsFixed(0)})"),
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
          "Add Expense",
          style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 20),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 10),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(20),
                boxShadow: isDark ? null : [
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
                        "Category: ",
                        style: TextStyle(color: isDark ? Colors.white54 : Colors.grey, fontSize: 13),
                      ),
                      Text(
                        widget.category,
                        style: const TextStyle(
                          color: Color(0xff7B4DFF),
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: amountController,
                    keyboardType: const TextInputType.numberWithOptions(decimal: true),
                    style: TextStyle(color: textColor, fontSize: 22, fontWeight: FontWeight.bold),
                    decoration: InputDecoration(
                      hintText: "Enter Amount (e.g. \u20b9250)",
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
                  SizedBox(
                    width: double.infinity,
                    height: 52,
                    child: ElevatedButton(
                      onPressed: _saveExpense,
                      style: ElevatedButton.styleFrom(
                        backgroundColor: const Color(0xff7B4DFF),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                      ),
                      child: const Text(
                        "SAVE EXPENSE",
                        style: TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
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
}
