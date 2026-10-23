import 'package:flutter/foundation.dart';

class TransactionNotifier extends ChangeNotifier {
  TransactionNotifier._();

  static final TransactionNotifier instance = TransactionNotifier._();

  void notifyTransactionChanged() {
    notifyListeners();
  }
}
