import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:provider/provider.dart';
import '../../core/theme/theme_extensions.dart';
import '../../widgets/notifications_panel.dart';
import '../../widgets/bottom_navbar.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../services/auth_service.dart';
import '../../providers/user_provider.dart';
import '../../providers/transaction_notifier.dart';
import '../../models/transaction_model.dart';
import '../../widgets/profile_avatar.dart';
import '../../core/constants/categories.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  double income = 0;
  double expense = 0;
  double budget = 0;
  bool budgetAlertShown = false;
  List<TransactionModel> transactions = [];

  @override
  void initState() {
    super.initState();
    TransactionNotifier.instance.addListener(_onTransactionsChanged);
    loadTransactions();
    _loadUserName();
  }

  @override
  void dispose() {
    TransactionNotifier.instance.removeListener(_onTransactionsChanged);
    super.dispose();
  }

  void _onTransactionsChanged() {
    loadTransactions();
  }

  Future<void> _loadUserName() async {
    await context.read<UserProvider>().loadFromStorage();
  }

  Future<void> loadTransactions() async {
    final data = await DatabaseService.instance.getTransactions();
    final savedBudget = await DatabaseService.instance.getBudget();

    double totalIncome = 0;
    double totalExpense = 0;

    for (var t in data) {
      if (t.type == "Income") {
        totalIncome += t.amount;
      } else if (t.type == "Expense") {
        totalExpense += t.amount;
      }
    }

    if (!mounted) return;

    setState(() {
      transactions = data;
      income = totalIncome;
      expense = totalExpense;
      budget = savedBudget;
    });

    if (savedBudget > 0 && mounted && !budgetAlertShown) {
      if (totalExpense >= savedBudget) {
        budgetAlertShown = true;
        NotificationService.instance.checkAndNotifyBudgetAlerts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.red,
            content: Text(
              "Budget Exceeded!\nExceeded by ₹${(totalExpense - savedBudget).toStringAsFixed(0)}",
            ),
          ),
        );
      } else if (totalExpense >= savedBudget * 0.8) {
        budgetAlertShown = true;
        NotificationService.instance.checkAndNotifyBudgetAlerts();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: Colors.orange,
            content: Text(
              "Warning!\nYou've used ${(totalExpense / savedBudget * 100).toStringAsFixed(0)}% of your budget.",
            ),
          ),
        );
      }
    }
  }

  void _showSearchSheet(BuildContext context) {
    final searchController = TextEditingController();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: context.appBg,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return StatefulBuilder(
          builder: (ctx, setModalState) {
            final query = searchController.text.trim().toLowerCase();

            final searchResults = transactions.where((t) {
              if (query.isEmpty) return true;
              final cat = t.category.toLowerCase();
              final pay = t.paymentMethod.toLowerCase();
              final date = t.date.toLowerCase();
              final desc = t.description.toLowerCase();
              final amount = t.amount.toString();
              return cat.contains(query) ||
                  pay.contains(query) ||
                  date.contains(query) ||
                  desc.contains(query) ||
                  amount.contains(query);
            }).toList();

            return Padding(
              padding: EdgeInsets.fromLTRB(
                20,
                20,
                20,
                MediaQuery.of(ctx).viewInsets.bottom + 20,
              ),
              child: Container(
                constraints: BoxConstraints(
                  maxHeight: MediaQuery.of(ctx).size.height * 0.75,
                ),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          "Search",
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        IconButton(
                          icon: Icon(Icons.close, color: context.textSecondary),
                          onPressed: () => Navigator.pop(ctx),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: searchController,
                      autofocus: true,
                      style: TextStyle(color: context.textPrimary),
                      onChanged: (_) => setModalState(() {}),
                      decoration: InputDecoration(
                        hintText: "Search by date, category, UPI, amount...",
                        hintStyle: TextStyle(color: context.textMuted, fontSize: 13),
                        prefixIcon: const Icon(Icons.search, color: Color(0xff7B4DFF)),
                        suffixIcon: searchController.text.isNotEmpty
                            ? IconButton(
                                icon: const Icon(Icons.clear, size: 18),
                                onPressed: () {
                                  searchController.clear();
                                  setModalState(() {});
                                },
                              )
                            : null,
                        filled: true,
                        fillColor: context.cardBg,
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide.none,
                        ),
                      ),
                    ),
                    const SizedBox(height: 15),
                    Wrap(
                      spacing: 8,
                      children: [
                        _suggestionChip("Fuel", searchController, setModalState),
                        _suggestionChip("UPI", searchController, setModalState),
                        _suggestionChip("Food", searchController, setModalState),
                        _suggestionChip("Shopping", searchController, setModalState),
                      ],
                    ),
                    const SizedBox(height: 15),
                    Expanded(
                      child: searchResults.isEmpty
                          ? Center(
                              child: Text(
                                "No transactions match '$query'",
                                style: TextStyle(color: context.textMuted),
                              ),
                            )
                          : ListView.builder(
                              itemCount: searchResults.length,
                              itemBuilder: (context, index) {
                                final t = searchResults[index];
                                final catData = getCategoryByName(t.category);
                                return Container(
                                  margin: const EdgeInsets.only(bottom: 12),
                                  padding: const EdgeInsets.all(14),
                                  decoration: BoxDecoration(
                                    color: context.cardBg,
                                    borderRadius: BorderRadius.circular(16),
                                  ),
                                  child: Row(
                                    children: [
                                      CircleAvatar(
                                        radius: 22,
                                        backgroundColor: catData.color.withValues(alpha: 0.15),
                                        child: Text(
                                          catData.emoji ?? "🏷️",
                                          style: const TextStyle(fontSize: 20),
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment: CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              t.description,
                                              style: TextStyle(
                                                color: context.textPrimary,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              "${t.category} • ${t.paymentMethod} • ${t.date.split('T').first}",
                                              style: TextStyle(
                                                color: context.textMuted,
                                                fontSize: 12,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      Text(
                                        "${t.type == "Income" ? "+" : t.type == "Transfer" ? "↔" : "-"} ₹${t.amount.toStringAsFixed(0)}",
                                        style: TextStyle(
                                          color: t.type == "Income"
                                              ? Colors.green
                                              : t.type == "Transfer"
                                                  ? Colors.blue
                                                  : Colors.redAccent,
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                    ],
                                  ),
                                );
                              },
                            ),
                    ),
                  ],
                ),
              ),
            );
          },
        );
      },
    );
  }

  Widget _buildProfileDrawer(UserProvider user) {
    return Drawer(
      width: 300,
      child: Container(
        color: context.appBg,
        child: SafeArea(
          child: Column(
            children: [
              Container(
                width: double.infinity,
                padding: const EdgeInsets.fromLTRB(20, 24, 20, 20),
                decoration: const BoxDecoration(
                  gradient: LinearGradient(
                    colors: [Color(0xff7B4DFF), Color(0xff9D74FF)],
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        ProfileAvatar(
                          photo: user.profilePhoto,
                          name: user.userName,
                          radius: 26,
                          backgroundColor: Colors.white.withValues(alpha: 0.2),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                user.userName.isNotEmpty ? user.userName : 'Diwakar',
                                style: const TextStyle(color: Colors.white, fontSize: 16, fontWeight: FontWeight.bold),
                              ),
                              Text(
                                user.userEmail.isNotEmpty ? user.userEmail : 'Premium User',
                                style: TextStyle(color: Colors.white.withValues(alpha: 0.7), fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
              Expanded(
                child: ListView(
                  padding: EdgeInsets.zero,
                  children: [
                    _drawerTile(
                      icon: Icons.home_outlined,
                      title: "Dashboard",
                      onTap: () => _navigateToRoute('/dashboard'),
                    ),
                    _drawerTile(
                      icon: Icons.pie_chart_outline_rounded,
                      title: "Analytics",
                      onTap: () => _navigateToRoute('/analytics'),
                    ),
                    _drawerTile(
                      icon: Icons.calendar_today_outlined,
                      title: "Calendar",
                      onTap: () => _navigateToRoute('/calendar'),
                    ),
                    _drawerTile(
                      icon: Icons.history_rounded,
                      title: "History",
                      onTap: () => _navigateToRoute('/history'),
                    ),
                    _drawerTile(
                      icon: Icons.account_balance_wallet_outlined,
                      title: "Budget",
                      onTap: () => _navigateToRoute('/budget'),
                    ),
                    _drawerTile(
                      icon: Icons.smart_toy_outlined,
                      title: "AI Insights",
                      onTap: () => _navigateToRoute('/ai'),
                    ),
                    _drawerTile(
                      icon: Icons.settings_outlined,
                      title: "Settings",
                      onTap: () => _navigateToRoute('/settings'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _drawerTile({
    required IconData icon,
    required String title,
    String? subtitle,
    Widget? trailing,
    VoidCallback? onTap,
  }) {
    return ListTile(
      leading: Icon(icon, color: const Color(0xff7B4DFF)),
      title: Text(
        title,
        style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.w600, fontSize: 15),
      ),
      subtitle: subtitle != null
          ? Text(subtitle, style: TextStyle(color: context.textSecondary, fontSize: 12))
          : null,
      trailing: trailing ?? (onTap != null ? const Icon(Icons.chevron_right, color: Colors.grey) : null),
      onTap: onTap,
    );
  }

  Widget _suggestionChip(String text, TextEditingController controller, void Function(void Function()) setModalState) {
    return ActionChip(
      label: Text(text, style: const TextStyle(fontSize: 12)),
      backgroundColor: const Color(0xff7B4DFF).withValues(alpha: 0.15),
      labelStyle: const TextStyle(color: Color(0xff7B4DFF), fontWeight: FontWeight.w600),
      onPressed: () {
        controller.text = text;
        setModalState(() {});
      },
    );
  }

  void _navigateToRoute(String route) {
    Navigator.pop(context);
    context.go(route);
  }

  Future<void> _handleLogout() async {
    Navigator.pop(context);
    await AuthService.instance.logout();
    if (mounted) {
      context.go('/login');
    }
  }

  @override
  Widget build(BuildContext context) {
    final balance = income - expense;
    final user = context.watch<UserProvider>();

    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: context.appBg,
      drawer: _buildProfileDrawer(user),
      onDrawerChanged: (isOpened) {
        if (isOpened) _loadUserName();
      },
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await context.push('/ai');
          if (mounted) loadTransactions();
        },
        backgroundColor: const Color(0xff7B4DFF),
        child: const Icon(Icons.smart_toy_rounded, color: Colors.white),
      ),
      floatingActionButtonLocation: FloatingActionButtonLocation.endFloat,
      bottomNavigationBar: AppBottomNavBar(
        currentRoute: '/dashboard',
        onRefreshRequired: loadTransactions,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Top Header Row with Profile, Name, Notifications & KEPT Search Icon
              Row(
                children: [
                  InkWell(
                    borderRadius: BorderRadius.circular(30),
                    onTap: () => _scaffoldKey.currentState?.openDrawer(),
                    child: CircleAvatar(
                      radius: 26,
                      backgroundColor: context.iconBg,
                      child: Icon(Icons.menu_rounded, color: context.iconFg, size: 28),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          "Hello 👋",
                          style: TextStyle(
                            color: context.textSecondary,
                            fontSize: 14,
                          ),
                        ),
                        Text(
                          user.userName,
                          style: TextStyle(
                            color: context.textPrimary,
                            fontSize: 22,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                  ),
                ),
                // Kept Search Icon near Notifications button
                InkWell(
                  onTap: () => _showSearchSheet(context),
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: context.iconBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.search_rounded,
                        color: context.iconFg,
                        size: 22,
                      ),
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Notification Bell Icon
                  InkWell(
                    onTap: () => showNotificationsPanel(context),
                    borderRadius: BorderRadius.circular(15),
                    child: Container(
                      height: 44,
                      width: 44,
                      decoration: BoxDecoration(
                        color: context.iconBg,
                        borderRadius: BorderRadius.circular(14),
                      ),
                      child: Icon(
                        Icons.notifications_none_rounded,
                        color: context.iconFg,
                        size: 22,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 25),

              // Total Balance & Expense Cards
              Row(
                children: [
                  Expanded(
                    child: Container(
                      height: 140,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(22),
                        gradient: const LinearGradient(
                          colors: [Color(0xff7B4DFF), Color(0xff9D74FF)],
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Total Balance",
                            style: const TextStyle(color: Colors.white70, fontSize: 13),
                          ),
                          const Spacer(),
                          Text(
                            "₹${balance.toStringAsFixed(0)}",
                            style: const TextStyle(
                              color: Colors.white,
                              fontSize: 28,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Container(
                      height: 140,
                      padding: const EdgeInsets.all(18),
                      decoration: BoxDecoration(
                        color: context.cardBgAlt,
                        borderRadius: BorderRadius.circular(22),
                        boxShadow: context.isDarkTheme
                            ? null
                            : [
                                BoxShadow(
                                  color: context.shadowColor,
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            "Expense",
                            style: TextStyle(color: context.textSecondary, fontSize: 13),
                          ),
                          const Spacer(),
                          Text(
                            "₹${expense.toStringAsFixed(0)}",
                            style: const TextStyle(
                              color: Colors.redAccent,
                              fontSize: 26,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 30),

              // Quick Actions Row
              Text(
                "Quick Actions",
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 20,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _actionItem(context, icon: Icons.qr_code_scanner, title: "Scan", color: Colors.green, onTap: () async {
                    await context.push('/qr');
                    if (mounted) loadTransactions();
                  }),
                  _actionItem(context, icon: Icons.receipt_long, title: "OCR", color: Colors.red, onTap: () async {
                    await context.push('/ocr');
                    if (mounted) loadTransactions();
                  }),
                  _actionItem(context, icon: Icons.add_circle_outline, title: "Income", color: Colors.blue, onTap: () async {
                    await context.push('/add-income');
                    if (mounted) loadTransactions();
                  }),
                  _actionItem(context, icon: Icons.account_balance_wallet, title: "Budget", color: Colors.orange, onTap: () async {
                    await context.push('/budget');
                    if (mounted) loadTransactions();
                  }),
                ],
              ),
              const SizedBox(height: 30),

              // Monthly Budget Progress Card
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: context.cardDecoration.copyWith(
                  borderRadius: BorderRadius.circular(22),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Monthly Budget",
                      style: TextStyle(
                        color: context.textPrimary,
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 16),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(20),
                      child: LinearProgressIndicator(
                        minHeight: 12,
                        value: budget == 0 ? 0 : (expense / budget).clamp(0.0, 1.0),
                        backgroundColor: context.progressBg,
                        valueColor: const AlwaysStoppedAnimation(Color(0xff7B4DFF)),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        _budgetStat(context, "Budget", "₹${budget.toStringAsFixed(0)}", context.textPrimary),
                        _budgetStat(context, "Spent", "₹${expense.toStringAsFixed(0)}", Colors.redAccent),
                        _budgetStat(context, "Left", "₹${(budget - expense).toStringAsFixed(0)}", Colors.green),
                      ],
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 30),

              // Recent Transactions Header
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Recent Transactions",
                    style: TextStyle(
                      color: context.textPrimary,
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  TextButton(
                    onPressed: () async {
                      await context.push('/history');
                      if (mounted) loadTransactions();
                    },
                    child: const Text("View All", style: TextStyle(color: Color(0xff7B4DFF), fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
              const SizedBox(height: 12),

              if (transactions.isEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(40),
                  decoration: context.cardDecoration.copyWith(
                    borderRadius: BorderRadius.circular(22),
                  ),
                  child: Column(
                    children: [
                      Icon(Icons.receipt_long, color: context.textMuted, size: 50),
                      const SizedBox(height: 12),
                      Text(
                        "No Transactions Yet",
                        style: TextStyle(
                          color: context.textSecondary,
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                )
              else
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: transactions.length > 5 ? 5 : transactions.length,
                  itemBuilder: (context, index) {
                    final t = transactions[index];
                    final catData = getCategoryByName(t.category);
                    return Container(
                      margin: const EdgeInsets.only(bottom: 12),
                      padding: const EdgeInsets.all(16),
                      decoration: context.cardDecoration.copyWith(
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 24,
                            backgroundColor: t.type == "Income"
                                ? Colors.green.withValues(alpha: 0.15)
                                : t.type == "Transfer"
                                    ? Colors.blue.withValues(alpha: 0.15)
                                    : catData.color.withValues(alpha: 0.15),
                            child: Text(
                              t.type == "Transfer"
                                  ? "↔️"
                                  : catData.emoji ?? (t.type == "Income" ? "💰" : "🏷️"),
                              style: const TextStyle(fontSize: 22),
                            ),
                          ),
                          const SizedBox(width: 14),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  t.description,
                                  style: TextStyle(
                                    color: context.textPrimary,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                                const SizedBox(height: 4),
                                Text(
                                  "${t.category} • ${t.paymentMethod}",
                                  style: TextStyle(color: context.textMuted, fontSize: 12),
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  t.date.contains("T") ? t.date.split("T").first : t.date,
                                  style: TextStyle(color: context.textMuted, fontSize: 11),
                                ),
                              ],
                            ),
                          ),
                          Text(
                            "${t.type == "Income" ? "+" : t.type == "Transfer" ? "↔" : "-"} ₹${t.amount.toStringAsFixed(0)}",
                            style: TextStyle(
                              color: t.type == "Income"
                                  ? Colors.green
                                  : t.type == "Transfer"
                                      ? Colors.blue
                                      : Colors.redAccent,
                              fontWeight: FontWeight.bold,
                              fontSize: 17,
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _budgetStat(BuildContext context, String label, String value, Color valueColor) {
    return Column(
      children: [
        Text(label, style: TextStyle(color: context.textMuted, fontSize: 12)),
        const SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(color: valueColor, fontWeight: FontWeight.bold, fontSize: 16),
        ),
      ],
    );
  }

  Widget _actionItem(
    BuildContext context, {
    required IconData icon,
    required String title,
    required Color color,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Column(
        children: [
          Container(
            height: 60,
            width: 60,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color, size: 28),
          ),
          const SizedBox(height: 8),
          Text(
            title,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: context.textPrimary,
              fontWeight: FontWeight.w600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }
}
