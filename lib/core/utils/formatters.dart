import 'package:intl/intl.dart';

String formatCurrency(num value, {String currencyCode = 'PHP'}) {
  try {
    return NumberFormat.simpleCurrency(name: currencyCode).format(value);
  } catch (_) {
    return NumberFormat.currency(symbol: '$currencyCode ', decimalDigits: 2).format(value);
  }
}

String formatDate(DateTime date) => DateFormat('MMM dd, yyyy').format(date);

String formatLongDate(DateTime date) => DateFormat('MMMM d, yyyy').format(date);

DateTime _toPhilippineTime(DateTime date) {
  final utc = date.isUtc ? date : date.toUtc();
  return utc.add(const Duration(hours: 8));
}

String formatPhilippineDateTime(DateTime date) =>
    DateFormat('MMMM d, yyyy • hh:mm a').format(_toPhilippineTime(date));
