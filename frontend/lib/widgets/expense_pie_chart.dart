import 'package:fl_chart/fl_chart.dart';
import 'package:flutter/material.dart';

class ExpensePieChart extends StatelessWidget {
  final double income;
  final double expense;

  const ExpensePieChart({
    super.key,
    required this.income,
    required this.expense,
  });

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 280,
      child: PieChart(
        PieChartData(
          centerSpaceRadius: 55,
          sectionsSpace: 3,
          sections: [

            PieChartSectionData(
              value: income,
              color: Colors.green,
              title: "Income",
              radius: 70,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),

            PieChartSectionData(
              value: expense,
              color: Colors.red,
              title: "Expense",
              radius: 70,
              titleStyle: const TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }
}