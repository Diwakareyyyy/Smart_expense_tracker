import 'package:flutter/material.dart';

import '../../core/theme/theme_extensions.dart';
import '../../models/transaction_model.dart';
import '../../services/database_service.dart';
import '../../providers/transaction_notifier.dart';
import '../../widgets/transaction_title.dart';
import '../../widgets/bottom_navbar.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  List<TransactionModel> allTransactions = [];
  List<TransactionModel> filteredTransactions = [];

  final TextEditingController searchController = TextEditingController();

  String selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    loadTransactions();
  }

  Future<void> loadTransactions() async {
    final data = await DatabaseService.instance.getTransactions();

    setState(() {
      allTransactions = data;
      filteredTransactions = data;
    });
  }

  void applyFilters() {
    setState(() {
      filteredTransactions = allTransactions.where((transaction) {
        final search = searchController.text.toLowerCase();

        final matchesSearch = transaction.description
                .toLowerCase()
                .contains(search) ||
            transaction.category
                .toLowerCase()
                .contains(search) ||
            transaction.type
                .toLowerCase()
                .contains(search);

        final matchesFilter = selectedFilter == "All"
            ? true
            : transaction.paymentMethod.toUpperCase() ==
                selectedFilter.toUpperCase();

        return matchesSearch && matchesFilter;
      }).toList();
    });
  }

  void searchTransaction(String value) {
    applyFilters();
  }

  void filterTransactions(String filter) {
    selectedFilter = filter;
    applyFilters();
  }

  Future<void> deleteTransaction(int id) async {
    await DatabaseService.instance.deleteTransaction(id);

    await loadTransactions();

    TransactionNotifier.instance.notifyTransactionChanged();

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text("Transaction Deleted"),
      ),
    );
  }

  Widget filterChip(String text) {
    final selected = selectedFilter == text;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 6),
      child: ChoiceChip(
        label: Text(text),
        selected: selected,
        selectedColor: const Color(0xff7B4DFF),
        backgroundColor: context.cardBg,
        labelStyle: TextStyle(
          color: selected ? Colors.white : context.textSecondary,
          fontWeight: FontWeight.bold,
        ),
        onSelected: (_) {
          filterTransactions(text);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBg,
      appBar: AppBar(
        backgroundColor: context.appBg,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text(
          "Transaction History",
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
        ),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentRoute: '/history'),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.all(16),
            child: TextField(
              controller: searchController,
              onChanged: searchTransaction,
              style: TextStyle(color: context.textPrimary),
              decoration: InputDecoration(
                hintText: "Search transactions...",
                hintStyle: TextStyle(color: context.textMuted),
                prefixIcon: Icon(Icons.search, color: context.textSecondary),
                filled: true,
                fillColor: context.inputFill,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide.none,
                ),
              ),
            ),
          ),

          /// Filters
          SizedBox(
            height: 50,
            child: ListView(
              scrollDirection: Axis.horizontal,
              padding: const EdgeInsets.symmetric(horizontal: 12),
              children: [
                filterChip("All"),
                filterChip("UPI"),
                filterChip("CARD"),
                filterChip("CASH"),
                filterChip("BANK"),
              ],
            ),
          ),

          const SizedBox(height: 12),

          /// Transactions List
          Expanded(
            child: filteredTransactions.isEmpty
                ? Center(
                    child: Text(
                      "No Transactions Found",
                      style: TextStyle(
                        color: context.textSecondary,
                        fontSize: 18,
                      ),
                    ),
                  )
                : ListView.builder(
                    itemCount: filteredTransactions.length,
                    itemBuilder: (context, index) {
                      final transaction = filteredTransactions[index];

                      return TransactionTile(
                        transaction: transaction,
                        onDelete: () {
                          deleteTransaction(
                            transaction.id!,
                          );
                        },
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}