import 'dart:convert';
import 'package:path/path.dart';
import 'package:sqflite/sqflite.dart';

import '../models/transaction_model.dart';
import 'auth_service.dart';
import 'api_client.dart';

class DatabaseService {
  DatabaseService._();

  static final DatabaseService instance = DatabaseService._();

  static Database? _database;

  Future<Database> get database async {
    if (_database != null) return _database!;

    _database = await _initDatabase();

    return _database!;
  }

  Future<String> _getEffectiveUserEmail(String? providedEmail) async {
    if (providedEmail != null && providedEmail.trim().isNotEmpty) {
      return providedEmail.trim().toLowerCase();
    }
    final loggedInEmail = await AuthService.instance.getEmail();
    if (loggedInEmail != null && loggedInEmail.trim().isNotEmpty) {
      return loggedInEmail.trim().toLowerCase();
    }
    return AuthService.defaultEmail.toLowerCase();
  }

  Future<Database> _initDatabase() async {
    final dbPath = await getDatabasesPath();
    final path = join(dbPath, "expense_tracker.db");

    return await openDatabase(
      path,
      version: 2,
      onCreate: _createDatabase,
      onUpgrade: _upgradeDatabase,
    );
  }

  Future<void> _createDatabase(Database db, int version) async {
    // Transactions Table
    await db.execute('''
      CREATE TABLE transactions(
        id INTEGER PRIMARY KEY AUTOINCREMENT,
        userEmail TEXT,
        amount REAL,
        description TEXT,
        category TEXT,
        paymentMethod TEXT,
        date TEXT,
        type TEXT
      )
    ''');

    // Budget Table
    await db.execute('''
      CREATE TABLE budget(
        userEmail TEXT PRIMARY KEY,
        amount REAL
      )
    ''');
  }

  Future<void> _upgradeDatabase(Database db, int oldVersion, int newVersion) async {
    if (oldVersion < 2) {
      await db.execute('ALTER TABLE transactions ADD COLUMN userEmail TEXT');
      await db.execute(
        'UPDATE transactions SET userEmail = ? WHERE userEmail IS NULL OR userEmail = ""',
        [AuthService.defaultEmail.toLowerCase()],
      );
      await db.execute('CREATE TABLE IF NOT EXISTS budget_new (userEmail TEXT PRIMARY KEY, amount REAL)');
      await db.execute(
        'INSERT OR IGNORE INTO budget_new (userEmail, amount) SELECT ?, amount FROM budget',
        [AuthService.defaultEmail.toLowerCase()],
      );
      await db.execute('DROP TABLE IF EXISTS budget');
      await db.execute('ALTER TABLE budget_new RENAME TO budget');
    }
  }

  /// Insert Transaction
  Future<int> insertTransaction(TransactionModel transaction, {String? userEmail}) async {
    final email = await _getEffectiveUserEmail(userEmail ?? transaction.userEmail);

    try {
      final response = await ApiClient.instance.post(
        "/api/transactions/",
        body: jsonEncode({
          "amount": transaction.amount,
          "description": transaction.description,
          "category": transaction.category,
          "payment_method": transaction.paymentMethod,
          "type": transaction.type,
        }),
      );
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final backendId = data["id"] as int;

        // Write to local SQLite with backend ID
        final db = await database;
        final map = transaction.toMap();
        map['id'] = backendId;
        map['userEmail'] = email;
        await db.insert(
          "transactions",
          map,
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return backendId;
      }
    } catch (e) {
      print("DatabaseService: insertTransaction backend error: $e");
    }

    // Fallback: Local SQLite
    final db = await database;
    final map = transaction.toMap();
    map['userEmail'] = email;
    return await db.insert(
      "transactions",
      map,
    );
  }

  /// Get Transactions for User
  Future<List<TransactionModel>> getTransactions({String? userEmail}) async {
    final email = await _getEffectiveUserEmail(userEmail);

    try {
      final response = await ApiClient.instance.get("/api/transactions/");
      if (response.statusCode == 200) {
        final List<dynamic> dataList = jsonDecode(response.body);
        final List<TransactionModel> backendTransactions = dataList.map((item) {
          return TransactionModel(
            id: item["id"],
            userEmail: email,
            amount: (item["amount"] as num).toDouble(),
            description: item["description"] ?? "",
            category: item["category"] ?? "Uncategorized",
            paymentMethod: item["payment_method"] ?? "",
            date: item["date"] ?? "",
            type: item["type"] ?? "Expense",
          );
        }).toList();

        // Sync local SQLite cache
        final db = await database;
        await db.delete(
          "transactions",
          where: "LOWER(userEmail) = ?",
          whereArgs: [email],
        );
        for (var t in backendTransactions) {
          final map = t.toMap();
          map['userEmail'] = email;
          await db.insert("transactions", map, conflictAlgorithm: ConflictAlgorithm.replace);
        }
        return backendTransactions;
      }
    } catch (e) {
      print("DatabaseService: getTransactions backend error: $e");
    }

    // Fallback: local SQLite cache
    final db = await database;
    final result = await db.query(
      "transactions",
      where: "LOWER(userEmail) = ?",
      whereArgs: [email],
      orderBy: "id DESC",
    );

    return result
        .map((e) => TransactionModel.fromMap(e))
        .toList();
  }

