import 'package:flutter/material.dart';
import '../core/money.dart';
import '../l10n/translations.dart';
import '../models/income_source.dart';

class IncomeAddDialog extends StatefulWidget {
  final String language;
  final void Function(IncomeSource) onSave;
  const IncomeAddDialog({super.key, required this.language, required this.onSave});

  @override
  State<IncomeAddDialog> createState() => _IncomeAddDialogState();
}

class _IncomeAddDialogState extends State<IncomeAddDialog> {
  final _nameCtrl = TextEditingController();
  final _amountCtrl = TextEditingController();
  DateTime _selectedDate = DateTime.now();
  String? _amountError;

  @override
  void dispose() {
    _nameCtrl.dispose();
    _amountCtrl.dispose();
    super.dispose();
  }

  bool get _canSave =>
      _nameCtrl.text.trim().isNotEmpty &&
      _amountCtrl.text.isNotEmpty &&
      _amountError == null;

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;
    return AlertDialog(
      title: Text(t('income', 'add_income', lang)),
      content: SingleChildScrollView(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Wrap(
              spacing: 8,
              runSpacing: 4,
              children: ['salary', 'business', 'rent_income', 'other']
                  .map((key) => ActionChip(
                        label: Text(t('income', key, lang)),
                        onPressed: () =>
                            setState(() => _nameCtrl.text = t('income', key, lang)),
                      ))
                  .toList(),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _nameCtrl,
              decoration: InputDecoration(
                labelText: t('income', 'source_name', lang),
                border: const OutlineInputBorder(),
              ),
              onChanged: (_) => setState(() {}),
            ),
            const SizedBox(height: 12),
            TextField(
              controller: _amountCtrl,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: t('income', 'amount', lang),
                prefixText: '${t('shared', 'rupees', lang)} ',
                errorText: _amountError,
                border: const OutlineInputBorder(),
              ),
              onChanged: (v) => setState(() {
                if (v.isEmpty) {
                  _amountError = null;
                } else {
                  final key = validateRupeeInput(v);
                  _amountError = key == null ? null : t('shared', key, lang);
                }
              }),
            ),
            const SizedBox(height: 12),
            InkWell(
              onTap: () async {
                final picked = await showDatePicker(
                  context: context,
                  initialDate: _selectedDate,
                  firstDate: DateTime(2020),
                  lastDate: DateTime.now(),
                );
                if (picked != null) setState(() => _selectedDate = picked);
              },
              child: InputDecorator(
                decoration: InputDecoration(
                  labelText: t('income', 'date', lang),
                  border: const OutlineInputBorder(),
                  suffixIcon: const Icon(Icons.calendar_today, size: 20),
                ),
                child: Text(
                    '${_selectedDate.day}/${_selectedDate.month}/${_selectedDate.year}'),
              ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context),
          child: Text(t('shared', 'cancel', lang)),
        ),
        ElevatedButton(
          onPressed: _canSave
              ? () {
                  widget.onSave(IncomeSource(
                    id: DateTime.now().millisecondsSinceEpoch.toString(),
                    type: _nameCtrl.text.trim(),
                    amount: rupeesToPaisa(_amountCtrl.text),
                    date: _selectedDate,
                  ));
                }
              : null,
          child: Text(t('shared', 'save', lang)),
        ),
      ],
    );
  }
}
