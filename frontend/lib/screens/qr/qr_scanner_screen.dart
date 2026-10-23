import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../models/transaction_model.dart';
import '../../services/category_classifier.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../services/upi_service.dart';
import '../../core/constants/categories.dart';

import '../../widgets/upi_brand_logo.dart';

class QRScannerScreen extends StatefulWidget {
  const QRScannerScreen({super.key});

  @override
  State<QRScannerScreen> createState() => _QRScannerScreenState();
}


class _QRScannerScreenState extends State<QRScannerScreen> with WidgetsBindingObserver {
  final MobileScannerController controller = MobileScannerController();
  final amountController = TextEditingController();

  bool scanned = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addObserver(this);
  }

  @override
  void dispose() {
    WidgetsBinding.instance.removeObserver(this);
    controller.dispose();
    amountController.dispose();
    super.dispose();
  }

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed && scanned) {
      // User returned from payment app — handled in payment flow
    }
  }

  void _handleBarcode(BarcodeCapture capture) {
    if (scanned) return;
    if (capture.barcodes.isEmpty) return;

    final String code = capture.barcodes.first.rawValue ?? "";
    if (code.isEmpty) return;

    scanned = true;
    controller.stop();

    final upiData = UpiService.parseQrCode(code);

    if (upiData != null && upiData.isValid) {
      _showPaymentSheet(upiData);
    } else {
      _showNonUpiDialog(code);
    }
  }

  void _showNonUpiDialog(String code) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("QR Code Scanned"),
        content: SelectableText(code),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetScanner();
            },
            child: const Text("Scan Again"),
          ),
        ],
      ),
    );
  }

  void _showPaymentSheet(UpiPaymentData upiData) {
    amountController.text = upiData.amount ?? "";

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Theme.of(context).cardColor,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      builder: (ctx) {
        return Padding(
          padding: EdgeInsets.fromLTRB(20, 20, 20, MediaQuery.of(ctx).viewInsets.bottom + 20),
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  "UPI Payment",
                  style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                Text("Pay to: ${upiData.payeeName}", style: const TextStyle(color: Colors.grey)),
                Text("UPI ID: ${upiData.payeeAddress}", style: const TextStyle(color: Colors.grey, fontSize: 12)),
                const SizedBox(height: 20),
                TextField(
                  controller: amountController,
                  keyboardType: TextInputType.number,
                  decoration: InputDecoration(
                    labelText: "Enter Amount (\u20b9)",
                    prefixIcon: const Icon(Icons.currency_rupee),
                    border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                  ),
                ),
                const SizedBox(height: 20),
                const Text("Select Payment App", style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                const SizedBox(height: 12),
                ...UpiService.supportedApps.map((app) {
                  return ListTile(
                    leading: UpiBrandLogoWidget(appName: app.name, size: 42),
                    title: Text(app.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                    trailing: const Icon(Icons.arrow_forward_ios, size: 16),
                    onTap: () async {
                      final amount = amountController.text.trim();
                      if (amount.isEmpty || double.tryParse(amount) == null) {
                        ScaffoldMessenger.of(ctx).showSnackBar(
                          const SnackBar(content: Text("Please enter a valid amount")),
                        );
                        return;
                      }

                      Navigator.pop(ctx);
                      await UpiService.launchPaymentApp(app, upiData, amount);

                      if (!mounted) return;
                      _showPaymentResultDialog(upiData, amount);
                    },
                  );
                }),
                const SizedBox(height: 10),
              ],
            ),
          ),
        );
      },
    ).whenComplete(_resetScanner);
  }

  void _showPaymentResultDialog(UpiPaymentData upiData, String amount) {
    final category = CategoryClassifier.classifyMerchant(upiData.payeeName);

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (ctx) => AlertDialog(
        title: const Text("Payment Status"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Text("Was the payment successful?"),
            const SizedBox(height: 12),
            Row(
              children: [
                Icon(getCategoryByName(category).icon, color: getCategoryByName(category).color),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    "Will be recorded as $category expense",
                    style: const TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ),
              ],
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(ctx);
              _resetScanner();
            },
            child: const Text("Failed"),
          ),
          ElevatedButton(
            onPressed: () async {
              Navigator.pop(ctx);

              final transaction = TransactionModel(
                amount: double.parse(amount),
                description: upiData.payeeName,
                category: category,
                paymentMethod: "UPI",
                date: DateTime.now().toIso8601String(),
                type: "Expense",
              );

              await DatabaseService.instance.insertTransaction(transaction);
              await NotificationService.instance.notifyPaymentSuccess(upiData.payeeName, category);
              await NotificationService.instance.checkAndNotifyBudgetAlerts();

              if (!mounted) return;

              ScaffoldMessenger.of(context).showSnackBar(
                SnackBar(
                  content: Text("₹$amount payment to ${upiData.payeeName} saved under $category"),
                  backgroundColor: Colors.green,
                ),
              );

              Navigator.pop(context);
            },
            style: ElevatedButton.styleFrom(backgroundColor: Colors.green),
            child: const Text("Success", style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );
  }

  void _resetScanner() {
    setState(() => scanned = false);
    controller.start();
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xff070B16) : Theme.of(context).scaffoldBackgroundColor;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text(
          "Scan QR Code",
          style: TextStyle(color: isDark ? Colors.white : Colors.black87),
        ),
      ),
      body: Stack(
        children: [
          MobileScanner(
            controller: controller,
            onDetect: _handleBarcode,
          ),
          Center(
            child: Container(
              width: 250,
              height: 250,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.greenAccent, width: 3),
                borderRadius: BorderRadius.circular(20),
              ),
            ),
          ),
          const Positioned(
            left: 0,
            right: 0,
            bottom: 40,
            child: Center(
              child: Text(
                "Scan a UPI payment QR code",
                style: TextStyle(color: Colors.white, fontSize: 16, shadows: [
                  Shadow(blurRadius: 4, color: Colors.black),
                ]),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
