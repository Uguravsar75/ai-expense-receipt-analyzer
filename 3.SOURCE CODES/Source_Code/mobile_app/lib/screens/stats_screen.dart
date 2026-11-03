import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../services/expense_service.dart';
import '../utils/category_constants.dart';
import '../models/stats_models.dart';
import '../models/daily_stat_model.dart';
import '../widgets/category_pie_chart.dart';
import '../widgets/daily_bar_chart.dart';
import '../widgets/ai_widgets.dart';
import '../auth/auth_storage.dart';
import '../utils/ui_constants.dart';
import '../utils/app_strings.dart';
import '../widgets/shared_app_bar.dart';

class StatsScreen extends StatefulWidget {
  const StatsScreen({super.key});

  @override
  State<StatsScreen> createState() => _StatsScreenState();
}

class _StatsScreenState extends State<StatsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  // Özet & AI
  Future<Map<String, dynamic>>? _insightsFuture;
  Future<List<DailyStatModel>>? _dailyFuture;
  Future<Map<String, dynamic>>? _analyzeFuture;
  Future<Map<String, dynamic>>? _smartFuture;
  Future<Map<String, dynamic>>? _smartBudgetFuture;

  // Bütçe
  bool _budgetLoading = true;
  Map<String, Map<String, double>> _budgets = {};
  final Map<String, Map<String, double>> _spentMap = {};

  String? _fatalError;
  final _money = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

  static const _categories = [
    'Market', 'Yeme & İçme', 'Faturalar', 'Ulaşım',
    'Kira & Ev', 'Sağlık', 'Eğlence', 'Giyim', 'Eğitim', 'Diğer',
  ];

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
    _safeInit();
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  Future<void> _safeInit() async {
    final userId = await AuthStorage.getUserId();
    if (userId == null) {
      setState(() => _fatalError = AppStrings.current.statsSessionError);
      return;
    }
    setState(() {
      _insightsFuture = ExpenseService.getInsights();
      _dailyFuture = ExpenseService.getDailyStats(days: 7);
      _analyzeFuture = ExpenseService.analyzeExpenses();
      _smartFuture = ExpenseService.getSmartAnalysis();
      _smartBudgetFuture = ExpenseService.getSmartBudget();
    });
    await _loadBudget();
  }

  Future<void> _loadBudget() async {
    setState(() => _budgetLoading = true);
    try {
      final prefs = await SharedPreferences.getInstance();
      final raw = prefs.getString('budgets_v5');
      if (raw != null) {
        final decoded = jsonDecode(raw) as Map<String, dynamic>;
        _budgets = decoded.map((k, v) {
          final m = Map<String, dynamic>.from(v as Map);
          return MapEntry(k, m.map((pk, pv) => MapEntry(pk, (pv as num).toDouble())));
        });
      }
      final expenses = await ExpenseService.getExpenses();
      final now = DateTime.now();
      _spentMap.clear();
      for (final cat in _categories) {
        double g = 0, h = 0, a = 0;
        for (final e in expenses) {
          if (CategoryConstants.toTr(e.category) != cat) continue;
          final dt = DateTime.tryParse(e.createdAt ?? '') ?? now;
          if (dt.year == now.year && dt.month == now.month && dt.day == now.day) g += e.amount;
          if (now.difference(dt).inDays <= 7) h += e.amount;
          if (dt.year == now.year && dt.month == now.month) a += e.amount;
        }
        _spentMap[cat] = {'gunluk': g, 'haftalik': h, 'aylik': a};
      }
    } catch (_) {}
    if (mounted) setState(() => _budgetLoading = false);
  }

  Future<void> _saveBudget(String cat, Map<String, double> b) async {
    _budgets[cat] = b;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('budgets_v5', jsonEncode(_budgets));
    await _loadBudget();
  }

  @override
  Widget build(BuildContext context) {
    if (_fatalError != null) {
      return Scaffold(
        appBar: SharedAppBar(title: AppStrings.current.statsTitle),
        body: Center(child: Text(_fatalError!, style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)),
      );
    }

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.of(context).statsTitle),
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          isScrollable: true,
          tabs: [
            Tab(icon: const Icon(Icons.bar_chart, size: 18), text: AppStrings.of(context).statsTabSummary),
            Tab(icon: const Icon(Icons.smart_toy, size: 18), text: AppStrings.of(context).statsTabAI),
            Tab(icon: const Icon(Icons.track_changes, size: 18), text: AppStrings.of(context).statsTabBudget),
            Tab(icon: const Icon(Icons.compare_arrows, size: 18), text: AppStrings.of(context).statsTabMonthly),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            onPressed: _safeInit,
            tooltip: AppStrings.of(context).refresh,
          ),
        ],
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildOzetTab(),
          _buildAiTab(),
          _buildBudgetTab(),
          _buildMonthlyTab(),
        ],
      ),
    );
  }

  // ── TAB 1: ÖZET ──────────────────────────────────────────
  Widget _buildOzetTab() {
    return RefreshIndicator(
      onRefresh: _safeInit,
      child: ListView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(UI.pagePadding),
        children: [
          FutureBuilder<Map<String, dynamic>>(
            future: _insightsFuture,
            builder: (ctx, snap) {
              if (snap.connectionState == ConnectionState.waiting) {
                return const Center(child: Padding(padding: EdgeInsets.all(48), child: CircularProgressIndicator()));
              }
              if (snap.hasError) return _errorBox(snap.error.toString());
              final data = snap.data!;
              final summary = SummaryModel.fromJson(data['summary']);
              final categories = (data['categoryStats'] as List)
                  .map((e) => CategoryStatModel.fromJson(e)).toList();
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _summaryCard(AppStrings.of(ctx).statsTotalExpense, _money.format(summary.totalAmount), Icons.account_balance_wallet),
                  _summaryCard(AppStrings.of(ctx).statsDailyAvg, _money.format(summary.averageDaily), Icons.calendar_today),
                  _summaryCard(AppStrings.of(ctx).statsTopCategory, CategoryConstants.toTr(summary.topCategory), Icons.star),
                  const SizedBox(height: 20),
                  Text(AppStrings.of(ctx).statsCategoryDist, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  if (categories.isEmpty)
                    Center(child: Padding(padding: const EdgeInsets.all(24), child: Text(AppStrings.of(ctx).noData)))
                  else ...[
                    CategoryPieChart(categories: categories),
                    const SizedBox(height: 16),
                    _categoryLegend(categories),
                  ],
                  const SizedBox(height: 20),
                  Text(AppStrings.of(ctx).statsLast7Days, style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                  const SizedBox(height: 12),
                  FutureBuilder<List<DailyStatModel>>(
                    future: _dailyFuture,
                    builder: (ctx2, snap2) {
                      if (snap2.connectionState == ConnectionState.waiting) {
                        return const SizedBox(height: 160, child: Center(child: CircularProgressIndicator()));
                      }
                      if (snap2.hasError) return _errorBox(snap2.error.toString());
                      final stats = snap2.data!;
                      if (stats.isEmpty) return Center(child: Text(AppStrings.of(ctx2).noData));
                      return DailyBarChart(stats: stats);
                    },
                  ),
                ],
              );
            },
          ),
        ],
      ),
    );
  }

  // ── TAB 2: AI ANALİZ ──────────────────────────────────────
  Widget _buildAiTab() {
    return RefreshIndicator(
      onRefresh: _safeInit,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _analyzeFuture,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: AILoadingWidget());
          }
          if (snap.hasError) return _errorBox(snap.error.toString());
          final d = snap.data ?? {};
          final anomalies = d['anomalies'] as List? ?? [];
          final advice = d['budget_advice'] as Map? ?? {};
          final aiInsights = d['insights'] as List? ?? [];
          final forecast = d['forecast'] as Map? ?? {};
          final predictedMonthly = (forecast['predicted_monthly'] as num?)?.toDouble() ?? 0;
          final trend = forecast['trend'] as String? ?? '';
          final method = forecast['method'] as String? ?? '';

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              if (aiInsights.isNotEmpty) ...[
                Text(AppStrings.of(ctx).statsAiInsights, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...aiInsights.cast<String>().map((i) => Builder(builder: (context) {
                  final cs = Theme.of(context).colorScheme;
                  return Card(
                    elevation: 0,
                    color: cs.primaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(Icons.smart_toy, color: cs.primary),
                      title: Text(i, style: TextStyle(fontSize: 13, color: cs.onPrimaryContainer)),
                    ),
                  );
                })),
                const SizedBox(height: 16),
              ],
              if (anomalies.isNotEmpty) ...[
                Text(AppStrings.of(ctx).statsAnomalies, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: Colors.red)),
                const SizedBox(height: 8),
                ...anomalies.map((a) => AnomalyWarningBadge(
                  message: "${a['amount']?.toString() ?? '?'} ₺ — ${a['reason']?.toString() ?? 'Anormal'}",
                )),
                const SizedBox(height: 16),
              ],
              BudgetAdviceCard(
                riskLevel: advice['risk_level'] as String? ?? 'low',
                savingsPotential: (advice['savings_potential'] as num?)?.toDouble() ?? 0,
                adviceList: (advice['advice'] as List? ?? []).cast<String>(),
                warnings: (advice['warnings'] as List? ?? []).cast<String>(),
              ),
              if (predictedMonthly > 0) ...[
                const SizedBox(height: 16),
                Builder(builder: (context) {
                  final cs = Theme.of(context).colorScheme;
                  return Card(
                    elevation: 0,
                    color: cs.tertiaryContainer,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                      side: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
                    ),
                    child: Padding(
                      padding: const EdgeInsets.all(16),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(children: [
                            Icon(Icons.trending_up, color: cs.tertiary),
                            const SizedBox(width: 8),
                            Text(AppStrings.of(context).statsAiForecast, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: cs.onTertiaryContainer)),
                          ]),
                          const SizedBox(height: 12),
                          _row(AppStrings.of(context).statsMonthlyExpense, "${predictedMonthly.toStringAsFixed(0)} ₺"),
                          if (trend.isNotEmpty) _row(AppStrings.of(context).statsTrend, trend),
                          if (method.isNotEmpty && method != 'none') _row(AppStrings.of(context).statsModel, method),
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ],
          );
        },
      ),
    );
  }

  // ── TAB 3: BÜTÇE ──────────────────────────────────────────
  Widget _buildBudgetTab() {
    if (_budgetLoading) return const Center(child: CircularProgressIndicator());
    return ListView(
      padding: const EdgeInsets.all(16),
      children: [
        // AI Akıllı Bütçe Tahmini kartı
        FutureBuilder<Map<String, dynamic>>(
          future: _smartBudgetFuture,
          builder: (ctx, snap) {
            if (snap.connectionState == ConnectionState.waiting) {
              return const Padding(
                padding: EdgeInsets.only(bottom: 12),
                child: LinearProgressIndicator(),
              );
            }
            if (snap.hasError || !snap.hasData) return const SizedBox.shrink();
            final data = snap.data!;
            final summary = data['summary'] as String? ?? '';
            final items = (data['items'] as List?) ?? [];
            final totalRec = (data['total_recommended'] as num?)?.toDouble() ?? 0;
            if (items.isEmpty) return const SizedBox.shrink();
            return Builder(builder: (context) {
              final cs = Theme.of(context).colorScheme;
              return Card(
                elevation: 0,
                color: cs.tertiaryContainer,
                margin: const EdgeInsets.only(bottom: 12),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                  side: BorderSide(color: cs.outline.withValues(alpha: 0.3)),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(14),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(children: [
                        Icon(Icons.auto_awesome, color: cs.tertiary, size: 18),
                        const SizedBox(width: 8),
                        Text(AppStrings.of(context).statsAiBudget,
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: cs.onTertiaryContainer)),
                        const Spacer(),
                        Text(_money.format(totalRec),
                            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14, color: cs.tertiary)),
                      ]),
                      if (summary.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(summary, style: TextStyle(fontSize: 12, color: cs.onTertiaryContainer.withValues(alpha: 0.8))),
                      ],
                      const SizedBox(height: 10),
                      ...items.map((item) {
                        final m = item as Map;
                        final cat = m['category'] as String? ?? '';
                        final rec = (m['recommended'] as num?)?.toDouble() ?? 0;
                        final trend = m['trend'] as String? ?? 'sabit';
                        final icon = trend == 'artan'
                            ? Icons.trending_up
                            : trend == 'azalan'
                                ? Icons.trending_down
                                : Icons.trending_flat;
                        final trendColor = trend == 'artan'
                            ? Colors.red
                            : trend == 'azalan'
                                ? Colors.green
                                : cs.onTertiaryContainer;
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 3),
                          child: Row(children: [
                            Icon(icon, size: 14, color: trendColor),
                            const SizedBox(width: 6),
                            Expanded(child: Text(cat,
                                style: TextStyle(fontSize: 12, color: cs.onTertiaryContainer))),
                            Text(_money.format(rec),
                                style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600,
                                    color: cs.onTertiaryContainer)),
                          ]),
                        );
                      }),
                    ],
                  ),
                ),
              );
            });
          },
        ),
        Builder(builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return Card(
            elevation: 0,
            color: cs.secondaryContainer,
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cs.outline.withValues(alpha: 0.4))),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Text(
                AppStrings.of(context).statsBudgetHint,
                style: TextStyle(fontSize: 13, color: cs.onSecondaryContainer),
              ),
            ),
          );
        }),
        const SizedBox(height: 12),
        ..._categories.map((cat) => _budgetCard(cat)),
      ],
    );
  }

  Widget _budgetCard(String cat) {
    final budget = _budgets[cat] ?? {};
    final spent = _spentMap[cat] ?? {};
    final color = CategoryConstants.colorOf(cat);
    final icon = CategoryConstants.iconOf(cat);
    final aylikBudget = budget['aylik'] ?? 0;
    final aylikSpent = spent['aylik'] ?? 0;
    final progress = aylikBudget > 0 ? (aylikSpent / aylikBudget).clamp(0.0, 1.0) : 0.0;
    final isOver = aylikBudget > 0 && aylikSpent > aylikBudget;

    return Builder(builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 8),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12), side: BorderSide(color: cs.outlineVariant)),
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Icon(icon, color: color, size: 18),
                  const SizedBox(width: 8),
                  Text(cat, style: TextStyle(fontWeight: FontWeight.bold, color: cs.onSurface)),
                  const Spacer(),
                  TextButton.icon(
                    icon: const Icon(Icons.edit, size: 14),
                    label: Text(AppStrings.of(context).statsBudgetGoal, style: const TextStyle(fontSize: 12)),
                    onPressed: () => _showBudgetDialog(cat, budget),
                  ),
                ],
              ),
              if (aylikBudget > 0) ...[
                const SizedBox(height: 6),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text("${AppStrings.of(context).statsBudgetThisMonth}${_money.format(aylikSpent)}", style: TextStyle(fontSize: 12, color: isOver ? Colors.red : cs.onSurface.withValues(alpha: 0.6))),
                    Text("${AppStrings.of(context).statsBudgetTarget}${_money.format(aylikBudget)}", style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6))),
                  ],
                ),
                const SizedBox(height: 4),
                LinearProgressIndicator(
                  value: progress,
                  backgroundColor: cs.surfaceContainerHighest,
                  color: isOver ? Colors.red : color,
                  minHeight: 6,
                  borderRadius: BorderRadius.circular(4),
                ),
              ] else
                Text(AppStrings.of(context).statsBudgetNoGoal, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.4))),
            ],
          ),
        ),
      );
    });
  }

  void _showBudgetDialog(String cat, Map<String, double> current) {
    final gunlukCtrl = TextEditingController(text: current['gunluk']?.toStringAsFixed(0) ?? '');
    final haftalikCtrl = TextEditingController(text: current['haftalik']?.toStringAsFixed(0) ?? '');
    final aylikCtrl = TextEditingController(text: current['aylik']?.toStringAsFixed(0) ?? '');

    final s = AppStrings.current;
    showDialog(
      context: context,
      builder: (_) => AlertDialog(
        title: Text("$cat ${s.statsBudgetDialogTitle}"),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            TextField(controller: gunlukCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: s.statsBudgetDaily)),
            const SizedBox(height: 8),
            TextField(controller: haftalikCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: s.statsBudgetWeekly)),
            const SizedBox(height: 8),
            TextField(controller: aylikCtrl, keyboardType: TextInputType.number, decoration: InputDecoration(labelText: s.statsBudgetMonthly)),
          ],
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context), child: Text(s.cancel)),
          ElevatedButton(
            onPressed: () {
              Navigator.pop(context);
              _saveBudget(cat, {
                'gunluk': double.tryParse(gunlukCtrl.text) ?? 0,
                'haftalik': double.tryParse(haftalikCtrl.text) ?? 0,
                'aylik': double.tryParse(aylikCtrl.text) ?? 0,
              });
            },
            child: Text(s.save),
          ),
        ],
      ),
    );
  }

  // ── TAB 4: AYLIK KARŞILAŞTIRMA ────────────────────────────
  Widget _buildMonthlyTab() {
    return RefreshIndicator(
      onRefresh: _safeInit,
      child: FutureBuilder<Map<String, dynamic>>(
        future: _smartFuture,
        builder: (ctx, snap) {
          if (snap.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snap.hasError) return _errorBox(snap.error.toString());
          final d = snap.data ?? {};
          final thisTotal = (d['thisMonthTotal'] as num?)?.toDouble() ?? 0;
          final lastTotal = (d['lastMonthTotal'] as num?)?.toDouble() ?? 0;
          final changePct = (d['totalChangePct'] as num?)?.toDouble() ?? 0;
          final thisName = d['thisMonthName'] as String? ?? 'Bu ay';
          final lastName = d['lastMonthName'] as String? ?? 'Geçen ay';
          final insights = List<String>.from(d['insights'] ?? []);
          final comparisons = List<Map<String, dynamic>>.from(d['comparisons'] ?? []);

          return ListView(
            padding: const EdgeInsets.all(16),
            children: [
              // Ay karşılaştırma kartı
              Builder(builder: (context) {
                final cs = Theme.of(context).colorScheme;
                return Card(
                  elevation: 0,
                  color: changePct > 10 ? cs.errorContainer : changePct < -10 ? cs.secondaryContainer : cs.surfaceContainerLow,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(14),
                    side: BorderSide(color: cs.outlineVariant),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.spaceAround,
                          children: [
                            _monthBox(thisName, thisTotal, cs.primary),
                            Icon(
                              changePct > 0 ? Icons.trending_up : changePct < 0 ? Icons.trending_down : Icons.trending_flat,
                              size: 32,
                              color: changePct > 10 ? cs.error : changePct < -10 ? cs.secondary : cs.tertiary,
                            ),
                            _monthBox(lastName, lastTotal, cs.onSurface.withValues(alpha: 0.5)),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          changePct == 0 ? (AppStrings.of(context).isEn ? "Same as last month" : "Geçen ayla aynı") :
                          changePct > 0 ? "%${changePct.abs().toStringAsFixed(1)} ${AppStrings.of(context).isEn ? 'increase' : 'artış'}" :
                          "%${changePct.abs().toStringAsFixed(1)} ${AppStrings.of(context).isEn ? 'decrease' : 'azalış'}",
                          style: TextStyle(
                            fontWeight: FontWeight.bold,
                            color: changePct > 10 ? cs.error : changePct < -10 ? cs.secondary : cs.tertiary,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }),
              const SizedBox(height: 16),
              if (insights.isNotEmpty) ...[
                Text(AppStrings.of(ctx).statsAiInsights, style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...insights.map((i) => Builder(builder: (context) {
                  final cs = Theme.of(context).colorScheme;
                  return Card(
                    elevation: 0,
                    color: cs.primaryContainer,
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                    child: ListTile(
                      leading: Icon(Icons.lightbulb, color: cs.primary),
                      title: Text(i, style: TextStyle(fontSize: 13, color: cs.onPrimaryContainer)),
                    ),
                  );
                })),
                const SizedBox(height: 16),
              ],
              if (comparisons.isNotEmpty) ...[
                Text(AppStrings.of(ctx).isEn ? 'Category Comparison' : 'Kategori Karşılaştırması', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                ...comparisons.map((c) => Builder(builder: (context) {
                  final cs = Theme.of(context).colorScheme;
                  final cat = c['category'] as String? ?? '';
                  final thisAmt = (c['thisMonth'] as num?)?.toDouble() ?? 0;
                  final lastAmt = (c['lastMonth'] as num?)?.toDouble() ?? 0;
                  final diff = (c['changePct'] as num?)?.toDouble() ?? 0;
                  final color = CategoryConstants.colorOf(cat);
                  return Card(
                    elevation: 0,
                    margin: const EdgeInsets.only(bottom: 6),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10), side: BorderSide(color: cs.outlineVariant)),
                    child: ListTile(
                      leading: Icon(CategoryConstants.iconOf(cat), color: color, size: 20),
                      title: Text(CategoryConstants.toTr(cat), style: TextStyle(fontSize: 13, color: cs.onSurface)),
                      subtitle: Text("${_money.format(thisAmt)} / ${_money.format(lastAmt)}", style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.6))),
                      trailing: Text(
                        diff == 0 ? "=" : diff > 0 ? "+${diff.toStringAsFixed(0)}%" : "${diff.toStringAsFixed(0)}%",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          color: diff > 10 ? cs.error : diff < -10 ? cs.secondary : cs.onSurface.withValues(alpha: 0.5),
                        ),
                      ),
                    ),
                  );
                })),
              ],
            ],
          );
        },
      ),
    );
  }

  // ── YARDIMCI WİDGETLER ────────────────────────────────────
  Widget _monthBox(String name, double amount, Color color) {
    return Column(children: [
      Text(name, style: TextStyle(fontSize: 12, color: color)),
      const SizedBox(height: 4),
      Text(_money.format(amount), style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: color)),
    ]);
  }

  Widget _summaryCard(String title, String value, IconData icon) {
    return Builder(builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return Card(
        elevation: 0,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          child: Row(
            children: [
              Container(
                width: 38, height: 38,
                decoration: BoxDecoration(color: cs.primaryContainer, borderRadius: BorderRadius.circular(10)),
                child: Icon(icon, color: cs.primary),
              ),
              const SizedBox(width: 12),
              Expanded(child: Text(title, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.6)))),
              Text(value, style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16, color: cs.onSurface)),
            ],
          ),
        ),
      );
    });
  }

  Widget _categoryLegend(List<CategoryStatModel> cats) {
    return Wrap(
      spacing: 16, runSpacing: 10,
      children: cats.map((c) {
        final color = CategoryConstants.colorOf(c.category);
        return Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(width: 12, height: 12, decoration: BoxDecoration(color: color, shape: BoxShape.circle)),
            const SizedBox(width: 6),
            Text(CategoryConstants.toTr(c.category), style: const TextStyle(fontSize: 13)),
          ],
        );
      }).toList(),
    );
  }

  Widget _row(String label, String value) {
    return Builder(builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return Padding(
        padding: const EdgeInsets.only(bottom: 6),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: TextStyle(fontSize: 13, color: cs.onSurface.withValues(alpha: 0.7))),
            Text(value, style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold, color: cs.onSurface)),
          ],
        ),
      );
    });
  }

  Widget _errorBox(String msg) {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Center(child: Text("${AppStrings.current.error}: $msg", style: const TextStyle(color: Colors.red), textAlign: TextAlign.center)),
    );
  }
}
