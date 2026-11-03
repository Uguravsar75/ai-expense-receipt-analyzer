import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pdf/pdf.dart';
import 'package:pdf/widgets.dart' as pw;
import 'package:printing/printing.dart';

import '../auth/auth_storage.dart';
import '../main.dart' show themeNotifier, localeNotifier;
import '../services/expense_service.dart';
import '../models/stats_models.dart';
import '../utils/ui_constants.dart';
import '../utils/app_strings.dart';

class ProfileScreen extends StatefulWidget {
  const ProfileScreen({super.key});

  @override
  State<ProfileScreen> createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  late Future<Map<String, dynamic>> _insightsFuture;
  final _money = NumberFormat.currency(locale: 'tr_TR', symbol: '₺', decimalDigits: 0);

  String _selectedLanguage = 'Türkçe';

  static const _languages = [
    {'code': 'tr', 'name': 'Türkçe', 'flag': '🇹🇷', 'label': 'Türk dili'},
    {'code': 'en', 'name': 'English', 'flag': '🇬🇧', 'label': 'English'},
  ];

  @override
  void initState() {
    super.initState();
    _insightsFuture = ExpenseService.getInsights();
    _loadPrefs();
  }

  Future<void> _loadPrefs() async {
    final prefs = await SharedPreferences.getInstance();
    final savedCode = prefs.getString('locale_code') ?? 'tr';
    final lang = _languages.firstWhere(
      (l) => l['code'] == savedCode,
      orElse: () => _languages.first,
    )['name']!;
    setState(() => _selectedLanguage = lang);
  }

