import 'package:flutter/material.dart';
import '../../core/theme/theme_extensions.dart';

class TermsScreen extends StatelessWidget {
  const TermsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: context.appBg,
      appBar: AppBar(
        backgroundColor: context.appBg,
        title: Text(
          "Terms & Conditions",
          style: TextStyle(color: context.textPrimary, fontWeight: FontWeight.bold),
        ),
        iconTheme: IconThemeData(color: context.textPrimary),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            color: context.cardBg,
            borderRadius: BorderRadius.circular(20),
          ),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                "Smart AI Expense Tracker Terms of Service",
                style: TextStyle(
                  color: context.textPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 10),
              Text(
                "Last Updated: July 2026",
                style: TextStyle(color: context.textMuted, fontSize: 12),
              ),
              const Divider(height: 30),
              _sectionTitle(context, "1. Acceptance of Terms"),
              _sectionBody(context, "By accessing or using the Smart AI Expense Tracker application, you agree to be bound by these Terms and Conditions and Privacy Policy."),
              _sectionTitle(context, "2. Privacy & Data Storage"),
              _sectionBody(context, "Your financial data and transactions are stored locally on your device in a secure SQLite database. We do not sell or share your personal transaction data with third parties."),
              _sectionTitle(context, "3. AI Assistant Services"),
              _sectionBody(context, "Our AI Assistant offers financial insights based on your provided expenses. Recommendations are for informational purposes only and do not constitute formal financial advice."),
              _sectionTitle(context, "4. UPI Payments & Scanner"),
              _sectionBody(context, "The QR payment launcher integrates standard UPI protocols to launch your installed payment apps (Google Pay, PhonePe, Paytm, etc.). Transactions are executed directly by your payment provider."),
              _sectionTitle(context, "5. Contact Us"),
              _sectionBody(context, "For any inquiries or feedback regarding these terms, please contact support@expensetracker.app."),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }

  Widget _sectionTitle(BuildContext context, String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 14, bottom: 6),
      child: Text(
        title,
        style: TextStyle(
          color: context.textPrimary,
          fontSize: 15,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Widget _sectionBody(BuildContext context, String body) {
    return Text(
      body,
      style: TextStyle(
        color: context.textSecondary,
        fontSize: 13,
        height: 1.4,
      ),
    );
  }
}
