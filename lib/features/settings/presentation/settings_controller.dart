import 'package:flutter/foundation.dart';

import '../domain/item_settings.dart';

class SettingsController extends ChangeNotifier {
  SettingsController({
    required GetItemSettingsSnapshotUseCase getSettingsSnapshotUseCase,
    required AddItemCategoryUseCase addItemCategoryUseCase,
    required RemoveItemCategoryUseCase removeItemCategoryUseCase,
    required AddItemUnitUseCase addItemUnitUseCase,
    required RemoveItemUnitUseCase removeItemUnitUseCase,
  }) : _getSettingsSnapshotUseCase = getSettingsSnapshotUseCase,
       _addItemCategoryUseCase = addItemCategoryUseCase,
       _removeItemCategoryUseCase = removeItemCategoryUseCase,
       _addItemUnitUseCase = addItemUnitUseCase,
       _removeItemUnitUseCase = removeItemUnitUseCase;

  final GetItemSettingsSnapshotUseCase _getSettingsSnapshotUseCase;
  final AddItemCategoryUseCase _addItemCategoryUseCase;
  final RemoveItemCategoryUseCase _removeItemCategoryUseCase;
  final AddItemUnitUseCase _addItemUnitUseCase;
  final RemoveItemUnitUseCase _removeItemUnitUseCase;

  ItemSettingsSnapshot _snapshot = ItemSettingsSnapshot.empty;
  bool _isLoading = false;
  String? _errorMessage;

  List<String> get categories => _snapshot.categories;
  List<String> get units => _snapshot.units;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> load() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      _snapshot = await _getSettingsSnapshotUseCase();
    } catch (error) {
      _errorMessage = _humanizeError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> addCategory(String category) async {
    await _addItemCategoryUseCase(category);
    await load();
  }

  Future<void> removeCategory(String category) async {
    await _removeItemCategoryUseCase(category);
    await load();
  }

  Future<void> addUnit(String unit) async {
    await _addItemUnitUseCase(unit);
    await load();
  }

  Future<void> removeUnit(String unit) async {
    await _removeItemUnitUseCase(unit);
    await load();
  }

  String _humanizeError(Object error) {
    if (error is StateError) {
      return error.message;
    }
    return 'Nao foi possivel carregar as configuracoes.';
  }
}
