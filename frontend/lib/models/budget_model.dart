class BudgetModel {
  final int? id;
  final double amount;

  BudgetModel({
    this.id,
    required this.amount,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'amount': amount,
    };
  }

  factory BudgetModel.fromMap(Map<String, dynamic> map) {
    return BudgetModel(
      id: map['id'],
      amount: map['amount'],
    );
  }
}