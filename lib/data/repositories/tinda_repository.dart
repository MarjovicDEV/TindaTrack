import '../local/app_database.dart';

class TindaRepository {
  TindaRepository(this.db);

  final AppDatabase db;

  Stream<List<Product>> watchProducts() => db.watchProducts();
  Stream<List<Sale>> watchSales() => db.watchSales();
  Stream<List<Customer>> watchCustomers() => db.watchCustomers();
  Stream<List<ExpenseWithCategory>> watchExpenses() => db.watchExpenses();
  Stream<List<GroceryItem>> watchGroceryItems() => db.watchGroceryItems();
  Stream<List<GroceryItem>> watchGroceryItemsByList(int listId) =>
      db.watchGroceryItemsByList(listId);
  Stream<List<GroceryList>> watchGroceryLists() => db.watchGroceryLists();
  Stream<List<ExpenseCategory>> watchExpenseCategories() =>
      db.watchExpenseCategories();
  Stream<List<UnitMeasurement>> watchUnitMeasurements() =>
      db.watchUnitMeasurements();
  Stream<List<CustomerBalance>> watchCustomerBalances() =>
      db.watchCustomerBalances();
  Stream<List<UtangEntry>> watchUtangEntriesByCustomer(int customerId) =>
      db.watchUtangEntriesByCustomer(customerId);
  Stream<List<UtangEntryItemDetail>> watchUtangEntryItems(int entryId) =>
      db.watchUtangEntryItems(entryId);

  Stream<double> watchTotalSales() => db.watchTotalSales();
  Stream<double> watchTotalExpenses() => db.watchTotalExpenses();
  Stream<int> watchLowStockCount() => db.watchLowStockCount();
  Stream<List<Sale>> watchSalesInRange(DateTime from, DateTime to) =>
      db.watchSalesInRange(from, to);
  Stream<List<Expense>> watchExpensesInRange(DateTime from, DateTime to) =>
      db.watchExpensesInRange(from, to);

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
  }) => db.addProduct(
    name: name,
    brandName: brandName,
    price: price,
    stockQty: stockQty,
    threshold: threshold,
    weight: weight,
    netWeightUnit: netWeightUnit,
    unitType: unitType,
    imagePath: imagePath,
  );

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
  }) => db.updateProduct(
    id: id,
    name: name,
    brandName: brandName,
    price: price,
    stockQty: stockQty,
    threshold: threshold,
    weight: weight,
    netWeightUnit: netWeightUnit,
    unitType: unitType,
    imagePath: imagePath,
  );

  Future<void> deleteProduct(int id) => db.deleteProduct(id);

  Future<int> createSale({
    required int productId,
    required double quantity,
    required int customerId,
  }) => db.createSale(
        productId: productId,
        quantity: quantity,
        customerId: customerId,
      );
  Future<void> updateSale({
    required int saleId,
    required int productId,
    required double quantity,
    required int customerId,
  }) => db.updateSale(
        saleId: saleId,
        productId: productId,
        quantity: quantity,
        customerId: customerId,
      );
  Future<void> deleteSaleAndRestoreStock(int saleId) =>
      db.deleteSaleAndRestoreStock(saleId);
  Future<List<SaleItem>> getSaleItems(int saleId) => db.getSaleItems(saleId);
  Future<SaleReceiptDetail> getSaleReceipt(int saleId) =>
      db.getSaleReceipt(saleId);
  Future<int> addCustomer(String name) => db.addCustomer(name);
  Future<void> updateCustomer(int id, String name) =>
      db.updateCustomer(id, name);
  Future<void> deleteCustomer(int id) => db.deleteCustomer(id);
  Future<int> addUtang({
    required int customerId,
    required double amount,
    required bool isPayment,
    DateTime? dueDate,
    String? itemName,
    String? note,
  }) => db.addUtang(
    customerId: customerId,
    amount: amount,
    isPayment: isPayment,
    dueDate: dueDate,
    itemName: itemName,
    note: note,
  );
  Future<int> addUtangWithItems({
    required int customerId,
    required List<UtangLineInput> lines,
    DateTime? dueDate,
    String? note,
  }) => db.addUtangWithItems(
    customerId: customerId,
    lines: lines,
    dueDate: dueDate,
    note: note,
  );
  Future<void> updateUtangEntry({
    required int entryId,
    required double amount,
    required bool isPayment,
    DateTime? dueDate,
    String? itemName,
    String? note,
  }) => db.updateUtangEntry(
    entryId: entryId,
    amount: amount,
    isPayment: isPayment,
    dueDate: dueDate,
    itemName: itemName,
    note: note,
  );
  Future<UtangReceiptDetail> getUtangReceipt(int entryId) =>
      db.getUtangReceipt(entryId);
  Future<void> deleteUtangEntry(int entryId) => db.deleteUtangEntry(entryId);
  Future<int> addExpenseCategory(String name) => db.addExpenseCategory(name);

  Future<int> addExpense({
    required int categoryId,
    required String expenseName,
    required String reason,
    required double amount,
  }) => db.addExpense(
    categoryId: categoryId,
    expenseName: expenseName,
    reason: reason,
    amount: amount,
  );

  Future<void> updateExpense({
    required int expenseId,
    required int categoryId,
    required String expenseName,
    required String reason,
    required double amount,
  }) => db.updateExpense(
    expenseId: expenseId,
    categoryId: categoryId,
    expenseName: expenseName,
    reason: reason,
    amount: amount,
  );

  Future<void> deleteExpense(int expenseId) => db.deleteExpense(expenseId);

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
  }) => db.addGroceryItem(
    name,
    groceryListId: groceryListId,
    brandName: brandName,
    netWeight: netWeight,
    netWeightUnit: netWeightUnit,
    qty: qty,
    unitType: unitType,
    imagePath: imagePath,
    plannedDate: plannedDate,
  );
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
  }) => db.updateGroceryItem(
    id: id,
    groceryListId: groceryListId,
    name: name,
    brandName: brandName,
    netWeight: netWeight,
    netWeightUnit: netWeightUnit,
    qty: qty,
    unitType: unitType,
    imagePath: imagePath,
    plannedDate: plannedDate,
  );
  Future<void> deleteGroceryItem(int id) => db.deleteGroceryItem(id);
  Future<void> toggleGrocery(int id, bool done) => db.toggleGrocery(id, done);
  Future<int> addGroceryList({required DateTime startAt, required String mallName}) =>
      db.addGroceryList(startAt: startAt, mallName: mallName);
  Future<void> deleteGroceryList(int id) => db.deleteGroceryList(id);

  Future<List<int>> exportSimpleSnapshot() => db.exportSimpleSnapshot();
  Future<Map<String, dynamic>> exportJsonBackup() => db.exportJsonBackup();
  Future<Map<String, int>> previewJsonBackup(Map<String, dynamic> payload) =>
      db.previewJsonBackup(payload);
  Future<void> importJsonBackup(
    Map<String, dynamic> payload, {
    required bool replaceAll,
  }) => db.importJsonBackup(payload, replaceAll: replaceAll);
}
