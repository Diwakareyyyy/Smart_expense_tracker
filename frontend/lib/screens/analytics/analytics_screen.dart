import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../services/database_service.dart';
import '../../services/pdf_service.dart';
import '../../models/transaction_model.dart';
import '../../widgets/category_pie_chart.dart';
import '../../widgets/bottom_navbar.dart';
import '../../core/constants/categories.dart';

enum AnalyticsFilterType { month, range }

class AnalyticsScreen extends StatefulWidget {
  const AnalyticsScreen({super.key});

  @override
  State<AnalyticsScreen> createState() => _AnalyticsScreenState();
}

class _AnalyticsScreenState extends State<AnalyticsScreen> {
  List<TransactionModel> allExpenses = [];
  List<TransactionModel> monthExpenses = [];
  List<TransactionModel> filteredExpenses = [];
  Map<String, double> categoryTotals = {};

  AnalyticsFilterType _filterType = AnalyticsFilterType.month;
  DateTime? rangeStartDate = DateTime(DateTime.now().year, DateTime.now().month, 1);
  DateTime? rangeEndDate = DateTime.now();

  DateTime selectedMonth = DateTime.now();
  DateTime? selectedDateOnCalendar;
  String selectedCategory = "All";
  int _currentPage = 0;
  static const int _pageSize = 10;

  @override
  void initState() {
    super.initState();
    loadData();
  }

  Future<void> loadData() async {
    final data = await DatabaseService.instance.getTransactions();
    final expenses = data.where((t) => t.type == "Expense").toList();

    setState(() {
      allExpenses = expenses;
      applyFilters();
    });
  }

  void applyFilters() {
    List<TransactionModel> result = [];

    // 1. Filter by Period (Month or Custom Range)
    if (_filterType == AnalyticsFilterType.month) {
      monthExpenses = allExpenses.where((t) {
        final d = DateTime.tryParse(t.date);
        if (d == null) return false;
        return d.year == selectedMonth.year && d.month == selectedMonth.month;
      }).toList();

      result = List.from(monthExpenses);

      // Specific Date Filter from Calendar
      if (selectedDateOnCalendar != null) {
        result = result.where((t) {
          final d = DateTime.tryParse(t.date);
          if (d == null) return false;
          return d.year == selectedDateOnCalendar!.year &&
              d.month == selectedDateOnCalendar!.month &&
              d.day == selectedDateOnCalendar!.day;
        }).toList();
      }
    } else {
      // Date Range Filter
      if (rangeStartDate != null) {
        final start = DateTime(rangeStartDate!.year, rangeStartDate!.month, rangeStartDate!.day);
        final end = rangeEndDate != null
            ? DateTime(rangeEndDate!.year, rangeEndDate!.month, rangeEndDate!.day, 23, 59, 59, 999)
            : DateTime(rangeStartDate!.year, rangeStartDate!.month, rangeStartDate!.day, 23, 59, 59, 999);
        
        result = allExpenses.where((t) {
          final d = DateTime.tryParse(t.date);
          if (d == null) return false;
          return d.isAfter(start.subtract(const Duration(microseconds: 1))) &&
              d.isBefore(end.add(const Duration(microseconds: 1)));
        }).toList();

      } else {
        result = List.from(allExpenses);
      }
      
      // Sync monthExpenses to keep calendar consistent if user toggles back
      monthExpenses = allExpenses.where((t) {
        final d = DateTime.tryParse(t.date);
        if (d == null) return false;
        return d.year == selectedMonth.year && d.month == selectedMonth.month;
      }).toList();
    }

    // 2. Category Filter
    if (selectedCategory != "All") {
      result = result
          .where((t) => t.category.toLowerCase() == selectedCategory.toLowerCase())
          .toList();
    }

    // Calculate Category Totals
    final totals = <String, double>{};
    for (final t in result) {
      totals[t.category] = (totals[t.category] ?? 0) + t.amount;
    }

    setState(() {
      filteredExpenses = result;
      categoryTotals = totals;
      _currentPage = 0;
    });
  }

