import 'package:flutter/material.dart';
import '../../core/theme/theme_extensions.dart';
import '../../core/constants/payment_methods.dart';
import '../../models/transaction_model.dart';
import '../../services/database_service.dart';
import '../../widgets/bottom_navbar.dart';

class AddTransferScreen extends StatefulWidget {
  const AddTransferScreen({super.key});

  @override
  State<AddTransferScreen> createState() => _AddTransferScreenState();
}

class _AddTransferScreenState extends State<AddTransferScreen> {
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

  Future<void> saveTransfer() async {
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
    String finalDesc = rawDesc.isNotEmpty ? "Transfer ($selectedPayment): $rawDesc" : "Transfer ($selectedPayment)";

    final transfer = TransactionModel(
      amount: amount,
      description: finalDesc,
      category: "Transfer",
      paymentMethod: selectedPayment,
      date: selectedDate.toIso8601String(),
      type: "Transfer",
    );

    await DatabaseService.instance.insertTransaction(transfer);

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Transfer Saved Successfully"), backgroundColor: Colors.green),
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
        title: Text("Add Transfer", style: TextStyle(color: context.textPrimary)),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentRoute: '/add-transfer'),
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
            Container(
              decoration: BoxDecoration(
                color: context.inputFill,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: context.isDarkTheme ? Colors.white12 : Colors.grey.shade200),
              ),
              padding: const EdgeInsets.symmetric(horizontal: 14),
              child: DropdownButtonHideUnderline(
                child: DropdownButtonFormField<String>(
                  dropdownColor: context.inputFill,
                  value: selectedPayment,
                  isExpanded: true,
                  style: TextStyle(color: context.textPrimary, fontSize: 15),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                    labelText: "From Account",
                    prefixIcon: Icon(Icons.account_balance_wallet_outlined, color: Color(0xff7B4DFF)),
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
                  onChanged: (val) => setState(() => selectedPayment = val!),
                ),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: descriptionController,
              style: TextStyle(color: context.textPrimary),
              decoration: _inputDecoration(context, "Description (Optional)", Icons.description),
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
                onPressed: saveTransfer,
                style: ElevatedButton.styleFrom(backgroundColor: const Color(0xff7B4DFF)),
                child: const Text("SAVE TRANSFER", style: TextStyle(fontSize: 18, color: Colors.white)),
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
