String? validateGramInput(String input) {
  if (input.isEmpty || double.tryParse(input) == null) return 'error_invalid_amount';
  if (double.parse(input) < 0) return 'error_invalid_amount';
  final dot = input.indexOf('.');
  if (dot != -1 && input.length - dot - 1 > 3) return 'error_too_many_gram_decimals';
  return null;
}

int gramsToMilligrams(String input) {
  final parts = input.split('.');
  final grams = int.parse(parts[0]);
  if (parts.length == 1) return grams * 1000;
  return grams * 1000 + int.parse(parts[1].padRight(3, '0'));
}

String milligramsToGrams(int mg) {
  if (mg % 1000 == 0) return (mg ~/ 1000).toString();
  final remainder = mg % 1000;
  if (remainder % 100 == 0) return '${mg ~/ 1000}.${remainder ~/ 100}';
  if (remainder % 10 == 0) return '${mg ~/ 1000}.${(remainder ~/ 10).toString().padLeft(2, '0')}';
  return '${mg ~/ 1000}.${remainder.toString().padLeft(3, '0')}';
}

// (metalMg × pricePerGramPaisa + 500) ~/ 1000
// Units: mg × paisa/g = paisa/1000 (milli-paisa); ÷1000 → paisa. +500 = round-half-up.
int computeMetalValue(int metalMg, int pricePerGramPaisa) {
  return (metalMg * pricePerGramPaisa + 500) ~/ 1000;
}

// Nisab = 612.36 g × silver price/g. 612.36 g = 612360 mg (exact integer).
// (silverPricePerGramPaisa × 612360 + 500) ~/ 1000 → paisa, round-half-up.
int computeNisab(int silverPricePerGramPaisa) {
  return (silverPricePerGramPaisa * 612360 + 500) ~/ 1000;
}

int computeTotalAssets(int cash, int goldValue, int silverValue, int business) {
  return cash + goldValue + silverValue + business;
}

// 2.5% = 25/1000. (totalAssets × 25 + 500) ~/ 1000 → paisa, round-half-up.
int computeZakat(int totalAssets, int nisab) {
  if (totalAssets < nisab) return 0;
  return (totalAssets * 25 + 500) ~/ 1000;
}
