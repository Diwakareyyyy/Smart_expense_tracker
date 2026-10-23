import 'dart:io';

import 'package:flutter/material.dart';
import 'package:google_mlkit_text_recognition/google_mlkit_text_recognition.dart';
import 'package:image_picker/image_picker.dart';

import '../../models/transaction_model.dart';
import '../../services/database_service.dart';
import '../../services/notification_service.dart';
import '../../services/ocr_service.dart';
import '../../core/constants/categories.dart';
import '../../core/constants/payment_methods.dart';

class OCRReceiptScreen extends StatefulWidget {
  const OCRReceiptScreen({super.key});

  @override
  State<OCRReceiptScreen> createState() => _OCRReceiptScreenState();
}

class _OCRReceiptScreenState extends State<OCRReceiptScreen> {
  File? imageFile;
  String extractedText = "No receipt scanned.";
  ParsedReceipt? parsedReceipt;
  bool isProcessing = false;

  final picker = ImagePicker();
  final textRecognizer = TextRecognizer();

  final TextEditingController amountEditController = TextEditingController();
  final TextEditingController merchantEditController = TextEditingController();
  String selectedCategory = "Others";
  String selectedPayment = "Cash";

  @override
  void dispose() {
    textRecognizer.close();
    amountEditController.dispose();
    merchantEditController.dispose();
    super.dispose();
  }

  Future<void> pickImage(ImageSource source) async {
    final XFile? image = await picker.pickImage(source: source);
    if (image == null) return;

    setState(() {
      imageFile = File(image.path);
      isProcessing = true;
    });

    await scanText();
  }

  Future<void> scanText() async {
    if (imageFile == null) return;

    final inputImage = InputImage.fromFile(imageFile!);
    final RecognizedText recognizedText =
        await textRecognizer.processImage(inputImage);

    final text = recognizedText.text.isEmpty
        ? "No text found."
        : recognizedText.text;

    final parsed = text != "No text found."
        ? await OcrService.parseReceiptTextOnline(text)
        : null;

    setState(() {
      extractedText = text;
      parsedReceipt = parsed;
      isProcessing = false;
      if (parsed?.amount != null) {
        amountEditController.text = parsed!.amount!.toStringAsFixed(2);
      }
      if (parsed?.merchant != null) {
        merchantEditController.text = parsed!.merchant;
      }
      if (parsed?.category != null) {
        selectedCategory = parsed!.category;
      }
      selectedPayment = parsed?.paymentMethod ?? "Cash";
    });
  }

