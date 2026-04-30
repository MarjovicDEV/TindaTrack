import 'package:intl/intl.dart';

final _currency = NumberFormat.currency(
  locale: 'en_PH',
  symbol: 'PHP ',
  decimalDigits: 2,
);

String formatCurrency(num value) => _currency.format(value);

String formatDate(DateTime date) => DateFormat('MMM dd, yyyy').format(date);

String formatLongDate(DateTime date) => DateFormat('MMMM d, yyyy').format(date);

DateTime _toPhilippineTime(DateTime date) {
  final utc = date.isUtc ? date : date.toUtc();
  return utc.add(const Duration(hours: 8));
}

String formatPhilippineDateTime(DateTime date) =>
    DateFormat('MMMM d, yyyy • hh:mm a').format(_toPhilippineTime(date));