  Future<void> _setLanguage(String lang) async {
    final code = _languages.firstWhere(
      (l) => l['name'] == lang,
      orElse: () => _languages.first,
    )['code']!;
    await localeNotifier.setLocale(code);
    setState(() => _selectedLanguage = lang);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${AppStrings.of(context).profileLangChanged}$lang'),
        duration: const Duration(seconds: 2),
      ));
    }
  }

  Future<void> _refresh() async {
    setState(() => _insightsFuture = ExpenseService.getInsights());
    await _insightsFuture;
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.of(context).profileTitle),
        centerTitle: true,
      ),
      body: RefreshIndicator(
        onRefresh: _refresh,
        child: ListView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(UI.pagePadding),
          children: [
            _profileHeader(cs),
            const SizedBox(height: UI.sectionSpacing),
            _statsSection(cs),
            const SizedBox(height: UI.sectionSpacing),
            _settingsSection(cs, isDark),
            const SizedBox(height: UI.sectionSpacing),
            _actionsSection(cs),
            const SizedBox(height: 24),
            _appVersion(cs),
          ],
        ),
      ),
    );
  }

  // ── HEADER ────────────────────────────────────────────────
  Widget _profileHeader(ColorScheme cs) {
    return FutureBuilder<List<String?>>(
      future: Future.wait([AuthStorage.getName(), AuthStorage.getEmail()]),
      builder: (context, snapshot) {
        final name = snapshot.data?[0];
        final email = snapshot.data?[1];
        final displayName =
            (name != null && name.trim().isNotEmpty) ? name : (email ?? (AppStrings.of(context).isEn ? "User" : "Kullanıcı"));
        final initials = displayName.isNotEmpty ? displayName[0].toUpperCase() : "?";

        return Container(
          padding: const EdgeInsets.all(20),
          decoration: BoxDecoration(
            gradient: LinearGradient(
              colors: [cs.primary, cs.primary.withValues(alpha: 0.75)],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
            borderRadius: BorderRadius.circular(UI.cardRadius),
          ),
          child: Row(
            children: [
              CircleAvatar(
                radius: 36,
                backgroundColor: Colors.white24,
                child: Text(initials,
                    style: const TextStyle(
                        color: Colors.white,
                        fontSize: 28,
                        fontWeight: FontWeight.bold)),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(displayName,
                        style: const TextStyle(
                            color: Colors.white,
                            fontWeight: FontWeight.bold,
                            fontSize: 20)),
                    if (email != null && email.trim().isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(email,
                          style: const TextStyle(
                              color: Colors.white70, fontSize: 13)),
                    ],
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 10, vertical: 4),
                      decoration: BoxDecoration(
                        color: Colors.white24,
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Text(AppStrings.of(context).profileActiveUser,
                          style:
                              TextStyle(color: Colors.white, fontSize: 11)),
                    ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  // ── STATS ─────────────────────────────────────────────────
  Widget _statsSection(ColorScheme cs) {
    return FutureBuilder<Map<String, dynamic>>(
      future: _insightsFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const SizedBox(
              height: 80, child: Center(child: CircularProgressIndicator()));
        }
        if (snapshot.hasError || !snapshot.hasData) {
          return const SizedBox.shrink();
        }
        final summary = SummaryModel.fromJson(snapshot.data!['summary']);
        final catCount = (snapshot.data!['categoryStats'] as List).length;

        return Row(
          children: [
            Expanded(child: _statCard(AppStrings.of(context).profileTotalExpense,
                _money.format(summary.totalAmount), Icons.account_balance_wallet, cs)),
            const SizedBox(width: 10),
            Expanded(child: _statCard(AppStrings.of(context).profileDailyAvg,
                _money.format(summary.averageDaily), Icons.today, cs)),
            const SizedBox(width: 10),
            Expanded(child: _statCard(AppStrings.of(context).profileCategory,
                "$catCount", Icons.category, cs)),
          ],
        );
      },
    );
  }

  Widget _statCard(String label, String value, IconData icon, ColorScheme cs) {
    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(UI.cardRadius)),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 8),
        child: Column(
          children: [
            Icon(icon, color: cs.primary, size: 22),
            const SizedBox(height: 6),
            Text(value,
                style: TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 14,
                    color: cs.onSurface),
                textAlign: TextAlign.center),
            const SizedBox(height: 2),
            Text(label,
                style: TextStyle(
                    fontSize: 11, color: cs.onSurface.withValues(alpha:0.55)),
                textAlign: TextAlign.center),
          ],
        ),
      ),
    );
  }

  // ── SETTINGS ──────────────────────────────────────────────
  Widget _settingsSection(ColorScheme cs, bool isDark) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(AppStrings.of(context).profileSettings, cs),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UI.cardRadius)),
          child: Column(
            children: [
              // Karanlık Mod
              ListenableBuilder(
                listenable: themeNotifier,
                builder: (_, __) => SwitchListTile(
                  secondary: Icon(
                    themeNotifier.isDark ? Icons.dark_mode : Icons.light_mode,
                    color: cs.primary,
                  ),
                  title: Text(AppStrings.of(context).profileDarkMode,
                      style: TextStyle(color: cs.onSurface)),
                  subtitle: Text(themeNotifier.isDark ? AppStrings.of(context).profileDarkOn : AppStrings.of(context).profileDarkOff,
                      style: TextStyle(
                          fontSize: 12,
                          color: cs.onSurface.withValues(alpha:0.6))),
                  value: themeNotifier.isDark,
                  activeThumbColor: cs.primary,
                  onChanged: (_) => themeNotifier.toggle(),
                ),
              ),

              Divider(height: 1, indent: 16, endIndent: 16,
                  color: cs.onSurface.withValues(alpha:0.1)),

              // Dil
              ListTile(
                leading: Text(
                  _languages.firstWhere(
                    (l) => l['name'] == _selectedLanguage,
                    orElse: () => _languages.first,
                  )['flag']!,
                  style: const TextStyle(fontSize: 22),
                ),
                title: Text(AppStrings.of(context).profileLanguage, style: TextStyle(color: cs.onSurface)),
                subtitle: Text(_selectedLanguage,
                    style: TextStyle(
                        fontSize: 12,
                        color: cs.onSurface.withValues(alpha:0.6))),
                trailing: Icon(Icons.arrow_forward_ios,
                    size: 14, color: cs.onSurface.withValues(alpha:0.4)),
                onTap: () => _showLanguageDialog(cs),
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── ACTIONS ───────────────────────────────────────────────
  Widget _actionsSection(ColorScheme cs) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        _sectionTitle(AppStrings.of(context).profileAccount, cs),
        const SizedBox(height: 8),
        Card(
          elevation: 0,
          shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(UI.cardRadius)),
          child: Column(
            children: [
              ListTile(
                leading: Icon(Icons.picture_as_pdf, color: cs.primary),
                title: Text(AppStrings.of(context).profileReport,
                    style: TextStyle(color: cs.onSurface)),
                subtitle: Text(AppStrings.of(context).profileReportSub,
                    style: TextStyle(fontSize: 12,
                        color: cs.onSurface.withValues(alpha: 0.5))),
                trailing: Icon(Icons.arrow_forward_ios,
                    size: 14, color: cs.onSurface.withValues(alpha: 0.4)),
                onTap: _generatePdfReport,
              ),
              Divider(height: 1, indent: 16, endIndent: 16,
                  color: cs.onSurface.withValues(alpha: 0.1)),
              ListTile(
                leading: const Icon(Icons.delete_sweep, color: Colors.orange),
                title: Text(AppStrings.of(context).profileDeleteAll,
                    style: TextStyle(color: cs.onSurface)),
                subtitle: Text(AppStrings.of(context).profileDeleteSub,
                    style:
                        const TextStyle(fontSize: 12, color: Colors.orange)),
                trailing: Icon(Icons.arrow_forward_ios,
                    size: 14, color: cs.onSurface.withValues(alpha:0.4)),
                onTap: _deleteAllExpenses,
              ),
              Divider(height: 1, indent: 16, endIndent: 16,
                  color: cs.onSurface.withValues(alpha:0.1)),
              ListTile(
                leading: const Icon(Icons.logout, color: Colors.red),
                title: Text(AppStrings.of(context).profileLogout,
                    style: const TextStyle(color: Colors.red)),
                trailing: Icon(Icons.arrow_forward_ios,
                    size: 14, color: cs.onSurface.withValues(alpha:0.4)),
                onTap: _logout,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _sectionTitle(String title, ColorScheme cs) {
    return Text(title,
        style: TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w600,
            color: cs.onSurface.withValues(alpha:0.5),
            letterSpacing: 0.5));
  }

  Widget _appVersion(ColorScheme cs) {
    return Center(
      child: Text("FaturaAnaliz v1.0.0",
          style: TextStyle(
              fontSize: 12, color: cs.onSurface.withValues(alpha:0.3))),
    );
  }

  // ── DİL DİYALOĞU ──────────────────────────────────────────
  void _showLanguageDialog(ColorScheme cs) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(AppStrings.of(ctx).profileSelectLang),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: _languages.map((lang) {
            final name = lang['name']!;
            final flag = lang['flag']!;
            final label = lang['label']!;
            final selected = name == _selectedLanguage;
            return ListTile(
              contentPadding: EdgeInsets.zero,
              leading: Text(flag, style: const TextStyle(fontSize: 24)),
              title: Text(name,
                  style: TextStyle(
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                      color: selected ? cs.primary : cs.onSurface)),
              subtitle: Text(label,
                  style: TextStyle(fontSize: 11, color: cs.onSurface.withValues(alpha: 0.5))),
              trailing: selected
                  ? Icon(Icons.check_circle, color: cs.primary, size: 20)
                  : null,
              onTap: () {
                Navigator.pop(ctx);
                _setLanguage(name);
              },
            );
          }).toList(),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: Text(AppStrings.of(ctx).cancel),
          ),
        ],
      ),
    );
  }

  // ── PDF RAPORU ────────────────────────────────────────────
  Future<void> _generatePdfReport() async {
    try {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).profilePdfPreparing), duration: const Duration(seconds: 2)),
      );

      final insights = await ExpenseService.getInsights();
      final summary = SummaryModel.fromJson(insights['summary']);
      final categories = (insights['categoryStats'] as List)
          .map((e) => CategoryStatModel.fromJson(e))
          .toList();

      final now = DateTime.now();
      final monthName = DateFormat('MMMM yyyy', 'tr_TR').format(now);

      final pdf = pw.Document();
      final accentColor = PdfColor.fromHex('#5C35CC');
      final lightBg = PdfColor.fromHex('#F5F3FF');

      pdf.addPage(pw.MultiPage(
        pageFormat: PdfPageFormat.a4,
        margin: const pw.EdgeInsets.all(32),
        build: (pw.Context ctx) => [
          // Başlık
          pw.Container(
            padding: const pw.EdgeInsets.all(16),
            decoration: pw.BoxDecoration(
              color: accentColor,
              borderRadius: const pw.BorderRadius.all(pw.Radius.circular(12)),
            ),
            child: pw.Column(
              crossAxisAlignment: pw.CrossAxisAlignment.start,
              children: [
                pw.Text('FaturaAnaliz',
                    style: pw.TextStyle(color: PdfColors.white, fontSize: 22,
                        fontWeight: pw.FontWeight.bold)),
                pw.SizedBox(height: 4),
                pw.Text('${AppStrings.of(context).profilePdfReport} — $monthName',
                    style: pw.TextStyle(color: const PdfColor(1, 1, 1, 0.7), fontSize: 13)),
              ],
            ),
          ),
          pw.SizedBox(height: 20),

          // Özet kutular
          pw.Row(children: [
            _pdfStatBox('Toplam Harcama', _money.format(summary.totalAmount), accentColor),
            pw.SizedBox(width: 10),
            _pdfStatBox('Günlük Ort.', _money.format(summary.averageDaily), PdfColor.fromHex('#4CAF50')),
            pw.SizedBox(width: 10),
            _pdfStatBox('En Çok', summary.topCategory, PdfColor.fromHex('#FF9800')),
          ]),
          pw.SizedBox(height: 20),

          // Kategori tablosu
          pw.Text(AppStrings.of(context).statsCategoryDist,
              style: pw.TextStyle(fontSize: 14, fontWeight: pw.FontWeight.bold)),
          pw.SizedBox(height: 8),
          pw.Table(
            border: pw.TableBorder.all(color: PdfColors.grey300, width: 0.5),
            columnWidths: {
              0: const pw.FlexColumnWidth(3),
              1: const pw.FlexColumnWidth(2),
              2: const pw.FlexColumnWidth(1.5),
            },
            children: [
              pw.TableRow(
                decoration: pw.BoxDecoration(color: accentColor),
                children: [
                  _pdfHeaderCell(AppStrings.of(context).profilePdfCategory),
                  _pdfHeaderCell(AppStrings.of(context).profilePdfAmount),
                  _pdfHeaderCell(AppStrings.of(context).profilePdfRatio),
                ],
              ),
              ...categories.map((cat) => pw.TableRow(
                decoration: pw.BoxDecoration(
                    color: categories.indexOf(cat).isEven ? lightBg : PdfColors.white),
                children: [
                  _pdfCell(cat.category),
                  _pdfCell(_money.format(cat.total)),
                  _pdfCell('%${cat.percentage.toStringAsFixed(1)}'),
                ],
              )),
            ],
          ),
          pw.SizedBox(height: 20),

          // Alt bilgi
          pw.Divider(color: PdfColors.grey300),
          pw.SizedBox(height: 8),
          pw.Text('${AppStrings.of(context).profilePdfCreated}${DateFormat('dd.MM.yyyy HH:mm').format(now)}',
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
          pw.Text(AppStrings.of(context).profilePdfFooter,
              style: const pw.TextStyle(fontSize: 10, color: PdfColors.grey600)),
        ],
      ));

      final bytes = await pdf.save();
      await Printing.sharePdf(bytes: bytes,
          filename: 'FaturaAnaliz_$monthName.pdf');
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.of(context).profilePdfError}$e'), backgroundColor: Colors.red),
      );
    }
  }

  pw.Widget _pdfStatBox(String label, String value, PdfColor color) =>
      pw.Expanded(
        child: pw.Container(
          padding: const pw.EdgeInsets.all(10),
          decoration: pw.BoxDecoration(
            color: color,
            borderRadius: const pw.BorderRadius.all(pw.Radius.circular(8)),
          ),
          child: pw.Column(
            crossAxisAlignment: pw.CrossAxisAlignment.start,
            children: [
              pw.Text(value, style: pw.TextStyle(color: PdfColors.white,
                  fontWeight: pw.FontWeight.bold, fontSize: 13)),
              pw.SizedBox(height: 2),
              pw.Text(label, style: pw.TextStyle(color: const PdfColor(1, 1, 1, 0.7), fontSize: 10)),
            ],
          ),
        ),
      );

  pw.Widget _pdfHeaderCell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text,
            style: pw.TextStyle(color: PdfColors.white, fontWeight: pw.FontWeight.bold, fontSize: 11)),
      );

  pw.Widget _pdfCell(String text) => pw.Padding(
        padding: const pw.EdgeInsets.all(6),
        child: pw.Text(text, style: const pw.TextStyle(fontSize: 11)),
      );

  // ── DELETE & LOGOUT ───────────────────────────────────────
  Future<void> _deleteAllExpenses() async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) {
        final s = AppStrings.of(ctx);
        return AlertDialog(
          title: Text(s.profileDeleteConfirmTitle),
          content: Text(s.profileDeleteConfirmBody),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(ctx, false),
                child: Text(s.cancel)),
            ElevatedButton(
              style: ElevatedButton.styleFrom(backgroundColor: Colors.orange),
              onPressed: () => Navigator.pop(ctx, true),
              child: Text(s.profileDeleteYes,
                  style: const TextStyle(color: Colors.white)),
            ),
          ],
        );
      },
    );
    if (confirm != true) return;

    try {
      await ExpenseService.deleteAllExpenses();
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
          content: Text(AppStrings.of(context).profileDeleted),
          backgroundColor: Colors.orange));
      _refresh();
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("${AppStrings.of(context).error}: $e"), backgroundColor: Colors.red));
    }
  }

  Future<void> _logout() async {
    await AuthStorage.clear();
    if (!mounted) return;
    Navigator.of(context).pushNamedAndRemoveUntil("/login", (_) => false);
  }
}
