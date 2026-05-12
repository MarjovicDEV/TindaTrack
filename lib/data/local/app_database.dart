import 'package:drift/drift.dart';
import 'package:drift_flutter/drift_flutter.dart';
import 'package:path_provider/path_provider.dart';

part 'app_database.g.dart';

class Products extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  TextColumn get brandName => text().withDefault(const Constant(''))();
  RealColumn get price => real()();
  RealColumn get stockQty => real()();
  RealColumn get lowStockThreshold => real().withDefault(const Constant(5))();
  RealColumn get weight => real().withDefault(const Constant(1))();
  TextColumn get netWeightUnit => text().withDefault(const Constant('g'))();
  TextColumn get unitType => text().withDefault(const Constant('pcs'))();
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class Sales extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get createdAt => dateTime()();
  RealColumn get totalAmount => real()();
  IntColumn get customerId => integer().nullable().references(Customers, #id)();
  /// When set, this [Sale] mirrors an [UtangEntries] payment row (cash collected on account).
  IntColumn get sourceUtangEntryId => integer().nullable().references(
        UtangEntries,
        #id,
        onDelete: KeyAction.cascade,
      )();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class SaleItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get saleId => integer().references(Sales, #id)();
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get qty => real()();
  RealColumn get unitPrice => real()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class Customers extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class UtangEntries extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get customerId => integer().references(Customers, #id)();
  RealColumn get amount => real()();
  BoolColumn get isPayment => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get dueDate => dateTime().nullable()();
  TextColumn get itemName => text().nullable()();
  TextColumn get note => text().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class UtangEntryItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get utangEntryId =>
      integer().references(UtangEntries, #id, onDelete: KeyAction.cascade)();
  IntColumn get productId => integer().references(Products, #id)();
  RealColumn get qty => real()();
  RealColumn get unitPrice => real()();
  RealColumn get lineTotal => real()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class ExpenseCategories extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class UnitMeasurements extends Table {
  IntColumn get id => integer().autoIncrement()();
  TextColumn get name => text().unique()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class Expenses extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get categoryId => integer().references(ExpenseCategories, #id)();
  TextColumn get expenseName => text()();
  TextColumn get reason => text()();
  RealColumn get amount => real()();
  DateTimeColumn get createdAt => dateTime()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class GroceryItems extends Table {
  IntColumn get id => integer().autoIncrement()();
  IntColumn get groceryListId => integer().nullable().references(
    GroceryLists,
    #id,
    onDelete: KeyAction.setNull,
  )();
  TextColumn get name => text()();
  TextColumn get brandName => text().withDefault(const Constant(''))();
  RealColumn get netWeight => real().withDefault(const Constant(1))();
  TextColumn get netWeightUnit => text().withDefault(const Constant('g'))();
  RealColumn get qty => real().withDefault(const Constant(1))();
  TextColumn get unitType => text().withDefault(const Constant('pcs'))();
  TextColumn get imagePath => text().nullable()();
  DateTimeColumn get plannedDate => dateTime().nullable()();
  BoolColumn get isDone => boolean().withDefault(const Constant(false))();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class GroceryLists extends Table {
  IntColumn get id => integer().autoIncrement()();
  DateTimeColumn get startAt => dateTime()();
  TextColumn get mallName => text()();
  DateTimeColumn get createdAt => dateTime().nullable()();
  DateTimeColumn get deletedAt => dateTime().nullable()();
}

class ExpenseWithCategory {
  ExpenseWithCategory({required this.expense, required this.categoryName});

  final Expense expense;
  final String categoryName;
}

class CustomerBalance {
  CustomerBalance({
    required this.customerId,
    required this.name,
    required this.balance,
  });

  final int customerId;
  final String name;
  final double balance;
}

class UtangLineInput {
  UtangLineInput({required this.productId, required this.qty});

  final int productId;
  final double qty;
}

class UtangEntryItemDetail {
  UtangEntryItemDetail({
    required this.productName,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
    required this.unitType,
  });

  final String productName;
  final double qty;
  final double unitPrice;
  final double lineTotal;
  final String unitType;
}

class SaleReceiptLine {
  SaleReceiptLine({
    required this.productName,
    required this.qty,
    required this.unitPrice,
    required this.lineTotal,
    required this.unitType,
  });

  final String productName;
  final double qty;
  final double unitPrice;
  final double lineTotal;
  final String unitType;
}

class SaleReceiptDetail {
  SaleReceiptDetail({
    required this.sale,
    required this.customerName,
    required this.lines,
  });

  final Sale sale;
  final String customerName;
  final List<SaleReceiptLine> lines;
}

class UtangReceiptDetail {
  UtangReceiptDetail({
    required this.entry,
    required this.customerName,
    required this.lines,
  });

  final UtangEntry entry;
  final String customerName;
  final List<UtangEntryItemDetail> lines;
}

@DriftDatabase(
  tables: [
    Products,
    Sales,
    SaleItems,
    Customers,
    UtangEntries,
    UtangEntryItems,
    ExpenseCategories,
    UnitMeasurements,
    Expenses,
    GroceryLists,
    GroceryItems,
  ],
)
class AppDatabase extends _$AppDatabase {
  AppDatabase() : super(_openConnection());
  AppDatabase.test(QueryExecutor executor) : super(executor);

  static const List<String> _defaultExpenseCategories = [
    'Pagkain',
    'Transportasyon',
    'Kuryente',
    'Tubig',
    'Internet',
    'Upa',
    'Sahod',
    'Iba pa',
  ];

  static const List<String> _defaultUnitMeasurements = ['kg', 'meters', 'pcs'];

  @override
  int get schemaVersion => 13;

  @override
  MigrationStrategy get migration => MigrationStrategy(
    onCreate: (m) => m.createAll(),
    onUpgrade: (m, from, to) async {
      if (from < 2) {
        await customStatement(
          'ALTER TABLE products ADD COLUMN weight REAL NOT NULL DEFAULT 1',
        );
        await customStatement(
          "ALTER TABLE products ADD COLUMN unit_type TEXT NOT NULL DEFAULT 'pcs'",
        );
        await customStatement(
          'ALTER TABLE products ADD COLUMN stock_qty_tmp REAL',
        );
        await customStatement('UPDATE products SET stock_qty_tmp = stock_qty');
        await customStatement(
          'ALTER TABLE products ADD COLUMN low_stock_threshold_tmp REAL',
        );
        await customStatement(
          'UPDATE products SET low_stock_threshold_tmp = low_stock_threshold',
        );
        await customStatement(
          'ALTER TABLE utang_entries ADD COLUMN item_name TEXT',
        );
        await m.createTable(expenseCategories);
        await customStatement(
          'ALTER TABLE expenses ADD COLUMN category_id INTEGER REFERENCES expense_categories(id)',
        );
        await customStatement(
          "ALTER TABLE expenses ADD COLUMN expense_name TEXT NOT NULL DEFAULT ''",
        );
        await customStatement(
          "ALTER TABLE expenses ADD COLUMN reason TEXT NOT NULL DEFAULT ''",
        );
        await customStatement(
          'ALTER TABLE grocery_items ADD COLUMN unit_type TEXT NOT NULL DEFAULT \'pcs\'',
        );
        await customStatement(
          'ALTER TABLE grocery_items ADD COLUMN planned_date INTEGER',
        );
      }
      if (from < 3) {
        await m.createTable(utangEntryItems);
      }
      if (from < 4) {
        await customStatement(
          'ALTER TABLE utang_entries ADD COLUMN due_date INTEGER',
        );
      }
      if (from < 5) {
        await customStatement(
          'ALTER TABLE products ADD COLUMN created_at INTEGER',
        );
        await customStatement(
          'ALTER TABLE products ADD COLUMN deleted_at INTEGER',
        );
        await customStatement(
          'ALTER TABLE sales ADD COLUMN deleted_at INTEGER',
        );
        await customStatement(
          'ALTER TABLE sale_items ADD COLUMN created_at INTEGER',
        );
        await customStatement(
          'ALTER TABLE sale_items ADD COLUMN deleted_at INTEGER',
        );
        await customStatement(
          'ALTER TABLE customers ADD COLUMN created_at INTEGER',
        );
        await customStatement(
          'ALTER TABLE customers ADD COLUMN deleted_at INTEGER',
        );
        await customStatement(
          'ALTER TABLE utang_entries ADD COLUMN deleted_at INTEGER',
        );
        await customStatement(
          'ALTER TABLE utang_entry_items ADD COLUMN created_at INTEGER',
        );
        await customStatement(
          'ALTER TABLE utang_entry_items ADD COLUMN deleted_at INTEGER',
        );
        await customStatement(
          'ALTER TABLE expense_categories ADD COLUMN created_at INTEGER',
        );
        await customStatement(
          'ALTER TABLE expense_categories ADD COLUMN deleted_at INTEGER',
        );
        await customStatement(
          'ALTER TABLE expenses ADD COLUMN deleted_at INTEGER',
        );
        await customStatement(
          'ALTER TABLE grocery_items ADD COLUMN created_at INTEGER',
        );
        await customStatement(
          'ALTER TABLE grocery_items ADD COLUMN deleted_at INTEGER',
        );
      }
      if (from < 6) {
        await m.createTable(unitMeasurements);
      }
      if (from < 7) {
        await customStatement(
          "ALTER TABLE products ADD COLUMN brand_name TEXT NOT NULL DEFAULT ''",
        );
        await customStatement(
          "ALTER TABLE grocery_items ADD COLUMN brand_name TEXT NOT NULL DEFAULT ''",
        );
        await customStatement(
          'ALTER TABLE grocery_items ADD COLUMN net_weight REAL NOT NULL DEFAULT 1',
        );
      }
      if (from < 8) {
        await customStatement(
          "ALTER TABLE products ADD COLUMN net_weight_unit TEXT NOT NULL DEFAULT 'g'",
        );
        await customStatement(
          "ALTER TABLE grocery_items ADD COLUMN net_weight_unit TEXT NOT NULL DEFAULT 'g'",
        );
      }
      if (from < 9) {
        await customStatement(
          'ALTER TABLE products ADD COLUMN image_path TEXT',
        );
        await customStatement(
          'ALTER TABLE grocery_items ADD COLUMN image_path TEXT',
        );
      }
      if (from < 10) {
        await m.createTable(groceryLists);
        await customStatement(
          'ALTER TABLE grocery_items ADD COLUMN grocery_list_id INTEGER',
        );
      }
      if (from < 11) {
        await customStatement(
          'ALTER TABLE sales ADD COLUMN customer_id INTEGER',
        );
      }
      if (from < 12) {
        await customStatement(
          'ALTER TABLE sales ADD COLUMN source_utang_entry_id INTEGER '
          'REFERENCES utang_entries (id) ON DELETE CASCADE',
        );
        await customStatement(
          "INSERT INTO sales (created_at, total_amount, customer_id, source_utang_entry_id, deleted_at) "
          "SELECT u.created_at, u.amount, u.customer_id, u.id, NULL "
          'FROM utang_entries u '
          "WHERE u.is_payment = 1 AND u.deleted_at IS NULL "
          'AND NOT EXISTS ('
          '  SELECT 1 FROM sales s WHERE s.source_utang_entry_id = u.id'
          ')',
        );
      }
      if (from < 13) {
        await customStatement(
          "DELETE FROM sales WHERE id NOT IN ("
          "SELECT MIN(id) FROM sales "
          "WHERE source_utang_entry_id IS NOT NULL "
          "GROUP BY source_utang_entry_id"
          ") AND source_utang_entry_id IS NOT NULL",
        );
        await customStatement(
          'CREATE UNIQUE INDEX IF NOT EXISTS sales_source_utang_entry_id_uidx '
          'ON sales (source_utang_entry_id) '
          'WHERE source_utang_entry_id IS NOT NULL',
        );
      }
    },
    beforeOpen: (details) async {
      final hasDueDate = await customSelect(
        "SELECT 1 FROM pragma_table_info('utang_entries') WHERE name='due_date'",
      ).getSingleOrNull();
      if (hasDueDate == null) {
        await customStatement(
          'ALTER TABLE utang_entries ADD COLUMN due_date INTEGER',
        );
      }
      final hasUnitMeasurementsTable = await customSelect(
        "SELECT 1 FROM sqlite_master WHERE type='table' AND name='unit_measurements'",
      ).getSingleOrNull();
      if (hasUnitMeasurementsTable == null) {
        await customStatement(
          'CREATE TABLE IF NOT EXISTS unit_measurements ('
          'id INTEGER NOT NULL PRIMARY KEY AUTOINCREMENT, '
          'name TEXT NOT NULL UNIQUE, '
          'created_at INTEGER NULL, '
          'deleted_at INTEGER NULL'
          ')',
        );
      }
      await _seedDefaultExpenseCategories();
      await _seedDefaultUnitMeasurements();
    },
  );

  static QueryExecutor _openConnection() {
    return driftDatabase(
      name: 'tinda_track',
      native: const DriftNativeOptions(
        databaseDirectory: getApplicationDocumentsDirectory,
      ),
      web: DriftWebOptions(
        sqlite3Wasm: Uri.parse('sqlite3.wasm'),
        driftWorker: Uri.parse('drift_worker.dart.js'),
      ),
    );
  }

  Future<int> addProduct({
    required String name,
    required String brandName,
    required double price,
    required double stockQty,
    required double threshold,
    required double weight,
    required String netWeightUnit,
    required String unitType,
    String? imagePath,
  }) {
    return into(products).insert(
      ProductsCompanion.insert(
        name: name,
        brandName: Value(brandName),
        price: price,
        stockQty: stockQty,
        lowStockThreshold: Value(threshold),
        weight: Value(weight),
        netWeightUnit: Value(netWeightUnit),
        unitType: Value(unitType),
        imagePath: Value(imagePath),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateProduct({
    required int id,
    required String name,
    required String brandName,
    required double price,
    required double stockQty,
    required double threshold,
    required double weight,
    required String netWeightUnit,
    required String unitType,
    String? imagePath,
  }) {
    return (update(products)..where((t) => t.id.equals(id))).write(
      ProductsCompanion(
        name: Value(name),
        brandName: Value(brandName),
        price: Value(price),
        stockQty: Value(stockQty),
        lowStockThreshold: Value(threshold),
        weight: Value(weight),
        netWeightUnit: Value(netWeightUnit),
        unitType: Value(unitType),
        imagePath: Value(imagePath),
      ),
    );
  }

  Future<void> deleteProduct(int id) {
    return transaction(() async {
      final linkedSaleItem = await (select(
        saleItems,
      )..where((s) => s.productId.equals(id))).getSingleOrNull();
      if (linkedSaleItem != null) {
        throw Exception(
          'Hindi puwedeng burahin: may Benta record na gumagamit ng produktong ito.',
        );
      }
      await (delete(products)..where((t) => t.id.equals(id))).go();
    });
  }

  Stream<List<Product>> watchProducts() => select(products).watch();

  Stream<List<Sale>> watchSales() =>
      (select(sales)..orderBy([(t) => OrderingTerm.desc(t.createdAt)])).watch();

  Future<int> createSale({
    required int productId,
    required double quantity,
    required int customerId,
  }) async {
    return transaction(() async {
      final product = await (select(
        products,
      )..where((p) => p.id.equals(productId))).getSingle();
      if (quantity <= 0) {
        throw Exception('Invalid quantity.');
      }
      if (quantity > product.stockQty) {
        throw Exception('Insufficient stock.');
      }

      final total = quantity * product.price;
      final saleId = await into(sales).insert(
        SalesCompanion.insert(
          createdAt: DateTime.now(),
          totalAmount: total,
          customerId: Value(customerId),
        ),
      );
      await into(saleItems).insert(
        SaleItemsCompanion.insert(
          saleId: saleId,
          productId: productId,
          qty: quantity,
          unitPrice: product.price,
        ),
      );
      await customStatement(
        'UPDATE products SET stock_qty = stock_qty - ? WHERE id = ?',
        [quantity, productId],
      );
      return saleId;
    });
  }

  Future<void> updateSale({
    required int saleId,
    required int productId,
    required double quantity,
    required int customerId,
  }) async {
    await transaction(() async {
      final existingItems = await (select(
        saleItems,
      )..where((i) => i.saleId.equals(saleId))).get();
      for (final item in existingItems) {
        await customStatement(
          'UPDATE products SET stock_qty = stock_qty + ? WHERE id = ?',
          [item.qty, item.productId],
        );
      }

      final product = await (select(
        products,
      )..where((p) => p.id.equals(productId))).getSingle();
      if (quantity <= 0 || quantity > product.stockQty) {
        throw Exception('Invalid quantity or insufficient stock.');
      }

      final total = quantity * product.price;
      await (update(sales)..where((s) => s.id.equals(saleId))).write(
        SalesCompanion(
          totalAmount: Value(total),
          customerId: Value(customerId),
        ),
      );
      await (delete(saleItems)..where((i) => i.saleId.equals(saleId))).go();
      await into(saleItems).insert(
        SaleItemsCompanion.insert(
          saleId: saleId,
          productId: productId,
          qty: quantity,
          unitPrice: product.price,
        ),
      );
      await customStatement(
        'UPDATE products SET stock_qty = stock_qty - ? WHERE id = ?',
        [quantity, productId],
      );
    });
  }

  Future<void> deleteSaleAndRestoreStock(int saleId) async {
    await transaction(() async {
      final sale = await (select(sales)..where((s) => s.id.equals(saleId)))
          .getSingleOrNull();
      if (sale == null) return;

      if (sale.sourceUtangEntryId != null) {
        await (delete(utangEntries)
              ..where((u) => u.id.equals(sale.sourceUtangEntryId!)))
            .go();
        return;
      }

      final items = await (select(
        saleItems,
      )..where((i) => i.saleId.equals(saleId))).get();
      for (final item in items) {
        await customStatement(
          'UPDATE products SET stock_qty = stock_qty + ? WHERE id = ?',
          [item.qty, item.productId],
        );
      }
      await (delete(saleItems)..where((i) => i.saleId.equals(saleId))).go();
      await (delete(sales)..where((s) => s.id.equals(saleId))).go();
    });
  }

  Future<List<SaleItem>> getSaleItems(int saleId) {
    return (select(saleItems)..where((i) => i.saleId.equals(saleId))).get();
  }

  Future<SaleReceiptDetail> getSaleReceipt(int saleId) async {
    final sale = await (select(sales)
          ..where((s) => s.id.equals(saleId)))
        .getSingle();
    final customer = sale.customerId == null
        ? null
        : await (select(customers)
              ..where((c) => c.id.equals(sale.customerId!)))
            .getSingleOrNull();

    if (sale.sourceUtangEntryId != null) {
      return SaleReceiptDetail(
        sale: sale,
        customerName: customer?.name ?? 'Unknown customer',
        lines: [
          SaleReceiptLine(
            productName: 'Bayad sa utang (account payment)',
            qty: 1,
            unitPrice: sale.totalAmount,
            lineTotal: sale.totalAmount,
            unitType: 'pcs',
          ),
        ],
      );
    }

    final q = select(saleItems).join([
      leftOuterJoin(products, products.id.equalsExp(saleItems.productId)),
    ])..where(saleItems.saleId.equals(saleId));
    final rows = await q.get();
    final lines = rows
        .map(
          (row) {
            final item = row.readTable(saleItems);
            final product = row.readTableOrNull(products);
            return SaleReceiptLine(
              productName: product?.name ?? 'N/A',
              qty: item.qty,
              unitPrice: item.unitPrice,
              lineTotal: item.qty * item.unitPrice,
              unitType: product?.unitType ?? 'pcs',
            );
          },
        )
        .toList();
    return SaleReceiptDetail(
      sale: sale,
      customerName: customer?.name ?? 'Unknown customer',
      lines: lines,
    );
  }

  Future<int> addCustomer(String name) {
    return into(customers).insert(
      CustomersCompanion.insert(name: name, createdAt: Value(DateTime.now())),
    );
  }

  Future<void> updateCustomer(int id, String name) {
    return (update(customers)..where((c) => c.id.equals(id))).write(
      CustomersCompanion(name: Value(name)),
    );
  }

  Future<void> deleteCustomer(int id) async {
    await transaction(() async {
      final entries =
          await (select(utangEntries)..where(
                (u) => u.customerId.equals(id) & u.isPayment.equals(false),
              ))
              .get();

      for (final entry in entries) {
        final lines = await (select(
          utangEntryItems,
        )..where((i) => i.utangEntryId.equals(entry.id))).get();
        for (final line in lines) {
          await customStatement(
            'UPDATE products SET stock_qty = stock_qty + ? WHERE id = ?',
            [line.qty, line.productId],
          );
        }
      }

      await (delete(customers)..where((c) => c.id.equals(id))).go();
    });
  }

  Stream<List<Customer>> watchCustomers() => select(customers).watch();

  Stream<List<CustomerBalance>> watchCustomerBalances() {
    final q = customSelect(
      '''
      SELECT c.id as customer_id, c.name as name,
      COALESCE(SUM(CASE WHEN u.is_payment = 1 THEN -u.amount ELSE u.amount END), 0) as balance
      FROM customers c
      LEFT JOIN utang_entries u ON u.customer_id = c.id
      GROUP BY c.id, c.name
      ORDER BY c.name ASC
      ''',
      readsFrom: {customers, utangEntries},
    );
    return q.watch().map(
      (rows) => rows
          .map(
            (r) => CustomerBalance(
              customerId: r.read<int>('customer_id'),
              name: r.read<String>('name'),
              balance: r.read<double>('balance'),
            ),
          )
          .toList(),
    );
  }

  Future<int> addUtang({
    required int customerId,
    required double amount,
    required bool isPayment,
    DateTime? dueDate,
    String? itemName,
    String? note,
  }) async {
    if (!isPayment && dueDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final selected = DateTime(dueDate.year, dueDate.month, dueDate.day);
      if (selected.isBefore(today)) {
        throw Exception('Due date dapat today o future lang.');
      }
    }
    if (amount <= 0) {
      throw Exception('Amount dapat mas mataas sa zero.');
    }

    if (isPayment) {
      return transaction(() async {
        final now = DateTime.now();
        final entryId = await into(utangEntries).insert(
          UtangEntriesCompanion.insert(
            customerId: customerId,
            amount: amount,
            isPayment: const Value(true),
            createdAt: now,
            dueDate: const Value.absent(),
            itemName: Value(itemName),
            note: Value(note),
          ),
        );
        await into(sales).insert(
          SalesCompanion.insert(
            createdAt: now,
            totalAmount: amount,
            customerId: Value(customerId),
            sourceUtangEntryId: Value(entryId),
          ),
        );
        return entryId;
      });
    }

    return into(utangEntries).insert(
      UtangEntriesCompanion.insert(
        customerId: customerId,
        amount: amount,
        isPayment: Value(isPayment),
        createdAt: DateTime.now(),
        dueDate: Value(dueDate),
        itemName: Value(itemName),
        note: Value(note),
      ),
    );
  }

  Future<int> addUtangWithItems({
    required int customerId,
    required List<UtangLineInput> lines,
    DateTime? dueDate,
    String? note,
  }) async {
    if (lines.isEmpty) {
      throw Exception('Pumili ng kahit isang item.');
    }

    return transaction(() async {
      if (dueDate != null) {
        final now = DateTime.now();
        final today = DateTime(now.year, now.month, now.day);
        final selected = DateTime(dueDate.year, dueDate.month, dueDate.day);
        if (selected.isBefore(today)) {
          throw Exception('Due date dapat today o future lang.');
        }
      }
      final ids = lines.map((e) => e.productId).toSet().toList();
      final dbProducts = await (select(
        products,
      )..where((p) => p.id.isIn(ids))).get();
      if (dbProducts.length != ids.length) {
        throw Exception('May napiling produktong hindi nahanap.');
      }

      final productById = {for (final p in dbProducts) p.id: p};
      final lineRows = <UtangEntryItemsCompanion>[];
      final summaryParts = <String>[];
      var total = 0.0;

      for (final line in lines) {
        final product = productById[line.productId];
        if (product == null) throw Exception('Invalid product.');

        if (line.qty <= 0) throw Exception('Invalid qty.');
        if (product.unitType == 'pcs') {
          if (line.qty % 1 != 0) {
            throw Exception('Whole numbers lang para sa pcs.');
          }
        }
        if (line.qty > product.stockQty) {
          throw Exception('Kulang stock para sa ${product.name}.');
        }

        final lineTotal = line.qty * product.price;
        total += lineTotal;
        final qtyLabel = product.unitType == 'pcs'
            ? line.qty.toInt().toString()
            : line.qty.toStringAsFixed(2);
        summaryParts.add('${product.name} x$qtyLabel ${product.unitType}');
        lineRows.add(
          UtangEntryItemsCompanion.insert(
            utangEntryId: -1,
            productId: line.productId,
            qty: line.qty,
            unitPrice: product.price,
            lineTotal: lineTotal,
            createdAt: Value(DateTime.now()),
          ),
        );
      }

      if (total <= 0) throw Exception('Amount dapat mas mataas sa zero.');

      final entryId = await into(utangEntries).insert(
        UtangEntriesCompanion.insert(
          customerId: customerId,
          amount: total,
          isPayment: const Value(false),
          createdAt: DateTime.now(),
          dueDate: Value(dueDate),
          itemName: Value(summaryParts.join(', ')),
          note: Value(note),
        ),
      );

      for (final row in lineRows) {
        await into(
          utangEntryItems,
        ).insert(row.copyWith(utangEntryId: Value(entryId)));
      }

      for (final line in lines) {
        await customStatement(
          'UPDATE products SET stock_qty = stock_qty - ? WHERE id = ?',
          [line.qty, line.productId],
        );
      }

      return entryId;
    });
  }

  Stream<List<UtangEntry>> watchUtangEntriesByCustomer(int customerId) {
    return (select(utangEntries)
          ..where((u) => u.customerId.equals(customerId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Future<void> updateUtangEntry({
    required int entryId,
    required double amount,
    required bool isPayment,
    DateTime? dueDate,
    String? itemName,
    String? note,
  }) async {
    if (!isPayment && dueDate != null) {
      final now = DateTime.now();
      final today = DateTime(now.year, now.month, now.day);
      final selected = DateTime(dueDate.year, dueDate.month, dueDate.day);
      if (selected.isBefore(today)) {
        throw Exception('Due date dapat today o future lang.');
      }
    }
    if (amount <= 0) {
      throw Exception('Amount dapat mas mataas sa zero.');
    }

    await transaction(() async {
      final prev = await (select(utangEntries)
            ..where((u) => u.id.equals(entryId)))
          .getSingleOrNull();
      if (prev == null) return;

      if (prev.isPayment != isPayment) {
        throw StateError(
          'Hindi puwedeng palitan ang Utang papuntang Bayad (o baligtad) sa edit. '
          'Magdagdag ng hiwalay na entry para sa bayad.',
        );
      }

      await (update(utangEntries)..where((u) => u.id.equals(entryId))).write(
        UtangEntriesCompanion(
          amount: Value(amount),
          isPayment: Value(isPayment),
          dueDate: Value(isPayment ? null : dueDate),
          itemName: Value(itemName),
          note: Value(note),
        ),
      );

      if (isPayment) {
        final linked = await (select(sales)
              ..where((s) => s.sourceUtangEntryId.equals(entryId))
              ..orderBy([(s) => OrderingTerm.asc(s.id)]))
            .get();
        for (var i = 1; i < linked.length; i++) {
          await (delete(sales)..where((s) => s.id.equals(linked[i].id))).go();
        }
        final sale = linked.isNotEmpty ? linked.first : null;
        if (sale != null) {
          await (update(sales)..where((s) => s.id.equals(sale.id))).write(
            SalesCompanion(
              totalAmount: Value(amount),
              customerId: Value(prev.customerId),
            ),
          );
        } else {
          await into(sales).insert(
            SalesCompanion.insert(
              createdAt: prev.createdAt,
              totalAmount: amount,
              customerId: Value(prev.customerId),
              sourceUtangEntryId: Value(entryId),
            ),
          );
        }
      } else {
        await (delete(sales)..where((s) => s.sourceUtangEntryId.equals(entryId))).go();
      }
    });
  }

  Future<void> deleteUtangEntry(int entryId) async {
    await transaction(() async {
      final entry = await (select(
        utangEntries,
      )..where((u) => u.id.equals(entryId))).getSingleOrNull();
      if (entry == null) return;

      if (!entry.isPayment) {
        final lines = await (select(
          utangEntryItems,
        )..where((i) => i.utangEntryId.equals(entryId))).get();
        for (final line in lines) {
          await customStatement(
            'UPDATE products SET stock_qty = stock_qty + ? WHERE id = ?',
            [line.qty, line.productId],
          );
        }
      }

      await (delete(utangEntries)..where((u) => u.id.equals(entryId))).go();
    });
  }

  Stream<List<UtangEntryItemDetail>> watchUtangEntryItems(int entryId) {
    final q = select(utangEntryItems).join([
      leftOuterJoin(products, products.id.equalsExp(utangEntryItems.productId)),
    ])..where(utangEntryItems.utangEntryId.equals(entryId));

    return q.watch().map(
      (rows) => rows
          .map(
            (row) => UtangEntryItemDetail(
              productName: row.readTableOrNull(products)?.name ?? 'N/A',
              qty: row.readTable(utangEntryItems).qty,
              unitPrice: row.readTable(utangEntryItems).unitPrice,
              lineTotal: row.readTable(utangEntryItems).lineTotal,
              unitType: row.readTableOrNull(products)?.unitType ?? 'pcs',
            ),
          )
          .toList(),
    );
  }

  Future<UtangReceiptDetail> getUtangReceipt(int entryId) async {
    final entry = await (select(utangEntries)
          ..where((u) => u.id.equals(entryId)))
        .getSingle();
    if (entry.isPayment) {
      throw Exception('Receipt not available for payment entries.');
    }
    final customer = await (select(customers)
          ..where((c) => c.id.equals(entry.customerId)))
        .getSingleOrNull();
    final q = select(utangEntryItems).join([
      leftOuterJoin(products, products.id.equalsExp(utangEntryItems.productId)),
    ])..where(utangEntryItems.utangEntryId.equals(entryId));
    final rows = await q.get();
    final lines = rows
        .map(
          (row) => UtangEntryItemDetail(
            productName: row.readTableOrNull(products)?.name ?? 'N/A',
            qty: row.readTable(utangEntryItems).qty,
            unitPrice: row.readTable(utangEntryItems).unitPrice,
            lineTotal: row.readTable(utangEntryItems).lineTotal,
            unitType: row.readTableOrNull(products)?.unitType ?? 'pcs',
          ),
        )
        .toList();
    return UtangReceiptDetail(
      entry: entry,
      customerName: customer?.name ?? 'Unknown customer',
      lines: lines,
    );
  }

  Future<int> addExpenseCategory(String name) {
    return into(expenseCategories).insert(
      ExpenseCategoriesCompanion.insert(
        name: name,
        createdAt: Value(DateTime.now()),
      ),
      mode: InsertMode.insertOrIgnore,
    );
  }

  Future<void> _seedDefaultExpenseCategories() async {
    for (final name in _defaultExpenseCategories) {
      await into(expenseCategories).insert(
        ExpenseCategoriesCompanion.insert(
          name: name,
          createdAt: Value(DateTime.now()),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }

  Future<void> _seedDefaultUnitMeasurements() async {
    for (final name in _defaultUnitMeasurements) {
      await into(unitMeasurements).insert(
        UnitMeasurementsCompanion.insert(
          name: name,
          createdAt: Value(DateTime.now()),
        ),
        mode: InsertMode.insertOrIgnore,
      );
    }
  }

  Stream<List<ExpenseCategory>> watchExpenseCategories() {
    return (select(
      expenseCategories,
    )..orderBy([(c) => OrderingTerm.asc(c.name)])).watch();
  }

  Stream<List<UnitMeasurement>> watchUnitMeasurements() {
    return (select(
      unitMeasurements,
    )..orderBy([(u) => OrderingTerm.asc(u.name)])).watch();
  }

  Future<int> addExpense({
    required int categoryId,
    required String expenseName,
    required String reason,
    required double amount,
  }) {
    return into(expenses).insert(
      ExpensesCompanion.insert(
        categoryId: categoryId,
        expenseName: expenseName,
        reason: reason,
        amount: amount,
        createdAt: DateTime.now(),
      ),
    );
  }

  Future<void> updateExpense({
    required int expenseId,
    required int categoryId,
    required String expenseName,
    required String reason,
    required double amount,
  }) {
    return (update(expenses)..where((e) => e.id.equals(expenseId))).write(
      ExpensesCompanion(
        categoryId: Value(categoryId),
        expenseName: Value(expenseName),
        reason: Value(reason),
        amount: Value(amount),
      ),
    );
  }

  Future<void> deleteExpense(int expenseId) {
    return (delete(expenses)..where((e) => e.id.equals(expenseId))).go();
  }

  Stream<List<ExpenseWithCategory>> watchExpenses() {
    final q = select(expenses).join([
      leftOuterJoin(
        expenseCategories,
        expenseCategories.id.equalsExp(expenses.categoryId),
      ),
    ])..orderBy([OrderingTerm.desc(expenses.createdAt)]);

    return q.watch().map(
      (rows) => rows
          .map(
            (row) => ExpenseWithCategory(
              expense: row.readTable(expenses),
              categoryName:
                  row.readTableOrNull(expenseCategories)?.name ?? 'N/A',
            ),
          )
          .toList(),
    );
  }

  Stream<List<GroceryItem>> watchGroceryItems() =>
      (select(groceryItems)
            ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
          .watch();

  Stream<List<GroceryItem>> watchGroceryItemsByList(int listId) {
    return (select(groceryItems)
          ..where((t) => t.groceryListId.equals(listId))
          ..orderBy([(t) => OrderingTerm.desc(t.createdAt)]))
        .watch();
  }

  Stream<List<GroceryList>> watchGroceryLists() {
    return (select(groceryLists)
          ..orderBy([(t) => OrderingTerm.asc(t.startAt)]))
        .watch();
  }

  Future<int> addGroceryList({
    required DateTime startAt,
    required String mallName,
  }) {
    return into(groceryLists).insert(
      GroceryListsCompanion.insert(
        startAt: startAt,
        mallName: mallName,
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> deleteGroceryList(int id) {
    return transaction(() async {
      await (delete(groceryItems)..where((g) => g.groceryListId.equals(id))).go();
      await (delete(groceryLists)..where((g) => g.id.equals(id))).go();
    });
  }

  Future<int> addGroceryItem(
    String name, {
    required int groceryListId,
    String brandName = '',
    double netWeight = 1,
    String netWeightUnit = 'g',
    double qty = 1,
    String unitType = 'pcs',
    String? imagePath,
    DateTime? plannedDate,
  }) {
    return into(groceryItems).insert(
      GroceryItemsCompanion.insert(
        name: name,
        groceryListId: Value(groceryListId),
        brandName: Value(brandName),
        netWeight: Value(netWeight),
        netWeightUnit: Value(netWeightUnit),
        qty: Value(qty),
        unitType: Value(unitType),
        imagePath: Value(imagePath),
        plannedDate: Value(plannedDate),
        createdAt: Value(DateTime.now()),
      ),
    );
  }

  Future<void> updateGroceryItem({
    required int id,
    required int groceryListId,
    required String name,
    required String brandName,
    required double netWeight,
    required String netWeightUnit,
    required double qty,
    required String unitType,
    String? imagePath,
    DateTime? plannedDate,
  }) {
    return (update(groceryItems)..where((g) => g.id.equals(id))).write(
      GroceryItemsCompanion(
        name: Value(name),
        groceryListId: Value(groceryListId),
        brandName: Value(brandName),
        netWeight: Value(netWeight),
        netWeightUnit: Value(netWeightUnit),
        qty: Value(qty),
        unitType: Value(unitType),
        imagePath: Value(imagePath),
        plannedDate: Value(plannedDate),
      ),
    );
  }

  Future<void> deleteGroceryItem(int id) {
    return (delete(groceryItems)..where((g) => g.id.equals(id))).go();
  }

  Future<void> toggleGrocery(int id, bool done) {
    return (update(groceryItems)..where((t) => t.id.equals(id))).write(
      GroceryItemsCompanion(isDone: Value(done)),
    );
  }

  Stream<double> watchTotalSales() {
    final q = customSelect(
      'SELECT COALESCE(SUM(total_amount), 0) as total FROM sales',
      readsFrom: {sales},
    );
    return q.watchSingle().map((row) => row.read<double>('total'));
  }

  Stream<double> watchTotalExpenses() {
    final q = customSelect(
      'SELECT COALESCE(SUM(amount), 0.0) as total FROM expenses',
      readsFrom: {expenses},
    );
    return q.watchSingle().map((row) => row.read<double>('total'));
  }

  Stream<int> watchLowStockCount() {
    final q = customSelect(
      'SELECT COUNT(*) as total FROM products WHERE stock_qty <= low_stock_threshold',
      readsFrom: {products},
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
      'products': (await select(
        products,
      ).get()).map((e) => e.toJson()).toList(),
      'sales': (await select(sales).get()).map((e) => e.toJson()).toList(),
      'saleItems': (await select(
        saleItems,
      ).get()).map((e) => e.toJson()).toList(),
      'customers': (await select(
        customers,
      ).get()).map((e) => e.toJson()).toList(),
      'utangEntries': (await select(
        utangEntries,
      ).get()).map((e) => e.toJson()).toList(),
      'expenseCategories': (await select(
        expenseCategories,
      ).get()).map((e) => e.toJson()).toList(),
      'expenses': (await select(
        expenses,
      ).get()).map((e) => e.toJson()).toList(),
      'groceryLists': (await select(
        groceryLists,
      ).get()).map((e) => e.toJson()).toList(),
      'groceryItems': (await select(
        groceryItems,
      ).get()).map((e) => e.toJson()).toList(),
    };
    return payload;
  }

  Future<Map<String, int>> previewJsonBackup(
    Map<String, dynamic> payload,
  ) async {
    return {
      'products': (payload['products'] as List<dynamic>? ?? const []).length,
      'sales': (payload['sales'] as List<dynamic>? ?? const []).length,
      'customers': (payload['customers'] as List<dynamic>? ?? const []).length,
      'expenseCategories':
          (payload['expenseCategories'] as List<dynamic>? ?? const []).length,
      'expenses': (payload['expenses'] as List<dynamic>? ?? const []).length,
      'groceryLists':
          (payload['groceryLists'] as List<dynamic>? ?? const []).length,
      'groceryItems':
          (payload['groceryItems'] as List<dynamic>? ?? const []).length,
    };
  }

  Future<void> importJsonBackup(
    Map<String, dynamic> payload, {
    required bool replaceAll,
  }) async {
    await transaction(() async {
      if (replaceAll) {
        await delete(groceryItems).go();
        await delete(groceryLists).go();
        await delete(utangEntries).go();
        await delete(saleItems).go();
        await delete(expenses).go();
        await delete(expenseCategories).go();
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
            brandName: Value(data['brand_name'] as String? ?? ''),
            price: Value((data['price'] as num).toDouble()),
            stockQty: Value((data['stock_qty'] as num).toDouble()),
            lowStockThreshold: Value(
              (data['low_stock_threshold'] as num).toDouble(),
            ),
            weight: Value((data['weight'] as num?)?.toDouble() ?? 1),
            netWeightUnit: Value(data['net_weight_unit'] as String? ?? 'g'),
            unitType: Value(data['unit_type'] as String? ?? 'pcs'),
            imagePath: Value(data['image_path'] as String?),
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
      for (final row in (payload['sales'] as List<dynamic>? ?? const [])) {
        final data = row as Map<String, dynamic>;
        await safeInsert(
          sales,
          SalesCompanion(
            id: Value(data['id'] as int),
            createdAt: Value(DateTime.parse(data['created_at'] as String)),
            totalAmount: Value((data['total_amount'] as num).toDouble()),
            customerId: Value(data['customer_id'] as int?),
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
            qty: Value((data['qty'] as num).toDouble()),
            unitPrice: Value((data['unit_price'] as num).toDouble()),
          ),
        );
      }
      for (final row
          in (payload['utangEntries'] as List<dynamic>? ?? const [])) {
        final data = row as Map<String, dynamic>;
        await safeInsert(
          utangEntries,
          UtangEntriesCompanion(
            id: Value(data['id'] as int),
            customerId: Value(data['customer_id'] as int),
            amount: Value((data['amount'] as num).toDouble()),
            isPayment: Value(data['is_payment'] as bool),
            createdAt: Value(DateTime.parse(data['created_at'] as String)),
            dueDate: Value(
              data['due_date'] == null
                  ? null
                  : DateTime.parse(data['due_date'] as String),
            ),
            itemName: Value(data['item_name'] as String?),
            note: Value(data['note'] as String?),
          ),
        );
      }
      for (final row
          in (payload['expenseCategories'] as List<dynamic>? ?? const [])) {
        final data = row as Map<String, dynamic>;
        await safeInsert(
          expenseCategories,
          ExpenseCategoriesCompanion(
            id: Value(data['id'] as int),
            name: Value(data['name'] as String),
          ),
        );
      }
      for (final row in (payload['expenses'] as List<dynamic>? ?? const [])) {
        final data = row as Map<String, dynamic>;
        await safeInsert(
          expenses,
          ExpensesCompanion(
            id: Value(data['id'] as int),
            categoryId: Value(data['category_id'] as int),
            expenseName: Value(data['expense_name'] as String),
            reason: Value(data['reason'] as String),
            amount: Value((data['amount'] as num).toDouble()),
            createdAt: Value(DateTime.parse(data['created_at'] as String)),
          ),
        );
      }
      for (final row in (payload['groceryLists'] as List<dynamic>? ?? const [])) {
        final data = row as Map<String, dynamic>;
        await safeInsert(
          groceryLists,
          GroceryListsCompanion(
            id: Value(data['id'] as int),
            startAt: Value(DateTime.parse(data['start_at'] as String)),
            mallName: Value(data['mall_name'] as String),
          ),
        );
      }
      for (final row
          in (payload['groceryItems'] as List<dynamic>? ?? const [])) {
        final data = row as Map<String, dynamic>;
        await safeInsert(
          groceryItems,
          GroceryItemsCompanion(
            id: Value(data['id'] as int),
            name: Value(data['name'] as String),
            groceryListId: Value(data['grocery_list_id'] as int?),
            brandName: Value(data['brand_name'] as String? ?? ''),
            netWeight: Value((data['net_weight'] as num?)?.toDouble() ?? 1),
            netWeightUnit: Value(data['net_weight_unit'] as String? ?? 'g'),
            qty: Value((data['qty'] as num).toDouble()),
            unitType: Value(data['unit_type'] as String? ?? 'pcs'),
            imagePath: Value(data['image_path'] as String?),
            plannedDate: Value(
              data['planned_date'] == null
                  ? null
                  : DateTime.parse(data['planned_date'] as String),
            ),
            isDone: Value(data['is_done'] as bool),
          ),
        );
      }
    });
  }

  Future<List<int>> exportSimpleSnapshot() async {
    final productCount = await customSelect(
      'SELECT COUNT(*) AS c FROM products',
    ).getSingle();
    final salesCount = await customSelect(
      'SELECT COUNT(*) AS c FROM sales',
    ).getSingle();
    final customerCount = await customSelect(
      'SELECT COUNT(*) AS c FROM customers',
    ).getSingle();
    return [
      productCount.read<int>('c'),
      salesCount.read<int>('c'),
      customerCount.read<int>('c'),
    ];
  }
}
