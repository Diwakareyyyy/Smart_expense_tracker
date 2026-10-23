import 'package:flutter/material.dart';
import '../../core/theme/theme_extensions.dart';

class GuideScreen extends StatefulWidget {
  const GuideScreen({super.key});

  @override
  State<GuideScreen> createState() => _GuideScreenState();
}

class _GuideScreenState extends State<GuideScreen> {
  final List<Map<String, dynamic>> _guideTopics = [
    {
      "title": "Manage Notes & Expenses",
      "icon": Icons.notes_rounded,
      "content": "• Tap the **+** button on the dashboard to add a new expense.\n• Select **Add Expense**, enter the amount, and choose a category.\n• You can also add notes to describe the transaction.",
      "isExpanded": false,
    },
    {
      "title": "Add Budget",
      "icon": Icons.account_balance_wallet_outlined,
      "content": "• Navigate to the **Budget** tab.\n• Tap on **Set Budget** to define monthly spending limits for various categories like Food, Fuel, or Shopping.\n• The app will warn you if you exceed 80% of your limit.",
      "isExpanded": false,
    },
    {
      "title": "Income Tracking",
      "icon": Icons.attach_money_rounded,
      "content": "• Track your earnings easily.\n• Tap the **+** button and select **Add Income**.\n• Categorize it as Salary, Investment, or Others to see a clear picture of your cash flow in Analytics.",
      "isExpanded": false,
    },
    {
      "title": "OCR / Scan Receipts",
      "icon": Icons.document_scanner_outlined,
      "content": "• Don't type manually!\n• Use the **OCR / Scan** feature on the dashboard to take a photo of your receipt.\n• Our smart AI will automatically extract the total amount and suggest a category.",
      "isExpanded": false,
    },
    {
      "title": "Analytics & Charts",
      "icon": Icons.pie_chart_outline_rounded,
      "content": "• Go to the **Analytics** section to view visual breakdowns of your spending.\n• You can filter by **Week**, **Month**, or **Year** to understand your financial habits.",
      "isExpanded": false,
    },
    {
      "title": "AI Assistant",
      "icon": Icons.psychology_rounded,
      "content": "• Our **Smart AI Assistant** can answer any financial query.\n• Just ask things like **\"What is my highest expense category?\"**\n• Or **\"Total spend this month?\"**\n• Or **\"How much did I spend on food last week?\"**",
      "isExpanded": false,
    },
  ];

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xff070B16) : const Color(0xffF8FAFC);
    final cardColor = isDark ? const Color(0xff1B233A) : Colors.white;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        iconTheme: IconThemeData(color: context.textPrimary),
        title: Text(
          "Guide",
          style: TextStyle(
              color: context.textPrimary,
              fontSize: 20,
              fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            // Top Hero Card
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(vertical: 30, horizontal: 20),
              decoration: BoxDecoration(
                gradient: const LinearGradient(
                  colors: [Color(0xff5D34F8), Color(0xff865EFE)],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                borderRadius: BorderRadius.circular(24),
                boxShadow: [
                  BoxShadow(
                    color: const Color(0xff5D34F8).withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 10),
                  ),
                ],
              ),
              child: Column(
                children: [
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.2),
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(Icons.menu_book_rounded,
                        color: Colors.white, size: 40),
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    "Smart App Guide",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 22,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    "Your complete manual for mastering budget, tracking, and AI.",
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      color: Colors.white.withOpacity(0.9),
                      fontSize: 14,
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 24),
            // Accordion List
            ..._guideTopics.map((topic) {
              return _buildAccordionItem(topic, cardColor);
            }),
          ],
        ),
      ),
    );
  }

  Widget _buildAccordionItem(Map<String, dynamic> topic, Color cardColor) {
    return Container(
      margin: const EdgeInsets.only(bottom: 12),
      decoration: BoxDecoration(
        color: cardColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: context.isDarkTheme ? Colors.white12 : Colors.grey.shade200,
        ),
        boxShadow: context.isDarkTheme
            ? null
            : [
                BoxShadow(
                  color: Colors.black.withOpacity(0.03),
                  blurRadius: 10,
                  offset: const Offset(0, 4),
                ),
              ],
      ),
      child: Theme(
        data: Theme.of(context).copyWith(dividerColor: Colors.transparent),
        child: ExpansionTile(
          iconColor: context.textPrimary,
          collapsedIconColor: context.textSecondary,
          tilePadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          leading: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: const Color(0xff7B4DFF).withOpacity(0.1),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(topic["icon"], color: const Color(0xff7B4DFF), size: 22),
          ),
          title: Text(
            topic["title"],
            style: TextStyle(
              color: context.textPrimary,
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          children: [
            Padding(
              padding: const EdgeInsets.fromLTRB(16, 0, 16, 20),
              child: _buildRichText(topic["content"]),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildRichText(String text) {
    final spans = <TextSpan>[];
    final regex = RegExp(r'\*\*(.*?)\*\*');
    int lastEnd = 0;

    for (final match in regex.allMatches(text)) {
      if (match.start > lastEnd) {
        spans.add(TextSpan(text: text.substring(lastEnd, match.start)));
      }
      spans.add(TextSpan(
        text: match.group(1),
        style: TextStyle(
          fontWeight: FontWeight.bold,
          color: context.textPrimary,
        ),
      ));
      lastEnd = match.end;
    }

    if (lastEnd < text.length) {
      spans.add(TextSpan(text: text.substring(lastEnd)));
    }

    return RichText(
      text: TextSpan(
        style: TextStyle(
          color: context.textSecondary,
          fontSize: 14.5,
          height: 1.5,
        ),
        children: spans,
      ),
    );
  }
}
