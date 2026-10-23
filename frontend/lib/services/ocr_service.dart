import 'dart:convert';
import 'category_classifier.dart';
import 'api_client.dart';

class ParsedReceipt {
  final double? amount;
  final String merchant;
  final String category;
  final String paymentMethod;
  final String rawText;

  ParsedReceipt({
    this.amount,
    required this.merchant,
    required this.category,
    required this.paymentMethod,
    required this.rawText,
  });
}

class OcrService {
  static Future<ParsedReceipt?> parseReceiptTextOnline(String text) async {
    try {
      final response = await ApiClient.instance.post(
        '/api/ocr/parse-text',
        body: jsonEncode({'text': text}),
      ).timeout(const Duration(seconds: 8));

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data is Map) {
          final amountVal = data['amount'];
          final double? amount = amountVal != null ? (amountVal as num).toDouble() : null;
          return ParsedReceipt(
            amount: amount,
            merchant: data['merchant'] ?? 'Receipt Expense',
            category: data['category'] ?? 'Others',
            paymentMethod: data['payment_method'] ?? 'UPI',
            rawText: text,
          );
        }
      }
    } catch (e) {
      print("OcrService: parseReceiptTextOnline error, falling back to local: $e");
    }
    // Fallback to local parsing if offline or error
    return parseReceiptText(text);
  }

  static ParsedReceipt parseReceiptText(String text) {
    final amount = _extractAmount(text);
    final merchant = _extractMerchant(text);
    final category = CategoryClassifier.classify(text);
    final paymentMethod = _extractPaymentMethod(text);

    return ParsedReceipt(
      amount: amount,
      merchant: merchant,
      category: category,
      paymentMethod: paymentMethod,
      rawText: text,
    );
  }

  static double? _extractAmount(String text) {
    final cleanText = text.replaceAll('\r', '');

    // 1. Look for explicit total patterns with high priority
    final explicitTotalPatterns = [
      RegExp(r'(?:grand\s*total|net\s*amount|total\s*payable|amount\s*paid|total\s*amount)[^\d]*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'(?:total|amount|pay|paid)[^\d]*([\d,]+\.?\d*)', caseSensitive: false),
      RegExp(r'[₹]\s*([\d,]+\.\d{2})', caseSensitive: false),
      RegExp(r'[₹]\s*([\d,]+)(?!\s*:\s)', caseSensitive: false),
      RegExp(r'Rs\.?\s*([\d,]+\.\d{2})', caseSensitive: false),
    ];

    for (final pattern in explicitTotalPatterns) {
      final matches = pattern.allMatches(cleanText);
      for (final match in matches) {
        final raw = match.group(1)?.replaceAll(',', '') ?? '';
        final val = double.tryParse(raw);
        if (val != null && val > 0 && val < 1000000) {
          if (_isValidAmount(val, cleanText, raw)) {
            return val;
          }
        }
      }
    }

    // 2. Check for itemized bill amounts
    final lines = cleanText.split('\n');
    final List<double> lineItemAmounts = [];
    bool hasTableHeader = false;

    for (final line in lines) {
      final trimmed = line.trim();
      if (trimmed.isEmpty) continue;

      // Detect if this bill has a table structure (common in Indian bills)
      if (trimmed.toLowerCase().contains("qty") && trimmed.toLowerCase().contains("amount")) {
        hasTableHeader = true;
      }

      // Match item row amounts (line ending with "20.00" or "8.00")
      final lineAmountMatch = RegExp(r'(?<!\/)(?:^|\s)([\d,]+\.\d{2})(?:\s|$)').firstMatch(trimmed);
      if (lineAmountMatch != null) {
        final raw = lineAmountMatch.group(1)?.replaceAll(',', '') ?? '';
        final val = double.tryParse(raw);
        if (val != null && val > 0 && val < 50000) {
          if (!trimmed.toLowerCase().contains('/kg') &&
              !trimmed.toLowerCase().contains('/gm') &&
              !trimmed.toLowerCase().contains('total') &&
              !trimmed.toLowerCase().contains('grand') &&
              !trimmed.toLowerCase().contains('gst') &&
              !trimmed.toLowerCase().contains('cgst') &&
              !trimmed.toLowerCase().contains('sgst') &&
              !trimmed.toLowerCase().contains('tax')) {
            lineItemAmounts.add(val);
          }
        }
      }
    }

    if (lineItemAmounts.isNotEmpty && hasTableHeader) {
      if (lineItemAmounts.length > 1) {
        final sum = lineItemAmounts.reduce((a, b) => a + b);
        return double.parse(sum.toStringAsFixed(2));
      }
      return lineItemAmounts.first;
    }

    // 3. Fallback: Find highest reasonable standalone number
    double? maxFound;
    final numberMatches = RegExp(r'(?<!\d)([\d,]+\.\d{2}|[\d,]+)(?!\d)').allMatches(cleanText);
    for (final match in numberMatches) {
      final raw = match.group(1)?.replaceAll(',', '') ?? '';
      final val = double.tryParse(raw);
      if (val != null && val > 0 && val < 100000) {
        if (_isValidAmount(val, cleanText, raw)) {
          if (maxFound == null || val > maxFound) {
            maxFound = val;
          }
        }
      }
    }

    return maxFound;
  }

  static bool _isValidAmount(double val, String fullText, String rawStr) {
    if (fullText.contains('$rawStr:') || fullText.contains(':$rawStr')) return false;
    if (val >= 2020 && val <= 2030 && !rawStr.contains('.')) return false;
    if (val >= 1000 && val <= 9999 && fullText.contains('Bank $rawStr')) return false;
    if (rawStr.length >= 7 && !rawStr.contains('.')) return false;
    // Ignore standalone 2-digit or 3-digit numbers that look like item counts
    if (val < 10 && fullText.contains("qty $rawStr")) return false;
    // Ignore phone number fragments
    if (rawStr.length >= 10 && !rawStr.contains('.')) return false;

    return true;
  }

  static String _extractMerchant(String text) {
    // Check for "To: [Name]" in UPI payment screenshots
    final toMatch = RegExp(r'To:\s*([A-Za-z0-9\s]+)', caseSensitive: false).firstMatch(text);
    if (toMatch != null) {
      final name = toMatch.group(1)?.trim();
      if (name != null && name.isNotEmpty && name.length <= 30) {
        return name;
      }
    }

    // Check for "Receiver's bank" or "deposit of money to [Name]"
    final depositMatch = RegExp(r'money\s+to\s+([A-Za-z0-9\s]+?)(?:\x27s|\s+bank|$)', caseSensitive: false).firstMatch(text);
    if (depositMatch != null) {
      final name = depositMatch.group(1)?.trim();
      if (name != null && name.isNotEmpty && name.length <= 30) {
        return name;
      }
    }

    final lines = text.split('\n').where((l) => l.trim().isNotEmpty).toList();
    if (lines.isEmpty) return "Receipt Expense";

    for (final line in lines.take(5)) {
      final trimmed = line.trim();
      if (trimmed.length > 3 &&
          !RegExp(r'^\d').hasMatch(trimmed) &&
          !trimmed.toLowerCase().contains('receipt') &&
          !trimmed.toLowerCase().contains('invoice') &&
          !trimmed.toLowerCase().contains('completed') &&
          !trimmed.toLowerCase().contains('payment')) {
        return trimmed.length > 40 ? trimmed.substring(0, 40) : trimmed;
      }
    }

    return lines.first.trim();
  }

  static String _extractPaymentMethod(String text) {
    final lower = text.toLowerCase();
    if (lower.contains('upi') ||
        lower.contains('gpay') ||
        lower.contains('google pay') ||
        lower.contains('phonepe') ||
        lower.contains('paytm')) {
      return "UPI";
    }
    if (lower.contains('card') || lower.contains('visa') || lower.contains('mastercard')) {
      return "Card";
    }
    if (lower.contains('netbanking') || lower.contains('bank transfer') || lower.contains('neft')) {
      return "NetBanking";
    }
    return "UPI"; // Default to UPI for scanned digital receipts
  }
}
