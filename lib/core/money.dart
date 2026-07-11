String? validateRupeeInput(String input) {
  if (input.isEmpty || double.tryParse(input) == null) {
    return 'error_invalid_amount';
  }
  final dot = input.indexOf('.');
  if (dot != -1 && input.length - dot - 1 > 2) {
    return 'error_too_many_decimals';
  }
  return null;
}

// Caller must validate input with validateRupeeInput before calling this.
int rupeesToPaisa(String input) {
  final parts = input.split('.');
  final rupees = int.parse(parts[0]);
  if (parts.length == 1) return rupees * 100;
  return rupees * 100 + int.parse(parts[1].padRight(2, '0'));
}

String paisaToDisplay(int paisa) {
  if (paisa % 100 == 0) return (paisa ~/ 100).toString();
  final cents = (paisa % 100).toString().padLeft(2, '0');
  return '${paisa ~/ 100}.$cents';
}
