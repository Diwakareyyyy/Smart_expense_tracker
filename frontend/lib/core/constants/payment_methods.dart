import 'package:flutter/material.dart';

const List<String> paymentMethods = [
  "Cash",
  "UPI",
  "Card",
  "Bank",
  "Wallet",
];

const Map<String, IconData> paymentMethodIcons = {
  "Cash": Icons.money_rounded,
  "UPI": Icons.phone_android_rounded,
  "Card": Icons.credit_card_rounded,
  "Bank": Icons.account_balance_rounded,
  "Wallet": Icons.account_balance_wallet_rounded,
};

const Map<String, String> paymentMethodEmojis = {
  "Cash": "\u{1F4B5}",
  "UPI": "\u{1F4F1}",
  "Card": "\u{1F4B3}",
  "Bank": "\u{1F3E6}",
  "Wallet": "\u{1F45B}",
};