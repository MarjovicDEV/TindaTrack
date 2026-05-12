import 'package:flutter/material.dart';

import '../../core/resources/app_copy.dart';
import '../../core/utils/formatters.dart';

/// Monochrome layout matched to [ReceiptSheet] for PNG / visual parity with receipts.
class ReportExportCard extends StatelessWidget {
  const ReportExportCard({
    super.key,
    required this.periodLabel,
    required this.rangeFrom,
    required this.rangeTo,
    required this.totalSales,
    required this.totalExpenses,
    required this.net,
    required this.currencyCode,
    required this.saleCount,
    required this.expenseCount,
  });

  final String periodLabel;
  final DateTime rangeFrom;
  final DateTime rangeTo;
  final double totalSales;
  final double totalExpenses;
  final double net;
  final String currencyCode;
  final int saleCount;
  final int expenseCount;

  static const Color _ink = Color(0xFF0D0D0D);
  static const Color _muted = Color(0xFF424242);

  Widget _rule() => Padding(
        padding: const EdgeInsets.symmetric(vertical: 10),
        child: Container(height: 1, color: _ink.withValues(alpha: 0.85)),
      );

  Widget _metaRow(AppCopy copy, String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 108,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: _muted,
                letterSpacing: 0.2,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w500,
                color: _ink,
                height: 1.25,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _amountLine(String label, double amount) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: _ink,
                height: 1.2,
              ),
            ),
          ),
          Text(
            formatCurrency(amount, currencyCode: currencyCode),
            textAlign: TextAlign.right,
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w600,
              color: _ink,
              height: 1.2,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    return Material(
      color: Colors.white,
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(color: Colors.black.withValues(alpha: 0.12)),
      ),
      clipBehavior: Clip.antiAlias,
      child: Padding(
        padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
        child: DefaultTextStyle(
          style: const TextStyle(color: _ink, fontFamily: 'Roboto'),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                copy.reportsPageTitle.toUpperCase(),
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  letterSpacing: 1.2,
                  color: _ink,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                copy.reportExportSubtitle,
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: _muted.withValues(alpha: 0.95),
                  letterSpacing: 0.4,
                ),
              ),
              _rule(),
              _metaRow(copy, copy.reportExportPeriodLabel, periodLabel),
              _metaRow(
                copy,
                copy.reportRangeLabel.replaceAll(':', ''),
                '${formatPhilippineDateTime(rangeFrom)} – ${formatPhilippineDateTime(rangeTo)}',
              ),
              _metaRow(
                copy,
                copy.reportExportRecordsLabel,
                copy.reportExportRecordsValue(saleCount, expenseCount),
              ),
              _rule(),
              _amountLine(copy.totalSales, totalSales),
              _amountLine(copy.totalExpenses, totalExpenses),
              const SizedBox(height: 4),
              _rule(),
              const SizedBox(height: 4),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    copy.netProfit.toUpperCase(),
                    style: const TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w800,
                      letterSpacing: 0.8,
                      color: _ink,
                    ),
                  ),
                  Text(
                    formatCurrency(net, currencyCode: currencyCode),
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w800,
                      color: _ink,
                      letterSpacing: -0.3,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                copy.isEnglish ? 'Thank you.' : 'Salamat po.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: _muted.withValues(alpha: 0.9),
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
