import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../items/domain/items.dart';
import '../domain/movements.dart';

class MovementFormDialog extends StatefulWidget {
  const MovementFormDialog({super.key, required this.items});

  final List<InventoryItem> items;

  @override
  State<MovementFormDialog> createState() => _MovementFormDialogState();
}

class _MovementFormDialogState extends State<MovementFormDialog> {
  final _formKey = GlobalKey<FormState>();
  final Map<int, TextEditingController> _quantityControllers = {};

  MovementType _selectedType = MovementType.entry;
  List<InventoryItem> _selectedItems = const [];
  late final TextEditingController _noteController;

  @override
  void initState() {
    super.initState();
    _noteController = TextEditingController();
  }

  @override
  void dispose() {
    for (final controller in _quantityControllers.values) {
      controller.dispose();
    }
    _noteController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final dialogWidth = MediaQuery.sizeOf(context).width * 0.92;

    return AlertDialog(
      title: const Text('Registrar movimentacao'),
      content: SizedBox(
        width: dialogWidth < 720 ? dialogWidth : 720,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _SelectedItemsCard(
                  selectedItems: _selectedItems,
                  onSelectItems: _openItemPicker,
                ),
                const SizedBox(height: 14),
                DropdownButtonFormField<MovementType>(
                  initialValue: _selectedType,
                  decoration: const InputDecoration(
                    labelText: 'Tipo de movimentacao',
                  ),
                  items: MovementType.values
                      .map(
                        (type) => DropdownMenuItem(
                          value: type,
                          child: Text(type.label),
                        ),
                      )
                      .toList(),
                  onChanged: (value) {
                    if (value == null) {
                      return;
                    }
                    setState(() {
                      _selectedType = value;
                    });
                  },
                ),
                const SizedBox(height: 14),
                Text(
                  _selectedType == MovementType.adjustment
                      ? 'Use valor positivo ou negativo para corrigir o saldo de cada item.'
                      : 'Informe a quantidade movimentada em cada item selecionado.',
                  style: Theme.of(context).textTheme.bodySmall,
                ),
                const SizedBox(height: 14),
                if (_selectedItems.isEmpty)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppPalette.surfaceMuted,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppPalette.border),
                    ),
                    child: const Text(
                      'Selecione pelo menos um item para registrar a movimentacao.',
                    ),
                  )
                else
                  _SelectedItemsQuantityList(
                    items: _selectedItems,
                    movementType: _selectedType,
                    quantityControllers: _quantityControllers,
                    quantityValidator: _quantityValidator,
                    onRemoveItem: _removeSelectedItem,
                  ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _noteController,
                  minLines: 3,
                  maxLines: 5,
                  decoration: const InputDecoration(
                    labelText: 'Observacao',
                    hintText: 'Ex.: compra do fornecedor, venda, inventario.',
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton(
          onPressed: _submit,
          child: Text(
            _selectedItems.length <= 1
                ? 'Registrar'
                : 'Registrar ${_selectedItems.length} itens',
          ),
        ),
      ],
    );
  }

  Future<void> _openItemPicker() async {
    final selectedIds = _selectedItems
        .map((item) => item.id)
        .whereType<int>()
        .toSet();
    final result = await showDialog<Set<int>>(
      context: context,
      builder: (context) => _MovementItemPickerDialog(
        items: widget.items,
        initiallySelectedIds: selectedIds,
      ),
    );

    if (result == null) {
      return;
    }

    setState(() {
      _selectedItems = widget.items.where((item) {
        final itemId = item.id;
        return itemId != null && result.contains(itemId);
      }).toList();
      _syncQuantityControllers();
    });
  }

  void _syncQuantityControllers() {
    final selectedIds = _selectedItems.map((item) => item.id).whereType<int>();
    final selectedSet = selectedIds.toSet();

    final removedIds = _quantityControllers.keys
        .where((itemId) => !selectedSet.contains(itemId))
        .toList();
    for (final removedId in removedIds) {
      _quantityControllers.remove(removedId)?.dispose();
    }

    for (final item in _selectedItems) {
      final itemId = item.id;
      if (itemId == null || itemId <= 0) {
        continue;
      }
      _quantityControllers.putIfAbsent(
        itemId,
        () => TextEditingController(text: '1'),
      );
    }
  }

  void _removeSelectedItem(int itemId) {
    setState(() {
      _selectedItems = _selectedItems
          .where((item) => item.id != itemId)
          .toList();
      _quantityControllers.remove(itemId)?.dispose();
    });
  }

  void _submit() {
    if (_selectedItems.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Selecione pelo menos um item para movimentar.'),
          backgroundColor: AppPalette.black,
        ),
      );
      return;
    }

    if (!_formKey.currentState!.validate()) {
      return;
    }

    final drafts = <InventoryMovementDraft>[];
    for (final item in _selectedItems) {
      final itemId = item.id;
      if (itemId == null || itemId <= 0) {
        continue;
      }

      final quantityController = _quantityControllers[itemId];
      if (quantityController == null) {
        continue;
      }

      final quantity = AppFormatters.parseDecimal(quantityController.text);
      drafts.add(
        InventoryMovementDraft(
          itemId: itemId,
          type: _selectedType,
          quantity: quantity,
          note: _noteController.text.trim(),
        ),
      );
    }

    if (drafts.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Nao foi possivel montar as movimentacoes selecionadas.',
          ),
          backgroundColor: AppPalette.black,
        ),
      );
      return;
    }

    Navigator.of(context).pop(drafts);
  }

  String? _quantityValidator(String? value, InventoryItem item) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatorio';
    }

    try {
      final parsed = AppFormatters.parseDecimal(value);
      if (_selectedType == MovementType.adjustment) {
        if (parsed == 0) {
          return 'Use um ajuste diferente de zero';
        }
        final projectedQuantity = item.quantity + parsed;
        if (projectedQuantity < 0) {
          return 'Ajuste deixa o estoque negativo';
        }
      } else if (parsed <= 0) {
        return 'Use um valor maior que zero';
      } else if (_selectedType == MovementType.exit && parsed > item.quantity) {
        return 'Saldo insuficiente';
      }
    } catch (_) {
      return 'Numero invalido';
    }

    return null;
  }
}

