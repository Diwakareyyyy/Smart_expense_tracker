import 'dart:convert';

import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'database_service.dart';

class AppNotification {
  final String id;
  final String title;
  final String body;
  final DateTime timestamp;

  AppNotification({
    required this.id,
    required this.title,
    required this.body,
    required this.timestamp,
  });

  Map<String, dynamic> toJson() => {
        'id': id,
        'title': title,
        'body': body,
        'timestamp': timestamp.toIso8601String(),
      };

  factory AppNotification.fromJson(Map<String, dynamic> json) =>
      AppNotification(
        id: json['id'] as String,
        title: json['title'] as String,
        body: json['body'] as String,
        timestamp: DateTime.parse(json['timestamp'] as String),
      );
}

class NotificationService {
  NotificationService._();
  static final NotificationService instance = NotificationService._();

  final FlutterLocalNotificationsPlugin _plugin =
      FlutterLocalNotificationsPlugin();

  static const String _storageKey = 'inAppNotifications';

  bool _initialized = false;

  Future<void> initialize() async {
    if (_initialized) return;

    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const initSettings = InitializationSettings(android: androidSettings);

    await _plugin.initialize(initSettings);
    _initialized = true;
  }

  Future<List<AppNotification>> getNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_storageKey);
    if (raw == null) return [];

    final list = jsonDecode(raw) as List;
    return list
        .map((e) => AppNotification.fromJson(e as Map<String, dynamic>))
        .toList()
      ..sort((a, b) => b.timestamp.compareTo(a.timestamp));
  }

  Future<void> _addInAppNotification({
    required String title,
    required String body,
  }) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getNotifications();

    existing.insert(
      0,
      AppNotification(
        id: DateTime.now().millisecondsSinceEpoch.toString(),
        title: title,
        body: body,
        timestamp: DateTime.now(),
      ),
    );

    await prefs.setString(
      _storageKey,
      jsonEncode(existing.map((n) => n.toJson()).toList()),
    );
  }

  Future<void> deleteNotification(String id) async {
    final prefs = await SharedPreferences.getInstance();
    final existing = await getNotifications();
    existing.removeWhere((n) => n.id == id);
    await prefs.setString(
      _storageKey,
      jsonEncode(existing.map((n) => n.toJson()).toList()),
    );
  }

  Future<void> clearAllNotifications() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_storageKey);
  }

  Future<void> checkAndNotifyBudgetAlerts() async {
    await initialize();

    final transactions = await DatabaseService.instance.getTransactions();
    final budget = await DatabaseService.instance.getBudget();

    if (budget <= 0) return;

    double totalExpense = 0;
    final Map<String, double> categoryTotals = {};

    for (final t in transactions) {
      if (t.type == "Expense") {
        totalExpense += t.amount;
        categoryTotals[t.category] =
            (categoryTotals[t.category] ?? 0) + t.amount;
      }
    }

    if (totalExpense >= budget) {
      await _showNotification(
        id: 1,
        title: "Budget Exceeded!",
        body:
            "You've crossed your budget by ₹${(totalExpense - budget).toStringAsFixed(0)}. Review your spending.",
      );
    } else if (totalExpense >= budget * 0.8) {
      await _showNotification(
        id: 2,
        title: "Getting Close to Budget",
        body:
            "You've used ${(totalExpense / budget * 100).toStringAsFixed(0)}% of your monthly budget.",
      );
    }

    await _checkWeeklyCategorySpending(categoryTotals);
  }

  Future<void> _checkWeeklyCategorySpending(
    Map<String, double> categoryTotals,
  ) async {
    final now = DateTime.now();
    final weekAgo = now.subtract(const Duration(days: 7));

    final transactions = await DatabaseService.instance.getTransactions();
    final Map<String, double> weeklyTotals = {};

    for (final t in transactions) {
      if (t.type != "Expense") continue;
      final date = DateTime.tryParse(t.date);
      if (date == null || date.isBefore(weekAgo)) continue;
      weeklyTotals[t.category] = (weeklyTotals[t.category] ?? 0) + t.amount;
    }

    if (weeklyTotals.isEmpty) return;

    final topEntry = weeklyTotals.entries.reduce(
      (a, b) => a.value > b.value ? a : b,
    );

    if (topEntry.value > 500) {
      await _showNotification(
        id: 3,
        title: "Weekly Spending Insight",
        body:
            "You spent ₹${topEntry.value.toStringAsFixed(0)} on ${topEntry.key} this week — more than other categories.",
      );
    }
  }

  Future<void> notifyExpenseAdded(String category, double amount) async {
    await initialize();

    await _showNotification(
      id: DateTime.now().millisecondsSinceEpoch % 100000,
      title: "Expense Added",
      body: "₹${amount.toStringAsFixed(0)} added to $category.",
    );

    await checkAndNotifyBudgetAlerts();
  }

  Future<void> notifyPaymentSuccess(String merchant, String category) async {
    await initialize();

    await _showNotification(
      id: 4,
      title: "Payment Successful",
      body: "Payment to $merchant recorded under $category.",
    );
  }

  Future<void> _showNotification({
    required int id,
    required String title,
    required String body,
  }) async {
    await _addInAppNotification(title: title, body: body);

    const androidDetails = AndroidNotificationDetails(
      'expense_tracker_channel',
      'Expense Tracker Alerts',
      channelDescription: 'Budget and spending notifications',
      importance: Importance.high,
      priority: Priority.high,
    );

    const details = NotificationDetails(android: androidDetails);

    await _plugin.show(id, title, body, details);
  }
}
