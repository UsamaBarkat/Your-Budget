import 'package:flutter/material.dart';

// Translations
Map<String, Map<String, String>> gasTranslations = {
  'en': {
    'title': 'Gas Bill',
    'enter_units': 'Enter Units (HM³)',
    'calculate': 'Calculate',
    'your_bill': 'Your Bill',
    'units': 'Units',
    'rate': 'Rate',
    'total': 'Total',
    'rupees': 'Rs.',
    'per_unit': 'per unit',
    'note': 'Note: This is an estimate based on SSGC rates',
    'clear': 'Clear',
    'winter_note': 'Winter rates may be higher',
  },
  'ur': {
    'title': 'گیس کا بل',
    'enter_units': 'یونٹ درج کریں (HM³)',
    'calculate': 'حساب کریں',
    'your_bill': 'آپ کا بل',
    'units': 'یونٹ',
    'rate': 'ریٹ',
    'total': 'کل',
    'rupees': 'روپے',
    'per_unit': 'فی یونٹ',
    'note': 'نوٹ: یہ SSGC کے ریٹ پر اندازہ ہے',
    'clear': 'صاف کریں',
    'winter_note': 'سردیوں کے ریٹ زیادہ ہو سکتے ہیں',
  },
  'sd': {
    'title': 'گئس جو بل',
    'enter_units': 'يونٽ لکو (HM³)',
    'calculate': 'حساب ڪريو',
    'your_bill': 'توهان جو بل',
    'units': 'يونٽ',
    'rate': 'ريٽ',
    'total': 'ڪل',
    'rupees': 'رپيا',
    'per_unit': 'في يونٽ',
    'note': 'نوٽ: هي SSGC جي ريٽ تي اندازو آهي',
    'clear': 'صاف ڪريو',
    'winter_note': 'سياري جا ريٽ وڌيڪ ٿي سگهن ٿا',
  },
};

String getGasText(String key, String lang) {
  return gasTranslations[lang]?[key] ?? gasTranslations['en']![key]!;
}

class GasScreen extends StatefulWidget {
  final String language;

  const GasScreen({super.key, required this.language});

  @override
  State<GasScreen> createState() => _GasScreenState();
}

class _GasScreenState extends State<GasScreen> {
  final _unitsController = TextEditingController();
  double _bill = 0;
  double _rate = 0;
  bool _calculated = false;

  // SSGC Rate Slabs (approximate rates in PKR per HM³)
  // These are approximate domestic rates
  double _calculateBill(double units) {
    double bill = 0;
    double rate = 0;

    // SSGC domestic slab rates (approximate)
    if (units <= 0.5) {
      rate = 121;
      bill = units * rate;
    } else if (units <= 1) {
      rate = 212;
      bill = 0.5 * 121 + (units - 0.5) * rate;
    } else if (units <= 2) {
      rate = 400;
      bill = 0.5 * 121 + 0.5 * 212 + (units - 1) * rate;
    } else if (units <= 3) {
      rate = 738;
      bill = 0.5 * 121 + 0.5 * 212 + 1 * 400 + (units - 2) * rate;
    } else if (units <= 4) {
      rate = 1107;
      bill = 0.5 * 121 + 0.5 * 212 + 1 * 400 + 1 * 738 + (units - 3) * rate;
    } else {
      rate = 1476;
      bill = 0.5 * 121 + 0.5 * 212 + 1 * 400 + 1 * 738 + 1 * 1107 + (units - 4) * rate;
    }

    // Add fixed charges (meter rent, GST, etc.)
    double fixedCharges = 50; // Approximate
    double gst = bill * 0.17; // 17% GST

    _rate = rate;
    return bill + fixedCharges + gst;
  }

  void _calculate() {
    final units = double.tryParse(_unitsController.text) ?? 0;
    if (units > 0) {
      setState(() {
        _bill = _calculateBill(units);
        _calculated = true;
      });
    }
  }

  void _clear() {
    setState(() {
      _unitsController.clear();
      _bill = 0;
      _rate = 0;
      _calculated = false;
    });
  }

  @override
  void dispose() {
    _unitsController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(getGasText('title', widget.language)),
        centerTitle: true,
        backgroundColor: Theme.of(context).colorScheme.primaryContainer,
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 20),

              // Icon
              Icon(
                Icons.local_fire_department,
                size: 80,
                color: Colors.blue.shade600,
              ),

              const SizedBox(height: 30),

              // Units Input
              TextField(
                controller: _unitsController,
                keyboardType: const TextInputType.numberWithOptions(decimal: true),
                style: const TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: getGasText('enter_units', widget.language),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.blue.shade50,
                  contentPadding: const EdgeInsets.symmetric(
                    vertical: 20,
                    horizontal: 16,
                  ),
                ),
              ),

              const SizedBox(height: 20),

              // Calculate Button
              SizedBox(
                height: 60,
                child: ElevatedButton.icon(
                  onPressed: _calculate,
                  icon: const Icon(Icons.calculate, size: 28),
                  label: Text(
                    getGasText('calculate', widget.language),
                    style: const TextStyle(fontSize: 20),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.blue,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(12),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 30),

              // Result Card
              if (_calculated)
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.green.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.green, width: 2),
                  ),
                  child: Column(
                    children: [
                      Text(
                        getGasText('your_bill', widget.language),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${getGasText('rupees', widget.language)} ${_bill.toStringAsFixed(0)}',
                        style: const TextStyle(
                          fontSize: 40,
                          fontWeight: FontWeight.bold,
                          color: Colors.green,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Divider(color: Colors.green.shade200),
                      const SizedBox(height: 16),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            getGasText('units', widget.language),
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            '${_unitsController.text} HM³',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            getGasText('rate', widget.language),
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            '${getGasText('rupees', widget.language)} ${_rate.toStringAsFixed(0)} ${getGasText('per_unit', widget.language)}',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

              const SizedBox(height: 20),

              // Notes
              if (_calculated)
                Column(
                  children: [
                    Text(
                      getGasText('note', widget.language),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        fontStyle: FontStyle.italic,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      getGasText('winter_note', widget.language),
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.orange.shade700,
                      ),
                    ),
                  ],
                ),

              const SizedBox(height: 20),

              // Clear Button
              if (_calculated)
                TextButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.refresh),
                  label: Text(getGasText('clear', widget.language)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
