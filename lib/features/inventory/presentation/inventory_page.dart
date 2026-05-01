import 'package:flutter/material.dart';

import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/validators/input_validators.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/tinda_repository.dart';
import '../../../shared/widgets/product_image_picker.dart';

class InventoryPage extends StatefulWidget {
  const InventoryPage({required this.repo, super.key});

  final TindaRepository repo;

  @override
  State<InventoryPage> createState() => _InventoryPageState();
}

class _InventoryPageState extends State<InventoryPage> {
  int _crossAxisCount(double width) {
    if (width >= 1200) return 4;
    if (width >= 900) return 3;
    if (width >= 600) return 3;
    return 2;
  }

  @override
  Widget build(BuildContext context) {
    final width = MediaQuery.sizeOf(context).width;
    return Column(
      children: [
        Row(
          children: [
            Text('Imbentaryo', style: Theme.of(context).textTheme.titleLarge),
            const Spacer(),
            FilledButton.icon(
              onPressed: () => _showProductDialog(),
              icon: const Icon(Icons.add),
              label: const Text('Magdagdag'),
            ),
          ],
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: StreamBuilder(
            stream: widget.repo.watchProducts(),
            builder: (context, snapshot) {
              final items = snapshot.data ?? [];
              if (items.isEmpty) {
                return const Center(child: Text('Wala pang produkto.'));
              }
              return GridView.builder(
                padding: const EdgeInsets.all(AppSpacing.xs),
                gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                  crossAxisCount: _crossAxisCount(width),
                  crossAxisSpacing: AppSpacing.sm,
                  mainAxisSpacing: AppSpacing.sm,
                  childAspectRatio: 0.62,
                ),
                itemCount: items.length,
                itemBuilder: (context, index) {
                  final item = items[index];
                  return _ProductCard(
                    item: item,
                    onTap: () => _showProductDialog(product: item),
                    onDelete: () async {
                      try {
                        await widget.repo.deleteProduct(item.id);
                      } catch (e) {
                        if (!context.mounted) return;
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(content: Text(e.toString().replaceFirst('Exception: ', ''))),
                        );
                      }
                    },
                    onConfirmDelete: () => _confirmDelete('Burahin ang "${item.name}"?'),
                  );
                },
              );
            },
          ),
        ),
      ],
    );
  }

  Future<void> _showProductDialog({Product? product}) async {
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final netWeightCtrl = TextEditingController(text: '1');
    final priceCtrl = TextEditingController();
    final stockCtrl = TextEditingController(text: '1.0');
    final thresholdCtrl = TextEditingController(text: '5.0');
    var unitType = 'pcs';
    var netWeightUnit = 'g';
    String? imagePath;

    if (product != null) {
      nameCtrl.text = product.name;
      brandCtrl.text = product.brandName;
      netWeightCtrl.text = product.weight.toString();
      priceCtrl.text = product.price.toString();
      stockCtrl.text = product.stockQty.toString();
      thresholdCtrl.text = product.lowStockThreshold.toString();
      unitType = product.unitType;
      netWeightUnit = product.netWeightUnit;
      imagePath = product.imagePath;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(
            product == null ? 'Magdagdag ng produkto' : 'I-update ang produkto',
          ),
          content: SingleChildScrollView(
            child: StreamBuilder(
              stream: widget.repo.watchUnitMeasurements(),
              builder: (context, snapshot) {
                final units = snapshot.data ?? [];
                final unitNames = units.map((u) => u.name).toList();
                final selectedUnit = unitNames.contains(unitType)
                    ? unitType
                    : (unitNames.isNotEmpty ? unitNames.first : 'pcs');
                return Form(
                  key: formKey,
                  autovalidateMode: AutovalidateMode.onUserInteraction,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      ProductImagePicker(
                        imagePath: imagePath,
                        onChanged: (v) => setState(() => imagePath = v),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: brandCtrl,
                        decoration: const InputDecoration(labelText: 'Brand name'),
                        validator: (v) => InputValidators.validateName(v ?? '', field: 'Brand'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: const InputDecoration(labelText: 'Pangalan ng produkto'),
                        validator: (v) => InputValidators.validateName(v ?? ''),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: netWeightCtrl,
                        decoration: const InputDecoration(labelText: 'Net weight / kapasidad'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => InputValidators.validateDecimalPositive(v ?? '', field: 'Net weight'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        initialValue: netWeightUnit,
                        decoration: const InputDecoration(labelText: 'Net weight unit'),
                        items: const [
                          DropdownMenuItem(value: 'g', child: Text('g')),
                          DropdownMenuItem(value: 'kg', child: Text('kg')),
                          DropdownMenuItem(value: 'ml', child: Text('ml')),
                          DropdownMenuItem(value: 'L', child: Text('L')),
                        ],
                        onChanged: (v) => setState(() => netWeightUnit = v ?? 'g'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: priceCtrl,
                        decoration: const InputDecoration(labelText: 'Presyo'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => InputValidators.validateDecimalPositive(v ?? '', field: 'Presyo'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: stockCtrl,
                        decoration: const InputDecoration(labelText: 'Stock'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => selectedUnit == 'pcs'
                            ? InputValidators.validateWholePositive(v ?? '', field: 'Stock')
                            : InputValidators.validateDecimalPositive(v ?? '', field: 'Stock'),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        initialValue: selectedUnit,
                        decoration: const InputDecoration(labelText: 'Unit of Measure'),
                        items: unitNames
                            .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                            .toList(),
                        validator: (v) => v == null || v.isEmpty ? 'Unit ay required.' : null,
                        onChanged: (v) => setState(() => unitType = v ?? selectedUnit),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: thresholdCtrl,
                        decoration: const InputDecoration(labelText: 'Babala sa mababang stock'),
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        validator: (v) => InputValidators.validateDecimalPositive(v ?? '', field: 'Low stock'),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: const Text('Kanselahin')),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final units = await widget.repo.watchUnitMeasurements().first;
                final unitNames = units.map((u) => u.name).toList();
                final selectedUnit = unitNames.contains(unitType)
                    ? unitType
                    : (unitNames.isNotEmpty ? unitNames.first : 'pcs');

                if (product == null) {
                  await widget.repo.addProduct(
                    name: nameCtrl.text.trim(),
                    brandName: brandCtrl.text.trim(),
                    price: double.parse(priceCtrl.text),
                    stockQty: double.parse(stockCtrl.text),
                    threshold: double.parse(thresholdCtrl.text),
                    weight: double.parse(netWeightCtrl.text),
                    netWeightUnit: netWeightUnit,
                    unitType: selectedUnit,
                    imagePath: imagePath,
                  );
                } else {
                  await widget.repo.updateProduct(
                    id: product.id,
                    name: nameCtrl.text.trim(),
                    brandName: brandCtrl.text.trim(),
                    price: double.parse(priceCtrl.text),
                    stockQty: double.parse(stockCtrl.text),
                    threshold: double.parse(thresholdCtrl.text),
                    weight: double.parse(netWeightCtrl.text),
                    netWeightUnit: netWeightUnit,
                    unitType: selectedUnit,
                    imagePath: imagePath,
                  );
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: const Text('I-save'),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(String message) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Kumpirmahin ang delete'),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: const Text('Hindi')),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete'),
          ),
        ],
      ),
    );
  }
}

class _ProductCard extends StatelessWidget {
  const _ProductCard({
    required this.item,
    required this.onTap,
    required this.onDelete,
    required this.onConfirmDelete,
  });

  final Product item;
  final VoidCallback onTap;
  final Future<void> Function() onDelete;
  final Future<bool?> Function() onConfirmDelete;

  static const List<Color> _headerColors = [
    Color(0xFF6B4DB6),
    Color(0xFF2E7D8B),
    Color(0xFF1A4480),
    Color(0xFF2E7D32),
    Color(0xFFE65100),
    Color(0xFF880E4F),
  ];

  Color _headerColor(String seed) {
    return _headerColors[seed.hashCode.abs() % _headerColors.length];
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final low = item.stockQty <= item.lowStockThreshold;
    final hasImage = item.imagePath != null && item.imagePath!.isNotEmpty;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(
              height: 156,
              child: hasImage
                  ? ColoredBox(
                      color: cs.surfaceContainerHighest,
                      child: ProductImagePreview(
                        imageValue: item.imagePath,
                        fit: BoxFit.contain,
                        placeholder: _colorHeader(item.name),
                      ),
                    )
                  : _colorHeader(item.name),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 6),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    if (item.brandName.isNotEmpty)
                      Text(
                        item.brandName,
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    const Spacer(),
                    Text(
                      formatCurrency(item.price),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                    Row(
                      children: [
                        if (low) Icon(Icons.warning_amber_outlined, size: 12, color: cs.error),
                        Expanded(
                          child: Text(
                            'Stock: ${item.stockQty.toStringAsFixed(2)} ${item.unitType}',
                            style: Theme.of(context).textTheme.bodySmall?.copyWith(
                                  color: low ? cs.error : cs.onSurfaceVariant,
                                ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.only(right: 4, bottom: 2),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 18),
                    onPressed: onTap,
                    visualDensity: VisualDensity.compact,
                    tooltip: 'I-edit',
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 18, color: cs.error),
                    visualDensity: VisualDensity.compact,
                    tooltip: 'Burahin',
                    onPressed: () async {
                      final confirmed = await onConfirmDelete();
                      if (confirmed == true) await onDelete();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _colorHeader(String name) {
    final color = _headerColor(name);
    return Container(
      color: color,
      child: Center(
        child: Text(
          name.isNotEmpty ? name[0].toUpperCase() : '?',
          style: TextStyle(
            fontSize: 40,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}

