import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:image_picker/image_picker.dart';

import '../models/expense_create_request.dart';
import '../services/expense_service.dart';
import '../utils/category_constants.dart';
import '../utils/app_strings.dart';

class AddExpenseScreen extends StatefulWidget {
  const AddExpenseScreen({super.key});

  @override
  State<AddExpenseScreen> createState() => _AddExpenseScreenState();
}

class _AddExpenseScreenState extends State<AddExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  final amountController = TextEditingController();
  final descriptionController = TextEditingController();

  final List<String> categoriesTr = CategoryConstants.trList();
  late String selectedCategoryTr;

  bool _ocrLoading = false;
  final _imagePicker = ImagePicker();
  bool isLoading = false;

  @override
  void initState() {
    super.initState();
    selectedCategoryTr = categoriesTr.first;
  }

  @override
  void dispose() {
    amountController.dispose();
    descriptionController.dispose();
    super.dispose();
  }

  Future<void> _fillFromPhoto(ImageSource source) async {
    final effectiveSource = (kIsWeb || source == ImageSource.camera) ? ImageSource.gallery : source;
    final XFile? picked = await _imagePicker.pickImage(source: effectiveSource, imageQuality: 85);
    if (picked == null) return;

    setState(() => _ocrLoading = true);
    try {
      final bytes = await picked.readAsBytes();
      final result = await ExpenseService.uploadPhotoBytes(bytes, picked.name);
      final expenses = result['expenses'] as List?;
      if (expenses == null || expenses.isEmpty) return;

      final first = expenses.first as Map;
      final amount = (first['amount'] as num?)?.toDouble();
      final description = (first['description'] ?? first['name'] ?? '') as String;
      final category = (first['finalCategory'] ?? first['predictedCategory'] ?? first['category'] ?? '') as String;

      if (amount != null && amount > 0) {
        amountController.text = amount.toStringAsFixed(2);
      }
      if (description.isNotEmpty) {
        descriptionController.text = description;
      }
      if (category.isNotEmpty) {
        final tr = CategoryConstants.toTr(category);
        if (categoriesTr.contains(tr)) {
          setState(() => selectedCategoryTr = tr);
        }
      }
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text(AppStrings.of(context).addReceiptRead),
        backgroundColor: Colors.blue,
      ));
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(SnackBar(
        content: Text('${AppStrings.of(context).addPhotoError}$e'),
        backgroundColor: Colors.red,
      ));
    } finally {
      if (mounted) setState(() => _ocrLoading = false);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => isLoading = true);
    try {
      final amount = double.parse(amountController.text.trim().replaceAll(",", "."));
      final categoryCode = CategoryConstants.trToCode(selectedCategoryTr);

      final req = ExpenseCreateRequest(
        amount: amount,
        category: categoryCode,
        description: descriptionController.text.trim(),
      );

      await ExpenseService.createExpense(req);

      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(AppStrings.of(context).addExpenseAdded)),
      );
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('${AppStrings.of(context).addError}$e')),
      );
    } finally {
      if (mounted) setState(() => isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.of(context).addExpenseTitle),
        actions: [
          if (_ocrLoading)
            const Padding(
              padding: EdgeInsets.symmetric(horizontal: 16),
              child: Center(child: SizedBox(width: 20, height: 20,
                  child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))),
            )
          else
            PopupMenuButton<ImageSource>(
              icon: const Icon(Icons.document_scanner),
              tooltip: AppStrings.of(context).addScanTooltip,
              onSelected: _fillFromPhoto,
              itemBuilder: (ctx) {
                final s = AppStrings.of(ctx);
                return [
                  PopupMenuItem(
                    value: ImageSource.camera,
                    child: Row(children: [const Icon(Icons.camera_alt), const SizedBox(width: 8), Text(s.addCamera)]),
                  ),
                  PopupMenuItem(
                    value: ImageSource.gallery,
                    child: Row(children: [const Icon(Icons.photo_library), const SizedBox(width: 8), Text(s.addGallery)]),
                  ),
                ];
              },
            ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: amountController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}$')),
                ],
                decoration: InputDecoration(
                  labelText: AppStrings.of(context).addAmount,
                  hintText: AppStrings.of(context).addAmountHint,
                  border: const OutlineInputBorder(),
                ),
                validator: (v) {
                  final s = AppStrings.of(context);
                  final raw = (v ?? "").trim();
                  if (raw.isEmpty) return s.addAmountEmpty;
                  final value = double.tryParse(raw.replaceAll(",", "."));
                  if (value == null) return s.addAmountInvalid;
                  if (value <= 0) return s.addAmountZero;
                  if (value > 1000000) return s.addAmountTooLarge;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: descriptionController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: AppStrings.of(context).addDescription,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: selectedCategoryTr,
                items: categoriesTr
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v == null) return;
                  setState(() => selectedCategoryTr = v);
                },
                decoration: InputDecoration(
                  labelText: AppStrings.of(context).addCategory,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: isLoading ? null : _save,
                  child: isLoading
                      ? const SizedBox(width: 22, height: 22,
                          child: CircularProgressIndicator(strokeWidth: 2))
                      : Text(AppStrings.of(context).save),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
