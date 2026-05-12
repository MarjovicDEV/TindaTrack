import 'package:flutter/material.dart';

class AppCopy {
  AppCopy._(this._localeCode);

  factory AppCopy.of(BuildContext context) {
    return AppCopy._(Localizations.localeOf(context).languageCode);
  }

  final String _localeCode;

  bool get _english => _localeCode.startsWith('en');
  bool get isEnglish => _english;

  String _t(String en, String fil) => _english ? en : fil;

  String get appTitle => 'TindaTrack';

  String get navDashboard => _t('Dashboard', 'Ulat');
  String get navHome => _t('Home', 'Tahanan');
  String get navStock => _t('Stock', 'Stok');
  String get navInventory => _t('Inventory', 'Imbentaryo');
  String get navSales => _t('Sales', 'Benta');
  String get navUtang => _t('Debt', 'Utang');
  String get navExpenses => _t('Expenses', 'Gastos');
  String get navGrocery => _t('Grocery', 'Bilihin');
  String get navHistory => _t('History', 'Kasaysayan');
  String get navReports => _t('Reports', 'Ulat');

  String get speedDialTitle => _t('Add', 'Magdagdag');
  String get speedDialBenta => _t('Sale', 'Benta');
  String get speedDialUtang => _t('Debt', 'Utang');
  String get speedDialGastos => _t('Expense', 'Gastos');

  String get settingsTitle => _t('Settings', 'Mga Setting');
  String get settingsTooltip => _t('Settings', 'Mga Setting');
  String get settingsNotificationsSection => _t('Notifications', 'Abiso');
  String get settingsProfileSection => _t('Profile', 'Profile');
  String get settingsSystemSection => _t('System', 'Sistema');
  String get settingsLanguage => _t('Language', 'Wika');
  String get settingsCurrency => _t('Currency', 'Salapi');
  String get settingsOwnerName => _t('Owner name', 'Pangalan ng may-ari');
  String get settingsStoreName => _t('Store name', 'Pangalan ng tindahan');
  String get settingsEmailSoon => _t('Email (coming soon)', 'Email (malapit na)');
  String get settingsLocation => _t('Location', 'Lokasyon');
  String get settingsSearchLocation => _t('Search (OpenStreetMap)', 'Hanapin (OpenStreetMap)');
  String get settingsOsmAttribution => _t('© OpenStreetMap contributors', '© OpenStreetMap contributors');

  String get historyTitle => _t('History', 'Kasaysayan');
  String get historyEmpty => _t('No history records yet.', 'Walang tala sa kasaysayan.');

  String get homeChartSalesVsExpenses => _t('Sales vs expenses (pie)', 'Benta vs gastos (pie)');
  String get homeChartBarSalesExpenses => _t('Sales and expenses (bar)', 'Benta at gastos (bar)');
  String get homeNetPeriodLabel => _t('Net profit — period', 'Netong kita — saklaw');
  String get summaryTitle => _t('Store Summary', 'Buod ng Tindahan');
  String get reportsPageTitle => _t('Tinda Reports', 'Tinda Reports');
  String get totalSales => _t('Total Sales', 'Kabuuang Benta');
  String get totalExpenses => _t('Total Expenses', 'Kabuuang Gastos');
  String get netProfit => _t('Net Profit', 'Netong Kita');
  String get lowStockAlerts => _t('Low Stock', 'Mababang Stock');

  String get exportPng => _t('Export PNG', 'I-export PNG');
  String get exportPdf => _t('Export PDF', 'I-export PDF');
  String get exportJson => _t('Export JSON', 'I-export JSON');
  String get importJson => _t('Import JSON', 'I-import JSON');
  String get exportDb => _t('Export DB', 'I-export DB');
  String get importDb => _t('Import DB', 'I-import DB');
  String get replaceMode => _t('Replace all', 'Palitan lahat');
  String get mergeMode => _t('Merge', 'Pagsamahin');
  String get backupRestoreTitle => _t('Backup & Restore', 'Backup at Restore');
  String get backupRestoreDescription => _t(
    'Choose an export/import type. Preview and warning appear before restore.',
    'Pumili ng export/import type. May preview at babala bago i-restore.',
  );
  String get reportFilterDaily => _t('Daily', 'Araw-araw');
  String get reportFilterWeekly => _t('Weekly', 'Lingguhan');
  String get reportFilterMonthly => _t('Monthly', 'Buwanan');
  String get noDataRange => _t('No data in the selected range.', 'Walang datos sa napiling saklaw.');
  String get reportRangeLabel => _t('Range (PH UTC+8):', 'Saklaw (PH UTC+8):');

