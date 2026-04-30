class InputValidators {
  static final RegExp _nameRegex = RegExp(r'^[A-Za-zÑñ ]+$');
  static final RegExp _decimalRegex = RegExp(r'^\d+(\.\d+)?$');
  static final RegExp _wholeRegex = RegExp(r'^\d+$');

  static String? validateName(String value, {String field = 'Pangalan'}) {
    final text = value.trim();
    if (text.isEmpty) return '$field ay required.';
    if (!_nameRegex.hasMatch(text)) {
      return '$field: words at spaces lang.';
    }
    return null;
  }

  static String? validateDecimalPositive(
    String value, {
    required String field,
  }) {
    final text = value.trim();
    if (text.isEmpty) return '$field ay required.';
    if (!_decimalRegex.hasMatch(text)) {
      return '$field: decimal numbers lang.';
    }
    final number = double.parse(text);
    if (number <= 0) return '$field: dapat mas mataas sa zero.';
    return null;
  }

  static String? validateWholePositive(String value, {required String field}) {
    final text = value.trim();
    if (text.isEmpty) return '$field ay required.';
    if (!_wholeRegex.hasMatch(text)) {
      return '$field: whole numbers lang.';
    }
    final number = int.parse(text);
    if (number <= 0) return '$field: dapat mas mataas sa zero.';
    return null;
  }
}
