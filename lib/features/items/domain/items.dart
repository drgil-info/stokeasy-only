enum ItemStatusFilter { active, inactive, all }

enum ItemSortOption { nameAsc, newest, highestStock, lowestStock, highestValue }

class InventoryItem {
  const InventoryItem({
    this.id,
    required this.name,
    required this.sku,
    required this.category,
    required this.unit,
    required this.brand,
    required this.color,
    required this.quantity,
    required this.minimumStock,
    required this.price,
    required this.isActive,
    required this.createdAt,
    required this.updatedAt,
  });

  final int? id;
  final String name;
  final String sku;
  final String category;
  final String unit;
  final String brand;
  final String color;
  final double quantity;
  final double minimumStock;
  final double price;
  final bool isActive;
  final DateTime createdAt;
  final DateTime updatedAt;

  bool get isLowStock => quantity <= minimumStock;

  double get stockValue => quantity * price;

  InventoryItem copyWith({
    int? id,
    String? name,
    String? sku,
    String? category,
    String? unit,
    String? brand,
    String? color,
    double? quantity,
    double? minimumStock,
    double? price,
    bool? isActive,
    DateTime? createdAt,
    DateTime? updatedAt,
  }) {
    return InventoryItem(
      id: id ?? this.id,
      name: name ?? this.name,
      sku: sku ?? this.sku,
      category: category ?? this.category,
      unit: unit ?? this.unit,
      brand: brand ?? this.brand,
      color: color ?? this.color,
      quantity: quantity ?? this.quantity,
      minimumStock: minimumStock ?? this.minimumStock,
      price: price ?? this.price,
      isActive: isActive ?? this.isActive,
      createdAt: createdAt ?? this.createdAt,
      updatedAt: updatedAt ?? this.updatedAt,
    );
  }
}

class InventoryItemDraft {
  const InventoryItemDraft({
    required this.name,
    required this.sku,
    required this.category,
    required this.unit,
    this.brand = '',
    this.color = '',
    required this.initialQuantity,
    required this.minimumStock,
    required this.price,
  });

  final String name;
  final String sku;
  final String category;
  final String unit;
  final String brand;
  final String color;
  final double initialQuantity;
  final double minimumStock;
  final double price;

  void validate() {
    if (name.trim().isEmpty) {
      throw StateError('Informe o nome do item.');
    }
    if (category.trim().isEmpty) {
      throw StateError('Informe a categoria do item.');
    }
    if (unit.trim().isEmpty) {
      throw StateError('Informe a unidade de medida.');
    }
    if (initialQuantity < 0) {
      throw StateError('O estoque inicial nao pode ser negativo.');
    }
    if (minimumStock < 0) {
      throw StateError('O estoque minimo nao pode ser negativo.');
    }
    if (price < 0) {
      throw StateError('O custo unitario nao pode ser negativo.');
    }
  }
}

abstract class ItemsRepository {
  Future<List<InventoryItem>> getItems({
    String query = '',
    ItemStatusFilter status = ItemStatusFilter.all,
    String category = '',
    String unit = '',
    ItemSortOption sort = ItemSortOption.newest,
  });

  Future<InventoryItem> createItem(InventoryItemDraft draft);

  Future<void> updateItem(int id, InventoryItemDraft draft);

  Future<void> deactivateItem(int id);

  Future<void> reactivateItem(int id);
}

class GetItemsUseCase {
  const GetItemsUseCase(this._repository);

  final ItemsRepository _repository;

  Future<List<InventoryItem>> call({
    String query = '',
    ItemStatusFilter status = ItemStatusFilter.all,
    String category = '',
    String unit = '',
    ItemSortOption sort = ItemSortOption.newest,
  }) {
    return _repository.getItems(
      query: query,
      status: status,
      category: category,
      unit: unit,
      sort: sort,
    );
  }
}

class CreateItemUseCase {
  const CreateItemUseCase(this._repository);

  final ItemsRepository _repository;

  Future<InventoryItem> call(InventoryItemDraft draft) {
    return _repository.createItem(draft);
  }
}

class UpdateItemUseCase {
  const UpdateItemUseCase(this._repository);

  final ItemsRepository _repository;

  Future<void> call(int id, InventoryItemDraft draft) {
    return _repository.updateItem(id, draft);
  }
}

class DeactivateItemUseCase {
  const DeactivateItemUseCase(this._repository);

  final ItemsRepository _repository;

  Future<void> call(int id) {
    return _repository.deactivateItem(id);
  }
}

class ReactivateItemUseCase {
  const ReactivateItemUseCase(this._repository);

  final ItemsRepository _repository;

  Future<void> call(int id) {
    return _repository.reactivateItem(id);
  }
}