  String get notificationSettingsTitle => _t('Notification settings', 'Mga abiso');
  String get notificationLowStock => _t('Low stock alert', 'Babala sa mababang stock');
  String get notificationGroceryReminder => _t('Grocery reminder', 'Paalala sa bilihin');

  String get themeMenuTitle => _t('App theme', 'Tema ng App');
  String get themeSystem => _t('System theme', 'System Theme');
  String get themeDark => _t('Dark theme', 'Dark Theme');
  String get themeLight => _t('Light theme', 'Light Theme');

  String get productImageUpload => _t('Upload image', 'Mag-upload ng larawan');
  String get productImageCamera => _t('Camera', 'Kamera');
  String get productImageGallery => _t('Gallery', 'Gallery');
  String get productImageRemove => _t('Remove image', 'Alisin ang larawan');
  String get productImageCameraPermission => _t('Camera permission is required.', 'Kailangan ng pahintulot sa kamera.');
  String get productImageSettingsAction => _t('Settings', 'Settings');

  String get inventoryTitle => _t('Inventory', 'Imbentaryo');
  String get inventoryAdd => _t('Add', 'Magdagdag');
  String get inventoryNoProducts => _t('No products yet.', 'Wala pang produkto.');
  String get inventoryCancel => _t('Cancel', 'Kanselahin');
  String get inventorySave => _t('Save', 'I-save');
  String get inventoryConfirmDeleteTitle => _t('Confirm delete', 'Kumpirmahin ang delete');
  String get inventoryDeleteYes => _t('Delete', 'Delete');
  String get inventoryDeleteNo => _t('No', 'Hindi');
  String get inventoryBrandName => _t('Brand name', 'Brand name');
  String get inventoryProductName => _t('Product name', 'Pangalan ng produkto');
  String get inventoryNetWeight => _t('Net weight / capacity', 'Net weight / kapasidad');
  String get inventoryNetWeightUnit => _t('Net weight unit', 'Net weight unit');
  String get inventoryPrice => _t('Price', 'Presyo');
  String get inventoryStock => _t('Stock', 'Stock');
  String get inventoryUnitOfMeasure => _t('Unit of Measure', 'Unit of Measure');
  String get inventoryUnitRequired => _t('Unit is required.', 'Unit ay required.');
  String get inventoryLowStockAlert => _t('Low stock alert', 'Babala sa mababang stock');
  String get inventoryEdit => _t('Edit', 'I-edit');
  String get inventoryDelete => _t('Delete', 'Burahin');
  String get inventoryStockPrefix => _t('Stock:', 'Stock:');