class _SelectedItemsCard extends StatelessWidget {
  const _SelectedItemsCard({
    required this.selectedItems,
    required this.onSelectItems,
  });

  final List<InventoryItem> selectedItems;
  final VoidCallback onSelectItems;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppPalette.surfaceMuted,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: AppPalette.border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  selectedItems.isEmpty
                      ? 'Nenhum item selecionado'
                      : '${selectedItems.length} ${selectedItems.length == 1 ? 'item selecionado' : 'itens selecionados'}',
                  style: Theme.of(context).textTheme.titleSmall,
                ),
              ),
              OutlinedButton.icon(
                onPressed: onSelectItems,
                icon: const Icon(Icons.playlist_add_check_rounded),
                label: Text(
                  selectedItems.isEmpty ? 'Selecionar itens' : 'Alterar itens',
                ),
              ),
            ],
          ),
          if (selectedItems.isNotEmpty) ...[
            const SizedBox(height: 8),
            Text(
              'Use busca e filtros para encontrar os itens mais rapido.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ],
      ),
    );
  }
}

class _SelectedItemsQuantityList extends StatelessWidget {
  const _SelectedItemsQuantityList({
    required this.items,
    required this.movementType,
    required this.quantityControllers,
    required this.quantityValidator,
    required this.onRemoveItem,
  });

