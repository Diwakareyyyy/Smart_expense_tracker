import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';

import '../core/theme/theme_extensions.dart';
import '../models/transaction_model.dart';

class TransactionTile extends StatelessWidget {
  final TransactionModel transaction;
  final VoidCallback? onDelete;

  const TransactionTile({
    super.key,
    required this.transaction,
    this.onDelete,
  });

  @override
  Widget build(BuildContext context) {
    final bool isIncome = transaction.type == "Income";

    Widget card = Card(
      color: context.cardBg,
      elevation: context.isDarkTheme ? 0 : 1,
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: ListTile(
        leading: CircleAvatar(
          backgroundColor: isIncome ? Colors.green : Colors.red,
          child: Icon(
            isIncome ? Icons.arrow_downward : Icons.arrow_upward,
            color: Colors.white,
          ),
        ),
        title: Text(
          transaction.description,
          style: TextStyle(
            color: context.textPrimary,
            fontWeight: FontWeight.bold,
          ),
        ),
        subtitle: Text(
          "${transaction.category}\n${transaction.paymentMethod}",
          style: TextStyle(color: context.textSecondary),
        ),
        isThreeLine: true,
        trailing: Text(
          "${isIncome ? "+" : "-"} ₹${transaction.amount.toStringAsFixed(2)}",
          style: TextStyle(
            color: isIncome ? Colors.green : Colors.redAccent,
            fontWeight: FontWeight.bold,
            fontSize: 16,
          ),
        ),
      ),
    );

    if (onDelete == null) {
      return card;
    }

    return Slidable(
      key: ValueKey(transaction.id),
      endActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          _buildDeleteAction(),
        ],
      ),
      startActionPane: ActionPane(
        motion: const DrawerMotion(),
        extentRatio: 0.25,
        children: [
          _buildDeleteAction(),
        ],
      ),
      child: card,
    );
  }

  Widget _buildDeleteAction() {
    return SlidableAction(
      onPressed: (_) => onDelete?.call(),
      backgroundColor: Colors.red,
      foregroundColor: Colors.white,
      icon: Icons.delete,
      label: 'Delete',
      borderRadius: BorderRadius.circular(16),
    );
  }
}
