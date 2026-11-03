import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';

import '../models/stats_models.dart';
import '../utils/category_constants.dart';

class CategoryPieChart extends StatelessWidget {
  final List<CategoryStatModel> categories;

  const CategoryPieChart({
    super.key,
    required this.categories,
  });

  @override
  Widget build(BuildContext context) {
    if (categories.isEmpty) {
      return const Center(
        child: Text(
          "Kategori verisi yok",
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    return AspectRatio(
      aspectRatio: 1.25,
      child: PieChart(
        PieChartData(
          sectionsSpace: 3,
          centerSpaceRadius: 55, // 🎯 donut hissi
          startDegreeOffset: -90,
          sections: categories.map(_buildSection).toList(),
        ),
      ),
    );
  }

  PieChartSectionData _buildSection(CategoryStatModel c) {
    final color = CategoryConstants.colorOf(c.category);
    final trName = CategoryConstants.toTr(c.category);
    final bool showTitle = c.percentage > 5;

    return PieChartSectionData(
      color: color,
      value: c.percentage,
      radius: 70,
      showTitle: showTitle,
      title: "$trName\n${c.percentage.toStringAsFixed(0)}%",
      titleStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 11,
        height: 1.2,
      ),
      titlePositionPercentageOffset: 0.6,
    );
  }
}
