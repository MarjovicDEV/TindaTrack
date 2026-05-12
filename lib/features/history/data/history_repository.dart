import 'package:drift/drift.dart';

import '../../../data/local/app_database.dart';
import '../domain/history_item.dart';

class HistoryRepository {
  HistoryRepository(this._db);

  final AppDatabase _db;

  Future<List<HistoryItem>> recent({
    int perSource = 80,
    int limit = 100,
    DateTime? rangeFrom,
    DateTime? rangeTo,
  }) async {
    final scoped = rangeFrom != null || rangeTo != null;
    final cap = scoped ? 500 : perSource;
    final maxOut = scoped ? 500 : limit;

    final from = rangeFrom ?? DateTime.fromMillisecondsSinceEpoch(0);
    final to = rangeTo ?? DateTime(2100);

    final sales = await (_db.select(_db.sales)
          ..where((t) {
            var w = t.deletedAt.isNull();
            if (scoped) w = w & t.createdAt.isBetweenValues(from, to);
            return w;
          })
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(cap))
        .get();

    final expenses = await (_db.select(_db.expenses)
          ..where((t) {
            var w = t.deletedAt.isNull();
            if (scoped) w = w & t.createdAt.isBetweenValues(from, to);
            return w;
          })
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(cap))
        .get();

    final utangRows = await (_db.select(_db.utangEntries)
          ..where((t) {
            var w = t.deletedAt.isNull();
            if (scoped) w = w & t.createdAt.isBetweenValues(from, to);
            return w;
          })
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(cap))
        .get();

    final customers = await _db.select(_db.customers).get();
    final customerNames = {for (final c in customers) c.id: c.name};

    final categories = await _db.select(_db.expenseCategories).get();
    final categoryNames = {for (final c in categories) c.id: c.name};

    final items = <HistoryItem>[];

    for (final s in sales) {
      items.add(
        HistoryItem(
          kind: HistoryKind.sale,
          title: 'Benta #${s.id}',
          subtitle: 'Kabuuan: ${s.totalAmount.toStringAsFixed(2)}',
          createdAt: s.createdAt,
          amount: s.totalAmount,
        ),
      );
    }

    for (final e in expenses) {
      final cat = categoryNames[e.categoryId] ?? '';
      items.add(
        HistoryItem(
          kind: HistoryKind.expense,
          title: e.expenseName,
          subtitle: cat.isEmpty ? e.reason : '$cat · ${e.reason}',
          createdAt: e.createdAt,
          amount: e.amount,
        ),
      );
    }

    for (final u in utangRows) {
      final name = customerNames[u.customerId] ?? 'Customer';
      final label = u.isPayment ? 'Bayad' : 'Utang';
      items.add(
        HistoryItem(
          kind: HistoryKind.utang,
          title: '$label · $name',
          subtitle: u.itemName ?? u.note ?? '',
          createdAt: u.createdAt,
          amount: u.amount,
        ),
      );
    }

    items.sort((a, b) => b.createdAt.compareTo(a.createdAt));
    if (items.length > maxOut) {
      return items.sublist(0, maxOut);
    }
    return items;
  }
}
