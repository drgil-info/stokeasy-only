import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:intl/date_symbol_data_local.dart';

import '../core/database/local_database_service.dart';
import '../core/services/backup_service.dart';
import '../core/services/database_sync_service.dart';
import '../features/counts/data/sqlite_stock_counts_repository.dart';
import '../features/counts/data/stock_count_pdf_service.dart';
import '../features/counts/domain/stock_counts.dart';
import '../features/dashboard/data/sqlite_dashboard_repository.dart';
import '../features/dashboard/domain/dashboard.dart';
import '../features/items/data/sqlite_items_repository.dart';
import '../features/items/domain/items.dart';
import '../features/movements/data/sqlite_movements_repository.dart';
import '../features/movements/domain/movements.dart';
import '../features/settings/data/sqlite_item_settings_repository.dart';
import '../features/settings/domain/item_settings.dart';
import 'app.dart';

Future<void> bootstrapApplication() async {
  WidgetsFlutterBinding.ensureInitialized();
  Intl.defaultLocale = 'pt_BR';
  await initializeDateFormatting('pt_BR');

  final dependencies = await initializeAppDependencies();
  runApp(StokEasyApp(dependencies: dependencies));
}

Future<AppDependencies> initializeAppDependencies({
  bool useInMemoryDatabase = false,
}) async {
  final databaseService = LocalDatabaseService(inMemory: useInMemoryDatabase);
  await databaseService.database;

  final itemsRepository = SqliteItemsRepository(databaseService);
  final movementsRepository = SqliteMovementsRepository(databaseService);
  final dashboardRepository = SqliteDashboardRepository(databaseService);
  final stockCountPdfService = StockCountPdfService();
  final stockCountsRepository = SqliteStockCountsRepository(
    databaseService,
    stockCountPdfService,
  );
  final itemSettingsRepository = SqliteItemSettingsRepository(databaseService);
  final backupService = BackupService(databaseService);
  final databaseSyncService = DatabaseSyncService(
    databaseService: databaseService,
    syncIntervalSeconds: 10, // Sincroniza a cada 10 segundos
  );

  return AppDependencies(
    databaseService: databaseService,
    backupService: backupService,
    databaseSyncService: databaseSyncService,
    getItemsUseCase: GetItemsUseCase(itemsRepository),
    createItemUseCase: CreateItemUseCase(itemsRepository),
    updateItemUseCase: UpdateItemUseCase(itemsRepository),
    deactivateItemUseCase: DeactivateItemUseCase(itemsRepository),
    reactivateItemUseCase: ReactivateItemUseCase(itemsRepository),
    getMovementsUseCase: GetMovementsUseCase(movementsRepository),
    createMovementUseCase: CreateMovementUseCase(movementsRepository),
    getItemSettingsSnapshotUseCase: GetItemSettingsSnapshotUseCase(
      itemSettingsRepository,
    ),
    addItemCategoryUseCase: AddItemCategoryUseCase(itemSettingsRepository),
    removeItemCategoryUseCase: RemoveItemCategoryUseCase(
      itemSettingsRepository,
    ),
    addItemUnitUseCase: AddItemUnitUseCase(itemSettingsRepository),
    removeItemUnitUseCase: RemoveItemUnitUseCase(itemSettingsRepository),
    getDashboardMetricsUseCase: GetDashboardMetricsUseCase(dashboardRepository),
    getStockCountsUseCase: GetStockCountsUseCase(stockCountsRepository),
    getStockCountDetailsUseCase: GetStockCountDetailsUseCase(
      stockCountsRepository,
    ),
    createStockCountUseCase: CreateStockCountUseCase(stockCountsRepository),
    updateStockCountLineUseCase: UpdateStockCountLineUseCase(
      stockCountsRepository,
    ),
    setStockCountLineSelectionUseCase: SetStockCountLineSelectionUseCase(
      stockCountsRepository,
    ),
    closeStockCountUseCase: CloseStockCountUseCase(stockCountsRepository),
    exportStockCountWorksheetPdfUseCase: ExportStockCountWorksheetPdfUseCase(
      stockCountsRepository,
    ),
    exportStockCountResultPdfUseCase: ExportStockCountResultPdfUseCase(
      stockCountsRepository,
    ),
  );
}

class AppDependencies {
  const AppDependencies({
    required this.databaseService,
    required this.databaseSyncService,
    required this.backupService,
    required this.getItemsUseCase,
    required this.createItemUseCase,
    required this.updateItemUseCase,
    required this.deactivateItemUseCase,
    required this.reactivateItemUseCase,
    required this.getMovementsUseCase,
    required this.createMovementUseCase,
    required this.getItemSettingsSnapshotUseCase,
    required this.addItemCategoryUseCase,
    required this.removeItemCategoryUseCase,
    required this.addItemUnitUseCase,
    required this.removeItemUnitUseCase,
    required this.getDashboardMetricsUseCase,
    required this.getStockCountsUseCase,
    required this.getStockCountDetailsUseCase,
    required this.createStockCountUseCase,
    required this.updateStockCountLineUseCase,
    required this.setStockCountLineSelectionUseCase,
    required this.closeStockCountUseCase,
    required this.exportStockCountWorksheetPdfUseCase,
    required this.exportStockCountResultPdfUseCase,
  });

  final LocalDatabaseService databaseService;
  final DatabaseSyncService databaseSyncService;
  final BackupService backupService;
  final GetItemsUseCase getItemsUseCase;
  final CreateItemUseCase createItemUseCase;
  final UpdateItemUseCase updateItemUseCase;
  final DeactivateItemUseCase deactivateItemUseCase;
  final ReactivateItemUseCase reactivateItemUseCase;
  final GetMovementsUseCase getMovementsUseCase;
  final CreateMovementUseCase createMovementUseCase;
  final GetItemSettingsSnapshotUseCase getItemSettingsSnapshotUseCase;
  final AddItemCategoryUseCase addItemCategoryUseCase;
  final RemoveItemCategoryUseCase removeItemCategoryUseCase;
  final AddItemUnitUseCase addItemUnitUseCase;
  final RemoveItemUnitUseCase removeItemUnitUseCase;
  final GetDashboardMetricsUseCase getDashboardMetricsUseCase;
  final GetStockCountsUseCase getStockCountsUseCase;
  final GetStockCountDetailsUseCase getStockCountDetailsUseCase;
  final CreateStockCountUseCase createStockCountUseCase;
  final UpdateStockCountLineUseCase updateStockCountLineUseCase;
  final SetStockCountLineSelectionUseCase setStockCountLineSelectionUseCase;
  final CloseStockCountUseCase closeStockCountUseCase;
  final ExportStockCountWorksheetPdfUseCase exportStockCountWorksheetPdfUseCase;
  final ExportStockCountResultPdfUseCase exportStockCountResultPdfUseCase;

  Future<void> dispose() async {
    await databaseSyncService.dispose();
    await databaseService.close();
  }
}
