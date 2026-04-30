import '../local/app_database.dart';

class TindaRepository {
  TindaRepository(this.db);

  final AppDatabase db;

  Stream<List<Product>> watchProducts() => db.watchProducts();
  Stream<List<Sale>> watchSales() => db.watchSales();
  Stream<List<Customer>> watchCustomers() => db.watchCustomers();
  Stream<List<Expense>> watchExpenses() => db.watchExpenses();
  Stream<List<GroceryItem>> watchGroceryItems() => db.watchGroceryItems();

  Stream<double> watchTotalSales() => db.watchTotalSales();
  Stream<double> watchTotalExpenses() => db.watchTotalExpenses();
  Stream<int> watchLowStockCount() => db.watchLowStockCount();
  Stream<List<Sale>> watchSalesInRange(DateTime from, DateTime to) =>
      db.watchSalesInRange(from, to);
  Stream<List<Expense>> watchExpensesInRange(DateTime from, DateTime to) =>
      db.watchExpensesInRange(from, to);

  Future<int> addProduct({
    required String name,
    required double price,
    required int stockQty,
    required int threshold,
  }) =>
      db.addProduct(
        name: name,
        price: price,
        stockQty: stockQty,
        threshold: threshold,
      );

  Future<void> recordSale(List<SaleItemsCompanion> items) => db.recordSale(items);
  Future<int> addCustomer(String name) => db.addCustomer(name);
  Future<int> addUtang({
    required int customerId,
    required double amount,
    required bool isPayment,
    String? note,
  }) =>
      db.addUtang(
        customerId: customerId,
        amount: amount,
        isPayment: isPayment,
        note: note,
      );

  Future<int> addExpense({
    required String category,
    required double amount,
    String? note,
  }) =>
      db.addExpense(category: category, amount: amount, note: note);

  Future<int> addGroceryItem(String name, {int qty = 1}) =>
      db.addGroceryItem(name, qty: qty);
  Future<void> toggleGrocery(int id, bool done) => db.toggleGrocery(id, done);

  Future<List<int>> exportSimpleSnapshot() => db.exportSimpleSnapshot();
  Future<Map<String, dynamic>> exportJsonBackup() => db.exportJsonBackup();
  Future<Map<String, int>> previewJsonBackup(Map<String, dynamic> payload) =>
      db.previewJsonBackup(payload);
  Future<void> importJsonBackup(
    Map<String, dynamic> payload, {
    required bool replaceAll,
  }) => db.importJsonBackup(payload, replaceAll: replaceAll);
}
