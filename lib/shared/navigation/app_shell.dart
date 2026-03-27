import 'dart:async';

import 'package:flutter/material.dart';

import '../../app/bootstrap.dart';
import '../../app/navigation/app_sections.dart';
import '../../app/theme/app_palette.dart';
import '../../features/backup/presentation/backup_controller.dart';
import '../../features/backup/presentation/backup_page.dart';
import '../../features/counts/presentation/counts_controller.dart';
import '../../features/counts/presentation/counts_page.dart';
import '../../features/dashboard/presentation/dashboard_controller.dart';
import '../../features/dashboard/presentation/dashboard_page.dart';
import '../../features/items/presentation/items_controller.dart';
import '../../features/items/presentation/items_page.dart';
import '../../features/movements/presentation/movements_controller.dart';
import '../../features/movements/presentation/movements_page.dart';
import '../../features/reports/presentation/reports_page.dart';
import '../../features/settings/presentation/settings_controller.dart';
import '../../features/settings/presentation/settings_page.dart';
import 'app_sidebar.dart';

class AppShell extends StatefulWidget {
  const AppShell({super.key, required this.dependencies});

  final AppDependencies dependencies;

  @override
  State<AppShell> createState() => _AppShellState();
}

class _AppShellState extends State<AppShell> {
  late final DashboardController _dashboardController;
  late final ItemsController _itemsController;
  late final MovementsController _movementsController;
  late final CountsController _countsController;
  late final BackupController _backupController;
  late final SettingsController _settingsController;

  AppSection _selectedSection = AppSection.dashboard;

  @override
  void initState() {
    super.initState();

    _dashboardController = DashboardController(
      getDashboardMetricsUseCase:
          widget.dependencies.getDashboardMetricsUseCase,
    );
    _itemsController = ItemsController(
      getItemsUseCase: widget.dependencies.getItemsUseCase,
      createItemUseCase: widget.dependencies.createItemUseCase,
      updateItemUseCase: widget.dependencies.updateItemUseCase,
      deactivateItemUseCase: widget.dependencies.deactivateItemUseCase,
      reactivateItemUseCase: widget.dependencies.reactivateItemUseCase,
    );
    _movementsController = MovementsController(
      getMovementsUseCase: widget.dependencies.getMovementsUseCase,
      createMovementUseCase: widget.dependencies.createMovementUseCase,
      getItemsUseCase: widget.dependencies.getItemsUseCase,
    );
    _countsController = CountsController(
      getStockCountsUseCase: widget.dependencies.getStockCountsUseCase,
      getStockCountDetailsUseCase:
          widget.dependencies.getStockCountDetailsUseCase,
      createStockCountUseCase: widget.dependencies.createStockCountUseCase,
      updateStockCountLineUseCase:
          widget.dependencies.updateStockCountLineUseCase,
      setStockCountLineSelectionUseCase:
          widget.dependencies.setStockCountLineSelectionUseCase,
      closeStockCountUseCase: widget.dependencies.closeStockCountUseCase,
      exportStockCountWorksheetPdfUseCase:
          widget.dependencies.exportStockCountWorksheetPdfUseCase,
      exportStockCountResultPdfUseCase:
          widget.dependencies.exportStockCountResultPdfUseCase,
    );
    _backupController = BackupController(
      backupService: widget.dependencies.backupService,
    );
    _settingsController = SettingsController(
      getSettingsSnapshotUseCase:
          widget.dependencies.getItemSettingsSnapshotUseCase,
      addItemCategoryUseCase: widget.dependencies.addItemCategoryUseCase,
      removeItemCategoryUseCase: widget.dependencies.removeItemCategoryUseCase,
      addItemUnitUseCase: widget.dependencies.addItemUnitUseCase,
      removeItemUnitUseCase: widget.dependencies.removeItemUnitUseCase,
    );

    unawaited(_loadInitialData());
  }