  /// Get Transactions by Category
  Future<List<TransactionModel>> getTransactionsByCategory(String category, {String? userEmail}) async {
    final all = await getTransactions(userEmail: userEmail);
    return all.where((t) => t.category.toLowerCase() == category.toLowerCase()).toList();
  }

  /// Delete Transaction
  Future<int> deleteTransaction(int id) async {
    try {
      final response = await ApiClient.instance.delete("/api/transactions/$id");
      if (response.statusCode == 200) {
        print("DatabaseService: Deleted from backend successfully");
      }
    } catch (e) {
      print("DatabaseService: deleteTransaction backend error: $e");
    }

    final db = await database;
    return await db.delete(
      "transactions",
      where: "id=?",
      whereArgs: [id],
    );
  }

  /// Update Transaction
  Future<int> updateTransaction(TransactionModel transaction, {String? userEmail}) async {
    final email = await _getEffectiveUserEmail(userEmail ?? transaction.userEmail);

    if (transaction.id != null) {
      try {
        final response = await ApiClient.instance.put(
          "/api/transactions/${transaction.id}",
          body: jsonEncode({
            "amount": transaction.amount,
            "description": transaction.description,
            "category": transaction.category,
            "payment_method": transaction.paymentMethod,
            "type": transaction.type,
          }),
        );
        if (response.statusCode == 200) {
          print("DatabaseService: Updated on backend successfully");
        }
      } catch (e) {
        print("DatabaseService: updateTransaction backend error: $e");
      }
    }

    final db = await database;
    final map = transaction.toMap();
    map['userEmail'] = email;

    return await db.update(
      "transactions",
      map,
      where: "id=?",
      whereArgs: [transaction.id],
    );
  }

  /// Save Budget for User (Sets exact amount)
  Future<void> saveBudget(double amount, {String? userEmail}) async {
    final email = await _getEffectiveUserEmail(userEmail);

    try {
      final response = await ApiClient.instance.post(
        "/api/budget/",
        body: jsonEncode({
          "amount": amount,
        }),
      );
      if (response.statusCode == 200) {
        print("DatabaseService: Saved budget to backend successfully");
      }
    } catch (e) {
      print("DatabaseService: saveBudget backend error: $e");
    }

    final db = await database;
    await db.insert(
      "budget",
      {
        "userEmail": email,
        "amount": amount,
      },
      conflictAlgorithm: ConflictAlgorithm.replace,
    );
  }

  /// Add to existing budget
  Future<double> addBudget(double additionalAmount, {String? userEmail}) async {
    final currentBudget = await getBudget(userEmail: userEmail);
    final newBudget = currentBudget + additionalAmount;
    await saveBudget(newBudget, userEmail: userEmail);
    return newBudget;
  }

  /// Get Budget for User
  Future<double> getBudget({String? userEmail}) async {
    final email = await _getEffectiveUserEmail(userEmail);

    try {
      final response = await ApiClient.instance.get("/api/budget/");
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final amount = (data["amount"] as num).toDouble();

        // Save locally
        final db = await database;
        await db.insert(
          "budget",
          {
            "userEmail": email,
            "amount": amount,
          },
          conflictAlgorithm: ConflictAlgorithm.replace,
        );
        return amount;
      }
    } catch (e) {
      print("DatabaseService: getBudget backend error: $e");
    }

    final db = await database;
    final result = await db.query(
      "budget",
      where: "LOWER(userEmail) = ?",
      whereArgs: [email],
    );

    if (result.isEmpty) {
      return 0.0;
    }

    return (result.first["amount"] as num).toDouble();
  }

  /// Financial Summary for AI (includes category totals + recent transactions)
  Future<String> getFinancialSummary({String? userEmail}) async {
    final transactions = await getTransactions(userEmail: userEmail);
    final budget = await getBudget(userEmail: userEmail);

    double totalIncome = 0;
    double totalExpense = 0;

    Map<String, double> categoryTotals = {};
    List<TransactionModel> recentExpenses = [];

    for (var t in transactions) {
      if (t.type == "Income") {
        totalIncome += t.amount;
      } else {
        totalExpense += t.amount;
        categoryTotals[t.category] =
            (categoryTotals[t.category] ?? 0) + t.amount;
        recentExpenses.add(t);
      }
    }

    double remainingBudget = budget - totalExpense;

    String summary = "";

    summary += "Total Income: ₹${totalIncome.toStringAsFixed(2)}\n";
    summary += "Total Expense: ₹${totalExpense.toStringAsFixed(2)}\n";
    summary += "Budget: ₹${budget.toStringAsFixed(2)}\n";
    summary +=
        "Remaining Budget: ₹${remainingBudget.toStringAsFixed(2)}\n\n";

    summary += "Category Spending:\n";

    categoryTotals.forEach((category, amount) {
      summary +=
          "- $category : ₹${amount.toStringAsFixed(2)}\n";
    });

    summary += "\nAll Recorded Transactions:\n";
    for (var t in recentExpenses) {
      final dateParts = t.date.split('T').first.split('-');
      final formattedDate = dateParts.length == 3 ? "${dateParts[2]}/${dateParts[1]}/${dateParts[0]}" : t.date.split('T').first;
      summary += "  [$formattedDate] ${t.category}: ${t.description} - ₹${t.amount.toStringAsFixed(2)}\n";
    }

    return summary;
  }
}