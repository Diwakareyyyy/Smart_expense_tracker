class TransactionModel {
  final int? id;
  final String? userEmail;
  final double amount;
  final String description;
  final String category;
  final String paymentMethod;
  final String date;
  final String type; // Income or Expense

  TransactionModel({
    this.id,
    this.userEmail,
    required this.amount,
    required this.description,
    required this.category,
    required this.paymentMethod,
    required this.date,
    required this.type,
  });

  Map<String, dynamic> toMap() {
    return {
      'id': id,
      'userEmail': userEmail,
      'amount': amount,
      'description': description,
      'category': category,
      'paymentMethod': paymentMethod,
      'date': date,
      'type': type,
    };
  }

  factory TransactionModel.fromMap(Map<String, dynamic> map) {
    return TransactionModel(
      id: map['id'],
      userEmail: map['userEmail'],
      amount: map['amount'],
      description: map['description'],
      category: map['category'],
      paymentMethod: map['paymentMethod'],
      date: map['date'],
      type: map['type'],
    );
  }
}