import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:image_picker/image_picker.dart';

import '../services/expense_service.dart';
import '../utils/app_strings.dart';
import '../utils/category_constants.dart';

class ImportScreen extends StatefulWidget {
  const ImportScreen({super.key});

  @override
  State<ImportScreen> createState() => _ImportScreenState();
}

class _ImportScreenState extends State<ImportScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  final _imagePicker = ImagePicker();

  // Dosya sekme — bytes olarak tutuyoruz (web uyumlu)
  List<int>? _fileBytes;
  String? _selectedFilename;

  // Fotoğraf sekme
  Uint8List? _photoBytes;
  String _photoName = 'receipt.jpg';

  // Ortak
  bool _analyzing = false;
  bool _saving = false;
  Map<String, dynamic>? _preview;
  String? _error;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() {
      setState(() {
        _preview = null;
        _error = null;
      });
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  // ── CSV / Excel seç ──────────────────────────────
  Future<void> _pickFile() async {
    final picked = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['csv', 'xlsx'],
      allowMultiple: false,
      withData: true,
    );
    if (picked == null || picked.files.isEmpty) return;
    final f = picked.files.first;
    final bytes = f.bytes ?? (f.path != null ? await _readPath(f.path!) : null);
    if (bytes == null) return;
    setState(() {
      _fileBytes = bytes;
      _selectedFilename = f.name;
      _preview = null;
      _error = null;
    });
  }

  Future<List<int>?> _readPath(String path) async {
    try {
      // dart:io sadece mobil/masaüstünde
      if (!kIsWeb) {
        // ignore: avoid_dynamic_calls
        final dynamic ioFile = await _ioFile(path);
        return ioFile;
      }
    } catch (_) {}
    return null;
  }

  Future<List<int>?> _ioFile(String path) async {
    // Conditional import ile çözebiliriz ama basit tutmak için
    // FilePicker withData:true ile bytes zaten geliyor
    return null;
  }

  Future<void> _analyzeFile() async {
    if (_fileBytes == null || _selectedFilename == null) return;
    setState(() { _analyzing = true; _preview = null; _error = null; });
    try {
      final result = await ExpenseService.importFileBytes(_fileBytes!, _selectedFilename!);
      setState(() => _preview = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _analyzing = false);
    }
  }

  // ── Fotoğraf seç ─────────────────────────────────
  Future<void> _pickPhotoFromGallery() async {
    final picked = await _imagePicker.pickImage(
      source: ImageSource.gallery,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _photoBytes = bytes;
      _photoName = picked.name;
      _preview = null;
      _error = null;
    });
  }

  Future<void> _pickPhotoFromCamera() async {
    if (kIsWeb) {
      // Web'de kamera image_picker ile galeri gibi çalışır
      await _pickPhotoFromGallery();
      return;
    }
    final picked = await _imagePicker.pickImage(
      source: ImageSource.camera,
      imageQuality: 85,
    );
    if (picked == null) return;
    final bytes = await picked.readAsBytes();
    setState(() {
      _photoBytes = bytes;
      _photoName = picked.name;
      _preview = null;
      _error = null;
    });
  }

  Future<void> _analyzePhoto() async {
    if (_photoBytes == null) return;
    setState(() { _analyzing = true; _preview = null; _error = null; });
    try {
      final result = await ExpenseService.uploadPhotoBytes(_photoBytes!, _photoName);
      setState(() => _preview = result);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _analyzing = false);
    }
  }

  // ── Onayla & kaydet ──────────────────────────────
  Future<void> _confirmImport() async {
    final expenses = _preview?['expenses'] as List?;
    if (expenses == null || expenses.isEmpty) return;
    setState(() => _saving = true);
    try {
      final items = expenses.cast<Map>().map((e) => {
        'amount': e['amount'],
        'description': e['description'] ?? e['name'] ?? '',
        'predictedCategory': e['predictedCategory'] ?? e['category'] ?? 'Diğer',
        'finalCategory': e['finalCategory'] ?? e['category'] ?? 'Diğer',
        'date': e['date'] ?? '',
      }).toList().cast<Map<String, dynamic>>();

      final saved = await ExpenseService.confirmImport(items);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('$saved ${AppStrings.of(context).importSaved}'),
        backgroundColor: Colors.green,
      ));
      Navigator.pop(context, true);
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  void _reset() => setState(() {
    _preview = null;
    _fileBytes = null;
    _selectedFilename = null;
    _photoBytes = null;
    _error = null;
  });

  // ─────────────────────────────────────────────────
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.of(context).importTitle),
        backgroundColor: Colors.deepPurple,
        foregroundColor: Colors.white,
        bottom: TabBar(
          controller: _tabController,
          indicatorColor: Colors.white,
          labelColor: Colors.white,
          unselectedLabelColor: Colors.white60,
          tabs: [
            Tab(icon: const Icon(Icons.upload_file), text: AppStrings.of(context).importTabFile),
            Tab(icon: const Icon(Icons.camera_alt), text: AppStrings.of(context).importTabPhoto),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildFileTab(),
          _buildPhotoTab(),
        ],
      ),
    );
  }

  // ── DOSYA SEKMESİ ────────────────────────────────
  Widget _buildFileTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(builder: (context) {
            final s = AppStrings.of(context);
            return _buildInfoCard(
              s.importFileHint,
              [
                s.isEn ? "'amount' and 'description' columns required" : "'tutar' ve 'aciklama' sütunları olmalı",
                s.isEn ? "'Analyze' lets AI predict categories" : "'Analiz Et' ile AI kategorileri tahmin eder",
                s.isEn ? "Review the list, then tap 'Save All'" : "Listeyi gözden geçir, 'İçe Aktar' ile kaydet",
              ],
              Icons.upload_file,
              Colors.blue,
            );
          }),
          const SizedBox(height: 16),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton.icon(
              onPressed: (_analyzing || _saving) ? null : _pickFile,
              icon: const Icon(Icons.folder_open),
              label: Text(
                _selectedFilename ?? AppStrings.of(context).importSelectFile,
                overflow: TextOverflow.ellipsis,
              ),
              style: OutlinedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          const SizedBox(height: 12),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_fileBytes == null || _analyzing || _saving) ? null : _analyzeFile,
              icon: _analyzing
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.auto_awesome),
              label: Text(_analyzing ? AppStrings.of(context).loading : AppStrings.of(context).importAnalyze),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.deepPurple,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),
          if (_error != null) ...[const SizedBox(height: 16), _buildErrorBox()],
          if (_preview != null) ...[const SizedBox(height: 20), _buildPreview()],
        ],
      ),
    );
  }

  // ── FOTOĞRAF SEKMESİ ─────────────────────────────
  Widget _buildPhotoTab() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Builder(builder: (context) {
            final s = AppStrings.of(context);
            return _buildInfoCard(
              s.importPhotoHint,
              [
                s.isEn ? "Take a photo or choose from gallery" : "Kamera ile çek ya da galeriden seç",
                s.isEn ? "AI reads the text and predicts category + amount" : "AI metni okuyup kategori + tutarı tahmin eder",
                s.isEn ? "Adjust amount if needed, then tap 'Save All'" : "Tutarı gerekirse düzelt, 'İçe Aktar' ile kaydet",
              ],
              Icons.camera_alt,
              Colors.green,
            );
          }),
          const SizedBox(height: 16),

          // Fotoğraf önizleme
          if (_photoBytes != null) ...[
            ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: Image.memory(
                _photoBytes! as dynamic,
                width: double.infinity,
                height: 220,
                fit: BoxFit.cover,
              ),
            ),
            const SizedBox(height: 12),
          ],

          // Kamera / Galeri butonları
          Row(
            children: [
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (_analyzing || _saving) ? null : _pickPhotoFromCamera,
                  icon: const Icon(Icons.camera_alt),
                  label: Text(AppStrings.of(context).addCamera),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: (_analyzing || _saving) ? null : _pickPhotoFromGallery,
                  icon: const Icon(Icons.photo_library),
                  label: Text(AppStrings.of(context).addGallery),
                  style: OutlinedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 14),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: (_photoBytes == null || _analyzing || _saving) ? null : _analyzePhoto,
              icon: _analyzing
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.document_scanner),
              label: Text(_analyzing ? AppStrings.of(context).loading : AppStrings.of(context).importAnalyze),
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.green.shade700,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(10)),
              ),
            ),
          ),

          if (_error != null) ...[const SizedBox(height: 16), _buildErrorBox()],
          if (_preview != null) ...[const SizedBox(height: 20), _buildPreview()],
        ],
      ),
    );
  }

  // ── ORTAK WİDGETLER ──────────────────────────────
  Widget _buildInfoCard(String title, List<String> bullets, IconData icon, Color color) {
    return Card(
      elevation: 0,
      color: color.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: color.withValues(alpha: 0.3)),
      ),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 8),
              Text(title, style: TextStyle(fontWeight: FontWeight.bold, color: color)),
            ]),
            const SizedBox(height: 8),
            ...bullets.map((b) => Padding(
              padding: const EdgeInsets.only(bottom: 3),
              child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Icon(Icons.arrow_right, size: 16, color: color),
                const SizedBox(width: 4),
                Expanded(child: Text(b, style: TextStyle(fontSize: 13, color: color))),
              ]),
            )),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorBox() {
    return Builder(builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: cs.errorContainer,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: cs.error.withValues(alpha: 0.4)),
        ),
        child: Row(children: [
          Icon(Icons.error_outline, color: cs.error),
          const SizedBox(width: 8),
          Expanded(child: Text(_error!, style: TextStyle(color: cs.onErrorContainer))),
        ]),
      );
    });
  }

  Widget _buildPreview() {
    final total    = _preview!['totalRows'] as int? ?? 0;
    final count    = _preview!['imported']  as int? ?? 0;
    final skipped  = _preview!['skipped']   as int? ?? 0;
    final errors   = _preview!['errors']    as List? ?? [];
    final expenses = _preview!['expenses']  as List? ?? [];
    final rawText  = _preview!['rawText']   as String? ?? '';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Builder(builder: (context) {
          final cs = Theme.of(context).colorScheme;
          return Card(
            elevation: 0,
            color: cs.primaryContainer,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(12),
              side: BorderSide(color: cs.primary.withValues(alpha: 0.3)),
            ),
            child: Padding(
              padding: const EdgeInsets.all(14),
              child: Column(children: [
                Row(children: [
                  Icon(Icons.preview, color: cs.primary),
                  const SizedBox(width: 8),
                  Text(AppStrings.of(context).importPreview,
                      style: TextStyle(fontWeight: FontWeight.bold,
                          fontSize: 15, color: cs.onPrimaryContainer)),
                ]),
                const SizedBox(height: 12),
                Builder(builder: (context) {
                  final s = AppStrings.of(context);
                  return Row(mainAxisAlignment: MainAxisAlignment.spaceAround, children: [
                    _statBox(s.isEn ? 'Total' : 'Toplam', total.toString(), Colors.blue),
                    _statBox(s.isEn ? 'Analyzed' : 'Analiz', count.toString(), Colors.purple),
                    _statBox(s.isEn ? 'Skipped' : 'Atlandı', skipped.toString(), Colors.orange),
                  ]);
                }),
              ]),
            ),
          );
        }),

        if (rawText.isNotEmpty) ...[
          const SizedBox(height: 10),
          Builder(builder: (context) {
            final cs = Theme.of(context).colorScheme;
            return ExpansionTile(
              tilePadding: EdgeInsets.zero,
              title: Text(AppStrings.of(context).isEn ? "Extracted Text (${rawText.split('\n').length} lines)" : "Okunan Metin (${rawText.split('\n').length} satır)",
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w600)),
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest,
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Text(rawText,
                      style: TextStyle(fontSize: 11, fontFamily: 'monospace', color: cs.onSurface)),
                ),
              ],
            );
          }),
        ],

        if (errors.isNotEmpty) ...[
          const SizedBox(height: 8),
          Text(AppStrings.of(context).isEn ? 'Warnings' : 'Uyarılar', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.orange)),
          ...errors.cast<String>().map((e) => Padding(
            padding: const EdgeInsets.only(bottom: 3, top: 3),
            child: Text("• $e", style: const TextStyle(fontSize: 12, color: Colors.orange)),
          )),
        ],

        if (expenses.isNotEmpty) ...[
          const SizedBox(height: 14),
          Text(AppStrings.of(context).isEn ? "Predicted Categories ($count records)" : "Tahmin Edilen Kategoriler ($count kayıt)",
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
          const SizedBox(height: 8),
          ...expenses.cast<Map>().map((e) => _expenseRow(e)),
          const SizedBox(height: 20),

          SizedBox(
            width: double.infinity,
            child: ElevatedButton.icon(
              onPressed: _saving ? null : _confirmImport,
              icon: _saving
                  ? const SizedBox(width: 18, height: 18,
                      child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                  : const Icon(Icons.save_alt),
              label: Text(_saving ? AppStrings.of(context).loading : "${AppStrings.of(context).importSave} ($count)"),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                textStyle: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
            ),
          ),
          const SizedBox(height: 10),
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _saving ? null : _reset,
              child: Text(AppStrings.of(context).isEn ? "Cancel – Select New File / Photo" : "İptal – Yeni Dosya / Fotoğraf Seç"),
            ),
          ),
        ],
      ],
    );
  }

  Widget _expenseRow(Map e) {
    final amount = (e['amount'] as num?)?.toDouble() ?? 0;
    final desc   = e['description'] as String? ?? '';
    final cat    = e['predictedCategory'] as String? ?? 'Diğer';
    final catTr  = CategoryConstants.toTr(cat);
    final color  = CategoryConstants.colorOf(cat);
    final icon   = CategoryConstants.iconOf(cat);

    return Builder(builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return Card(
        elevation: 0,
        margin: const EdgeInsets.only(bottom: 6),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(10),
          side: BorderSide(color: cs.outlineVariant),
        ),
        child: ListTile(
          dense: true,
          leading: CircleAvatar(
            backgroundColor: color.withValues(alpha: 0.15),
            radius: 18,
            child: Icon(icon, size: 16, color: color),
          ),
          title: Text(desc.isEmpty ? (AppStrings.of(context).isEn ? "(No description)" : "(Açıklama yok)") : desc,
              style: TextStyle(fontSize: 13, color: cs.onSurface),
              overflow: TextOverflow.ellipsis),
          subtitle: Text(catTr,
              style: TextStyle(fontSize: 11, color: color, fontWeight: FontWeight.w600)),
          trailing: amount == 0
              ? const Text("? ₺", style: TextStyle(color: Colors.orange,
                  fontWeight: FontWeight.bold, fontSize: 13))
              : Text("${amount.toStringAsFixed(2)} ₺",
                  style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: cs.onSurface)),
        ),
      );
    });
  }

  Widget _statBox(String label, String value, Color color) {
    return Builder(builder: (context) {
      final cs = Theme.of(context).colorScheme;
      return Column(children: [
        Text(value, style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold, color: color)),
        Text(label, style: TextStyle(fontSize: 12, color: cs.onSurface.withValues(alpha: 0.6))),
      ]);
    });
  }
}
