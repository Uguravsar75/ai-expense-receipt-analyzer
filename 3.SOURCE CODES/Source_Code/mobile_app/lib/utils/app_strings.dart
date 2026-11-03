import 'package:flutter/material.dart';
import '../main.dart' show localeNotifier;

class AppStrings {
  final bool _en;
  const AppStrings._(this._en);

  static AppStrings of(BuildContext context) {
    final locale = Localizations.localeOf(context);
    return AppStrings._(locale.languageCode == 'en');
  }

  static AppStrings get current =>
      AppStrings._(localeNotifier.locale.languageCode == 'en');

  bool get isEn => _en;

  // ── NAVİGASYON ──────────────────────────────────────────
  String get navHome        => _en ? 'Home'       : 'Ana Sayfa';
  String get navStats       => _en ? 'Statistics' : 'İstatistikler';
  String get navImport      => _en ? 'Import'     : 'İçe Aktar';
  String get navProfile     => _en ? 'Profile'    : 'Profil';

  // ── GENEL ───────────────────────────────────────────────
  String get cancel         => _en ? 'Cancel'  : 'İptal';
  String get save           => _en ? 'Save'    : 'Kaydet';
  String get delete         => _en ? 'Delete'  : 'Sil';
  String get confirm        => _en ? 'Confirm' : 'Onayla';
  String get yes            => _en ? 'Yes'     : 'Evet';
  String get no             => _en ? 'No'      : 'Hayır';
  String get loading        => _en ? 'Loading...' : 'Yükleniyor...';
  String get refresh        => _en ? 'Refresh' : 'Yenile';
  String get noData         => _en ? 'No data yet.' : 'Henüz veri yok.';
  String get error          => _en ? 'Error'   : 'Hata';
  String get close          => _en ? 'Close'   : 'Kapat';
  String get apply          => _en ? 'Apply'   : 'Uygula';

  // ── HOME ────────────────────────────────────────────────
  String get homeTitle           => _en ? 'Home'                  : 'Ana Sayfa';
  String get homeMonthlyTotal    => _en ? 'Monthly Total'         : 'Bu Ay Toplam Harcama';
  String get homeExpenses        => _en ? 'expenses'              : 'harcama';
  String get homeAvg             => _en ? 'Avg.'                  : 'Ort.';
  String get homeCategoryDist    => _en ? 'Category Breakdown'    : 'Kategori Dağılımı';
  String get homeLast7Days       => _en ? 'Last 7 Days'           : 'Son 7 Gün';
  String get homeRecentExpenses  => _en ? 'Recent Expenses'       : 'Son Harcamalar';
  String get homeDeleteTitle     => _en ? 'Delete Expense'        : 'Harcama Sil';
  String get homeDeleteConfirm   => _en ? 'Are you sure you want to delete this expense?' : 'Bu harcamayı silmek istediğine emin misin?';
  String get homeImportTooltip   => _en ? 'Import CSV/Excel'      : 'CSV/Excel İçe Aktar';
  String get homeAddTooltip      => _en ? 'Add Expense'           : 'Harcama Ekle';
  String get homeDeleteError     => _en ? 'Delete error: '        : 'Silme hatası: ';
  String get homeNoExpenses      => _en ? 'No expenses yet.\nTap + to add your first one.' : 'Henüz harcama yok.\n+ ile ilk harcamanı ekle.';

  // ── ADD EXPENSE ─────────────────────────────────────────
  String get addExpenseTitle     => _en ? 'Add Expense'           : 'Harcama Ekle';
  String get addAmount           => _en ? 'Amount'                : 'Tutar';
  String get addAmountHint       => _en ? 'e.g. 125.50'           : 'Örn: 125,50';
  String get addAmountEmpty      => _en ? 'Amount cannot be empty': 'Tutar boş olamaz';
  String get addAmountInvalid    => _en ? 'Enter a valid number'  : 'Geçerli bir sayı gir';
  String get addAmountZero       => _en ? 'Amount must be greater than 0' : 'Tutar 0\'dan büyük olmalı';
  String get addAmountTooLarge   => _en ? 'Value is too large'    : 'Çok büyük bir değer girdin';
  String get addDescription      => _en ? 'Description'           : 'Açıklama';
  String get addCategory         => _en ? 'Category'              : 'Kategori';
  String get addScanTooltip      => _en ? 'Fill from Photo'       : 'Fotoğraftan Doldur';
  String get addCamera           => _en ? 'Camera'                : 'Kamera';
  String get addGallery          => _en ? 'Gallery'               : 'Galeri';
  String get addReceiptRead      => _en ? 'Receipt read, please verify the details' : 'Fiş okundu, lütfen bilgileri kontrol edin';
  String get addPhotoError       => _en ? 'Could not read photo: ': 'Fotoğraf okunamadı: ';
  String get addAiSuggestion     => _en ? 'AI Suggestion'         : 'AI Önerisi';
  String get addExpenseAdded     => _en ? 'Expense added ✅'      : 'Harcama eklendi ✅';
  String get addError            => _en ? 'Error: '               : 'Hata: ';

