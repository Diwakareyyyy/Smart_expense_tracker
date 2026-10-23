import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';
import '../models/transaction_model.dart';

class PdfService {
  static Future<void> generateReport(
    List<TransactionModel> transactions, {
    String title = "Expense Report",
    String? subtitle,
  }) async {
    final pdf = pw.Document();

    final expenses = transactions.where((t) => t.type == "Expense").toList();
    double totalExpense = expenses.fold(0, (sum, t) => sum + t.amount);

    pdf.addPage(
      pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (context) => [
          pw.Center(
            child: pw.Text(
              "Smart AI Expense Tracker",
              style: pw.TextStyle(
                fontSize: 22,
                fontWeight: pw.FontWeight.bold,
                color: PdfColors.deepPurple,
              ),
            ),
          ),
          pw.SizedBox(height: 10),
          pw.Center(
            child: pw.Text(
              title,
              style: pw.TextStyle(
                fontSize: 16,
                fontWeight: pw.FontWeight.bold,
              ),
            ),
          ),
          if (subtitle != null && subtitle.isNotEmpty) ...[
            pw.SizedBox(height: 4),
            pw.Center(
              child: pw.Text(
                subtitle,
                style: const pw.TextStyle(
                  fontSize: 12,
                  color: PdfColors.grey700,
                ),
              ),
            ),
          ],
          pw.SizedBox(height: 15),
          pw.Divider(color: PdfColors.grey400),
          pw.SizedBox(height: 10),
          pw.Row(
            mainAxisAlignment: pw.MainAxisAlignment.spaceBetween,
            children: [
              pw.Text(
                "Total Expenses: INR ${totalExpense.toStringAsFixed(2)}",
                style: pw.TextStyle(
                  fontSize: 14,
                  fontWeight: pw.FontWeight.bold,
                ),
              ),
              pw.Text(
                "Total Items: ${expenses.length}",
                style: const pw.TextStyle(fontSize: 12, color: PdfColors.grey700),
              ),
            ],
          ),
          pw.SizedBox(height: 15),
          pw.Table.fromTextArray(
            headerStyle: pw.TextStyle(
              fontWeight: pw.FontWeight.bold,
              color: PdfColors.white,
            ),
            headerDecoration: const pw.BoxDecoration(
              color: PdfColors.deepPurple700,
            ),
            cellHeight: 30,
            cellAlignments: {
              0: pw.Alignment.centerLeft,
              1: pw.Alignment.centerLeft,
              2: pw.Alignment.centerRight,
              3: pw.Alignment.centerLeft,
            },
            headers: [
              "Date",
              "Category",
              "Amount",
              "Payment Method",
            ],
            data: expenses.map((t) {
              String formattedDate = t.date;
              if (formattedDate.contains("T")) {
                formattedDate = formattedDate.split("T").first;
              }
              return [
                formattedDate,
                t.category,
                "INR ${t.amount.toStringAsFixed(2)}",
                t.paymentMethod,
              ];
            }).toList(),
          ),
          pw.SizedBox(height: 30),
          pw.Divider(color: PdfColors.grey300),
          pw.Align(
            alignment: pw.Alignment.centerRight,
            child: pw.Text(
              "Generated on ${DateTime.now().day}/${DateTime.now().month}/${DateTime.now().year}",
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600),
            ),
          ),
        ],
      ),
    );

    await Printing.layoutPdf(
      onLayout: (format) async => pdf.save(),
    );
  }
}