import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../../core/resources/app_copy.dart';
import '../../../core/theme/app_spacing.dart';
import '../../../core/utils/formatters.dart';
import '../../../core/validators/input_validators.dart';
import '../../../data/local/app_database.dart';
import '../../../data/repositories/tinda_repository.dart';
import '../../../shared/widgets/product_image_picker.dart';

class GroceryPage extends StatefulWidget {
  const GroceryPage({required this.repo, super.key});

  final TindaRepository repo;

  @override
  State<GroceryPage> createState() => _GroceryPageState();
}

class _GroceryPageState extends State<GroceryPage> {
  static const List<String> _mallOptions = [
    'Gaisano',
    'KCC Mall of Gensan',
    'SM Supermarket',
    "Robinson's",
  ];

  int? _selectedListId;

  GroceryList? _findList(List<GroceryList> lists, int? id) {
    if (id == null) return null;
    for (final l in lists) {
      if (l.id == id) return l;
    }
    return null;
  }

  String _chipLine1(BuildContext context, DateTime startAt) {
    final d = DateFormat('MMM d').format(startAt);
    final t = TimeOfDay.fromDateTime(startAt).format(context);
    return '$d · $t';
  }

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(copy.groceryTitle, style: theme.textTheme.titleLarge),
                    const SizedBox(height: 2),
                    Text(
                      copy.grocerySubtitle,
                      style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                    ),
                  ],
                ),
              ),
              IconButton(
                tooltip: copy.groceryCreateScheduleTooltip,
                onPressed: _showListDialog,
                icon: const Icon(Icons.add_circle_outline),
              ),
            ],
          ),
        ),
        const SizedBox(height: AppSpacing.sm),
        StreamBuilder<List<GroceryList>>(
          stream: widget.repo.watchGroceryLists(),
          builder: (context, snapshot) {
            final lists = snapshot.data ?? [];
            if (lists.isEmpty) {
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                child: Padding(
                  padding: const EdgeInsets.all(AppSpacing.md),
                  child: Column(
                    children: [
                      Icon(Icons.event_available_outlined, size: 48, color: cs.onSurfaceVariant),
                      const SizedBox(height: AppSpacing.sm),
                      Text(copy.groceryNoSchedule, style: theme.textTheme.titleSmall),
                      const SizedBox(height: AppSpacing.xs),
                      Text(
                        copy.groceryNoScheduleDescription,
                        textAlign: TextAlign.center,
                        style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      FilledButton.icon(
                        onPressed: _showListDialog,
                        icon: const Icon(Icons.playlist_add),
                        label: Text(copy.groceryCreateSchedule),
                      ),
                    ],
                  ),
                ),
              );
            }

            final hasSelected =
                _selectedListId != null && lists.any((l) => l.id == _selectedListId);
            if (!hasSelected) {
              WidgetsBinding.instance.addPostFrameCallback((_) {
                if (mounted) setState(() => _selectedListId = lists.first.id);
              });
            }

            final selected = _findList(lists, _selectedListId);

            return Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                  child: Row(
                    children: lists.map((list) {
                      final fullLabel =
                          '${formatLongDate(list.startAt)} ${TimeOfDay.fromDateTime(list.startAt).format(context)} · ${list.mallName}';
                      return Padding(
                        padding: const EdgeInsets.only(right: AppSpacing.xs),
                        child: Tooltip(
                          message: fullLabel,
                          child: ChoiceChip(
                            showCheckmark: true,
                            label: SizedBox(
                              width: 128,
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  Text(
                                    _chipLine1(context, list.startAt),
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelMedium?.copyWith(
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(
                                    list.mallName,
                                    maxLines: 1,
                                    overflow: TextOverflow.ellipsis,
                                    style: theme.textTheme.labelSmall?.copyWith(
                                      color: cs.onSurfaceVariant,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            selected: list.id == _selectedListId,
                            onSelected: (_) => setState(() => _selectedListId = list.id),
                          ),
                        ),
                      );
                    }).toList(),
                  ),
                ),
                if (selected != null) ...[
                  const SizedBox(height: AppSpacing.sm),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: AppSpacing.sm),
                    child: Card(
                      elevation: 0,
                      color: cs.surfaceContainerLow,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                        side: BorderSide(color: cs.outlineVariant),
                      ),
                      child: Padding(
                        padding: const EdgeInsets.all(AppSpacing.md),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Icon(Icons.storefront_outlined, size: 20, color: cs.primary),
                                const SizedBox(width: AppSpacing.xs),
                                Expanded(
                                  child: Text(
                                    selected.mallName,
                                    style: theme.textTheme.titleMedium?.copyWith(
                                      fontWeight: FontWeight.w700,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 4),
                            Text(
                              '${formatLongDate(selected.startAt)} · ${TimeOfDay.fromDateTime(selected.startAt).format(context)}',
                              style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                            ),
                            const SizedBox(height: AppSpacing.md),
                            LayoutBuilder(
                              builder: (context, c) {
                                final narrow = c.maxWidth < 420;
                                if (narrow) {
                                  return Column(
                                    crossAxisAlignment: CrossAxisAlignment.stretch,
                                    children: [
                                      FilledButton.icon(
                                        onPressed: () =>
                                            _showItemDialog(groceryListId: selected.id),
                                        icon: const Icon(Icons.add),
                          label: Text(copy.groceryAddItem),
                                      ),
                                    ],
                                  );
                                }
                                return Row(
                                  children: [
                                    Expanded(
                                      child: FilledButton.icon(
                                        onPressed: () =>
                                            _showItemDialog(groceryListId: selected.id),
                                        icon: const Icon(Icons.add),
                                          label: Text(copy.groceryAddItem),
                                      ),
                                    ),
                                  ],
                                );
                              },
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),
                ],
              ],
            );
          },
        ),
        const SizedBox(height: AppSpacing.sm),
        Expanded(
          child: _selectedListId == null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(AppSpacing.lg),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.touch_app_outlined, size: 56, color: cs.onSurfaceVariant),
                        const SizedBox(height: AppSpacing.md),
                        Text(
                          copy.groceryPickSchedule,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.titleSmall,
                        ),
                        const SizedBox(height: AppSpacing.xs),
                        Text(
                          copy.groceryPickScheduleDescription,
                          textAlign: TextAlign.center,
                          style: theme.textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        ),
                      ],
                    ),
                  ),
                )
              : StreamBuilder(
                  stream: widget.repo.watchGroceryItemsByList(_selectedListId!),
                  builder: (context, snapshot) {
                    final items = snapshot.data ?? [];
                    if (items.isEmpty) {
                      return LayoutBuilder(
                        builder: (context, constraints) => SingleChildScrollView(
                          padding: const EdgeInsets.all(AppSpacing.lg),
                          child: ConstrainedBox(
                            constraints: BoxConstraints(minHeight: constraints.maxHeight - 12),
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.shopping_bag_outlined,
                                  size: 52,
                                  color: cs.onSurfaceVariant,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                Text(
                                  'Wala pang items sa schedule na ito.',
                                  textAlign: TextAlign.center,
                                  style: theme.textTheme.titleSmall,
                                ),
                                const SizedBox(height: AppSpacing.sm),
                                FilledButton.icon(
                                  onPressed: () =>
                                      _showItemDialog(groceryListId: _selectedListId!),
                                  icon: const Icon(Icons.add),
                          label: Text(copy.groceryAddFirstItem),
                                ),
                              ],
                            ),
                          ),
                        ),
                      );
                    }
                    return GridView.builder(
                      padding: const EdgeInsets.fromLTRB(
                        AppSpacing.sm,
                        0,
                        AppSpacing.sm,
                        AppSpacing.sm,
                      ),
                      gridDelegate: const SliverGridDelegateWithMaxCrossAxisExtent(
                        maxCrossAxisExtent: 190,
                        crossAxisSpacing: AppSpacing.sm,
                        mainAxisSpacing: AppSpacing.sm,
                        childAspectRatio: 0.62,
                      ),
                      itemCount: items.length,
                      itemBuilder: (context, index) {
                        final item = items[index];
                        return _GroceryCard(
                          item: item,
                          onCardTap: () => widget.repo.toggleGrocery(item.id, !item.isDone),
                          onEdit: () => _showItemDialog(
                            existing: item,
                            groceryListId: item.groceryListId ?? _selectedListId!,
                          ),
                          onToggle: (v) => widget.repo.toggleGrocery(item.id, v),
                          onDelete: () => widget.repo.deleteGroceryItem(item.id),
                          onConfirmDelete: () => _confirmDelete(copy, 'Burahin ang "${item.name}"?'),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }

  Future<void> _showListDialog() async {
    final copy = AppCopy.of(context);
    final formKey = GlobalKey<FormState>();
    DateTime? pickedDate = DateTime.now();
    TimeOfDay? pickedTime = TimeOfDay.now();
    String mall = _mallOptions.first;

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(copy.groceryCreateScheduleDialogTitle),
          content: Form(
            key: formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(copy.dateLabel),
                  subtitle: Text(
                    pickedDate == null ? copy.pickDate : formatLongDate(pickedDate!),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.calendar_month_outlined),
                    onPressed: () async {
                      final now = DateTime.now();
                      final selected = await showDatePicker(
                        context: context,
                        firstDate: DateTime(now.year, now.month, now.day),
                        lastDate: DateTime(now.year + 3),
                        initialDate: pickedDate ?? now,
                      );
                      if (selected != null) {
                        setState(() => pickedDate = selected);
                      }
                    },
                  ),
                ),
                ListTile(
                  contentPadding: EdgeInsets.zero,
                  title: Text(copy.timeLabel),
                  subtitle: Text(
                    pickedTime == null ? copy.pickTime : pickedTime!.format(context),
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.access_time),
                    onPressed: () async {
                      final selected = await showTimePicker(
                        context: context,
                        initialTime: pickedTime ?? TimeOfDay.now(),
                      );
                      if (selected != null) {
                        setState(() => pickedTime = selected);
                      }
                    },
                  ),
                ),
                DropdownButtonFormField<String>(
                  initialValue: mall,
                  decoration: InputDecoration(labelText: copy.mallLocationLabel),
                  items: _mallOptions
                      .map((m) => DropdownMenuItem(value: m, child: Text(m)))
                      .toList(),
                  onChanged: (v) => setState(() => mall = v ?? _mallOptions.first),
                ),
              ],
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(copy.groceryCancel)),
            FilledButton(
              onPressed: () async {
                if (pickedDate == null || pickedTime == null) return;
                final startAt = DateTime(
                  pickedDate!.year,
                  pickedDate!.month,
                  pickedDate!.day,
                  pickedTime!.hour,
                  pickedTime!.minute,
                );
                final id = await widget.repo.addGroceryList(startAt: startAt, mallName: mall);
                if (!context.mounted) return;
                setState(() => _selectedListId = id);
                Navigator.pop(context);
              },
              child: Text(copy.grocerySave),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showItemDialog({
    required int groceryListId,
    GroceryItem? existing,
  }) async {
    final copy = AppCopy.of(context);
    final formKey = GlobalKey<FormState>();
    final nameCtrl = TextEditingController();
    final brandCtrl = TextEditingController();
    final netWeightCtrl = TextEditingController(text: '1');
    final qtyCtrl = TextEditingController(text: '1.0');
    var unitType = 'pcs';
    var netWeightUnit = 'g';
    String? imagePath;

    if (existing != null) {
      nameCtrl.text = existing.name;
      brandCtrl.text = existing.brandName;
      netWeightCtrl.text = existing.netWeight.toString();
      qtyCtrl.text = existing.qty.toString();
      unitType = existing.unitType;
      netWeightUnit = existing.netWeightUnit;
      imagePath = existing.imagePath;
    }

    await showDialog<void>(
      context: context,
      builder: (_) => StatefulBuilder(
        builder: (context, setState) => AlertDialog(
          title: Text(existing == null ? copy.groceryAddItem : copy.groceryAddItem),
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
                        decoration: InputDecoration(labelText: copy.inventoryBrandName),
                        validator: (v) => InputValidators.validateName(v ?? '', field: copy.inventoryBrandName),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: nameCtrl,
                        decoration: InputDecoration(labelText: copy.inventoryProductName),
                        validator: (v) => InputValidators.validateName(v ?? '', field: copy.inventoryProductName),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      TextFormField(
                        controller: netWeightCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: copy.inventoryNetWeight),
                        validator: (v) => InputValidators.validateDecimalPositive(v ?? '', field: copy.inventoryNetWeight),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        initialValue: netWeightUnit,
                        decoration: InputDecoration(labelText: copy.inventoryNetWeightUnit),
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
                        controller: qtyCtrl,
                        keyboardType: const TextInputType.numberWithOptions(decimal: true),
                        decoration: InputDecoration(labelText: copy.utangQty),
                        validator: (v) => InputValidators.validateDecimalPositive(v ?? '', field: copy.utangQty),
                      ),
                      const SizedBox(height: AppSpacing.md),
                      DropdownButtonFormField<String>(
                        initialValue: selectedUnit,
                        decoration: InputDecoration(labelText: copy.inventoryUnitOfMeasure),
                        validator: (v) => v == null || v.isEmpty ? copy.inventoryUnitRequired : null,
                        items: unitNames
                            .map((unit) => DropdownMenuItem(value: unit, child: Text(unit)))
                            .toList(),
                        onChanged: (v) => setState(() => unitType = v ?? selectedUnit),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
          actions: [
            TextButton(onPressed: () => Navigator.pop(context), child: Text(copy.groceryCancel)),
            FilledButton(
              onPressed: () async {
                if (!formKey.currentState!.validate()) return;
                final units = await widget.repo.watchUnitMeasurements().first;
                final unitNames = units.map((u) => u.name).toList();
                final selectedUnit = unitNames.contains(unitType)
                    ? unitType
                    : (unitNames.isNotEmpty ? unitNames.first : 'pcs');
                if (existing == null) {
                  await widget.repo.addGroceryItem(
                    nameCtrl.text.trim(),
                    groceryListId: groceryListId,
                    brandName: brandCtrl.text.trim(),
                    netWeight: double.parse(netWeightCtrl.text),
                    netWeightUnit: netWeightUnit,
                    qty: double.parse(qtyCtrl.text),
                    unitType: selectedUnit,
                    imagePath: imagePath,
                  );
                } else {
                  await widget.repo.updateGroceryItem(
                    id: existing.id,
                    groceryListId: groceryListId,
                    name: nameCtrl.text.trim(),
                    brandName: brandCtrl.text.trim(),
                    netWeight: double.parse(netWeightCtrl.text),
                    netWeightUnit: netWeightUnit,
                    qty: double.parse(qtyCtrl.text),
                    unitType: selectedUnit,
                    imagePath: imagePath,
                  );
                }
                if (context.mounted) Navigator.pop(context);
              },
              child: Text(copy.grocerySave),
            ),
          ],
        ),
      ),
    );
  }

  Future<bool?> _confirmDelete(AppCopy copy, String message) {
    return showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(copy.groceryConfirmDeleteTitle),
        content: Text(message),
        actions: [
          TextButton(onPressed: () => Navigator.pop(context, false), child: Text(copy.groceryDeleteNo)),
          FilledButton(
            style: FilledButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(context, true),
            child: Text(copy.groceryDeleteYes),
          ),
        ],
      ),
    );
  }
}