  // ── EDIT EXPENSE ────────────────────────────────────────
  String get editTitle           => _en ? 'Edit Expense'          : 'Harcamayı Düzenle';
  String get editAmountEmpty     => _en ? 'Amount cannot be empty': 'Tutar boş olamaz';
  String get editAmountInvalid   => _en ? 'Enter a valid number'  : 'Geçerli bir sayı gir';
  String get editAmountZero      => _en ? 'Amount must be greater than 0' : 'Tutar 0\'dan büyük olmalı';
  String get editDescription     => _en ? 'Description'           : 'Açıklama';
  String get editCategory        => _en ? 'Category'              : 'Kategori';
  String get editUpdated         => _en ? 'Expense updated'       : 'Harcama güncellendi';

  // ── STATS ───────────────────────────────────────────────
  String get statsTitle          => _en ? 'Statistics'            : 'İstatistikler';
  String get statsTabSummary     => _en ? 'Summary'               : 'Özet';
  String get statsTabAI          => _en ? 'AI Analysis'           : 'AI Analiz';
  String get statsTabBudget      => _en ? 'Budget'                : 'Bütçe';
  String get statsTabMonthly     => _en ? 'Monthly'               : 'Aylık';
  String get statsTotalExpense   => _en ? 'Total Expense'         : 'Toplam Harcama';
  String get statsDailyAvg       => _en ? 'Daily Avg.'            : 'Günlük Ortalama';
  String get statsTopCategory    => _en ? 'Top Category'          : 'En Çok Harcanan';
  String get statsCategoryDist   => _en ? 'Category Breakdown'    : 'Kategori Dağılımı';
  String get statsLast7Days      => _en ? 'Last 7 Days Trend'     : 'Son 7 Gün Trendi';
  String get statsAiInsights     => _en ? 'AI Insights'           : 'Yapay Zeka Yorumları';
  String get statsAnomalies      => _en ? '⚠️ Unusual Expenses'   : '⚠️ Anormal Harcamalar';
  String get statsAiForecast     => _en ? 'AI Forecast'           : 'AI Tahminleme';
  String get statsMonthlyExpense => _en ? 'Monthly Forecast'      : 'Aylık Tahmini Harcama';
  String get statsTrend          => _en ? 'Trend'                 : 'Trend';
  String get statsModel          => _en ? 'Model'                 : 'Model';
  String get statsBudgetHint     => _en ? 'Set budget limits per category. Track daily, weekly and monthly.' : 'Kategorilere bütçe limiti belirle. Harcamalarını günlük, haftalık ve aylık olarak takip et.';
  String get statsBudgetGoal     => _en ? 'Goal'                  : 'Hedef';
  String get statsBudgetNoGoal   => _en ? 'No goal set'           : 'Hedef belirlenmemiş';
  String get statsBudgetThisMonth=> _en ? 'This month: '          : 'Bu ay: ';
  String get statsBudgetTarget   => _en ? 'Target: '              : 'Hedef: ';
  String get statsBudgetDialogTitle => _en ? 'Budget Goal'        : 'Bütçe Hedefi';
  String get statsBudgetDaily    => _en ? 'Daily (₺)'             : 'Günlük (₺)';
  String get statsBudgetWeekly   => _en ? 'Weekly (₺)'            : 'Haftalık (₺)';
  String get statsBudgetMonthly  => _en ? 'Monthly (₺)'           : 'Aylık (₺)';
  String get statsAiBudget       => _en ? 'AI Budget Estimate'    : 'AI Bütçe Tahmini';
  String get statsSessionError   => _en ? 'Session not found. Please log out and log back in.' : 'Oturum bulunamadı. Çıkış yapıp tekrar giriş yap.';

