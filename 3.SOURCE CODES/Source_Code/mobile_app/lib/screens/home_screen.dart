import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';

import '../models/expense.dart';
import '../services/expense_service.dart';
import '../utils/category_constants.dart';
import '../utils/app_strings.dart';
import 'add_expense_screen.dart';
import 'edit_expense_screen.dart';
import 'import_screen.dart';
import '../widgets/shared_app_bar.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  bool _isLoading = true;
  String? _error;

  double _monthlyTotal = 0;
  int _totalCount = 0;
  List<Map<String, dynamic>> _categoryStats = [];
  List<Map<String, dynamic>> _dailyStats = [];
  List<Expense> _recentExpenses = [];
  List<Expense> _allExpenses = [];

  int _touchedPieIndex = -1;

  final _money = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);
  final _moneyDec = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 2);

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() { _isLoading = true; _error = null; });
    try {
      final data = await ExpenseService.getDashboard();
      final all = await ExpenseService.getExpenses();
      if (!mounted) return;
      setState(() {
        _monthlyTotal = (data['monthlyTotal'] as num?)?.toDouble() ?? 0;
        _totalCount = (data['totalCount'] as num?)?.toInt() ?? 0;
        _categoryStats = List<Map<String, dynamic>>.from(data['categoryStats'] ?? []);
        _dailyStats = List<Map<String, dynamic>>.from(data['dailyStats'] ?? []);
        _recentExpenses = List<Map<String, dynamic>>.from(data['recentExpenses'] ?? [])
            .map((e) => Expense.fromJson(e))
            .toList();
        _allExpenses = all;
        _isLoading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() { _error = e.toString(); _isLoading = false; });
    }
  }

  Future<void> _openAddExpense() async {
    final refreshed = await Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => const AddExpenseScreen()),
    );
    if (refreshed == true && mounted) _load();
  }

  Future<void> _deleteExpense(Expense expense) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final s = AppStrings.of(ctx);
        return AlertDialog(
          title: Text(s.homeDeleteTitle),
          content: Text(s.homeDeleteConfirm),
          actions: [
            TextButton(onPressed: () => Navigator.pop(ctx, false), child: Text(s.cancel)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s.delete),
            ),
          ],
        );
      },
    );
    if (confirmed != true) return;
    try {
      await ExpenseService.deleteExpense(expense.id);
      if (mounted) _load();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text("Silme hatası: $e")));
      }
    }
  }

  // ===========================
  // BUILD
  // ===========================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: SharedAppBar(title: AppStrings.of(context).homeTitle, onRefresh: _load),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? _buildError()
              : RefreshIndicator(
                  onRefresh: _load,
                  child: ListView(
                    padding: const EdgeInsets.all(16),
                    children: [
                      _buildSummaryCard(),
                      const SizedBox(height: 16),
                      if (_categoryStats.isNotEmpty) ...[
                        _buildSectionTitle(AppStrings.of(context).homeCategoryDist),
                        const SizedBox(height: 8),
                        _buildPieChart(),
                        const SizedBox(height: 16),
                      ],
                      if (_dailyStats.isNotEmpty) ...[
                        _buildSectionTitle(AppStrings.of(context).homeLast7Days),
                        const SizedBox(height: 8),
                        _buildBarChart(),
                        const SizedBox(height: 16),
                      ],
                      _buildSectionTitle(AppStrings.of(context).homeRecentExpenses),
                      const SizedBox(height: 8),
                      ..._buildRecentList(),
                      const SizedBox(height: 80),
                    ],
                  ),
                ),
      floatingActionButton: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          FloatingActionButton.small(
            heroTag: "import",
            onPressed: () async {
              final refreshed = await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const ImportScreen()),
              );
              if (refreshed == true && mounted) _load();
            },
            tooltip: AppStrings.of(context).homeImportTooltip,
            backgroundColor: Colors.deepPurple.shade300,
            child: const Icon(Icons.upload_file, color: Colors.white),
          ),
          const SizedBox(height: 10),
          FloatingActionButton(
            heroTag: "add",
            onPressed: _openAddExpense,
            tooltip: AppStrings.of(context).homeAddTooltip,
            child: const Icon(Icons.add),
          ),
        ],
      ),
    );
  }

  // ===========================
  // SUMMARY CARD
  // ===========================
  Widget _buildSummaryCard() {
    return Container(
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: [Colors.deepPurple.shade600, Colors.deepPurple.shade400],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(16),
      ),
      padding: const EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(AppStrings.of(context).homeMonthlyTotal,
              style: const TextStyle(color: Colors.white70, fontSize: 13)),
          const SizedBox(height: 6),
          Text(
            _moneyDec.format(_monthlyTotal),
            style: const TextStyle(
                color: Colors.white, fontSize: 32, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              _summaryChip(Icons.receipt_long, "$_totalCount ${AppStrings.of(context).homeExpenses}"),
              const SizedBox(width: 10),
              if (_totalCount > 0)
                _summaryChip(Icons.bar_chart,
                    "${AppStrings.of(context).homeAvg} ${_money.format(_monthlyTotal / _totalCount.clamp(1, 9999))}"),
            ],
          ),
        ],
      ),
    );
  }

  Widget _summaryChip(IconData icon, String label) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.18),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Row(
        children: [
          Icon(icon, color: Colors.white, size: 14),
          const SizedBox(width: 5),
          Text(label, style: const TextStyle(color: Colors.white, fontSize: 12)),
        ],
      ),
    );
  }

  // ===========================
  // PIE CHART
  // ===========================
  Widget _buildPieChart() {
    final stats = _categoryStats.take(6).toList();
    final sections = stats.asMap().entries.map((entry) {
      final i = entry.key;
      final s = entry.value;
      final cat = s['category'] as String? ?? 'Diğer';
      final pct = (s['percentage'] as num?)?.toDouble() ?? 0;
      final isTouched = i == _touchedPieIndex;
      return PieChartSectionData(
        value: pct,
        color: CategoryConstants.colorOf(cat),
        radius: isTouched ? 70 : 55,
        title: pct >= 8 ? '%${pct.toStringAsFixed(0)}' : '',
        titleStyle: const TextStyle(fontSize: 11, fontWeight: FontWeight.bold, color: Colors.white),
      );
    }).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            SizedBox(
              width: 160,
              height: 160,
              child: PieChart(
                PieChartData(
                  sections: sections,
                  centerSpaceRadius: 34,
                  sectionsSpace: 2,
                  pieTouchData: PieTouchData(
                    touchCallback: (event, response) {
                      setState(() {
                        if (response?.touchedSection != null) {
                          _touchedPieIndex =
                              response!.touchedSection!.touchedSectionIndex;
                        } else {
                          _touchedPieIndex = -1;
                        }
                      });
                    },
                  ),
                ),
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: stats.asMap().entries.map((entry) {
                  final s = entry.value;
                  final cat = s['category'] as String? ?? 'Diğer';
                  final pct = (s['percentage'] as num?)?.toDouble() ?? 0;
                  final color = CategoryConstants.colorOf(cat);
                  return Padding(
                    padding: const EdgeInsets.only(bottom: 6),
                    child: Row(
                      children: [
                        Container(width: 10, height: 10,
                            decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
                        const SizedBox(width: 6),
                        Expanded(
                          child: Text(cat,
                              style: const TextStyle(fontSize: 11),
                              overflow: TextOverflow.ellipsis),
                        ),
                        Text('%${pct.toStringAsFixed(0)}',
                            style: TextStyle(fontSize: 11, color: color,
                                fontWeight: FontWeight.bold)),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ===========================
  // BAR CHART
  // ===========================
  Widget _buildBarChart() {
    if (_dailyStats.isEmpty) return const SizedBox.shrink();

    final maxVal = _dailyStats
        .map((d) => (d['total'] as num?)?.toDouble() ?? 0)
        .fold(0.0, (a, b) => a > b ? a : b);

    final bars = _dailyStats.asMap().entries.map((entry) {
      final i = entry.key;
      final d = entry.value;
      final val = (d['total'] as num?)?.toDouble() ?? 0;
      final date = d['date'] as String? ?? '';
      try {
        DateTime.parse(date);
      } catch (_) {}

      return BarChartGroupData(
        x: i,
        barRods: [
          BarChartRodData(
            toY: val,
            color: Colors.deepPurple.shade400,
            width: 18,
            borderRadius: BorderRadius.circular(4),
            backDrawRodData: BackgroundBarChartRodData(
              show: true,
              toY: maxVal * 1.2,
              color: Theme.of(context).colorScheme.surfaceContainerHighest,
            ),
          ),
        ],
      );
    }).toList();

    final labels = _dailyStats.map((d) {
      final date = d['date'] as String? ?? '';
      try {
        final dt = DateTime.parse(date);
        return DateFormat('d/M').format(dt);
      } catch (_) {
        return '';
      }
    }).toList();

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(12, 16, 16, 8),
        child: SizedBox(
          height: 160,
          child: BarChart(
            BarChartData(
              barGroups: bars,
              maxY: maxVal * 1.2,
              gridData: FlGridData(
                show: true,
                drawVerticalLine: false,
                getDrawingHorizontalLine: (_) =>
                    FlLine(color: Theme.of(context).colorScheme.outlineVariant, strokeWidth: 1),
              ),
              borderData: FlBorderData(show: false),
              titlesData: FlTitlesData(
                bottomTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    getTitlesWidget: (val, meta) {
                      final i = val.toInt();
                      if (i < 0 || i >= labels.length) return const SizedBox.shrink();
                      return Padding(
                        padding: const EdgeInsets.only(top: 4),
                        child: Text(labels[i],
                            style: TextStyle(fontSize: 10, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.6))),
                      );
                    },
                  ),
                ),
                leftTitles: AxisTitles(
                  sideTitles: SideTitles(
                    showTitles: true,
                    reservedSize: 40,
                    getTitlesWidget: (val, meta) {
                      if (val == 0) return const SizedBox.shrink();
                      return Text(_money.format(val),
                          style: TextStyle(fontSize: 9, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.45)));
                    },
                  ),
                ),
                topTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
                rightTitles: const AxisTitles(sideTitles: SideTitles(showTitles: false)),
              ),
              barTouchData: BarTouchData(
                touchTooltipData: BarTouchTooltipData(
                  getTooltipItem: (group, groupIndex, rod, rodIndex) {
                    return BarTooltipItem(
                      _moneyDec.format(rod.toY),
                      const TextStyle(color: Colors.white, fontSize: 11),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  // ===========================
  // RECENT EXPENSES LIST
  // ===========================
  List<Widget> _buildRecentList() {
    final toShow = _recentExpenses.isEmpty ? _allExpenses.take(5).toList() : _recentExpenses;

    if (toShow.isEmpty) {
      return [
        Card(
          elevation: 0,
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Center(
              child: Column(children: [
                Icon(Icons.shopping_cart_outlined, size: 48, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.3)),
                const SizedBox(height: 8),
                Text(AppStrings.of(context).homeNoExpenses.split('\n').first,
                    style: TextStyle(color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.5))),
                const SizedBox(height: 12),
                ElevatedButton.icon(
                  onPressed: _openAddExpense,
                  icon: const Icon(Icons.add),
                  label: Text(AppStrings.of(context).homeAddTooltip),
                ),
              ]),
            ),
          ),
        ),
      ];
    }

    return toShow.map((expense) => _buildExpenseCard(expense)).toList();
  }

  Widget _buildExpenseCard(Expense expense) {
    final categoryTr = CategoryConstants.toTr(expense.category);
    final color = CategoryConstants.colorOf(expense.category);
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      elevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
        child: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: color.withValues(alpha: 0.15),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(CategoryConstants.iconOf(expense.category), color: color, size: 20),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    expense.description?.isNotEmpty == true ? expense.description! : (AppStrings.of(context).addDescription),
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(fontWeight: FontWeight.w600, fontSize: 13),
                  ),
                  const SizedBox(height: 3),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                    decoration: BoxDecoration(
                      color: color,
                      borderRadius: BorderRadius.circular(10),
                    ),
                    child: Text(categoryTr,
                        style: const TextStyle(fontSize: 10, color: Colors.white,
                            fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  _moneyDec.format(expense.amount),
                  style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 14,
                      color: Theme.of(context).colorScheme.secondary),
                ),
                PopupMenuButton<String>(
                  icon: Icon(Icons.more_vert, color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.4), size: 18),
                  padding: EdgeInsets.zero,
                  onSelected: (value) async {
                    if (value == "delete") {
                      _deleteExpense(expense);
                    } else if (value == "edit") {
                      final refreshed = await Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (_) => EditExpenseScreen(expense: expense)),
                      );
                      if (refreshed == true && mounted) _load();
                    }
                  },
                  itemBuilder: (ctx) {
                    final s = AppStrings.of(ctx);
                    return [
                      PopupMenuItem(
                        value: "edit",
                        child: Row(children: [
                          const Icon(Icons.edit, color: Colors.blue, size: 18),
                          const SizedBox(width: 8),
                          Text(s.editTitle, style: const TextStyle(color: Colors.blue, fontSize: 13)),
                        ]),
                      ),
                      PopupMenuItem(
                        value: "delete",
                        child: Row(children: [
                          const Icon(Icons.delete, color: Colors.red, size: 18),
                          const SizedBox(width: 8),
                          Text(s.delete, style: const TextStyle(color: Colors.red, fontSize: 13)),
                        ]),
                      ),
                    ];
                  },
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ===========================
  // HELPERS
  // ===========================
  Widget _buildSectionTitle(String title) {
    return Text(title,
        style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold));
  }

  Widget _buildError() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.red.shade300),
          const SizedBox(height: 16),
          Text("${AppStrings.of(context).error}: $_error",
              textAlign: TextAlign.center,
              style: TextStyle(color: Colors.red.shade700)),
          const SizedBox(height: 16),
          ElevatedButton.icon(
            onPressed: _load,
            icon: const Icon(Icons.refresh),
            label: const Text("Tekrar Dene"),
          ),
        ],
      ),
    );
  }
}
