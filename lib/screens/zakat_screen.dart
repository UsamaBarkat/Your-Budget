import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../core/money.dart';
import '../core/zakat.dart';
import '../l10n/translations.dart';
import '../services/persistence_service.dart';

class ZakatScreen extends StatefulWidget {
  final String language;
  const ZakatScreen({super.key, required this.language});

  @override
  State<ZakatScreen> createState() => _ZakatScreenState();
}

class _ZakatScreenState extends State<ZakatScreen> {
  final _cashCtrl = TextEditingController();
  final _goldGramsCtrl = TextEditingController();
  final _silverGramsCtrl = TextEditingController();
  final _businessCtrl = TextEditingController();
  final _goldPriceCtrl = TextEditingController();
  final _silverPriceCtrl = TextEditingController();

  String? _cashError, _goldGramsError, _silverGramsError;
  String? _businessError, _goldPriceError, _silverPriceError;
  bool _isDirty = false;
  late PersistenceService _persistence;

  static const _prefKey = 'zakat_data';

  @override
  void initState() {
    super.initState();
    _persistence = PersistenceService();
    _loadData();
  }

  @override
  void dispose() {
    _cashCtrl.dispose();
    _goldGramsCtrl.dispose();
    _silverGramsCtrl.dispose();
    _businessCtrl.dispose();
    _goldPriceCtrl.dispose();
    _silverPriceCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadData() async {
    final prefs = await SharedPreferences.getInstance();
    final raw = prefs.getString(_prefKey);
    if (raw == null || !mounted) return;
    final map = Map<String, dynamic>.from(json.decode(raw) as Map);
    setState(() {
      if (map['cash'] != null) _cashCtrl.text = paisaToDisplay((map['cash'] as num).toInt());
      if (map['gold_mg'] != null) _goldGramsCtrl.text = milligramsToGrams((map['gold_mg'] as num).toInt());
      if (map['silver_mg'] != null) _silverGramsCtrl.text = milligramsToGrams((map['silver_mg'] as num).toInt());
      if (map['business'] != null) _businessCtrl.text = paisaToDisplay((map['business'] as num).toInt());
      if (map['gold_price_pg'] != null) _goldPriceCtrl.text = paisaToDisplay((map['gold_price_pg'] as num).toInt());
      if (map['silver_price_pg'] != null) _silverPriceCtrl.text = paisaToDisplay((map['silver_price_pg'] as num).toInt());
    });
  }

  // Returns 0 for blank or invalid input — live calculation degrades gracefully.
  int _parsePaisa(String text) {
    if (text.isEmpty || validateRupeeInput(text) != null) return 0;
    return rupeesToPaisa(text);
  }

  int _parseMg(String text) {
    if (text.isEmpty || validateGramInput(text) != null) return 0;
    return gramsToMilligrams(text);
  }

  int get _goldValue => computeMetalValue(_parseMg(_goldGramsCtrl.text), _parsePaisa(_goldPriceCtrl.text));
  int get _silverValue => computeMetalValue(_parseMg(_silverGramsCtrl.text), _parsePaisa(_silverPriceCtrl.text));
  int get _totalAssets => computeTotalAssets(_parsePaisa(_cashCtrl.text), _goldValue, _silverValue, _parsePaisa(_businessCtrl.text));
  int get _nisab => computeNisab(_parsePaisa(_silverPriceCtrl.text));
  int get _zakatDue => computeZakat(_totalAssets, _nisab);

  String? _translateError(String? key) =>
      key == null ? null : t('zakat', key, widget.language);

  void _onRupeeChanged(String val, void Function(String?) set) {
    setState(() {
      _isDirty = true;
      set(_translateError(val.isEmpty ? null : validateRupeeInput(val)));
    });
  }

  void _onGramChanged(String val, void Function(String?) set) {
    setState(() {
      _isDirty = true;
      set(_translateError(val.isEmpty ? null : validateGramInput(val)));
    });
  }

  bool get _hasErrors => [
    _cashError, _goldGramsError, _silverGramsError,
    _businessError, _goldPriceError, _silverPriceError,
  ].any((e) => e != null);

  Future<void> _save() async {
    if (_hasErrors) return;
    final data = <String, int>{
      'cash': _parsePaisa(_cashCtrl.text),
      'gold_mg': _parseMg(_goldGramsCtrl.text),
      'silver_mg': _parseMg(_silverGramsCtrl.text),
      'business': _parsePaisa(_businessCtrl.text),
      'gold_price_pg': _parsePaisa(_goldPriceCtrl.text),
      'silver_price_pg': _parsePaisa(_silverPriceCtrl.text),
    };
    final ok = await _persistence.write(_prefKey, json.encode(data));
    if (!mounted) return;
    setState(() { if (ok) _isDirty = false; });
    if (!ok) _showSaveFailedSnackbar();
  }

  void _showSaveFailedSnackbar() {
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(
      content: Text(t('zakat', 'save_failed', widget.language)),
      action: SnackBarAction(
        label: t('zakat', 'retry', widget.language),
        onPressed: () async {
          final ok = await _persistence.retryPending();
          if (mounted) setState(() { if (ok) _isDirty = false; });
          if (!ok && mounted) _showSaveFailedSnackbar();
        },
      ),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final lang = widget.language;
    final isObligation = _totalAssets >= _nisab;
    return Scaffold(
      appBar: AppBar(
        title: Text(t('zakat', 'title', lang)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildField(_cashCtrl, 'cash', _cashError, false,
                  (v) => _onRupeeChanged(v, (e) => _cashError = e)),
              _buildField(_goldGramsCtrl, 'gold_grams', _goldGramsError, true,
                  (v) => _onGramChanged(v, (e) => _goldGramsError = e)),
              _buildField(_goldPriceCtrl, 'gold_price_per_gram', _goldPriceError, false,
                  (v) => _onRupeeChanged(v, (e) => _goldPriceError = e)),
              _buildField(_silverGramsCtrl, 'silver_grams', _silverGramsError, true,
                  (v) => _onGramChanged(v, (e) => _silverGramsError = e)),
              _buildField(_silverPriceCtrl, 'silver_price_per_gram', _silverPriceError, false,
                  (v) => _onRupeeChanged(v, (e) => _silverPriceError = e)),
              _buildField(_businessCtrl, 'business', _businessError, false,
                  (v) => _onRupeeChanged(v, (e) => _businessError = e)),
              const SizedBox(height: 8),
              _buildResults(lang, isObligation),
              const SizedBox(height: 16),
              ElevatedButton.icon(
                onPressed: _save,
                icon: Icon(_isDirty ? Icons.warning_amber : Icons.check),
                label: Text(t('zakat', 'save', lang)),
                style: ElevatedButton.styleFrom(
                  backgroundColor: _isDirty ? Colors.orange : Colors.green,
                  foregroundColor: Colors.white,
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
              ),
              const SizedBox(height: 16),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildField(
    TextEditingController ctrl,
    String labelKey,
    String? error,
    bool isGrams,
    void Function(String) onChanged,
  ) {
    final lang = widget.language;
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: TextField(
        controller: ctrl,
        keyboardType: const TextInputType.numberWithOptions(decimal: true),
        decoration: InputDecoration(
          labelText: t('zakat', labelKey, lang),
          prefixText: isGrams ? null : '${t('zakat', 'rupees', lang)} ',
          suffixText: isGrams ? t('zakat', 'grams', lang) : null,
          border: const OutlineInputBorder(),
          errorText: error,
        ),
        onChanged: onChanged,
      ),
    );
  }

  Widget _buildResults(String lang, bool isObligation) {
    final color = isObligation ? Colors.green.shade700 : Colors.orange.shade700;
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withAlpha(20),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: color.withAlpha(80)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildResultRow(t('zakat', 'total_assets', lang), _totalAssets, lang),
          _buildResultRow(t('zakat', 'nisab', lang), _nisab, lang),
          _buildResultRow(t('zakat', 'zakat_due', lang), _zakatDue, lang),
          const Divider(height: 20),
          Row(children: [
            Icon(isObligation ? Icons.check_circle : Icons.info_outline, color: color),
            const SizedBox(width: 8),
            Expanded(child: Text(
              t('zakat', isObligation ? 'obligatory' : 'below_nisab', lang),
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            )),
          ]),
        ],
      ),
    );
  }

  Widget _buildResultRow(String label, int paisa, String lang) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: const TextStyle(fontSize: 15)),
          Text(
            '${t('zakat', 'rupees', lang)} ${paisaToDisplay(paisa)}',
            style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
          ),
        ],
      ),
    );
  }
}
