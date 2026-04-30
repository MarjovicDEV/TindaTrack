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
