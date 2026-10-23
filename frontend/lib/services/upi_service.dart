import 'package:flutter/material.dart';
import 'package:url_launcher/url_launcher.dart';

class UpiPaymentData {
  final String payeeAddress;
  final String payeeName;
  final String? amount;
  final String? note;
  final String rawQr;

  UpiPaymentData({
    required this.payeeAddress,
    required this.payeeName,
    this.amount,
    this.note,
    required this.rawQr,
  });

  bool get isValid => payeeAddress.isNotEmpty;
}

class UpiApp {
  final String name;
  final String scheme;
  final String packageName;
  final IconData icon;
  final Color color;

  const UpiApp({
    required this.name,
    required this.scheme,
    required this.packageName,
    required this.icon,
    required this.color,
  });
}

class UpiService {
  static const List<UpiApp> supportedApps = [
    UpiApp(
      name: "Google Pay",
      scheme: "tez",
      packageName: "com.google.android.apps.nbu.paisa.user",
      icon: Icons.account_balance_wallet,
      color: Color(0xFF4285F4),
    ),
    UpiApp(
      name: "PhonePe",
      scheme: "phonepe",
      packageName: "com.phonepe.app",
      icon: Icons.phone_android,
      color: Color(0xFF5F259F),
    ),
    UpiApp(
      name: "Paytm",
      scheme: "paytmmp",
      packageName: "net.one97.paytm",
      icon: Icons.payment,
      color: Color(0xFF00BAF2),
    ),
    UpiApp(
      name: "Amazon Pay",
      scheme: "amazonpay",
      packageName: "in.amazon.mShop.android.shopping",
      icon: Icons.shopping_cart,
      color: Color(0xFFFF9900),
    ),
    UpiApp(
      name: "SuperMoney",
      scheme: "supermoney",
      packageName: "com.supermoney.app",
      icon: Icons.monetization_on,
      color: Color(0xFF00C853),
    ),
    UpiApp(
      name: "BHIM UPI",
      scheme: "upi",
      packageName: "in.org.npci.upiapp",
      icon: Icons.account_balance,
      color: Color(0xFF0066CC),
    ),
    UpiApp(
      name: "CRED Pay",
      scheme: "cred",
      packageName: "com.dreamplug.credint",
      icon: Icons.credit_card,
      color: Color(0xFF000000),
    ),
  ];


  static UpiPaymentData? parseQrCode(String qrData) {
    if (!qrData.toLowerCase().contains('upi://') &&
        !qrData.toLowerCase().contains('pa=')) {
      return null;
    }

    String data = qrData;
    if (!data.startsWith('upi://')) {
      final upiIndex = data.toLowerCase().indexOf('upi://');
      if (upiIndex >= 0) data = data.substring(upiIndex);
    }

    final uri = Uri.tryParse(data);
    if (uri == null) return null;

    final params = uri.queryParameters;

    return UpiPaymentData(
      payeeAddress: params['pa'] ?? '',
      payeeName: params['pn'] ?? params['tn'] ?? 'Merchant',
      amount: params['am'],
      note: params['tn'] ?? params['note'],
      rawQr: qrData,
    );
  }

  static String _formatAmount(String amount) {
    final parsed = double.tryParse(amount);
    if (parsed != null) {
      return parsed.toStringAsFixed(2);
    }
    return amount;
  }

  static String buildUpiUrl({
    required String payeeAddress,
    required String payeeName,
    required String amount,
    String? note,
    String scheme = 'upi',
  }) {
    final params = {
      'pa': payeeAddress,
      'pn': payeeName,
      'am': _formatAmount(amount),
      'cu': 'INR',
      if (note != null && note.isNotEmpty) 'tn': note,
    };

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return '$scheme://pay?$query';
  }

  static String buildIntentUrl({
    required String payeeAddress,
    required String payeeName,
    required String amount,
    String? note,
    required String packageName,
  }) {
    final params = {
      'pa': payeeAddress,
      'pn': payeeName,
      'am': _formatAmount(amount),
      'cu': 'INR',
      if (note != null && note.isNotEmpty) 'tn': note,
    };

    final query = params.entries
        .map((e) => '${e.key}=${Uri.encodeComponent(e.value)}')
        .join('&');

    return 'intent://pay?$query#Intent;scheme=upi;package=$packageName;end';
  }

  static Future<bool> launchPaymentApp(
    UpiApp app,
    UpiPaymentData data,
    String amount,
  ) async {
    final formattedAmount = _formatAmount(amount);

    // 1. Try launching with direct Android Intent URL targeting exact app package
    if (app.packageName.isNotEmpty) {
      final intentUrl = buildIntentUrl(
        payeeAddress: data.payeeAddress,
        payeeName: data.payeeName,
        amount: formattedAmount,
        note: data.note,
        packageName: app.packageName,
      );

      final intentUri = Uri.parse(intentUrl);
      try {
        final launched = await launchUrl(
          intentUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      } catch (_) {}
    }

    // 2. Try app specific scheme (e.g., tez://pay, phonepe://pay)
    final appSchemeUrl = buildUpiUrl(
      payeeAddress: data.payeeAddress,
      payeeName: data.payeeName,
      amount: formattedAmount,
      note: data.note,
      scheme: app.scheme,
    );

    final appSchemeUri = Uri.parse(appSchemeUrl);
    try {
      if (await canLaunchUrl(appSchemeUri)) {
        final launched = await launchUrl(
          appSchemeUri,
          mode: LaunchMode.externalApplication,
        );
        if (launched) return true;
      }
    } catch (_) {}

    // 3. Fallback to generic upi://pay URI
    final genericUrl = buildUpiUrl(
      payeeAddress: data.payeeAddress,
      payeeName: data.payeeName,
      amount: formattedAmount,
      note: data.note,
      scheme: 'upi',
    );

    final genericUri = Uri.parse(genericUrl);
    try {
      return await launchUrl(
        genericUri,
        mode: LaunchMode.externalApplication,
      );
    } catch (_) {
      return false;
    }
  }
}
