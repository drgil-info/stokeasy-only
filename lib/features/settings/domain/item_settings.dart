class ItemSettingsSnapshot {
  const ItemSettingsSnapshot({required this.categories, required this.units});

  static const empty = ItemSettingsSnapshot(categories: [], units: []);

  final List<String> categories;
  final List<String> units;
}

abstract class ItemSettingsRepository {
  Future<ItemSettingsSnapshot> getSnapshot();

  Future<void> addCategory(String category);

  Future<void> removeCategory(String category);

  Future<void> addUnit(String unit);

  Future<void> removeUnit(String unit);
}

class GetItemSettingsSnapshotUseCase {
  const GetItemSettingsSnapshotUseCase(this._repository);

  final ItemSettingsRepository _repository;

  Future<ItemSettingsSnapshot> call() {
    return _repository.getSnapshot();
  }
}

class AddItemCategoryUseCase {
  const AddItemCategoryUseCase(this._repository);

  final ItemSettingsRepository _repository;

  Future<void> call(String category) {
    return _repository.addCategory(category);
  }
}

class RemoveItemCategoryUseCase {
  const RemoveItemCategoryUseCase(this._repository);

  final ItemSettingsRepository _repository;

  Future<void> call(String category) {
    return _repository.removeCategory(category);
  }
}

class AddItemUnitUseCase {
  const AddItemUnitUseCase(this._repository);

  final ItemSettingsRepository _repository;

  Future<void> call(String unit) {
    return _repository.addUnit(unit);
  }
}

class RemoveItemUnitUseCase {
  const RemoveItemUnitUseCase(this._repository);

  final ItemSettingsRepository _repository;

  Future<void> call(String unit) {
    return _repository.removeUnit(unit);
  }
}
