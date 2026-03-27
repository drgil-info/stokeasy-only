import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/app_surface_card.dart';
import '../../../shared/widgets/empty_state_card.dart';
import '../../../shared/widgets/metric_card.dart';
import '../../../shared/widgets/page_header.dart';
import '../../../shared/widgets/status_chip.dart';
import '../../settings/presentation/settings_controller.dart';
import '../domain/items.dart';
import 'item_form_dialog.dart';
import 'items_controller.dart';

class ItemsPage extends StatefulWidget {
  const ItemsPage({
    super.key,
    required this.controller,
    required this.settingsController,
    required this.onInventoryChanged,
  });

  final ItemsController controller;
  final SettingsController settingsController;
  final Future<void> Function() onInventoryChanged;

  @override
  State<ItemsPage> createState() => _ItemsPageState();
}

class _ItemsPageState extends State<ItemsPage> {
  late final TextEditingController _searchController;

  static const _statusOptions = [
    (ItemStatusFilter.all, 'Todos'),
    (ItemStatusFilter.active, 'Ativos'),
    (ItemStatusFilter.inactive, 'Inativos'),
  ];

  static const _sortOptions = [
    (ItemSortOption.nameAsc, 'Nome A-Z'),
    (ItemSortOption.newest, 'Mais recentes'),
    (ItemSortOption.highestStock, 'Maior estoque'),
    (ItemSortOption.lowestStock, 'Menor estoque'),
    (ItemSortOption.highestValue, 'Maior valor'),
  ];