  @override
  void dispose() {
    _dashboardController.dispose();
    _itemsController.dispose();
    _movementsController.dispose();
    _countsController.dispose();
    _backupController.dispose();
    _settingsController.dispose();
    unawaited(widget.dependencies.dispose());
    super.dispose();
  }

  Future<void> _loadInitialData() async {
    await Future.wait([
      _dashboardController.loadMetrics(),
      _itemsController.loadItems(),
      _movementsController.loadData(),
      _countsController.loadData(),
      _backupController.load(),
      _settingsController.load(),
    ]);
  }

  Future<void> _refreshInventoryData() async {
    await Future.wait([
      _dashboardController.loadMetrics(),
      _itemsController.loadItems(query: _itemsController.searchQuery),
      _movementsController.loadData(),
      _countsController.loadData(
        selectCountId: _countsController.selectedCountId,
      ),
      _settingsController.load(),
    ]);
  }

  void _selectSection(AppSection section) {
    setState(() {
      _selectedSection = section;
    });

    if (section == AppSection.settings) {
      unawaited(_settingsController.load());
    }
  }

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 1100;

        return Scaffold(
          drawer: compact
              ? Drawer(
                  width: 320,
                  child: AppSidebar(
                    compact: true,
                    selectedSection: _selectedSection,
                    onSectionSelected: (section) {
                      Navigator.of(context).pop();
                      _selectSection(section);
                    },
                  ),
                )
              : null,
          body: DecoratedBox(
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [AppPalette.white, AppPalette.canvasStrong],
              ),
            ),
            child: SafeArea(
              child: Row(
                children: [
                  if (!compact)
                    AppSidebar(
                      selectedSection: _selectedSection,
                      onSectionSelected: _selectSection,
                    ),
                  Expanded(
                    child: Column(
                      children: [
                        if (compact)
                          _ShellTopBar(selectedSection: _selectedSection),
                        Expanded(
                          child: AnimatedSwitcher(
                            duration: const Duration(milliseconds: 260),
                            switchInCurve: Curves.easeOutCubic,
                            switchOutCurve: Curves.easeInCubic,
                            child: KeyedSubtree(
                              key: ValueKey(_selectedSection),
                              child: _buildCurrentPage(),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildCurrentPage() {
    return switch (_selectedSection) {
      AppSection.dashboard => DashboardPage(
        controller: _dashboardController,
        onNavigate: _selectSection,
      ),
      AppSection.items => ItemsPage(
        controller: _itemsController,
        settingsController: _settingsController,
        onInventoryChanged: _refreshInventoryData,
      ),
      AppSection.movements => MovementsPage(
        controller: _movementsController,
        onInventoryChanged: _refreshInventoryData,
      ),
      AppSection.counts => CountsPage(controller: _countsController),
      AppSection.reports => ReportsPage(
        dashboardController: _dashboardController,
        itemsController: _itemsController,
        movementsController: _movementsController,
      ),
      AppSection.settings => SettingsPage(controller: _settingsController),
      AppSection.backup => BackupPage(
        controller: _backupController,
        onInventoryRestored: _refreshInventoryData,
      ),
    };
  }
}

class _ShellTopBar extends StatelessWidget {
  const _ShellTopBar({required this.selectedSection});

  final AppSection selectedSection;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 20, 20, 12),
      child: Row(
        children: [
          Builder(
            builder: (context) {
              return IconButton.filledTonal(
                onPressed: Scaffold.of(context).openDrawer,
                icon: const Icon(Icons.menu_rounded),
              );
            },
          ),
          const SizedBox(width: 14),
          Container(
            width: 38,
            height: 38,
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: AppPalette.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: AppPalette.border),
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(8),
              child: Image.asset(
                'assets/images/stokeasy-png.png',
                fit: BoxFit.contain,
                errorBuilder: (_, _, _) => const Icon(
                  Icons.inventory_2_rounded,
                  color: AppPalette.black,
                  size: 20,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  selectedSection.label,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                Text(
                  selectedSection.headline,
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}
