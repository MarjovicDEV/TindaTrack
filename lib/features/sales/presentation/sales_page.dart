import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../../../core/resources/app_copy.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/validators/input_validators.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/tinda_repository.dart';
import '../../../features/receipts/application/receipt_pdf_builder.dart';
import '../../../shared/widgets/receipt_sheet.dart';
import '../../reports/presentation/report_export_stub.dart'
    if (dart.library.io) '../../reports/presentation/report_export_io.dart' as report_export;

class SalesPage extends StatefulWidget {
  const SalesPage({required this.repo, super.key});

  final TindaRepository repo;

  @override
  State<SalesPage> createState() => _SalesPageState();
}

class _SalesPageState extends State<SalesPage> {
  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.maybePop(context),
        ),
        title: Text(copy.navSales),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Align(
                alignment: Alignment.centerRight,
                child: FilledButton.icon(
                  onPressed: () => _showSaleDialog(),
                  icon: const Icon(Icons.save_outlined),
                  label: Text(copy.isEnglish ? 'Record sale' : 'Mag-record ng benta'),
                ),
              ),
              const SizedBox(height: AppSpacing.sm),
              Expanded(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    color: scheme.surfaceContainerHighest.withValues(alpha: 0.35),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: StreamBuilder<List<Sale>>(
                    stream: widget.repo.watchSales(),
                    builder: (context, snapshot) {
                      final sales = snapshot.data ?? const <Sale>[];
                      if (sales.isEmpty) {
                        return Center(
                          child: Text(
                            copy.isEnglish ? 'No sales yet recorded.' : 'Wala pang naitalang benta.',
                            style: Theme.of(context).textTheme.bodyLarge,
                          ),
                        );
                      }
                      return ListView.builder(
                        padding: const EdgeInsets.all(AppSpacing.sm),
                        itemCount: sales.length,
                        itemBuilder: (context, index) {
                          final item = sales[index];
                          final isUtangPayment = item.sourceUtangEntryId != null;
                          return Padding(
                            padding: const EdgeInsets.only(bottom: AppSpacing.sm),
                            child: Dismissible(
                              key: ValueKey('sale-${item.id}'),
                              direction: DismissDirection.endToStart,
                              confirmDismiss: (_) => _confirmDelete(
                                isUtangPayment
                                    ? copy.saleUtangPaymentDeleteConfirm(item.id)
                                    : (copy.isEnglish
                                        ? 'Delete sale #${item.id}?'
                                        : 'Burahin ang benta #${item.id}?'),
                              ),
                              onDismissed: (_) =>
                                  widget.repo.deleteSaleAndRestoreStock(item.id),
                              background: Container(
                                alignment: Alignment.centerRight,
                                padding: const EdgeInsets.symmetric(
                                  horizontal: AppSpacing.sm,
                                ),
                                decoration: BoxDecoration(
                                  color: Colors.red.shade600,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: const Icon(Icons.delete, color: Colors.white),
                              ),
                              child: Card(
                                elevation: 0,
                                shape: RoundedRectangleBorder(
                                  borderRadius: BorderRadius.circular(12),
                                  side: BorderSide(color: scheme.outlineVariant),
                                ),
                                child: ListTile(
                                  onTap: isUtangPayment
                                      ? () {
                                          ScaffoldMessenger.of(context).showSnackBar(
                                            SnackBar(content: Text(copy.saleUtangPaymentEditHint)),
                                          );
                                        }
                                      : () => _showSaleDialog(existingSale: item),
                                   title: Text(
                                     isUtangPayment
                                         ? copy.saleUtangPaymentTitle
                                         : (copy.isEnglish ? 'Sale #${item.id}' : 'Benta #${item.id}'),
                                   ),
                                   subtitle: Text(
                                     '${copy.isEnglish ? 'Transaction' : 'Transaksyon'} (PH UTC+8): ${formatPhilippineDateTime(item.createdAt)}',
                                     style: Theme.of(context).textTheme.bodySmall,
                                   ),
                                  trailing: Row(
                                    mainAxisSize: MainAxisSize.min,
                                    children: [
                                      Text(formatCurrency(item.totalAmount)),
                                      IconButton(
                                        icon: const Icon(Icons.receipt_outlined),
                                        tooltip: copy.saleReceiptTitle,
                                        onPressed: () => _showSaleReceipt(item.id),
                                      ),
                                    ],
                                  ),
                                ),
                              ),
                            ),
                          );
                        },
                      );
                    },
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _showSaleDialog({dynamic existingSale}) async {
    final copy = AppCopy.of(context);
    final customers = await widget.repo.watchCustomers().first;
    if (customers.isEmpty) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(copy.utangNoCustomers)),
      );
      return;
    }
    final formKey = GlobalKey<FormState>();
    final qtyCtrl = TextEditingController(text: '1');
    int? selectedProductId;
    int? priorProductId;
    var priorQty = 0.0;
    int? selectedCustomerId;
    if (existingSale != null) {
      selectedCustomerId = existingSale.customerId;
      final items = await widget.repo.getSaleItems(existingSale.id);
      if (items.isNotEmpty) {
        selectedProductId = items.first.productId;
        priorProductId = items.first.productId;
        priorQty = items.first.qty;
        qtyCtrl.text = items.first.qty.toString();
      }
    }

    if (!mounted) return;
    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            existingSale == null
                ? (copy.isEnglish ? 'Record sale' : 'Mag-record ng benta')
                : (copy.isEnglish ? 'Update sale' : 'I-update ang benta'),
          ),
          content: StreamBuilder(
            stream: widget.repo.watchProducts(),
            builder: (context, snapshot) {
              final products = snapshot.data ?? [];
              dynamic selectedProduct;
              if (selectedProductId != null) {
                for (final product in products) {
                  if (product.id == selectedProductId) {
                    selectedProduct = product;
                    break;
                  }
                }
              }
              return SizedBox(
                width: double.maxFinite,
                child: SingleChildScrollView(
                  child: Form(
                    key: formKey,
                    autovalidateMode: AutovalidateMode.onUserInteraction,
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        DropdownButtonFormField<int>(
                      initialValue: selectedCustomerId,
                      decoration: InputDecoration(
                        labelText: copy.receiptCustomerLabel,
                      ),
                      items: customers
                          .map(
                            (c) => DropdownMenuItem(
                              value: c.id,
                              child: Text(c.name),
                            ),
                          )
                          .toList(),
                      validator: (v) =>
                          v == null ? (copy.isEnglish ? 'Customer is required.' : 'Customer ay required.') : null,
                      onChanged: (value) => setState(() => selectedCustomerId = value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    DropdownButtonFormField<int>(
                      initialValue: selectedProductId,
                       hint: Text(copy.isEnglish ? 'Choose a product' : 'Pumili ng produkto'),
                      items: products
                          .map(
                            (p) => DropdownMenuItem(
                              value: p.id,
                              child: Text(
                                '${p.name} (${p.unitType}) stock:${p.stockQty.toStringAsFixed(2)}',
                              ),
                            ),
                          )
                          .toList(),
                      validator: (v) =>
                           v == null ? (copy.isEnglish ? 'Product is required.' : 'Produkto ay required.') : null,
                      onChanged: (value) =>
                          setState(() => selectedProductId = value),
                    ),
                    const SizedBox(height: AppSpacing.md),
                    TextFormField(
                      controller: qtyCtrl,
                      decoration: InputDecoration(
                         labelText: selectedProduct == null
                             ? (copy.isEnglish ? 'Quantity / weight' : 'Dami / Timbang')
                             : (copy.isEnglish ? 'Quantity (${selectedProduct.unitType})' : 'Dami (${selectedProduct.unitType})'),
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        if (selectedProductId == null) {
                          return copy.isEnglish ? 'Choose a product first.' : 'Pumili muna ng produkto.';
                        }
                        final product = products.firstWhere(
                          (p) => p.id == selectedProductId,
                        );
                        final base = product.unitType == 'kg'
                              ? InputValidators.validateDecimalPositive(
                                  v ?? '',
                                  field: copy.isEnglish ? 'Weight' : 'Timbang',
                                )
                            : InputValidators.validateWholePositive(
                                v ?? '',
                                 field: 'Qty',
                              );
                        if (base != null) return base;
                        final q = double.tryParse(v ?? '') ?? 0;
                        var effectiveAvailable = product.stockQty;
                        if (existingSale != null &&
                            priorProductId != null &&
                            selectedProductId == priorProductId) {
                          effectiveAvailable = product.stockQty + priorQty;
                        }
                        if (q > effectiveAvailable) {
                           return copy.isEnglish ? 'Not allowed. Insufficient stock. Max: ' : 'Hindi pwede. Kulang stock. Max: '
                               '${effectiveAvailable.toStringAsFixed(2)}.';
                        }
                        return null;
                      },
                    ),
                      ],
                    ),
                  ),
                ),
              );
            },
          ),
          actions: [
            TextButton(
               onPressed: () => Navigator.pop(context),
               child: Text(copy.inventoryCancel),
            ),
            FilledButton(
              onPressed: () async {
                if (selectedProductId == null) return;
                final products = await widget.repo.watchProducts().first;
                final product = products.firstWhere(
                  (p) => p.id == selectedProductId,
                );
                if (!formKey.currentState!.validate()) return;
                final quantity = double.parse(qtyCtrl.text);
                if (selectedCustomerId == null) return;
                if (existingSale == null) {
                  await widget.repo.createSale(
                    productId: product.id,
                    quantity: quantity,
                    customerId: selectedCustomerId!,
                  );
                } else {
                  await widget.repo.updateSale(
                    saleId: existingSale.id,
                    productId: product.id,
                    quantity: quantity,
                    customerId: selectedCustomerId!,
                  );
                }
                if (context.mounted) Navigator.pop(context);
              },
               child: Text(copy.isEnglish ? 'Save sale' : 'I-save ang benta'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showSaleReceipt(int saleId) async {
    final copy = AppCopy.of(context);
    final receipt = await widget.repo.getSaleReceipt(saleId);
    if (!mounted) return;
    await showModalBottomSheet<void>(
      context: context,
      isScrollControlled: true,
      builder: (sheetContext) => SafeArea(
        child: SingleChildScrollView(
          child: ReceiptSheet(
            model: ReceiptViewModel(
              title: copy.saleReceiptTitle,
              customerName: receipt.customerName,
              createdAt: receipt.sale.createdAt,
              totalAmount: receipt.sale.totalAmount,
              lines: receipt.lines
                  .map(
                    (line) => ReceiptLineItem(
                      productName: line.productName,
                      qtyLabel: line.qty.toStringAsFixed(2),
                      unitType: line.unitType,
                      unitPriceLabel: formatCurrency(line.unitPrice),
                      lineTotalLabel: formatCurrency(line.lineTotal),
                    ),
                  )
                  .toList(),
            ),
            onExportPngBytes: kIsWeb
                ? null
                : (bytes) => _writeSaleReceiptPng(bytes, copy),
            onExportPdf: () => _exportSalePdf(receipt, copy),
          ),
        ),
      ),
    );
  }

  Future<void> _writeSaleReceiptPng(Uint8List bytes, AppCopy copy) async {
    final path = await report_export.writeReportPngBytes(bytes);
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(copy.reportPngSaved(path))),
    );
  }

  Future<void> _exportSalePdf(SaleReceiptDetail receipt, AppCopy copy) async {
    try {
      final bytes = await ReceiptPdfBuilder.buildSaleReceiptBytes(
        title: copy.saleReceiptTitle,
        receipt: receipt,
        currencyCode: 'PHP',
        labelCustomer: copy.receiptCustomerLabel,
        labelTotal: copy.receiptTotalLabel,
        labelTransaction: copy.receiptTransactionLabel,
        labelDueDate: copy.receiptDueDateLabel,
        colItem: copy.receiptColItem,
        colQty: copy.receiptColQty,
        colUnitPrice: copy.receiptColUnitPrice,
        colLineTotal: copy.receiptColLineTotal,
      );
      if (kIsWeb) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(copy.reportPdfDownloadSoon(bytes.length))),
        );
        return;
      }
      final path = await report_export.writeReportPdfBytes(bytes);
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(copy.reportPdfSaved(path))),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(copy.reportExportError('$e'))),
      );
    }
  }

  Future<bool?> _confirmDelete(String message) {
    final copy = AppCopy.of(context);
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(copy.inventoryConfirmDeleteTitle),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(copy.inventoryDeleteNo)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(copy.inventoryDeleteYes),
          ),
        ],
      ),
    );
  }
}
