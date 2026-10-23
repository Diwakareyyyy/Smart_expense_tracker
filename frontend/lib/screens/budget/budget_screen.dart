import 'package:flutter/material.dart';
import '../../core/theme/theme_extensions.dart';
import '../../services/database_service.dart';
import '../../widgets/bottom_navbar.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({super.key});

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final TextEditingController budgetController = TextEditingController();
  double currentBudget = 0;
  bool isSetNewMode = false;

  @override
  void initState() {
    super.initState();
    _loadCurrentBudget();
  }

  Future<void> _loadCurrentBudget() async {
    final b = await DatabaseService.instance.getBudget();
    if (mounted) {
      setState(() {
        currentBudget = b;
      });
    }
  }

  @override
  void dispose() {
    budgetController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBg,
      appBar: AppBar(
        backgroundColor: context.appBg,
        elevation: 0,
        title: Text("Monthly Budget", style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: context.textPrimary),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentRoute: '/budget'),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff7B4DFF), Color(0xff9D74FF)],
                ),
                borderRadius: BorderRadius.circular(22),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    "Current Budget",
                    style: const TextStyle(color: Colors.white70, fontSize: 16),
                  ),
                  const SizedBox(height: 10),
                  Text(
                    "₹${currentBudget.toStringAsFixed(0)}",
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 25),
            Row(
              children: [
                Expanded(
                  child: FilterChip(
                    label: Center(
                      child: Text(
                        "Add to Budget",
                        style: TextStyle(
                          color: !isSetNewMode ? Colors.white : context.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    selected: !isSetNewMode,
                    selectedColor: const Color(0xff7B4DFF),
                    backgroundColor: context.cardBg,
                    onSelected: (_) => setState(() => isSetNewMode = false),
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: FilterChip(
                    label: Center(
                      child: Text(
                        "Set New Target Budget",
                        style: TextStyle(
                          color: isSetNewMode ? Colors.white : context.textPrimary,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                    selected: isSetNewMode,
                    selectedColor: const Color(0xff7B4DFF),
                    backgroundColor: context.cardBg,
                    onSelected: (_) => setState(() => isSetNewMode = true),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 25),
            TextField(
              controller: budgetController,
              keyboardType: TextInputType.number,
              style: TextStyle(color: context.textPrimary),
              decoration: InputDecoration(
                hintText: isSetNewMode ? "Enter New Total Budget Amount" : "Enter Amount to Add (e.g. 500)",
                hintStyle: TextStyle(color: context.textMuted),
                filled: true,
                fillColor: context.inputFill,
                prefixIcon: Icon(
                  isSetNewMode ? Icons.account_balance_wallet : Icons.add_circle,
                  color: const Color(0xff7B4DFF),
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(15),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
            const SizedBox(height: 30),
            SizedBox(
              width: double.infinity,
              height: 55,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xff7B4DFF),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                ),
                onPressed: () async {
                  final amount = double.tryParse(budgetController.text) ?? 0;
                  if (amount <= 0) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(content: Text("Please enter a valid amount")),
                    );
                    return;
                  }

                  final messenger = ScaffoldMessenger.of(context);
                  final navigator = Navigator.of(context);

                  if (isSetNewMode) {
                    await DatabaseService.instance.saveBudget(amount);
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text("Budget reset to ₹${amount.toStringAsFixed(0)}")),
                      );
                    }
                  } else {
                    final newBudget = await DatabaseService.instance.addBudget(amount);
                    if (mounted) {
                      messenger.showSnackBar(
                        SnackBar(content: Text("Added ₹${amount.toStringAsFixed(0)}. Total Budget: ₹${newBudget.toStringAsFixed(0)}")),
                      );
                    }
                  }

                  if (mounted) navigator.pop();
                },
                child: Text(
                  isSetNewMode ? "RESET & SAVE BUDGET" : "ADD TO BUDGET",
                  style: const TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