  String get groceryTitle => _t('Grocery List', 'Listahan ng Bilihin');
  String get grocerySubtitle => _t('Choose a schedule below, then add items.', 'Pumili ng schedule sa ibaba, tapos magdagdag ng item.');
  String get groceryCreateScheduleTooltip => _t('Create schedule', 'Gumawa ng schedule');
  String get groceryNoSchedule => _t('No grocery schedule yet.', 'Wala pang grocery schedule.');
  String get groceryNoScheduleDescription => _t('First choose the date, time, and mall to create a list.', 'Una pili ang petsa, oras, at mall para makagawa ng list.');
  String get groceryCreateSchedule => _t('Create schedule', 'Gumawa ng schedule');
  String get groceryPickSchedule => _t('Pick a schedule first', 'Pumili muna ng schedule');
  String get groceryPickScheduleDescription => _t('Tap the chips above to view and add items to the grocery list.', 'I-tap ang chip sa itaas para makita at magdagdag ng grocery list.');
  String get groceryNoItems => _t('No items in this schedule yet.', 'Wala pang items sa schedule na ito.');
  String get groceryAddFirstItem => _t('Add first item', 'Magdagdag ng unang item');
  String get groceryAddItem => _t('Add item', 'Magdagdag ng item');
  String get groceryCreateScheduleDialogTitle => _t('Create Grocery Schedule', 'Gumawa ng Grocery Schedule');
  String get dateLabel => _t('Date', 'Date');
  String get timeLabel => _t('Time', 'Time');
  String get pickDate => _t('Pick a date', 'Pumili ng date');
  String get pickTime => _t('Pick a time', 'Pumili ng oras');
  String get mallLocationLabel => _t('Mall / Location', 'Mall / Location');
  String get groceryCancel => _t('Cancel', 'Kanselahin');
  String get grocerySave => _t('Save', 'I-save');
  String get groceryConfirmDeleteTitle => _t('Confirm delete', 'Kumpirmahin ang delete');
  String get groceryDeleteNo => _t('No', 'Hindi');
  String get groceryDeleteYes => _t('Delete', 'Delete');
  String get groceryMarkDoneTooltip => _t('Mark as done', 'Markahan bilang nakuha na');
  String get groceryMarkNotDoneTooltip => _t('Mark as not done', 'Markahan bilang hindi pa');

  String get utangAdd => _t('Add', 'Magdagdag');
  String get utangNoCustomers => _t('No customers yet.', 'Wala pang customer.');
  String get utangAddCustomerTitle => _t('Add customer', 'Magdagdag ng customer');
  String get utangName => _t('Name', 'Pangalan');
  String get utangSelectAtLeastOneItem => _t('Select at least one item.', 'Pumili ng kahit isang item.');
  String get utangFirstBorrowedItem => _t('First borrowed item', 'Unang item na inutang');
  String get utangNoInventoryPrompt => _t('Add a product in Inventory first before creating a bulk debt.', 'Wala pang produkto sa Imbentaryo. Magdagdag muna bago gumawa ng bulk utang.');
  String get utangQty => 'Qty';
  String get utangInitialAmount => _t('Initial debt amount', 'Unang amount ng utang');
  String get utangDueDateLabel => _t('Debt due date', 'Due date ng utang');
  String get utangPickDueDate => _t('Pick a due date', 'Pumili ng due date');
  String get utangDueDateRequired => _t('Due date is required.', 'Due date ay required.');
  String get utangDueDateTodayOrFuture => _t('Due date must be today or later.', 'Due date dapat today o future lang.');
  String get utangSaveCustomer => _t('Save customer', 'I-save ang customer');
  String get utangAddEntryTitle => _t('Add debt entry', 'Magdagdag ng utang entry');
  String get utangPayment => _t('Payment', 'Bayad');
  String get utangNewDebt => _t('New debt', 'Bagong Utang');
  String get utangPaymentSubtitle => _t('Reduces the balance', 'Bawas sa balanse');
  String get utangDebtSubtitle => _t('Adds to the balance', 'Dagdag sa balanse');
  String get utangAmount => _t('Amount', 'Amount');
  String get utangItemProduct => _t('Item / Product', 'Item / Product');
  String get utangNote => _t('Note', 'Note');
  String get utangAmountAuto => _t('Amount (auto)', 'Amount (auto)');
  String get utangSaveEntry => _t('Save entry', 'I-save ang entry');
  String get utangUpdateCustomerTitle => _t('Update customer', 'I-update ang customer');
  String entriesForCustomer(String name) => _t('$name\'s entries', 'Entries ni $name');
  String get utangNoEntriesYet => _t('No entries yet.', 'Wala pang entries.');
  String get utangDetailTitle => _t('Entry details', 'Detalye ng Entry');
  String get utangNoBreakdownForPayment => _t('No item breakdown for payment entries.', 'Walang item breakdown para sa bayad entry.');
  String get utangNoLineItems => _t('No line items.', 'Walang line items.');
  String get utangBalance => _t('Balance:', 'Balanse:');
  String get utangAddDebtTooltip => _t('Add debt', 'Magdagdag ng utang');
  String get utangEdit => _t('Edit', 'I-edit');
  String get utangDelete => _t('Delete', 'Burahin');
  String get utangConfirmDeleteTitle => _t('Confirm delete', 'Kumpirmahin ang delete');
  String get utangDeleteNo => _t('No', 'Hindi');
  String get utangDeleteYes => _t('Delete', 'Delete');
  String get utangTransactionLabel => _t('Transaction (PH UTC+8):', 'Transaksyon (PH UTC+8):');
  String get utangDueDateLabelShort => _t('Due date:', 'Due date:');
  String get utangQtyShort => 'Qty';
  String get utangUnitLabel => _t('Unit:', 'Unit:');
  String get utangPaymentReceived => _t('Payment received', 'Payment received');
  String get utangInitialDebtNote => _t('Initial debt', 'Initial utang');
  String get utangDebtRecorded => _t('Debt recorded', 'Utang recorded');
  String get utangSaveFailedPrefix => _t('Save failed:', 'Hindi na-save:');
  String get utangSavePrefix => _t('Saved:', 'Na-save:');
  String get utangAddProductInventoryPrompt => _t('Add a product in Inventory first.', 'Magdagdag muna ng produkto sa Imbentaryo.');
  String get utangChooseProductFirst => _t('Choose a product first.', 'Pumili muna ng produkto.');
  String get utangInvalidSelectedQty => _t('Enter a valid quantity for the selected item.', 'Ilagay ang valid na quantity ng napiling item.');
  String get searchNoResults => _t('No results.', 'Walang resulta.');
  String get pickLocationTitle => _t('Choose a location', 'Pumili ng lokasyon');

