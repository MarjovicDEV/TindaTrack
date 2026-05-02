import 'package:drift/drift.dart';

import '../../../data/local/app_database.dart';
import '../domain/history_item.dart';

class HistoryRepository {
  HistoryRepository(this._db);

  final AppDatabase _db;

  Future<List<HistoryItem>> recent({int perSource = 80, int limit = 100}) async {
    final sales = await (_db.select(_db.sales)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(perSource))
        .get();

    final expenses = await (_db.select(_db.expenses)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(perSource))
        .get();

    final utangRows = await (_db.select(_db.utangEntries)
          ..where((t) => t.deletedAt.isNull())
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)])
          ..limit(perSource))
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
    if (items.length > limit) {
      return items.sublist(0, limit);
    }
    return items;
  }
}