  Future<void> saveExpense() async {
    final double? amount = double.tryParse(amountEditController.text) ?? parsedReceipt?.amount;

    if (parsedReceipt == null || amount == null || amount <= 0) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text("Could not detect valid amount. Please enter manually."),
          backgroundColor: Colors.redAccent,
        ),
      );
      return;
    }

    final merchant = merchantEditController.text.trim().isNotEmpty
        ? merchantEditController.text.trim()
        : parsedReceipt!.merchant;

    final transaction = TransactionModel(
      amount: amount,
      description: merchant,
      category: selectedCategory,
      paymentMethod: selectedPayment,
      date: DateTime.now().toIso8601String(),
      type: "Expense",
    );

    await DatabaseService.instance.insertTransaction(transaction);
    await NotificationService.instance.notifyExpenseAdded(
      selectedCategory,
      amount,
    );

    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(
          "Expense saved under $selectedCategory — ₹${amount.toStringAsFixed(0)}",
        ),
        backgroundColor: Colors.green,
      ),
    );

    Navigator.pop(context, true);
  }

  @override
  Widget build(BuildContext context) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    final bgColor = isDark ? const Color(0xff070B16) : const Color(0xffF8FAFC);
    final cardColor = isDark ? const Color(0xff1B233A) : Colors.white;
    final textColor = isDark ? Colors.white : Colors.black87;

    return Scaffold(
      backgroundColor: bgColor,
      appBar: AppBar(
        backgroundColor: bgColor,
        elevation: 0,
        title: Text("OCR Receipt Scanner", style: TextStyle(color: textColor, fontWeight: FontWeight.bold)),
      ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton(
            heroTag: "camera",
            backgroundColor: Colors.blue,
            onPressed: () => pickImage(ImageSource.camera),
            child: const Icon(Icons.camera_alt, color: Colors.white),
          ),
          const SizedBox(height: 12),
          FloatingActionButton(
            heroTag: "gallery",
            backgroundColor: const Color(0xff7B4DFF),
            onPressed: () => pickImage(ImageSource.gallery),
            child: const Icon(Icons.photo, color: Colors.white),
          ),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            if (imageFile != null)
              ClipRRect(
                borderRadius: BorderRadius.circular(15),
                child: Image.file(imageFile!, height: 250, width: double.infinity, fit: BoxFit.cover),
              )
            else
              Container(
                height: 220,
                decoration: BoxDecoration(
                  color: cardColor,
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.receipt_long, size: 60, color: textColor.withValues(alpha: 0.3)),
                      const SizedBox(height: 12),
                      Text(
                        "Capture or upload a receipt screenshot",
                        style: TextStyle(color: textColor.withValues(alpha: 0.5)),
                      ),
                    ],
                  ),
                ),
              ),
            if (isProcessing) ...[
              const SizedBox(height: 20),
              const CircularProgressIndicator(color: Color(0xff7B4DFF)),
              const SizedBox(height: 8),
              Text("Extracting & parsing text...", style: TextStyle(color: textColor.withValues(alpha: 0.6))),
            ],
            if (parsedReceipt != null) ...[
              const SizedBox(height: 25),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(18),
                decoration: BoxDecoration(
                  color: getCategoryByName(parsedReceipt!.category).color.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: getCategoryByName(parsedReceipt!.category).color.withValues(alpha: 0.4),
                  ),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        CircleAvatar(
                          radius: 18,
                          backgroundColor: getCategoryByName(parsedReceipt!.category).color.withValues(alpha: 0.2),
                          child: Text(getCategoryByName(parsedReceipt!.category).emoji ?? "🏷️", style: const TextStyle(fontSize: 18)),
                        ),
                        const SizedBox(width: 10),
                        Text(
                          "Category: ${parsedReceipt!.category}",
                          style: TextStyle(
                            color: textColor,
                            fontWeight: FontWeight.bold,
                            fontSize: 17,
                          ),
                        ),
                        const Spacer(),
                      ],
                    ),
                    const SizedBox(height: 14),
                    TextField(
                      controller: amountEditController,
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      style: TextStyle(color: textColor, fontSize: 20, fontWeight: FontWeight.bold),
                      decoration: InputDecoration(
                        labelText: "Detected Total Amount (₹)",
                        labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 14),
                        prefixIcon: const Icon(Icons.currency_rupee, color: Color(0xff7B4DFF)),
                        filled: true,
                        fillColor: cardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    TextField(
                      controller: merchantEditController,
                      style: TextStyle(color: textColor, fontSize: 15),
                      decoration: InputDecoration(
                        labelText: "Merchant / Item Description",
                        labelStyle: TextStyle(color: textColor.withValues(alpha: 0.7), fontSize: 14),
                        prefixIcon: const Icon(Icons.storefront_outlined, color: Color(0xff7B4DFF)),
                        filled: true,
                        fillColor: cardColor,
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(12), borderSide: BorderSide.none),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          value: selectedCategory,
                          dropdownColor: cardColor,
                          isExpanded: true,
                          style: TextStyle(color: textColor, fontSize: 15),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            labelText: "Category",
                            labelStyle: TextStyle(fontWeight: FontWeight.w600),
                            prefixIcon: Icon(Icons.category_outlined, color: Color(0xff7B4DFF)),
                          ),
                          items: expenseCategories.map((e) {
                            return DropdownMenuItem(
                              value: e.name,
                              child: Row(
                                children: [
                                  Text(e.emoji ?? "\u{1F3F7}\u{FE0F}", style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 10),
                                  Text(e.name, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => selectedCategory = val);
                          },
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Container(
                      decoration: BoxDecoration(
                        color: cardColor,
                        borderRadius: BorderRadius.circular(14),
                        border: Border.all(color: isDark ? Colors.white12 : Colors.grey.shade200),
                      ),
                      padding: const EdgeInsets.symmetric(horizontal: 14),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButtonFormField<String>(
                          value: selectedPayment,
                          dropdownColor: cardColor,
                          isExpanded: true,
                          style: TextStyle(color: textColor, fontSize: 15),
                          decoration: const InputDecoration(
                            border: InputBorder.none,
                            labelText: "Payment Method",
                            labelStyle: TextStyle(fontWeight: FontWeight.w600),
                            prefixIcon: Icon(Icons.payment_outlined, color: Color(0xff7B4DFF)),
                          ),
                          items: paymentMethods.map((method) {
                            return DropdownMenuItem(
                              value: method,
                              child: Row(
                                children: [
                                  Text(paymentMethodEmojis[method] ?? "\u{1F4B0}", style: const TextStyle(fontSize: 20)),
                                  const SizedBox(width: 10),
                                  Text(method, style: TextStyle(color: textColor, fontWeight: FontWeight.w500)),
                                ],
                              ),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) setState(() => selectedPayment = val);
                          },
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                height: 52,
                child: ElevatedButton.icon(
                  onPressed: saveExpense,
                  icon: const Icon(Icons.check_circle_outline, color: Colors.white),
                  label: const Text("Save Expense", style: TextStyle(fontSize: 17, fontWeight: FontWeight.bold, color: Colors.white)),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: const Color(0xff7B4DFF),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                  ),
                ),
              ),
            ],
            const SizedBox(height: 25),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                "Raw Extracted Text",
                style: TextStyle(color: textColor, fontSize: 18, fontWeight: FontWeight.bold),
              ),
            ),
            const SizedBox(height: 12),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: cardColor,
                borderRadius: BorderRadius.circular(15),
              ),
              child: Text(
                extractedText,
                style: TextStyle(color: textColor, height: 1.4, fontSize: 13),
              ),
            ),
            const SizedBox(height: 80),
          ],
        ),
      ),
    );
  }
}