  String get reportsPngUnavailable => _t('PNG export is available only on desktop/mobile for now.', 'Ang PNG export ay desktop/mobile app lamang sa ngayon.');
  String get reportsNoExportView => _t('Nothing to export.', 'Walang ma-export na view.');
  String reportPngSaved(String path) => _t('Saved PNG: $path', 'Na-save ang PNG: $path');
  String reportPdfSaved(String path) => _t('Saved PDF: $path', 'Na-save ang PDF: $path');
  String reportPdfDownloadSoon(int bytesLength) => _t('PDF ($bytesLength bytes) — download support coming soon.', 'PDF ($bytesLength bytes) — i-download support sa susunod.');
  String reportExportError(String error) => error;

  String backupJsonSaved(String path) => _t('JSON backup exported: $path', 'Na-export ang JSON backup: $path');
  String backupDbSaved(String path) => _t('DB backup exported: $path', 'Na-export ang DB backup: $path');
  String get backupReplaceDone => _t('Restored (replace).', 'Na-restore (replace).');
  String get backupMergeDone => _t('Restored (merge).', 'Na-restore (merge).');
  String get backupDbUnsupportedWeb => _t('DB import/export is not supported on web. Use JSON.', 'DB import/export ay hindi supported sa web. JSON ang gamitin.');
  String get backupDbImportRestart => _t('DB file imported. Restart the app if needed.', 'Na-import ang DB file. I-restart ang app kung kailangan.');
  String get backupRestoreModeTitle => _t('Choose restore mode', 'Piliin ang restore mode');
  String get backupReplaceWarning => _t('Warning: "Replace all" will delete existing records.', 'Babala: Ang "Palitan lahat" ay bubura ng kasalukuyang records.');

  String get themeSheetTitle => _t('App theme', 'Tema ng App');

  String get cameraPermissionRequired => productImageCameraPermission;
  String get settingsAction => productImageSettingsAction;
  String get uploadImage => productImageUpload;
  String get camera => productImageCamera;
  String get gallery => productImageGallery;
  String get removeImage => productImageRemove;
  String get addButton => _t('Add', 'Magdagdag');
  String get cancelButton => _t('Cancel', 'Kanselahin');
  String get saveButton => _t('Save', 'I-save');
  String get noButton => _t('No', 'Hindi');
  String get deleteButton => _t('Delete', 'Delete');
  String get editButton => _t('Edit', 'I-edit');
}