  @override
  void initState() {
    super.initState();
    _searchController = TextEditingController(
      text: widget.controller.searchQuery,
    );
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: Listenable.merge([
        widget.controller,
        widget.settingsController,
      ]),
      builder: (context, child) {
        final items = widget.controller.items;
        final activeItems = items.where((item) => item.isActive).toList();
        final totalValue = activeItems.fold<double>(
          0,
          (sum, item) => sum + item.stockValue,
        );
        final lowStockCount = activeItems
            .where((item) => item.isLowStock)
            .length;

        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              PageHeader(
                title: 'Itens',
                subtitle:
                    'Cadastre produtos, acompanhe nivel de estoque e mantenha a base pronta para crescer.',
                actions: [
                  FilledButton.icon(
                    onPressed: _openCreateDialog,
                    icon: const Icon(Icons.add_rounded),
                    label: const Text('Novo item'),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final availableWidth = constraints.maxWidth;
                  final columns = availableWidth > 1200
                      ? 3
                      : availableWidth > 760
                      ? 2
                      : 1;
                  final cardWidth =
                      (availableWidth - ((columns - 1) * 16)) / columns;

                  return Wrap(
                    spacing: 16,
                    runSpacing: 16,
                    children: [
                      SizedBox(
                        width: cardWidth,
                        child: MetricCard(
                          title: 'Itens cadastrados',
                          value: '${activeItems.length}',
                          subtitle: 'Itens ativos na operacao',
                          icon: Icons.inventory_2_rounded,
                          accentColor: AppPalette.gold,
                          highlight: true,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: MetricCard(
                          title: 'Itens abaixo do minimo',
                          value: '$lowStockCount',
                          subtitle: 'Acompanhe alertas criticos',
                          icon: Icons.warning_amber_rounded,
                          accentColor: AppPalette.black,
                        ),
                      ),
                      SizedBox(
                        width: cardWidth,
                        child: MetricCard(
                          title: 'Valor em estoque',
                          value: AppFormatters.currency(totalValue),
                          subtitle: 'Com base no custo unitario',
                          icon: Icons.payments_rounded,
                          accentColor: AppPalette.navy,
                        ),
                      ),
                    ],
                  );
                },
              ),
              const SizedBox(height: 24),
              AppSurfaceCard(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            'Catalogo de itens',
                            style: Theme.of(context).textTheme.titleLarge,
                          ),
                        ),
                        if (widget.controller.isLoading)
                          const SizedBox(
                            width: 22,
                            height: 22,
                            child: CircularProgressIndicator(strokeWidth: 2.2),
                          ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      onChanged: (value) {
                        widget.controller.loadItems(query: value);
                      },
                      decoration: const InputDecoration(
                        prefixIcon: Icon(Icons.search_rounded),
                        hintText:
                            'Buscar por nome, codigo, categoria, marca ou cor',
                      ),
                    ),
                    const SizedBox(height: 16),
                    Wrap(
                      spacing: 12,
                      runSpacing: 12,
                      children: [
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<ItemStatusFilter>(
                            initialValue: widget.controller.statusFilter,
                            decoration: const InputDecoration(
                              labelText: 'Status do item',
                            ),
                            items: [
                              for (final option in _statusOptions)
                                DropdownMenuItem(
                                  value: option.$1,
                                  child: Text(option.$2),
                                ),
                            ],
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              widget.controller.loadItems(status: value);
                            },
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<String>(
                            initialValue:
                                widget.controller.categoryFilter.isEmpty
                                ? null
                                : widget.controller.categoryFilter,
                            decoration: const InputDecoration(
                              labelText: 'Categoria',
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: '',
                                child: Text('Todas'),
                              ),
                              for (final category
                                  in widget.controller.availableCategories)
                                DropdownMenuItem(
                                  value: category,
                                  child: Text(category),
                                ),
                            ],
                            onChanged: (value) {
                              widget.controller.loadItems(
                                category: value ?? '',
                              );
                            },
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<String>(
                            initialValue: widget.controller.unitFilter.isEmpty
                                ? null
                                : widget.controller.unitFilter,
                            decoration: const InputDecoration(
                              labelText: 'Unidade',
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: '',
                                child: Text('Todas'),
                              ),
                              for (final unit
                                  in widget.controller.availableUnits)
                                DropdownMenuItem(
                                  value: unit,
                                  child: Text(unit),
                                ),
                            ],
                            onChanged: (value) {
                              widget.controller.loadItems(unit: value ?? '');
                            },
                          ),
                        ),
                        SizedBox(
                          width: 220,
                          child: DropdownButtonFormField<ItemSortOption>(
                            initialValue: widget.controller.sortOption,
                            decoration: const InputDecoration(
                              labelText: 'Ordenacao',
                            ),
                            items: [
                              for (final option in _sortOptions)
                                DropdownMenuItem(
                                  value: option.$1,
                                  child: Text(option.$2),
                                ),
                            ],
                            onChanged: (value) {
                              if (value == null) {
                                return;
                              }
                              widget.controller.loadItems(sort: value);
                            },
                          ),
                        ),
                        OutlinedButton.icon(
                          onPressed: () {
                            _searchController.clear();
                            widget.controller.clearFilters();
                          },
                          icon: const Icon(Icons.filter_alt_off_rounded),
                          label: const Text('Limpar filtros'),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Itens inativos permanecem salvos para preservar historico e relatorios.',
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                    const SizedBox(height: 20),
                    if (widget.controller.errorMessage != null)
                      Padding(
                        padding: const EdgeInsets.only(bottom: 16),
                        child: Text(
                          widget.controller.errorMessage!,
                          style: const TextStyle(color: AppPalette.black),
                        ),
                      ),
                    if (items.isEmpty)
                      EmptyStateCard(
                        icon: Icons.inventory_2_outlined,
                        title: 'Nenhum item cadastrado',
                        message:
                            'Comece pelo cadastro do primeiro item para alimentar dashboard, relatorios e movimentacoes.',
                        action: FilledButton.icon(
                          onPressed: _openCreateDialog,
                          icon: const Icon(Icons.add_rounded),
                          label: const Text('Cadastrar item'),
                        ),
                      )
                    else
                      Column(
                        children: [
                          for (
                            var index = 0;
                            index < items.length;
                            index++
                          ) ...[
                            _ItemTile(
                              item: items[index],
                              onEdit: () => _openEditDialog(items[index]),
                              onToggleStatus: () =>
                                  _toggleItemStatus(items[index]),
                            ),
                            if (index < items.length - 1)
                              const Divider(height: 28),
                          ],
                        ],
                      ),
                  ],
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _openCreateDialog() async {
    await _loadSettingsIfNeeded();
    if (!mounted) {
      return;
    }

    final categories = _categoryOptionsForForm();
    final units = _unitOptionsForForm();
    if (categories.isEmpty || units.isEmpty) {
      _showMessage(
        'Cadastre pelo menos uma categoria e uma unidade em Configuracoes.',
        error: true,
      );
      return;
    }

    final draft = await showDialog<InventoryItemDraft>(
      context: context,
      builder: (context) => ItemFormDialog(
        availableCategories: categories,
        availableUnits: units,
      ),
    );

    if (draft == null || !mounted) {
      return;
    }

    try {
      await widget.controller.createItem(draft);
      await widget.onInventoryChanged();
      if (!mounted) {
        return;
      }
      _showMessage('Item cadastrado com sucesso.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_humanizeError(error), error: true);
    }
  }

  Future<void> _openEditDialog(InventoryItem item) async {
    await _loadSettingsIfNeeded();
    if (!mounted) {
      return;
    }

    final draft = await showDialog<InventoryItemDraft>(
      context: context,
      builder: (context) => ItemFormDialog(
        item: item,
        availableCategories: _categoryOptionsForForm(item: item),
        availableUnits: _unitOptionsForForm(item: item),
      ),
    );

    if (draft == null || !mounted || item.id == null) {
      return;
    }

    try {
      await widget.controller.updateItem(item.id!, draft);
      await widget.onInventoryChanged();
      if (!mounted) {
        return;
      }
      _showMessage('Item atualizado com sucesso.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_humanizeError(error), error: true);
    }
  }

  Future<void> _toggleItemStatus(InventoryItem item) async {
    if (item.id == null) {
      return;
    }

    if (item.isActive) {
      final shouldDeactivate = await showDialog<bool>(
        context: context,
        builder: (context) {
          return AlertDialog(
            title: const Text('Inativar item'),
            content: Text(
              'Deseja inativar "${item.name}"?\n\n'
              'O historico sera preservado e o item nao podera receber novas movimentacoes enquanto estiver inativo.\n'
              'Para seguranca, somente itens com estoque zerado podem ser inativados.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.of(context).pop(false),
                child: const Text('Cancelar'),
              ),
              FilledButton(
                onPressed: () => Navigator.of(context).pop(true),
                child: const Text('Inativar'),
              ),
            ],
          );
        },
      );

      if (shouldDeactivate != true || !mounted) {
        return;
      }

      try {
        await widget.controller.deactivateItem(item.id!);
        await widget.onInventoryChanged();
        if (!mounted) {
          return;
        }
        _showMessage('Item inativado com sucesso.');
      } catch (error) {
        if (!mounted) {
          return;
        }
        _showMessage(_humanizeError(error), error: true);
      }
      return;
    }

    try {
      await widget.controller.reactivateItem(item.id!);
      await widget.onInventoryChanged();
      if (!mounted) {
        return;
      }
      _showMessage('Item reativado com sucesso.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_humanizeError(error), error: true);
    }
  }

  void _showMessage(String message, {bool error = false}) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? AppPalette.black : AppPalette.navy,
      ),
    );
  }

  String _humanizeError(Object error) {
    if (error is StateError) {
      return error.message;
    }
    return 'Nao foi possivel concluir a operacao.';
  }

  Future<void> _loadSettingsIfNeeded() async {
    if (widget.settingsController.categories.isNotEmpty &&
        widget.settingsController.units.isNotEmpty) {
      return;
    }

    await widget.settingsController.load();
  }

  List<String> _categoryOptionsForForm({InventoryItem? item}) {
    return _mergedOptions(
      primaryValues: widget.settingsController.categories,
      fallbackValue: item?.category,
    );
  }

  List<String> _unitOptionsForForm({InventoryItem? item}) {
    return _mergedOptions(
      primaryValues: widget.settingsController.units,
      fallbackValue: item?.unit,
    );
  }

  List<String> _mergedOptions({
    required List<String> primaryValues,
    String? fallbackValue,
  }) {
    final normalizedValues = <String>{};

    for (final value in primaryValues) {
      final normalizedValue = value.trim();
      if (normalizedValue.isNotEmpty) {
        normalizedValues.add(normalizedValue);
      }
    }

    final normalizedFallback = (fallbackValue ?? '').trim();
    if (normalizedFallback.isNotEmpty) {
      normalizedValues.add(normalizedFallback);
    }

    final sortedValues = normalizedValues.toList()
      ..sort(
        (first, second) => first.toLowerCase().compareTo(second.toLowerCase()),
      );
    return sortedValues;
  }
}

class _ItemTile extends StatelessWidget {
  const _ItemTile({
    required this.item,
    required this.onEdit,
    required this.onToggleStatus,
  });

  final InventoryItem item;
  final VoidCallback onEdit;
  final VoidCallback onToggleStatus;

  @override
  Widget build(BuildContext context) {
    final isInactive = !item.isActive;
    final statusColor = isInactive
        ? AppPalette.navy
        : item.isLowStock
        ? AppPalette.gold
        : AppPalette.black;
    final statusLabel = isInactive
        ? 'Inativo'
        : item.isLowStock
        ? 'Abaixo do minimo'
        : 'Estoque saudavel';

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 860;

        final info = Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(item.name, style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 6),
            Text(
              '${item.sku} | ${item.category}',
              style: Theme.of(context).textTheme.bodyMedium,
            ),
            if (item.brand.trim().isNotEmpty || item.color.trim().isNotEmpty)
              Padding(
                padding: const EdgeInsets.only(top: 6),
                child: Text(
                  _metadataLine(item),
                  style: Theme.of(context).textTheme.bodySmall,
                ),
              ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                StatusChip(label: statusLabel, color: statusColor),
                StatusChip(
                  label:
                      '${AppFormatters.quantity(item.quantity)} ${item.unit} em estoque',
                  color: AppPalette.gold,
                  icon: Icons.inventory_rounded,
                ),
              ],
            ),
          ],
        );

