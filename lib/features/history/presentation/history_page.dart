import 'package:flutter/material.dart';

import '../../../core/resources/app_copy.dart';
import '../../../core/utils/formatters.dart';
import '../../../data/repositories/tinda_repository.dart';
import '../data/history_repository.dart';
import '../domain/history_item.dart';

class HistoryPage extends StatefulWidget {
  const HistoryPage({required this.repo, super.key});

  final TindaRepository repo;

  @override
  State<HistoryPage> createState() => _HistoryPageState();
}

class _HistoryPageState extends State<HistoryPage> {
  late final HistoryRepository _historyRepo;
  late Future<List<HistoryItem>> _future;
  DateTimeRange? _dateRange;

  @override
  void initState() {
    super.initState();
    _historyRepo = HistoryRepository(widget.repo.db);
    _future = _loadHistory();
  }

  Future<List<HistoryItem>> _loadHistory() {
    final r = _dateRange;
    if (r == null) return _historyRepo.recent();
    final from = DateTime(r.start.year, r.start.month, r.start.day);
    final to = DateTime(
      r.end.year,
      r.end.month,
      r.end.day,
      23,
      59,
      59,
      999,
    );
    return _historyRepo.recent(rangeFrom: from, rangeTo: to);
  }

  Future<void> _pickDateRange() async {
    final now = DateTime.now();
    final picked = await showDateRangePicker(
      context: context,
      firstDate: DateTime(now.year - 10),
      lastDate: DateTime(now.year + 2),
      initialDateRange: _dateRange,
    );
    if (picked == null || !mounted) return;
    setState(() {
      _dateRange = picked;
      _future = _loadHistory();
    });
  }

  void _clearDateRange() {
    setState(() {
      _dateRange = null;
      _future = _loadHistory();
    });
  }

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(copy.historyTitle, style: Theme.of(context).textTheme.titleLarge),
        const SizedBox(height: 8),
        if (_dateRange == null)
          SizedBox(
            width: double.infinity,
            child: OutlinedButton(
              onPressed: _pickDateRange,
              child: Row(
                children: [
                  const Icon(Icons.date_range_outlined, size: 20),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      copy.historyFilterByDate,
                      overflow: TextOverflow.ellipsis,
                      maxLines: 2,
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: InputChip(
                      label: Text(
                        '${formatDate(_dateRange!.start)} – ${formatDate(_dateRange!.end)}',
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                      onDeleted: _clearDateRange,
                      deleteButtonTooltipMessage: copy.historyClearDateFilter,
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.centerLeft,
                child: TextButton(
                  onPressed: _pickDateRange,
                  child: Text(
                    copy.historyFilterByDate,
                    overflow: TextOverflow.ellipsis,
                    maxLines: 2,
                  ),
                ),
              ),
            ],
          ),
        const SizedBox(height: 8),
        Expanded(
          child: FutureBuilder<List<HistoryItem>>(
            future: _future,
            builder: (context, snap) {
              if (snap.connectionState != ConnectionState.done) {
                return const Center(child: CircularProgressIndicator());
              }
              final rows = snap.data ?? const [];
              if (rows.isEmpty) {
                return Center(
                  child: Text(
                    _dateRange == null ? copy.historyEmpty : copy.historyEmptyInRange,
                  ),
                );
              }
              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _future = _loadHistory();
                  });
                  await _future;
                },
                child: ListView.separated(
                  itemCount: rows.length,
                  separatorBuilder: (_, _) => const Divider(height: 1),
                  itemBuilder: (context, i) {
                    final e = rows[i];
                    final icon = switch (e.kind) {
                      HistoryKind.sale => Icons.point_of_sale_outlined,
                      HistoryKind.expense => Icons.receipt_long_outlined,
                      HistoryKind.utang => Icons.people_outline,
                    };
                    return ListTile(
                      leading: Icon(icon),
                      title: Text(e.title),
                      subtitle: Text(
                        e.subtitle.isEmpty
                            ? formatPhilippineDateTime(e.createdAt)
                            : '${e.subtitle}\n${formatPhilippineDateTime(e.createdAt)}',
                      ),
                      trailing: e.amount != null
                          ? Text(formatCurrency(e.amount!))
                          : null,
                      isThreeLine: e.subtitle.isNotEmpty,
                    );
                  },
                ),
              );
            },
          ),
        ),
      ],
    );
  }
}