  final List<InventoryItem> items;
  final MovementType movementType;
  final Map<int, TextEditingController> quantityControllers;
  final String? Function(String? value, InventoryItem item) quantityValidator;
  final ValueChanged<int> onRemoveItem;

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        for (var index = 0; index < items.length; index++) ...[
          _SelectedItemQuantityTile(
            item: items[index],
            movementType: movementType,
            quantityController: quantityControllers[items[index].id ?? -1],
            quantityValidator: quantityValidator,
            onRemove: () {
              final itemId = items[index].id;
              if (itemId == null || itemId <= 0) {
                return;
              }
              onRemoveItem(itemId);
            },
          ),
          if (index < items.length - 1) const SizedBox(height: 12),
        ],
      ],
    );
  }
}

class _SelectedItemQuantityTile extends StatelessWidget {
  const _SelectedItemQuantityTile({
    required this.item,
    required this.movementType,
    required this.quantityController,
    required this.quantityValidator,
    required this.onRemove,
  });

  final InventoryItem item;
  final MovementType movementType;
  final TextEditingController? quantityController;
  final String? Function(String? value, InventoryItem item) quantityValidator;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: AppPalette.border),
      ),
      child: LayoutBuilder(
        builder: (context, constraints) {
          final compact = constraints.maxWidth < 560;
          final info = Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(item.name, style: Theme.of(context).textTheme.titleSmall),
              const SizedBox(height: 4),
              Text(
                '${item.sku} | ${item.category}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 6),
              Text(
                'Saldo atual: ${AppFormatters.quantity(item.quantity)} ${item.unit}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
          );

          final quantityField = SizedBox(
            width: compact ? double.infinity : 210,
            child: TextFormField(
              controller: quantityController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
                signed: true,
              ),
              decoration: InputDecoration(
                labelText: movementType == MovementType.adjustment
                    ? 'Ajuste (${item.unit})'
                    : 'Quantidade (${item.unit})',
              ),
              validator: (value) => quantityValidator(value, item),
            ),
          );

          final removeButton = IconButton.filledTonal(
            onPressed: onRemove,
            icon: const Icon(Icons.close_rounded),
            tooltip: 'Remover item da movimentacao',
          );

          if (compact) {
            return Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(child: info),
                    const SizedBox(width: 8),
                    removeButton,
                  ],
                ),
                const SizedBox(height: 12),
                quantityField,
              ],
            );
          }

          return Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Expanded(child: info),
              const SizedBox(width: 12),
              quantityField,
              const SizedBox(width: 8),
              removeButton,
            ],
          );
        },
      ),
    );
  }
}

class _MovementItemPickerDialog extends StatefulWidget {
  const _MovementItemPickerDialog({
    required this.items,
    required this.initiallySelectedIds,
  });

  final List<InventoryItem> items;
  final Set<int> initiallySelectedIds;

  @override
  State<_MovementItemPickerDialog> createState() =>
      _MovementItemPickerDialogState();
}

class _MovementItemPickerDialogState extends State<_MovementItemPickerDialog> {
  late final TextEditingController _searchController;
  late final Set<int> _selectedIds;

  String _categoryFilter = '';
  String _unitFilter = '';

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController();
    _selectedIds = {...widget.initiallySelectedIds};
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  List<String> get _availableCategories =>
      _collectDistinctValues(widget.items.map((item) => item.category));
  List<String> get _availableUnits =>
      _collectDistinctValues(widget.items.map((item) => item.unit));

