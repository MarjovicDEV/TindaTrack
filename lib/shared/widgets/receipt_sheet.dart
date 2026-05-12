import 'dart:ui' as ui;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter/rendering.dart';

import '../../core/resources/app_copy.dart';
import '../../core/utils/formatters.dart';

class ReceiptLineItem {
  const ReceiptLineItem({
    required this.productName,
    required this.qtyLabel,
    required this.unitType,
    required this.unitPriceLabel,
    required this.lineTotalLabel,
  });

  final String productName;
  final String qtyLabel;
  final String unitType;
  final String unitPriceLabel;
  final String lineTotalLabel;
}

class ReceiptViewModel {
  ReceiptViewModel({
    required this.title,
    required this.customerName,
    required this.createdAt,
    required this.totalAmount,
    required this.lines,
    this.dueDate,
  });

  final String title;
  final String customerName;
  final DateTime createdAt;
  final DateTime? dueDate;
  final double totalAmount;
  final List<ReceiptLineItem> lines;
}

/// Monochrome receipt capture: black on white for clean PNG/JPG exports.
class ReceiptSheet extends StatefulWidget {
  const ReceiptSheet({
    super.key,
    required this.model,
    this.onExportPngBytes,
    this.onExportPdf,
  });

  final ReceiptViewModel model;
  final Future<void> Function(Uint8List bytes)? onExportPngBytes;
  final VoidCallback? onExportPdf;

  @override
  State<ReceiptSheet> createState() => _ReceiptSheetState();
}

class _ReceiptSheetState extends State<ReceiptSheet> {
  final GlobalKey _boundaryKey = GlobalKey();

  static const Color _ink = Color(0xFF0D0D0D);
  static const Color _muted = Color(0xFF424242);

  Future<void> _exportPng(BuildContext context, AppCopy copy) async {
    final onBytes = widget.onExportPngBytes;
    if (onBytes == null) return;
    if (kIsWeb) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(copy.reportsPngUnavailable)),
      );
      return;
    }
    await Future<void>.delayed(const Duration(milliseconds: 80));
    if (!context.mounted) return;
    final boundary =
        _boundaryKey.currentContext?.findRenderObject() as RenderRepaintBoundary?;
    if (boundary == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(copy.reportsNoExportView)),
      );
      return;
    }
    try {
      final image = await boundary.toImage(pixelRatio: 2);
      final byteData = await image.toByteData(format: ui.ImageByteFormat.png);
      if (byteData == null) return;
      final bytes = byteData.buffer.asUint8List();
      await onBytes(bytes);
    } catch (e) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(copy.reportExportError('$e'))),
      );
    }
  }

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

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    final m = widget.model;
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          RepaintBoundary(
            key: _boundaryKey,
            child: Material(
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
                        m.title.toUpperCase(),
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
                        copy.isEnglish ? 'Official receipt' : 'Opisyal na resibo',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w500,
                          color: _muted.withValues(alpha: 0.95),
                          letterSpacing: 0.4,
                        ),
                      ),
                      _rule(),
                      _metaRow(copy, copy.receiptCustomerLabel, m.customerName),
                      _metaRow(
                        copy,
                        copy.receiptTransactionLabel.replaceAll(':', ''),
                        formatPhilippineDateTime(m.createdAt),
                      ),
                      if (m.dueDate != null)
                        _metaRow(copy, copy.receiptDueDateLabel, formatLongDate(m.dueDate!)),
                      _rule(),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Expanded(
                            flex: 3,
                            child: Text(
                              copy.receiptColItem,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Text(
                              copy.receiptColQty,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              copy.receiptColUnitPrice,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              copy.receiptColLineTotal,
                              textAlign: TextAlign.right,
                              style: const TextStyle(
                                fontSize: 10,
                                fontWeight: FontWeight.w800,
                                color: _ink,
                                letterSpacing: 0.6,
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      Container(height: 1, color: _ink.withValues(alpha: 0.35)),
                      const SizedBox(height: 10),
                      ...m.lines.map(
                        (line) => Padding(
                          padding: const EdgeInsets.only(bottom: 10),
                          child: Row(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Expanded(
                                flex: 3,
                                child: Text(
                                  line.productName,
                                  style: const TextStyle(
                                    fontSize: 13,
                                    fontWeight: FontWeight.w600,
                                    color: _ink,
                                    height: 1.2,
                                  ),
                                ),
                              ),
                              Expanded(
                                child: Text(
                                  '${line.qtyLabel}\n${line.unitType}',
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _ink,
                                    height: 1.15,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  line.unitPriceLabel,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w500,
                                    color: _ink,
                                    height: 1.15,
                                  ),
                                ),
                              ),
                              Expanded(
                                flex: 2,
                                child: Text(
                                  line.lineTotalLabel,
                                  textAlign: TextAlign.right,
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w700,
                                    color: _ink,
                                    height: 1.15,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 4),
                      _rule(),
                      const SizedBox(height: 4),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            copy.receiptTotalLabel.toUpperCase(),
                            style: const TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 0.8,
                              color: _ink,
                            ),
                          ),
                          Text(
                            formatCurrency(m.totalAmount),
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
            ),
          ),
          const SizedBox(height: 12),
          Wrap(
            spacing: 8,
            children: [
              OutlinedButton(
                onPressed:
                    widget.onExportPngBytes == null ? null : () => _exportPng(context, copy),
                child: Text(copy.exportPng),
              ),
              OutlinedButton(
                onPressed: widget.onExportPdf,
                child: Text(copy.exportPdf),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
