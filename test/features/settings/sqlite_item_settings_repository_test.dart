import 'package:flutter_test/flutter_test.dart';
import 'package:stokeasy/core/database/local_database_service.dart';
import 'package:stokeasy/features/items/data/sqlite_items_repository.dart';
import 'package:stokeasy/features/items/domain/items.dart';
import 'package:stokeasy/features/settings/data/sqlite_item_settings_repository.dart';

void main() {
  late LocalDatabaseService databaseService;
  late SqliteItemSettingsRepository repository;
  late SqliteItemsRepository itemsRepository;

  setUp(() {
    databaseService = LocalDatabaseService(inMemory: true);
    repository = SqliteItemSettingsRepository(databaseService);
    itemsRepository = SqliteItemsRepository(databaseService);
  });

  tearDown(() async {
    await databaseService.close();
  });

  test('loads default category and unit in a fresh database', () async {
    final snapshot = await repository.getSnapshot();

    expect(snapshot.categories, contains('Geral'));
    expect(snapshot.units, contains('un'));
  });

  test('adds category and unit and rejects duplicates', () async {
    await repository.addCategory('Ferragens');
    await repository.addUnit('caixa');

    final snapshot = await repository.getSnapshot();
    expect(snapshot.categories, contains('Ferragens'));
    expect(snapshot.units, contains('caixa'));

    expect(
      () => repository.addCategory('ferragens'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Esta categoria ja esta cadastrada.',
        ),
      ),
    );
    expect(
      () => repository.addUnit('CAIXA'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Esta unidade ja esta cadastrada.',
        ),
      ),
    );
  });

  test('prevents removing category and unit that are being used', () async {
    await repository.addCategory('Bebidas');
    await repository.addUnit('garrafa');

    await itemsRepository.createItem(
      const InventoryItemDraft(
        name: 'Agua mineral',
        sku: 'BEB-001',
        category: 'Bebidas',
        unit: 'garrafa',
        initialQuantity: 5,
        minimumStock: 1,
        price: 3.2,
      ),
    );

    expect(
      () => repository.removeCategory('Bebidas'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Nao e possivel remover esta categoria porque ela esta em uso.',
        ),
      ),
    );
    expect(
      () => repository.removeUnit('garrafa'),
      throwsA(
        isA<StateError>().having(
          (error) => error.message,
          'message',
          'Nao e possivel remover esta unidade porque ela esta em uso.',
        ),
      ),
    );
  });
}