class _GroceryCard extends StatelessWidget {
  const _GroceryCard({
    required this.item,
    required this.onCardTap,
    required this.onEdit,
    required this.onToggle,
    required this.onDelete,
    required this.onConfirmDelete,
  });

  final GroceryItem item;
  final VoidCallback onCardTap;
  final VoidCallback onEdit;
  final ValueChanged<bool> onToggle;
  final VoidCallback onDelete;
  final Future<bool?> Function() onConfirmDelete;

  static const List<Color> _headerColors = [
    Color(0xFF2E7D32),
    Color(0xFF00695C),
    Color(0xFF1565C0),
    Color(0xFF6A1B9A),
    Color(0xFFE65100),
    Color(0xFF37474F),
  ];

  Color _headerColor(String seed) =>
      _headerColors[seed.hashCode.abs() % _headerColors.length];

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    final cs = Theme.of(context).colorScheme;
    final hasImage = item.imagePath != null && item.imagePath!.isNotEmpty;

    return Card(
      elevation: item.isDone ? 0 : 1,
      clipBehavior: Clip.antiAlias,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
        side: BorderSide(
          color: item.isDone ? cs.primary : cs.outlineVariant.withValues(alpha: 0.45),
          width: item.isDone ? 2 : 1,
        ),
      ),
      child: InkWell(
        onTap: onCardTap,
        borderRadius: BorderRadius.circular(12),
        child: AnimatedOpacity(
          duration: const Duration(milliseconds: 180),
          opacity: item.isDone ? 0.78 : 1,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              SizedBox(
                height: 148,
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    hasImage
                        ? ColoredBox(
                            color: cs.surfaceContainerHighest,
                            child: ProductImagePreview(
                              imageValue: item.imagePath,
                              fit: BoxFit.contain,
                              placeholder: _colorHeader(item.name),
                            ),
                          )
                        : _colorHeader(item.name),
                    Positioned(
                      top: 2,
                      right: 2,
                      child: Material(
                        color: cs.surface.withValues(alpha: 0.92),
                        shape: const CircleBorder(),
                        clipBehavior: Clip.antiAlias,
                        child: IconButton(
                          tooltip: item.isDone ? 'Mark as not done' : 'Mark as done',
                          constraints: const BoxConstraints(minWidth: 36, minHeight: 36),
                          padding: EdgeInsets.zero,
                          iconSize: 22,
                          icon: Icon(
                            item.isDone ? Icons.check_circle : Icons.circle_outlined,
                            color: item.isDone ? cs.primary : cs.onSurfaceVariant,
                          ),
                          onPressed: () => onToggle(!item.isDone),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                    Text(
                      item.name,
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                            fontWeight: FontWeight.w700,
                            decoration: item.isDone ? TextDecoration.lineThrough : null,
                          ),
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
                      '${copy.utangQty}: ${item.qty.toStringAsFixed(2)} ${item.unitType}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.primary),
                    ),
                    if (item.plannedDate != null)
                      Text(
                        formatLongDate(item.plannedDate!),
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ],
                  ),
                ),
              ),
            Padding(
              padding: const EdgeInsets.only(right: 2, bottom: 4),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  IconButton(
                    icon: const Icon(Icons.edit_outlined, size: 20),
                    onPressed: onEdit,
                    visualDensity: VisualDensity.compact,
                    tooltip: copy.inventoryEdit,
                  ),
                  IconButton(
                    icon: Icon(Icons.delete_outline, size: 20, color: cs.error),
                    visualDensity: VisualDensity.compact,
                    tooltip: copy.inventoryDelete,
                    onPressed: () async {
                      final confirmed = await onConfirmDelete();
                      if (confirmed == true) onDelete();
                    },
                  ),
                ],
              ),
            ),
          ],
        ),
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
            fontSize: 38,
            fontWeight: FontWeight.w800,
            color: Colors.white.withValues(alpha: 0.9),
          ),
        ),
      ),
    );
  }
}