        final details = Wrap(
          alignment: WrapAlignment.end,
          crossAxisAlignment: WrapCrossAlignment.center,
          spacing: 12,
          runSpacing: 12,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  AppFormatters.currency(item.stockValue),
                  style: Theme.of(context).textTheme.titleMedium,
                ),
                const SizedBox(height: 6),
                Text(
                  'Minimo: ${AppFormatters.quantity(item.minimumStock)} ${item.unit}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
              ],
            ),
            IconButton.filledTonal(
              onPressed: onEdit,
              icon: const Icon(Icons.edit_rounded),
              tooltip: 'Editar item',
            ),
            IconButton.filledTonal(
              onPressed: onToggleStatus,
              icon: Icon(
                isInactive
                    ? Icons.restart_alt_rounded
                    : Icons.inventory_2_outlined,
              ),
              tooltip: isInactive ? 'Reativar item' : 'Inativar item',
            ),
          ],
        );

        if (compact) {
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [info, const SizedBox(height: 16), details],
          );
        }

        return Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(child: info),
            const SizedBox(width: 20),
            details,
          ],
        );
      },
    );
  }

  String _metadataLine(InventoryItem item) {
    final parts = <String>[];
    if (item.brand.trim().isNotEmpty) {
      parts.add('Marca: ${item.brand}');
    }
    if (item.color.trim().isNotEmpty) {
      parts.add('Cor: ${item.color}');
    }
    return parts.join(' | ');
  }
}