  List<InventoryItem> get _filteredItems {
    final query = _searchController.text.trim().toLowerCase();
    return widget.items.where((item) {
      if (_categoryFilter.isNotEmpty && item.category != _categoryFilter) {
        return false;
      }
      if (_unitFilter.isNotEmpty && item.unit != _unitFilter) {
        return false;
      }
      if (query.isEmpty) {
        return true;
      }

      return item.name.toLowerCase().contains(query) ||
          item.sku.toLowerCase().contains(query) ||
          item.category.toLowerCase().contains(query);
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    final filteredItems = _filteredItems;
    final screenSize = MediaQuery.sizeOf(context);
    final dialogWidth = screenSize.width * 0.92;
    final listHeight = screenSize.height * 0.5;

    return AlertDialog(
      title: const Text('Selecionar itens'),
      content: SizedBox(
        width: dialogWidth < 800 ? dialogWidth : 800,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            TextField(
              controller: _searchController,
              onChanged: (_) => setState(() {}),
              decoration: const InputDecoration(
                prefixIcon: Icon(Icons.search_rounded),
                hintText: 'Buscar por nome, codigo ou categoria',
              ),
            ),
            const SizedBox(height: 14),
            Wrap(
              spacing: 12,
              runSpacing: 12,
              children: [
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    initialValue: _categoryFilter.isEmpty
                        ? null
                        : _categoryFilter,
                    decoration: const InputDecoration(labelText: 'Categoria'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Todas')),
                      for (final category in _availableCategories)
                        DropdownMenuItem(
                          value: category,
                          child: Text(category),
                        ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _categoryFilter = value ?? '';
                      });
                    },
                  ),
                ),
                SizedBox(
                  width: 220,
                  child: DropdownButtonFormField<String>(
                    initialValue: _unitFilter.isEmpty ? null : _unitFilter,
                    decoration: const InputDecoration(labelText: 'Unidade'),
                    items: [
                      const DropdownMenuItem(value: '', child: Text('Todas')),
                      for (final unit in _availableUnits)
                        DropdownMenuItem(value: unit, child: Text(unit)),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _unitFilter = value ?? '';
                      });
                    },
                  ),
                ),
                OutlinedButton.icon(
                  onPressed: _clearFilters,
                  icon: const Icon(Icons.filter_alt_off_rounded),
                  label: const Text('Limpar filtros'),
                ),
              ],
            ),
            const SizedBox(height: 12),
            Text(
              '${filteredItems.length} itens encontrados | ${_selectedIds.length} selecionados',
              style: Theme.of(context).textTheme.bodySmall,
            ),
            const SizedBox(height: 10),
            SizedBox(
              height: listHeight < 360 ? listHeight : 360,
              child: filteredItems.isEmpty
                  ? Center(
                      child: Text(
                        'Nenhum item encontrado para os filtros aplicados.',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    )
                  : ListView.separated(
                      itemCount: filteredItems.length,
                      separatorBuilder: (context, index) =>
                          const Divider(height: 1),
                      itemBuilder: (context, index) {
                        final item = filteredItems[index];
                        final itemId = item.id ?? -1;
                        final selectable = itemId > 0;
                        final isSelected =
                            selectable && _selectedIds.contains(itemId);

                        return CheckboxListTile(
                          value: isSelected,
                          onChanged: selectable
                              ? (selected) =>
                                    _toggleSelection(itemId, selected ?? false)
                              : null,
                          title: Text(item.name),
                          subtitle: Text(
                            '${item.sku} | ${item.category} | Saldo: ${AppFormatters.quantity(item.quantity)} ${item.unit}',
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                        );
                      },
                    ),
            ),
          ],
        ),
      ),
      actions: [
        TextButton(
          onPressed: () => Navigator.of(context).pop(),
          child: const Text('Cancelar'),
        ),
        FilledButton.icon(
          onPressed: () => Navigator.of(context).pop(_selectedIds),
          icon: const Icon(Icons.check_rounded),
          label: Text(
            _selectedIds.length == 1
                ? 'Selecionar 1 item'
                : 'Selecionar ${_selectedIds.length} itens',
          ),
        ),
      ],
    );
  }

  void _toggleSelection(int itemId, bool selected) {
    setState(() {
      if (selected) {
        _selectedIds.add(itemId);
      } else {
        _selectedIds.remove(itemId);
      }
    });
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _categoryFilter = '';
      _unitFilter = '';
    });
  }

  List<String> _collectDistinctValues(Iterable<String> values) {
    final normalized =
        values
            .map((value) => value.trim())
            .where((value) => value.isNotEmpty)
            .toSet()
            .toList()
          ..sort();
    return normalized;
  }
}
