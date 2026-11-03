import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../models/expense.dart';
import '../services/expense_service.dart';
import '../utils/category_constants.dart';
import '../utils/app_strings.dart';

class EditExpenseScreen extends StatefulWidget {
  final Expense expense;
  const EditExpenseScreen({super.key, required this.expense});

  @override
  State<EditExpenseScreen> createState() => _EditExpenseScreenState();
}

class _EditExpenseScreenState extends State<EditExpenseScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _amountCtrl;
  late final TextEditingController _descCtrl;
  late String _selectedCategory;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _amountCtrl = TextEditingController(
        text: widget.expense.amount.toStringAsFixed(2).replaceAll('.', ','));
    _descCtrl = TextEditingController(text: widget.expense.description ?? '');
    _selectedCategory =
        CategoryConstants.toTr(widget.expense.category) == 'Diğer'
            ? CategoryConstants.toTr(widget.expense.category)
            : CategoryConstants.toTr(widget.expense.category);
    // Fallback: eğer liste içinde yoksa ilk kategori
    if (!CategoryConstants.trList().contains(_selectedCategory)) {
      _selectedCategory = CategoryConstants.trList().first;
    }
  }

  @override
  void dispose() {
    _amountCtrl.dispose();
    _descCtrl.dispose();
    super.dispose();
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isLoading = true);
    try {
      final amount =
          double.parse(_amountCtrl.text.trim().replaceAll(',', '.'));
      await ExpenseService.updateExpense(
        widget.expense.id,
        amount: amount,
        category: _selectedCategory,
        description: _descCtrl.text.trim(),
      );
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text("Harcama güncellendi")));
      Navigator.pop(context, true);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context)
          .showSnackBar(SnackBar(content: Text("Hata: $e")));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final color = CategoryConstants.colorOf(widget.expense.category);
    return Scaffold(
      appBar: AppBar(
        title: Text(AppStrings.of(context).editTitle),
        backgroundColor: color,
        foregroundColor: Colors.white,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              TextFormField(
                controller: _amountCtrl,
                keyboardType:
                    const TextInputType.numberWithOptions(decimal: true),
                inputFormatters: [
                  FilteringTextInputFormatter.allow(RegExp(r'^\d*[.,]?\d{0,2}$')),
                ],
                decoration: InputDecoration(
                  labelText: AppStrings.of(context).addAmount,
                  border: const OutlineInputBorder(),
                  suffixText: '₺',
                ),
                validator: (v) {
                  final s = AppStrings.of(context);
                  final raw = (v ?? '').trim();
                  if (raw.isEmpty) return s.editAmountEmpty;
                  final val = double.tryParse(raw.replaceAll(',', '.'));
                  if (val == null) return s.editAmountInvalid;
                  if (val <= 0) return s.editAmountZero;
                  return null;
                },
              ),
              const SizedBox(height: 12),
              TextFormField(
                controller: _descCtrl,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: AppStrings.of(context).editDescription,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 12),
              DropdownButtonFormField<String>(
                initialValue: _selectedCategory,
                items: CategoryConstants.trList()
                    .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                    .toList(),
                onChanged: (v) {
                  if (v != null) setState(() => _selectedCategory = v);
                },
                decoration: InputDecoration(
                  labelText: AppStrings.of(context).editCategory,
                  border: const OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  style: ElevatedButton.styleFrom(
                      backgroundColor: color, foregroundColor: Colors.white),
                  onPressed: _isLoading ? null : _save,
                  child: _isLoading
                      ? const SizedBox(
                          width: 22,
                          height: 22,
                          child: CircularProgressIndicator(
                              strokeWidth: 2, color: Colors.white))
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
