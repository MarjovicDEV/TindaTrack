import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  RealColumn get price => real()();
  IntColumn get stockQty => integer()();
  IntColumn get lowStockThreshold => integer().withDefault(const Constant(5))();
}

class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime()();
  RealColumn get totalAmount => real()();
}

class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(Sales, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  IntColumn get qty => integer()();
  RealColumn get unitPrice => real()();
}

class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
}

class UtangEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId => integer().references(Customers, #id)();
  RealColumn get amount => real()();
  BoolColumn get isPayment => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get note => text().nullable()();
}

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get category => text()();
  RealColumn get amount => real()();
  DateTimeColumn get createdAt => dateTime()();
  TextColumn get note => text().nullable()();
}

class GroceryItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  IntColumn get qty => integer().withDefault(const Constant(1))();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
}

@DriftDatabase(
  tables: [
    Products,
    Sales,
    SaleItems,
    Customers,
    UtangEntries,
    Expenses,
    GroceryItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());

  @override
  int get schemaVersion => 1;

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'tinda_track',
      native: const DriftNativeOptions(databaseDirectory: getApplicationDocumentsDirectory),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.dart.js'),
      ),
    );
  }

  Future<int> addProduct({
    required String name,
    required double price,
    required int stockQty,
    required int threshold,
  }) {
    return into(products).insert(
      ProductsCompanion.insert(
        name: name,
        price: price,
        stockQty: stockQty,
        lowStockThreshold: Value(threshold),
      ),
    );
  }

  Stream<List<Product>> watchProducts() => select(products).watch();

  Stream<List<Sale>> watchSales() =>
      (select(sales)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  Future<void> recordSale(List<SaleItemsCompanion> items) async {
    await transaction(() async {
      var total = 0.0;
      for (final i in items) {
        total += i.unitPrice.value * i.qty.value;
      }
      final saleId = await into(sales).insert(
        SalesCompanion.insert(createdAt: DateTime.now(), totalAmount: total),
      );
      for (final i in items) {
        await into(saleItems).insert(i.copyWith(saleId: Value(saleId)));
        final id = i.productId.value;
        await customStatement(
          'UPDATE products SET stock_qty = stock_qty - ? WHERE id = ?',
          [i.qty.value, id],
        );
      }
    });
  }

  Future<int> addCustomer(String name) {
    return into(customers).insert(CustomersCompanion.insert(name: name));
  }

  Stream<List<Customer>> watchCustomers() => select(customers).watch();

  Future<int> addUtang({
    required int customerId,
    required double amount,
    required bool isPayment,
    String? note,
  }) {
    return into(utangEntries).insert(
      UtangEntriesCompanion.insert(
        customerId: customerId,
        amount: amount,
        isPayment: Value(isPayment),
        createdAt: DateTime.now(),
        note: Value(note),
      ),
    );
  }

  Future<int> addExpense({
    required String category,
    required double amount,
    String? note,
  }) {
    return into(expenses).insert(
      ExpensesCompanion.insert(
        category: category,
        amount: amount,
        createdAt: DateTime.now(),
        note: Value(note),
      ),
    );
  }

  Stream<List<Expense>> watchExpenses() =>
      (select(expenses)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  Stream<List<GroceryItem>> watchGroceryItems() => select(groceryItems).watch();

  Future<int> addGroceryItem(String name, {int qty = 1}) {
    return into(groceryItems).insert(
      GroceryItemsCompanion.insert(name: name, qty: Value(qty)),
    );
  }

  Future<void> toggleGrocery(int id, bool done) {
    return (update(groceryItems)..where((t) => t.id.equals(id))).write(
      GroceryItemsCompanion(isDone: Value(done)),
    );
  }

  Stream<double> watchTotalSales() {
    final q = customSelect('SELECT COALESCE(SUM(total_amount), 0) as total FROM sales');
    return q.watchSingle().map((row) => row.read<double>('total'));
  }

  Stream<double> watchTotalExpenses() {
    final q = customSelect('SELECT COALESCE(SUM(amount), 0) as total FROM expenses');
    return q.watchSingle().map((row) => row.read<double>('total'));
  }

  Stream<int> watchLowStockCount() {
    final q = customSelect(
      'SELECT COUNT(*) as total FROM products WHERE stock_qty <= low_stock_threshold',
    );
    return q.watchSingle().map((row) => row.read<int>('total'));
  }

  Stream<List<Sale>> watchSalesInRange(DateTime from, DateTime to) {
    return (select(sales)
          ..where((t) => t.createdAt.isBetweenValues(from, to))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Stream<List<Expense>> watchExpensesInRange(DateTime from, DateTime to) {
    return (select(expenses)
          ..where((t) => t.createdAt.isBetweenValues(from, to))
          ..orderBy([(t) => OrderingTerm.asc(t.createdAt)]))
        .watch();
  }

  Future<Map<String, dynamic>> exportJsonBackup() async {
    final payload = <String, dynamic>{
      'meta': {
        'schemaVersion': schemaVersion,
        'exportedAt': DateTime.now().toIso8601String(),
      },
      'products': (await select(products).get()).map((e) => e.toJson()).toList(),
      'sales': (await select(sales).get()).map((e) => e.toJson()).toList(),
      'saleItems': (await select(saleItems).get()).map((e) => e.toJson()).toList(),
      'customers': (await select(customers).get()).map((e) => e.toJson()).toList(),
      'utangEntries': (await select(utangEntries).get()).map((e) => e.toJson()).toList(),
      'expenses': (await select(expenses).get()).map((e) => e.toJson()).toList(),
      'groceryItems': (await select(groceryItems).get()).map((e) => e.toJson()).toList(),
    };
    return payload;
  }

  Future<Map<String, int>> previewJsonBackup(Map<String, dynamic> payload) async {
    return {
      'products': (payload['products'] as List<dynamic>? ?? const []).length,
      'sales': (payload['sales'] as List<dynamic>? ?? const []).length,
      'customers': (payload['customers'] as List<dynamic>? ?? const []).length,
      'expenses': (payload['expenses'] as List<dynamic>? ?? const []).length,
      'groceryItems': (payload['groceryItems'] as List<dynamic>? ?? const []).length,
    };
  }

  Future<void> importJsonBackup(
    Map<String, dynamic> payload, {
    required bool replaceAll,
  }) async {
    await transaction(() async {
      if (replaceAll) {
        await delete(groceryItems).go();
        await delete(utangEntries).go();
        await delete(saleItems).go();
        await delete(expenses).go();
        await delete(sales).go();
        await delete(customers).go();
        await delete(products).go();
      }

      Future<void> safeInsert<T extends Table, D>(
        TableInfo<T, D> table,
        Insertable<D> row,
      ) async {
        await into(table).insert(row, mode: InsertMode.insertOrIgnore);
      }

      for (final row in (payload['products'] as List<dynamic>? ?? const [])) {
        final data = row as Map<String, dynamic>;
        await safeInsert(
          products,
          ProductsCompanion(
            id: Value(data['id'] as int),
            name: Value(data['name'] as String),
            price: Value((data['price'] as num).toDouble()),
            stockQty: Value(data['stock_qty'] as int),
            lowStockThreshold: Value(data['low_stock_threshold'] as int),
          ),
        );
      }
      for (final row in (payload['sales'] as List<dynamic>? ?? const [])) {
        final data = row as Map<String, dynamic>;
        await safeInsert(
          sales,
          SalesCompanion(
            id: Value(data['id'] as int),
            createdAt: Value(DateTime.parse(data['created_at'] as String)),
            totalAmount: Value((data['total_amount'] as num).toDouble()),
          ),
        );
      }
      for (final row in (payload['saleItems'] as List<dynamic>? ?? const [])) {
        final data = row as Map<String, dynamic>;
        await safeInsert(
          saleItems,
          SaleItemsCompanion(
            id: Value(data['id'] as int),
            saleId: Value(data['sale_id'] as int),
            productId: Value(data['product_id'] as int),
            qty: Value(data['qty'] as int),
            unitPrice: Value((data['unit_price'] as num).toDouble()),
          ),
        );
      }
      for (final row in (payload['customers'] as List<dynamic>? ?? const [])) {
        final data = row as Map<String, dynamic>;
        await safeInsert(
          customers,
          CustomersCompanion(
            id: Value(data['id'] as int),
            name: Value(data['name'] as String),
          ),
        );
      }
      for (final row in (payload['utangEntries'] as List<dynamic>? ?? const [])) {
        final data = row as Map<String, dynamic>;
        await safeInsert(
          utangEntries,
          UtangEntriesCompanion(
            id: Value(data['id'] as int),
            customerId: Value(data['customer_id'] as int),
            amount: Value((data['amount'] as num).toDouble()),
            isPayment: Value(data['is_payment'] as bool),
            createdAt: Value(DateTime.parse(data['created_at'] as String)),
            note: Value(data['note'] as String?),
          ),
        );
      }
      for (final row in (payload['expenses'] as List<dynamic>? ?? const [])) {
        final data = row as Map<String, dynamic>;
        await safeInsert(
          expenses,
          ExpensesCompanion(
            id: Value(data['id'] as int),
            category: Value(data['category'] as String),
            amount: Value((data['amount'] as num).toDouble()),
            createdAt: Value(DateTime.parse(data['created_at'] as String)),
            note: Value(data['note'] as String?),
          ),
        );
      }
      for (final row in (payload['groceryItems'] as List<dynamic>? ?? const [])) {
        final data = row as Map<String, dynamic>;
        await safeInsert(
          groceryItems,
          GroceryItemsCompanion(
            id: Value(data['id'] as int),
            name: Value(data['name'] as String),
            qty: Value(data['qty'] as int),
            isDone: Value(data['is_done'] as bool),
          ),
        );
      }
    });
  }

  Future<List<int>> exportSimpleSnapshot() async {
    final productCount =
        await customSelect('SELECT COUNT(*) AS c FROM products').getSingle();
    final salesCount = await customSelect('SELECT COUNT(*) AS c FROM sales').getSingle();
    final customerCount =
        await customSelect('SELECT COUNT(*) AS c FROM customers').getSingle();
    return [
      productCount.read<int>('c'),
      salesCount.read<int>('c'),
      customerCount.read<int>('c'),
    ];
  }
}
