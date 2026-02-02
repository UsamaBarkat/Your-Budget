import 'package:flutter/material.dart';

// Translations for electricity screen
Map<String, Map<String, String>> electricityTranslations = {
  'en': {
    'title': 'Electricity Bill',
    'enter_units': 'Enter Units (kWh)',
    'calculate': 'Calculate',
    'your_bill': 'Your Bill',
    'units': 'Units',
    'rate': 'Rate',
    'total': 'Total',
    'rupees': 'Rs.',
    'unit': 'per unit',
    'note': 'Note: This is an estimate based on HESCO rates',
    'clear': 'Clear',
  },
  'ur': {
    'title': 'بجلی کا بل',
    'enter_units': 'یونٹ درج کریں (kWh)',
    'calculate': 'حساب کریں',
    'your_bill': 'آپ کا بل',
    'units': 'یونٹ',
    'rate': 'ریٹ',
    'total': 'کل',
    'rupees': 'روپے',
    'unit': 'فی یونٹ',
    'note': 'نوٹ: یہ HESCO کے ریٹ پر اندازہ ہے',
    'clear': 'صاف کریں',
  },
  'sd': {
    'title': 'بجلي جو بل',
    'enter_units': 'يونٽ لکو (kWh)',
    'calculate': 'حساب ڪريو',
    'your_bill': 'توهان جو بل',
    'units': 'يونٽ',
    'rate': 'ريٽ',
    'total': 'ڪل',
    'rupees': 'رپيا',
    'unit': 'في يونٽ',
    'note': 'نوٽ: هي HESCO جي ريٽ تي اندازو آهي',
    'clear': 'صاف ڪريو',
  },
};

String getElectricityText(String key, String lang) {
  return electricityTranslations[lang]?[key] ?? electricityTranslations['en']![key]!;
}

class ElectricityScreen extends StatefulWidget {
  final String language;

  const ElectricityScreen({super.key, required this.language});

  @override
  State<ElectricityScreen> createState() => _ElectricityScreenState();
}

class _ElectricityScreenState extends State<ElectricityScreen> {
  final _unitsController = TextEditingController();
  double _bill = 0;
  double _rate = 0;
  bool _calculated = false;

  // HESCO Rate Slabs (approximate rates in PKR per unit)
  double _calculateBill(double units) {
    double bill = 0;
    double rate = 0;

    if (units <= 50) {
      rate = 7.74;
      bill = units * rate;
    } else if (units <= 100) {
      rate = 10.06;
      bill = 50 * 7.74 + (units - 50) * rate;
    } else if (units <= 200) {
      rate = 14.11;
      bill = 50 * 7.74 + 50 * 10.06 + (units - 100) * rate;
    } else if (units <= 300) {
      rate = 17.60;
      bill = 50 * 7.74 + 50 * 10.06 + 100 * 14.11 + (units - 200) * rate;
    } else if (units <= 700) {
      rate = 22.95;
      bill = 50 * 7.74 + 50 * 10.06 + 100 * 14.11 + 100 * 17.60 + (units - 300) * rate;
    } else {
      rate = 26.00;
      bill = 50 * 7.74 + 50 * 10.06 + 100 * 14.11 + 100 * 17.60 + 400 * 22.95 + (units - 700) * rate;
    }

    // Add fixed charges and taxes (approximate)
    double fixedCharges = 150; // Meter rent, TV fee, etc.
    double fuelAdjustment = units * 3.5; // Approximate fuel adjustment

    _rate = rate;
    return bill + fixedCharges + fuelAdjustment;
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
        title: Text(getElectricityText('title', widget.language)),
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
                Icons.bolt,
                size: 80,
                color: Colors.orange.shade600,
              ),

              const SizedBox(height: 30),

              // Units Input
              TextField(
                controller: _unitsController,
                keyboardType: TextInputType.number,
                style: const TextStyle(fontSize: 24),
                textAlign: TextAlign.center,
                decoration: InputDecoration(
                  hintText: getElectricityText('enter_units', widget.language),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  filled: true,
                  fillColor: Colors.orange.shade50,
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
                    getElectricityText('calculate', widget.language),
                    style: const TextStyle(fontSize: 20),
                  ),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.orange,
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
                        getElectricityText('your_bill', widget.language),
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      Text(
                        '${getElectricityText('rupees', widget.language)} ${_bill.toStringAsFixed(0)}',
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
                            getElectricityText('units', widget.language),
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            _unitsController.text,
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
                            getElectricityText('rate', widget.language),
                            style: const TextStyle(fontSize: 16),
                          ),
                          Text(
                            '${getElectricityText('rupees', widget.language)} ${_rate.toStringAsFixed(2)} ${getElectricityText('unit', widget.language)}',
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

              // Note
              if (_calculated)
                Text(
                  getElectricityText('note', widget.language),
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    fontStyle: FontStyle.italic,
                  ),
                ),

              const SizedBox(height: 20),

              // Clear Button
              if (_calculated)
                TextButton.icon(
                  onPressed: _clear,
                  icon: const Icon(Icons.refresh),
                  label: Text(getElectricityText('clear', widget.language)),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