  // ── IMPORT ──────────────────────────────────────────────
  String get importTitle         => _en ? 'Import'                : 'İçe Aktar';
  String get importTabFile       => _en ? 'File'                  : 'Dosya';
  String get importTabPhoto      => _en ? 'Photo'                 : 'Fotoğraf';
  String get importSelectFile    => _en ? 'Select File'           : 'Dosya Seç';
  String get importFileHint      => _en ? 'Supported: CSV, XLSX'  : 'Desteklenen: CSV, XLSX';
  String get importAnalyze       => _en ? 'Analyze'               : 'Analiz Et';
  String get importSave          => _en ? 'Save All'              : 'Tümünü Kaydet';
  String get importPreview       => _en ? 'Preview'               : 'Önizleme';
  String get importTakePhoto     => _en ? 'Take Photo'            : 'Fotoğraf Çek';
  String get importFromGallery   => _en ? 'Choose from Gallery'   : 'Galeriden Seç';
  String get importPhotoHint     => _en ? 'Take a photo of your receipt and AI will extract the expenses.' : 'Fişin fotoğrafını çek, yapay zeka harcamaları otomatik okusun.';
  String get importSaved         => _en ? 'expenses saved'        : 'harcama kaydedildi';

  // ── PROFILE ─────────────────────────────────────────────
  String get profileTitle        => _en ? 'Profile'               : 'Profil';
  String get profileActiveUser   => _en ? 'Active User'           : 'Aktif Kullanıcı';
  String get profileTotalExpense => _en ? 'Total Expense'         : 'Toplam Harcama';
  String get profileDailyAvg    => _en ? 'Daily Avg.'             : 'Günlük Ort.';
  String get profileCategory    => _en ? 'Category'               : 'Kategori';
  String get profileSettings    => _en ? 'Settings'               : 'Ayarlar';
  String get profileDarkMode    => _en ? 'Dark Mode'              : 'Karanlık Mod';
  String get profileDarkOn      => _en ? 'On'                     : 'Açık';
  String get profileDarkOff     => _en ? 'Off'                    : 'Kapalı';
  String get profileLanguage    => _en ? 'Language'               : 'Dil';
  String get profileSelectLang  => _en ? 'Select Language'        : 'Dil Seç';
  String get profileAccount     => _en ? 'Account'                : 'Hesap';
  String get profileReport      => _en ? 'Download Monthly Report': 'Aylık Rapor İndir';
  String get profileReportSub   => _en ? 'Share as PDF'           : 'PDF olarak paylaş';
  String get profileDeleteAll   => _en ? 'Delete All Expenses'    : 'Tüm Harcamaları Sil';
  String get profileDeleteSub   => _en ? 'Permanently deleted'    : 'Kalıcı olarak siler';
  String get profileLogout      => _en ? 'Log Out'                : 'Çıkış Yap';
  String get profileDeleteConfirmTitle => _en ? 'Delete All Expenses' : 'Tüm Harcamaları Sil';
  String get profileDeleteConfirmBody => _en
      ? 'All expenses in this account will be deleted. This cannot be undone!'
      : 'Bu hesaba ait tüm harcamalar silinecek. Bu işlem geri alınamaz!';
  String get profileDeleteYes   => _en ? 'Yes, Delete'            : 'Evet, Sil';
  String get profileDeleted     => _en ? 'All expenses deleted.'  : 'Tüm harcamalar silindi.';
  String get profilePdfPreparing=> _en ? 'Preparing PDF...'       : 'PDF hazırlanıyor...';
  String get profilePdfError    => _en ? 'Could not create PDF: ' : 'PDF oluşturulamadı: ';
  String get profilePdfReport   => _en ? 'Monthly Expense Report' : 'Aylık Harcama Raporu';
  String get profilePdfCategory => _en ? 'Category'              : 'Kategori';
  String get profilePdfAmount   => _en ? 'Amount'                 : 'Tutar';
  String get profilePdfRatio    => _en ? 'Ratio'                  : 'Oran';
  String get profilePdfCreated  => _en ? 'Generated: '            : 'Oluşturulma: ';
  String get profilePdfFooter   => _en ? 'FaturaAnaliz v1.0.0 — AI-powered expense tracker' : 'FaturaAnaliz v1.0.0 — Yapay Zeka Destekli Harcama Takibi';
  String get profileLangChanged => _en ? 'Language: '             : 'Dil: ';

  // ── KATEGORİLER ─────────────────────────────────────────
  String catName(String trName) {
    if (!_en) return trName;
    const map = {
      'Market':      'Groceries',
      'Yeme & İçme': 'Food & Drink',
      'Faturalar':   'Bills',
      'Ulaşım':      'Transport',
      'Kira & Ev':   'Rent & Home',
      'Sağlık':      'Health',
      'Eğlence':     'Entertainment',
      'Giyim':       'Clothing',
      'Eğitim':      'Education',
      'Diğer':       'Other',
    };
    return map[trName] ?? trName;
  }
}
