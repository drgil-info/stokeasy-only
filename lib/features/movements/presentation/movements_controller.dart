import 'package:flutter/foundation.dart';

import '../../items/domain/items.dart';
import '../domain/movements.dart';

class MovementsController extends ChangeNotifier {
  MovementsController({
    required GetMovementsUseCase getMovementsUseCase,
    required CreateMovementUseCase createMovementUseCase,
    required GetItemsUseCase getItemsUseCase,
  }) : _getMovementsUseCase = getMovementsUseCase,
       _createMovementUseCase = createMovementUseCase,
       _getItemsUseCase = getItemsUseCase;

  final GetMovementsUseCase _getMovementsUseCase;
  final CreateMovementUseCase _createMovementUseCase;
  final GetItemsUseCase _getItemsUseCase;

  List<InventoryMovement> _movements = const [];
  List<InventoryItem> _availableItems = const [];
  bool _isLoading = false;
  String? _errorMessage;

  List<InventoryMovement> get movements => _movements;
  List<InventoryItem> get availableItems => _availableItems;
  bool get isLoading => _isLoading;
  String? get errorMessage => _errorMessage;

  Future<void> loadData() async {
    _isLoading = true;
    _errorMessage = null;
    notifyListeners();

    try {
      final results = await Future.wait([
        _getMovementsUseCase(limit: 150),
        _getItemsUseCase(status: ItemStatusFilter.active),
      ]);

      _movements = results[0] as List<InventoryMovement>;
      _availableItems = results[1] as List<InventoryItem>;
    } catch (error) {
      _errorMessage = _humanizeError(error);
    } finally {
      _isLoading = false;
      notifyListeners();
    }
  }

  Future<void> createMovement(InventoryMovementDraft draft) async {
    await createMovements([draft]);
  }

  Future<void> createMovements(List<InventoryMovementDraft> drafts) async {
    if (drafts.isEmpty) {
      throw StateError('Selecione ao menos um item para movimentar.');
    }

    var hasChanges = false;
    try {
      for (final draft in drafts) {
        await _createMovementUseCase(draft);
        hasChanges = true;
      }
    } finally {
      if (hasChanges) {
        await loadData();
      }
    }
  }

  String _humanizeError(Object error) {
    if (error is StateError) {
      return error.message;
    }
    return 'Nao foi possivel carregar as movimentacoes.';
  }
}
