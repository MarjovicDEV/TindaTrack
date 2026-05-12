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

  @override
  void initState() {
    super.initState();
    _historyRepo = HistoryRepository(widget.repo.db);
    _future = _historyRepo.recent();
  }

  @override
  Widget build(BuildContext context) {
    final copy = AppCopy.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(copy.historyTitle, style: Theme.of(context).textTheme.titleLarge),
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
                return Center(child: Text(copy.historyEmpty));
              }
              return RefreshIndicator(
                onRefresh: () async {
                  setState(() {
                    _future = _historyRepo.recent();
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
