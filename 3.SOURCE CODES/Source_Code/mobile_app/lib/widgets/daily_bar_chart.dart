import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import '../models/daily_stat_model.dart';

class DailyBarChart extends StatelessWidget {
  final List<DailyStatModel> stats;

  const DailyBarChart({
    super.key,
    required this.stats,
  });

  @override
  Widget build(BuildContext context) {
    if (stats.isEmpty) {
      return const Center(
        child: Text(
          "Günlük veri yok",
          style: TextStyle(color: Colors.black54),
        ),
      );
    }

    final maxValue =
        stats.map((e) => e.total).reduce((a, b) => a > b ? a : b);

    return AspectRatio(
      aspectRatio: 1.7,
      child: BarChart(
        BarChartData(
          alignment: BarChartAlignment.spaceAround,
          maxY: maxValue * 1.2,

          // =========================
          // TOUCH / TOOLTIP
          // =========================
          barTouchData: BarTouchData(
            enabled: true,
            touchTooltipData: BarTouchTooltipData(
              tooltipBgColor: Colors.deepPurple,
              tooltipRoundedRadius: 8,
              getTooltipItem: (group, groupIndex, rod, rodIndex) {
                final stat = stats[group.x.toInt()];
                return BarTooltipItem(
                  "${stat.dayLabel}\n",
                  const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                  children: [
                    TextSpan(
                      text: "${rod.toY.toStringAsFixed(0)} ₺",
                      style: const TextStyle(
                        color: Colors.white70,
                        fontSize: 11,
                      ),
                    ),
                  ],
                );
              },
            ),
          ),

          // =========================
          // GRID
          // =========================
          gridData: FlGridData(
            show: true,
            drawVerticalLine: false,
            horizontalInterval: maxValue / 4,
            getDrawingHorizontalLine: (value) => FlLine(
              color: Colors.grey.shade300,
              strokeWidth: 1,
            ),
          ),

          borderData: FlBorderData(show: false),

          // =========================
          // AXIS TITLES
          // =========================
          titlesData: FlTitlesData(
            rightTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),
            topTitles: const AxisTitles(
              sideTitles: SideTitles(showTitles: false),
            ),

            // LEFT (₺)
            leftTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                reservedSize: 44,
                interval: maxValue / 4,
                getTitlesWidget: (value, _) {
                  return Text(
                    "${value.toInt()} ₺",
                    style: const TextStyle(
                      fontSize: 10,
                      color: Colors.black54,
                    ),
                  );
                },
              ),
            ),

            // BOTTOM (GÜN)
            bottomTitles: AxisTitles(
              sideTitles: SideTitles(
                showTitles: true,
                getTitlesWidget: (value, _) {
                  final i = value.toInt();
                  if (i < 0 || i >= stats.length) {
                    return const SizedBox();
                  }

                  return Padding(
                    padding: const EdgeInsets.only(top: 6),
                    child: Text(
                      stats[i].dayLabel,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  );
                },
              ),
            ),
          ),

          // =========================
          // BAR DATA
          // =========================
          barGroups: List.generate(stats.length, (i) {
            return BarChartGroupData(
              x: i,
              barRods: [
                BarChartRodData(
                  toY: stats[i].total,
                  width: 16,
                  color: Colors.deepPurple,
                  borderRadius: BorderRadius.circular(6),
                ),
              ],
            );
          }),
        ),
      ),
    );
  }
}
