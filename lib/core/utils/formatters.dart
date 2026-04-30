import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(
  locale: 'en_PH',
  symbol: 'PHP ',
  decimalDigits: 2,
);

String formatCurrency(num value) => _currency.format(value);

String formatDate(DateTime date) => DateFormat('MMM dd, yyyy').format(date);