  Future<void> _pickMonth(BuildContext context) async {
    int chosenYear = selectedMonth.year;
    int chosenMonth = selectedMonth.month;

    await showDialog(
      context: context,
      builder: (ctx) {
        final isDark = Theme.of(ctx).brightness == Brightness.dark;
        final dialogBg = isDark ? const Color(0xff1B233A) : Colors.white;
        final textColor = isDark ? Colors.white : Colors.black87;

        return StatefulBuilder(
          builder: (ctx, setDialogState) {
            return AlertDialog(
              backgroundColor: dialogBg,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
              title: Text(
                "Select Month & Year",
                style: TextStyle(color: textColor, fontWeight: FontWeight.bold),
              ),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      IconButton(
                        icon: Icon(Icons.chevron_left, color: textColor),
                        onPressed: () => setDialogState(() => chosenYear--),
                      ),
                      Text(
                        "$chosenYear",
                        style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      IconButton(
                        icon: Icon(Icons.chevron_right, color: textColor),
                        onPressed: () => setDialogState(() => chosenYear++),
                      ),
                    ],
                  ),
                  Divider(color: isDark ? Colors.white24 : Colors.grey.shade300),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 8,
                    runSpacing: 8,
                    children: List.generate(12, (index) {
                      final mIndex = index + 1;
                      final mName = DateFormat('MMM').format(DateTime(chosenYear, mIndex));
                      final isSelected = mIndex == chosenMonth;

                      return ChoiceChip(
                        label: Text(mName),
                        selected: isSelected,
                        selectedColor: const Color(0xff7B4DFF),
                        backgroundColor: isDark ? const Color(0xff262E4A) : Colors.grey.shade200,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                        labelStyle: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isDark
                                  ? Colors.white
                                  : Colors.black87,
                          fontWeight: FontWeight.bold,
                        ),
                        onSelected: (_) {
                          setDialogState(() => chosenMonth = mIndex);
                        },
                      );
                    }),
                  ),
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(ctx),
                  child: Text("Cancel", style: TextStyle(color: isDark ? Colors.white70 : Colors.black54)),
                ),
                ElevatedButton(
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff7B4DFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                  onPressed: () {
                    setState(() {
                      selectedMonth = DateTime(chosenYear, chosenMonth);
                      selectedDateOnCalendar = null; // reset date selection
                      applyFilters();
                    });
                    Navigator.pop(ctx);
                  },
                  child: const Text("OK", style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                ),
              ],
            );
          },
        );
      },
    );
  }

  Widget _buildModeSelector(Color cardColor, Color textColor) {
    return Container(
      padding: const EdgeInsets.all(4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: cardColor.withValues(alpha: 0.1)),
      ),
      child: Row(
        children: [
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _filterType = AnalyticsFilterType.month;
                  applyFilters();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _filterType == AnalyticsFilterType.month
                      ? const Color(0xff7B4DFF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    "Monthly View",
                    style: TextStyle(
                      color: _filterType == AnalyticsFilterType.month
                          ? Colors.white
                          : textColor.withValues(alpha: 0.7),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                setState(() {
                  _filterType = AnalyticsFilterType.range;
                  applyFilters();
                });
              },
              child: AnimatedContainer(
                duration: const Duration(milliseconds: 200),
                padding: const EdgeInsets.symmetric(vertical: 10),
                decoration: BoxDecoration(
                  color: _filterType == AnalyticsFilterType.range
                      ? const Color(0xff7B4DFF)
                      : Colors.transparent,
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Center(
                  child: Text(
                    "Custom Range",
                    style: TextStyle(
                      color: _filterType == AnalyticsFilterType.range
                          ? Colors.white
                          : textColor.withValues(alpha: 0.7),
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  String getPeriodLabel() {
    if (_filterType == AnalyticsFilterType.month) {
      final monthStr = DateFormat('MMMM yyyy').format(selectedMonth);
      if (selectedDateOnCalendar != null) {
        return "Date: ${DateFormat('dd MMM yyyy').format(selectedDateOnCalendar!)} ($monthStr)";
      }
      return "Month: $monthStr";
    } else {
      if (rangeStartDate != null) {
        final startStr = DateFormat('dd MMM yyyy').format(rangeStartDate!);
        if (rangeEndDate != null) {
          final endStr = DateFormat('dd MMM yyyy').format(rangeEndDate!);
          return "Range: $startStr - $endStr";
        }
        return "Range: $startStr - ...";
      }
      return "Select Date Range";
    }
  }

  List<TransactionModel> _getCurrentPageTransactions() {
    final start = _currentPage * _pageSize;
    if (start >= filteredExpenses.length) return [];
    final end = (start + _pageSize).clamp(0, filteredExpenses.length);
    return filteredExpenses.sublist(start, end);
  }

  Widget _buildPagination(Color textColor, Color cardColor) {
    final totalPages = (filteredExpenses.length + _pageSize - 1) ~/ _pageSize;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 8),
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Wrap(
        alignment: WrapAlignment.end,
        crossAxisAlignment: WrapCrossAlignment.center,
        spacing: 8,
        runSpacing: 8,
        children: [
          if (_currentPage > 0)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xff7B4DFF),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => setState(() => _currentPage--),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(Icons.chevron_left, size: 20),
                  SizedBox(width: 2),
                  Text("Previous", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                ],
              ),
            ),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
            decoration: BoxDecoration(
              color: const Color(0xff7B4DFF).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              "${_currentPage + 1} / $totalPages",
              style: const TextStyle(
                color: Color(0xff7B4DFF),
                fontWeight: FontWeight.bold,
                fontSize: 13,
              ),
            ),
          ),
          if (_currentPage < totalPages - 1)
            TextButton(
              style: TextButton.styleFrom(
                foregroundColor: const Color(0xff7B4DFF),
                padding: const EdgeInsets.symmetric(horizontal: 10),
                minimumSize: Size.zero,
                tapTargetSize: MaterialTapTargetSize.shrinkWrap,
              ),
              onPressed: () => setState(() => _currentPage++),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text("Next", style: TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
                  SizedBox(width: 2),
                  Icon(Icons.chevron_right, size: 20),
                ],
              ),
            ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xff070B16) : const Color(0xffF8FAFC);
    final cardColor = isDark ? const Color(0xff1B233A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;
    final textSecondary = isDark ? Colors.white54 : Colors.grey.shade600;

    final totalExpense = categoryTotals.values.fold<double>(0, (sum, v) => sum + v);

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text("Analytics", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
        iconTheme: IconThemeData(color: textColor),
      ),
      bottomNavigationBar: const AppBottomNavBar(currentRoute: '/analytics'),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            final isCompact = constraints.maxWidth < 360;
            return SingleChildScrollView(
              padding: EdgeInsets.symmetric(horizontal: isCompact ? 14 : 20, vertical: 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _buildModeSelector(cardColor, textColor),
                  const SizedBox(height: 16),

                  // Month Selector Header Card OR Date Range Selector Header Card
                  if (_filterType == AnalyticsFilterType.month)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                      ),
                      child: isCompact
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.calendar_month, color: Color(0xff7B4DFF), size: 28),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Selected Month",
                                            style: TextStyle(color: textSecondary, fontSize: 12),
                                          ),
                                          Text(
                                            DateFormat('MMMM yyyy').format(selectedMonth),
                                            style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 12),
                                SizedBox(
                                  width: double.infinity,
                                  child: ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: const Color(0xff7B4DFF),
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    icon: const Icon(Icons.edit_calendar, color: Colors.white, size: 18),
                                    label: const Text("Select Month", style: TextStyle(color: Colors.white)),
                                    onPressed: () => _pickMonth(context),
                                  ),
                                ),
                              ],
                            )
                          : Row(
                              children: [
                                const Icon(Icons.calendar_month, color: Color(0xff7B4DFF), size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Selected Month",
                                        style: TextStyle(color: textSecondary, fontSize: 12),
                                      ),
                                      Text(
                                        DateFormat('MMMM yyyy').format(selectedMonth),
                                        style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                ElevatedButton.icon(
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: const Color(0xff7B4DFF),
                                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                  ),
                                  icon: const Icon(Icons.edit_calendar, color: Colors.white, size: 18),
                                  label: const Text("Select Month", style: TextStyle(color: Colors.white)),
                                  onPressed: () => _pickMonth(context),
                                ),
                              ],
                            ),
                    )
                  else
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(20),
                        boxShadow: isDark
                            ? null
                            : [
                                BoxShadow(
                                  color: Colors.black.withValues(alpha: 0.05),
                                  blurRadius: 10,
                                  offset: const Offset(0, 3),
                                ),
                              ],
                      ),
                      child: isCompact
                          ? Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    const Icon(Icons.date_range, color: Color(0xff7B4DFF), size: 28),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment: CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            "Selected Range",
                                            style: TextStyle(color: textSecondary, fontSize: 12),
                                          ),
                                          Text(
                                            rangeStartDate != null
                                                ? (rangeEndDate != null
                                                    ? "${DateFormat('dd MMM').format(rangeStartDate!)} - ${DateFormat('dd MMM yyyy').format(rangeEndDate!)}"
                                                    : "${DateFormat('dd MMM yyyy').format(rangeStartDate!)} - Select End Date")
                                                : "Tap calendar days to select range",
                                            style: TextStyle(color: textColor, fontSize: rangeStartDate != null ? 16 : 14, fontWeight: FontWeight.bold),
                                          ),
                                        ],
                                      ),
                                    ),
                                  ],
                                ),
                                if (rangeStartDate != null) ...[
                                  const SizedBox(height: 12),
                                  SizedBox(
                                    width: double.infinity,
                                    child: ElevatedButton.icon(
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.redAccent,
                                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                      ),
                                      icon: const Icon(Icons.clear, color: Colors.white, size: 18),
                                      label: const Text("Clear Range", style: TextStyle(color: Colors.white)),
                                      onPressed: () {
                                        setState(() {
                                          rangeStartDate = null;
                                          rangeEndDate = null;
                                          applyFilters();
                                        });
                                      },
                                    ),
                                  ),
                                ],
                              ],
                            )
                          : Row(
                              children: [
                                const Icon(Icons.date_range, color: Color(0xff7B4DFF), size: 28),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment: CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        "Selected Range",
                                        style: TextStyle(color: textSecondary, fontSize: 12),
                                      ),
                                      Text(
                                        rangeStartDate != null
                                            ? (rangeEndDate != null
                                                ? "${DateFormat('dd MMM').format(rangeStartDate!)} - ${DateFormat('dd MMM yyyy').format(rangeEndDate!)}"
                                                : "${DateFormat('dd MMM yyyy').format(rangeStartDate!)} - Select End Date")
                                            : "Tap calendar days to select range",
                                        style: TextStyle(color: textColor, fontSize: rangeStartDate != null ? 16 : 14, fontWeight: FontWeight.bold),
                                      ),
                                    ],
                                  ),
                                ),
                                if (rangeStartDate != null)
                                  ElevatedButton.icon(
                                    style: ElevatedButton.styleFrom(
                                      backgroundColor: Colors.redAccent,
                                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                                    ),
                                    icon: const Icon(Icons.clear, color: Colors.white, size: 18),
                                    label: const Text("Clear", style: TextStyle(color: Colors.white)),
                                    onPressed: () {
                                      setState(() {
                                        rangeStartDate = null;
                                        rangeEndDate = null;
                                        applyFilters();
                                      });
                                    },
                                  ),
                              ],
                            ),
                    ),
                  const SizedBox(height: 20),

                  // Month Calendar View Below (Always Visible)
                  _buildMonthCalendarWidget(cardColor, textColor, textSecondary),
                  const SizedBox(height: 25),

                  // Summary Label & Pie Chart
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              getPeriodLabel(),
                              style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                            ),
                            const SizedBox(height: 4),
                            Text(
                              "Total Expenses: ₹${totalExpense.toStringAsFixed(0)}",
                              style: TextStyle(color: textSecondary, fontSize: 15, fontWeight: FontWeight.w600),
                            ),
                          ],
                        ),
                      ),
                      if (_filterType == AnalyticsFilterType.month && selectedDateOnCalendar != null)
                        TextButton.icon(
                          icon: const Icon(Icons.clear, size: 16),
                          label: const Text("View All Month"),
                          onPressed: () {
                            setState(() {
                              selectedDateOnCalendar = null;
                              applyFilters();
                            });
                          },
                        ),
                    ],
                  ),
                  const SizedBox(height: 15),

                  CategoryPieChart(categoryTotals: categoryTotals),
                  const SizedBox(height: 25),

                  // Category Filter Chips
                  Text(
                    "Category Filter",
                    style: TextStyle(color: textColor, fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        _categoryChip("All", textColor, cardColor),
                        ...expenseCategories.map(
                          (cat) => _categoryChip(cat.name, textColor, cardColor),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 25),

                  // Expense Transactions List
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Text(
                        "Transactions (${filteredExpenses.length})",
                        style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
                      ),
                      SizedBox(
                        height: 36,
                        child: ElevatedButton.icon(
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xff7B4DFF),
                            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                          ),
                          icon: const Icon(Icons.picture_as_pdf, color: Colors.white, size: 18),
                          label: const Text(
                            "Download",
                            style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.white),
                          ),
                          onPressed: () async {
                            if (filteredExpenses.isEmpty) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(content: Text("No expenses to export")),
                              );
                              return;
                            }
                            await PdfService.generateReport(
                              filteredExpenses,
                              title: _filterType == AnalyticsFilterType.month
                                  ? (selectedDateOnCalendar != null ? "Daily Expense Report" : "Monthly Expense Report")
                                  : "Range Expense Report",
                              subtitle: getPeriodLabel(),
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),

                  if (filteredExpenses.isEmpty)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(35),
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(18),
                      ),
                      child: Center(
                        child: Text(
                          "No expenses found for ${selectedDateOnCalendar != null ? DateFormat('dd MMM').format(selectedDateOnCalendar!) : 'selected month'}",
                          style: TextStyle(color: textSecondary),
                        ),
                      ),
                    )
                  else
                    ..._getCurrentPageTransactions().map((t) {
                      final catData = getCategoryByName(t.category);
                      return Container(
                        margin: const EdgeInsets.only(bottom: 12),
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          color: cardColor,
                          borderRadius: BorderRadius.circular(16),
                          boxShadow: isDark
                              ? null
                              : [
                                  BoxShadow(
                                    color: Colors.black.withValues(alpha: 0.03),
                                    blurRadius: 8,
                                    offset: const Offset(0, 2),
                                  ),
                                ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 46,
                              height: 46,
                              decoration: BoxDecoration(
                                color: catData.color.withValues(alpha: 0.15),
                                borderRadius: BorderRadius.circular(14),
                              ),
                              child: Center(
                                child: Text(
                                  catData.emoji ?? "🏷️",
                                  style: const TextStyle(fontSize: 22),
                                ),
                              ),
                            ),
                            const SizedBox(width: 14),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    t.description,
                                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                                  ),
                                  const SizedBox(height: 4),
                                  Text(
                                    "${t.category} • ${t.paymentMethod} • ${t.date.split('T').first}",
                                    style: TextStyle(color: textSecondary, fontSize: 12),
                                  ),
                                ],
                              ),
                            ),
                            Text(
                              "₹${t.amount.toStringAsFixed(0)}",
                              style: const TextStyle(color: Colors.redAccent, fontWeight: FontWeight.bold, fontSize: 17),
                            ),
                          ],
                        ),
                      );
                    }),

                  if (filteredExpenses.length > _pageSize)
                    _buildPagination(textColor, cardColor),
                  const SizedBox(height: 30),
                ],
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildMonthCalendarWidget(Color cardColor, Color textColor, Color textSecondary) {
    final daysInMonth = DateTime(selectedMonth.year, selectedMonth.month + 1, 0).day;
    final firstWeekday = DateTime(selectedMonth.year, selectedMonth.month, 1).weekday; // 1 = Mon, 7 = Sun

    final transactionDays = <int, double>{};
    for (var t in monthExpenses) {
      final d = DateTime.tryParse(t.date);
      if (d != null) {
        transactionDays[d.day] = (transactionDays[d.day] ?? 0) + t.amount;
      }
    }

    final weekHeaders = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"];

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(20),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  IconButton(
                    icon: Icon(Icons.chevron_left, color: textColor, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        selectedMonth = DateTime(selectedMonth.year, selectedMonth.month - 1);
                        if (_filterType == AnalyticsFilterType.month) {
                          selectedDateOnCalendar = null;
                        }
                        applyFilters();
                      });
                    },
                  ),
                  const SizedBox(width: 8),
                  Text(
                    DateFormat('MMMM yyyy').format(selectedMonth),
                    style: TextStyle(color: textColor, fontWeight: FontWeight.bold, fontSize: 16),
                  ),
                  const SizedBox(width: 8),
                  IconButton(
                    icon: Icon(Icons.chevron_right, color: textColor, size: 20),
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                    onPressed: () {
                      setState(() {
                        selectedMonth = DateTime(selectedMonth.year, selectedMonth.month + 1);
                        if (_filterType == AnalyticsFilterType.month) {
                          selectedDateOnCalendar = null;
                        }
                        applyFilters();
                      });
                    },
                  ),
                ],
              ),
              if (_filterType == AnalyticsFilterType.month && selectedDateOnCalendar != null)
                Chip(
                  label: Text("Day: ${selectedDateOnCalendar!.day}"),
                  backgroundColor: const Color(0xff7B4DFF),
                  labelStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                )
              else if (_filterType == AnalyticsFilterType.range && rangeStartDate != null)
                Chip(
                  label: Text(rangeEndDate != null ? "Range Selected" : "Select End Date"),
                  backgroundColor: const Color(0xff7B4DFF),
                  labelStyle: const TextStyle(color: Colors.white, fontSize: 11, fontWeight: FontWeight.bold),
                ),
            ],
          ),
          const SizedBox(height: 12),

          Row(
            mainAxisAlignment: MainAxisAlignment.spaceAround,
            children: weekHeaders
                .map((day) => SizedBox(
                      width: 36,
                      child: Text(
                        day,
                        textAlign: TextAlign.center,
                        style: TextStyle(color: textSecondary, fontSize: 12, fontWeight: FontWeight.bold),
                      ),
                    ))
                .toList(),
          ),
          const SizedBox(height: 8),

          GridView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: (firstWeekday - 1) + daysInMonth,
            gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
              crossAxisCount: 7,
              mainAxisSpacing: 6,
              crossAxisSpacing: 6,
              childAspectRatio: 1.0,
            ),
            itemBuilder: (context, index) {
              if (index < firstWeekday - 1) {
                return const SizedBox();
              }
              final dayNumber = index - (firstWeekday - 1) + 1;
              final dayDate = DateTime(selectedMonth.year, selectedMonth.month, dayNumber);
              
              bool isSelected = false;
              bool isInRange = false;
              bool isRangeStart = false;
              bool isRangeEnd = false;

              if (_filterType == AnalyticsFilterType.month) {
                isSelected = selectedDateOnCalendar != null &&
                    selectedDateOnCalendar!.day == dayNumber &&
                    selectedDateOnCalendar!.month == selectedMonth.month &&
                    selectedDateOnCalendar!.year == selectedMonth.year;
              } else {
                if (rangeStartDate != null) {
                  final startNormalized = DateTime(rangeStartDate!.year, rangeStartDate!.month, rangeStartDate!.day);
                  isRangeStart = dayDate.isAtSameMomentAs(startNormalized);
                  
                  if (rangeEndDate != null) {
                    final endNormalized = DateTime(rangeEndDate!.year, rangeEndDate!.month, rangeEndDate!.day);
                    isRangeEnd = dayDate.isAtSameMomentAs(endNormalized);
                    isInRange = dayDate.isAfter(startNormalized) && dayDate.isBefore(endNormalized);
                  }
                  
                  isSelected = isRangeStart || isRangeEnd;
                }
              }

              final hasTransaction = transactionDays.containsKey(dayNumber);

              return InkWell(
                onTap: () {
                  setState(() {
                    if (_filterType == AnalyticsFilterType.month) {
                      if (isSelected) {
                        selectedDateOnCalendar = null;
                      } else {
                        selectedDateOnCalendar = dayDate;
                      }
                    } else {
                      final tappedDay = DateTime(dayDate.year, dayDate.month, dayDate.day);
                      if (rangeStartDate == null) {
                        rangeStartDate = tappedDay;
                        rangeEndDate = null;
                      } else if (rangeEndDate == null) {
                        if (tappedDay.isBefore(rangeStartDate!)) {
                          rangeStartDate = tappedDay;
                        } else if (tappedDay.isAtSameMomentAs(rangeStartDate!)) {
                          rangeStartDate = null;
                          rangeEndDate = null;
                        } else {
                          rangeEndDate = tappedDay;
                        }
                      } else {
                        rangeStartDate = tappedDay;
                        rangeEndDate = null;
                      }
                    }
                    applyFilters();
                  });
                },
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  decoration: BoxDecoration(
                    color: isSelected
                        ? const Color(0xff7B4DFF)
                        : isInRange
                            ? const Color(0xff7B4DFF).withValues(alpha: 0.2)
                            : hasTransaction
                                ? Colors.redAccent.withValues(alpha: 0.15)
                                : Colors.transparent,
                    borderRadius: BorderRadius.circular(12),
                    border: isSelected
                        ? Border.all(color: Colors.white, width: 2)
                        : hasTransaction
                            ? Border.all(color: Colors.redAccent.withValues(alpha: 0.4), width: 1)
                            : null,
                  ),
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Text(
                        "$dayNumber",
                        style: TextStyle(
                          color: isSelected
                              ? Colors.white
                              : isInRange
                                  ? const Color(0xff7B4DFF)
                                  : hasTransaction
                                      ? Colors.redAccent
                                      : textColor,
                          fontWeight: isSelected || isInRange || hasTransaction ? FontWeight.bold : FontWeight.normal,
                          fontSize: 14,
                        ),
                      ),
                      if (hasTransaction) ...[
                        const SizedBox(height: 2),
                        Container(
                          width: 4,
                          height: 4,
                          decoration: BoxDecoration(
                            color: isSelected ? Colors.white : Colors.redAccent,
                            shape: BoxShape.circle,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          ),
        ],
      ),
    );
  }

  Widget _categoryChip(String label, Color textColor, Color cardColor) {
    final isSelected = selectedCategory == label;
    final catData = label != "All" ? getCategoryByName(label) : null;

    return Padding(
      padding: const EdgeInsets.only(right: 8),
      child: FilterChip(
        avatar: catData?.emoji != null ? Text(catData!.emoji!, style: const TextStyle(fontSize: 12)) : null,
        label: Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: isSelected ? Colors.white : textColor,
            fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
          ),
        ),
        selected: isSelected,
        onSelected: (_) {
          setState(() {
            selectedCategory = label;
            applyFilters();
          });
        },
        backgroundColor: cardColor,
        selectedColor: catData?.color ?? const Color(0xff7B4DFF),
        checkmarkColor: Colors.white,
        side: BorderSide.none,
      ),
    );
  }
}
