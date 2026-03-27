import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../domain/items.dart';

class ItemFormDialog extends StatefulWidget {
  const ItemFormDialog({
    super.key,
    this.item,
    this.availableCategories = const [],
    this.availableUnits = const [],
  });

  final InventoryItem? item;
  final List<String> availableCategories;
  final List<String> availableUnits;

  @override
  State<ItemFormDialog> createState() => _ItemFormDialogState();
}

class _ItemFormDialogState extends State<ItemFormDialog> {
  final _formKey = GlobalKey<FormState>();

  late final TextEditingController _nameController;
  late final TextEditingController _skuController;
  late final TextEditingController _brandController;
  late final TextEditingController _colorController;
  late final TextEditingController _quantityController;
  late final TextEditingController _minimumStockController;
  late final TextEditingController _priceController;

  late final List<String> _categoryOptions;
  late final List<String> _unitOptions;

  String? _selectedCategory;
  String? _selectedUnit;

  bool get _isEditing => widget.item != null;
  bool get _canSubmit => _categoryOptions.isNotEmpty && _unitOptions.isNotEmpty;

  @override
  void initState() {
    super.initState();

    final item = widget.item;
    _nameController = TextEditingController(text: item?.name ?? '');
    _skuController = TextEditingController(text: item?.sku ?? '');
    _brandController = TextEditingController(text: item?.brand ?? '');
    _colorController = TextEditingController(text: item?.color ?? '');
    _quantityController = TextEditingController(
      text: item == null ? '0' : AppFormatters.quantity(item.quantity),
    );
    _minimumStockController = TextEditingController(
      text: item == null ? '0' : AppFormatters.quantity(item.minimumStock),
    );
    _priceController = TextEditingController(
      text: item == null ? '0' : item.price.toStringAsFixed(2),
    );

    _categoryOptions = _normalizeOptions(
      widget.availableCategories,
      fallbackValue: item?.category,
    );
    _unitOptions = _normalizeOptions(
      widget.availableUnits,
      fallbackValue: item?.unit,
    );
    _selectedCategory = _resolveInitialSelection(
      _categoryOptions,
      preferredValue: item?.category,
    );
    _selectedUnit = _resolveInitialSelection(
      _unitOptions,
      preferredValue: item?.unit,
      preferredDefault: 'un',
    );
  }

  @override
  void dispose() {
    _nameController.dispose();
    _skuController.dispose();
    _brandController.dispose();
    _colorController.dispose();
    _quantityController.dispose();
    _minimumStockController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final item = widget.item;

    return AlertDialog(
      title: Text(_isEditing ? 'Editar item' : 'Novo item'),
      content: SizedBox(
        width: 560,
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(labelText: 'Nome do item'),
                  validator: _requiredValidator,
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _skuController,
                        decoration: const InputDecoration(
                          labelText: 'Codigo do item',
                          hintText: 'Opcional',
                          helperText:
                              'Deixe em branco para gerar automaticamente.',
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _brandController,
                        decoration: const InputDecoration(
                          labelText: 'Marca',
                          hintText: 'Opcional',
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _colorController,
                        decoration: const InputDecoration(
                          labelText: 'Cor',
                          hintText: 'Opcional',
                        ),
                      ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: _categoryOptions.isEmpty
                          ? const _MissingSettingField(
                              label: 'Categoria',
                              message:
                                  'Cadastre categorias na tela de configuracoes.',
                            )
                          : DropdownButtonFormField<String>(
                              initialValue: _selectedCategory,
                              decoration: const InputDecoration(
                                labelText: 'Categoria',
                              ),
                              items: [
                                for (final category in _categoryOptions)
                                  DropdownMenuItem(
                                    value: category,
                                    child: Text(category),
                                  ),
                              ],
                              validator: _dropdownRequiredValidator,
                              onChanged: (value) {
                                setState(() {
                                  _selectedCategory = value;
                                });
                              },
                            ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                Row(
                  children: [
                    Expanded(
                      child: _unitOptions.isEmpty
                          ? const _MissingSettingField(
                              label: 'Unidade',
                              message:
                                  'Cadastre unidades na tela de configuracoes.',
                            )
                          : DropdownButtonFormField<String>(
                              initialValue: _selectedUnit,
                              decoration: const InputDecoration(
                                labelText: 'Unidade',
                              ),
                              items: [
                                for (final unit in _unitOptions)
                                  DropdownMenuItem(
                                    value: unit,
                                    child: Text(unit),
                                  ),
                              ],
                              validator: _dropdownRequiredValidator,
                              onChanged: (value) {
                                setState(() {
                                  _selectedUnit = value;
                                });
                              },
                            ),
                    ),
                    const SizedBox(width: 14),
                    Expanded(
                      child: TextFormField(
                        controller: _minimumStockController,
                        decoration: const InputDecoration(
                          labelText: 'Estoque minimo',
                        ),
                        keyboardType: const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        validator: _numberValidator,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 14),
                if (_isEditing && item != null)
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: AppPalette.surfaceMuted,
                      borderRadius: BorderRadius.circular(20),
                      border: Border.all(color: AppPalette.border),
                    ),
                    child: Text(
                      'Estoque atual: ${AppFormatters.quantity(item.quantity)} ${item.unit}. Para alterar o saldo, use a tela de movimentacoes.',
                    ),
                  )
                else
                  TextFormField(
                    controller: _quantityController,
                    decoration: const InputDecoration(
                      labelText: 'Estoque inicial',
                    ),
                    keyboardType: const TextInputType.numberWithOptions(
                      decimal: true,
                    ),
                    validator: _numberValidator,
                  ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _priceController,
                  decoration: const InputDecoration(
                    labelText: 'Valor de custo',
                    prefixText: 'R\$ ',
                  ),
                  keyboardType: const TextInputType.numberWithOptions(
                    decimal: true,
                  ),
                  validator: _numberValidator,
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
          onPressed: _canSubmit ? _submit : null,
          child: Text(_isEditing ? 'Salvar' : 'Cadastrar'),
        ),
      ],
    );
  }

  void _submit() {
    if (!_formKey.currentState!.validate()) {
      return;
    }

    final selectedCategory = _selectedCategory?.trim() ?? '';
    final selectedUnit = _selectedUnit?.trim() ?? '';
    if (selectedCategory.isEmpty || selectedUnit.isEmpty) {
      return;
    }

    final draft = InventoryItemDraft(
      name: _nameController.text.trim(),
      sku: _skuController.text.trim(),
      category: selectedCategory,
      unit: selectedUnit,
      brand: _brandController.text.trim(),
      color: _colorController.text.trim(),
      initialQuantity: _isEditing && widget.item != null
          ? widget.item!.quantity
          : AppFormatters.parseDecimal(_quantityController.text),
      minimumStock: AppFormatters.parseDecimal(_minimumStockController.text),
      price: AppFormatters.parseDecimal(_priceController.text),
    );

    Navigator.of(context).pop(draft);
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatorio';
    }
    return null;
  }

  String? _dropdownRequiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Selecione uma opcao';
    }
    return null;
  }

  String? _numberValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Campo obrigatorio';
    }

    try {
      AppFormatters.parseDecimal(value);
    } catch (_) {
      return 'Numero invalido';
    }

    return null;
  }

  List<String> _normalizeOptions(
    List<String> sourceValues, {
    String? fallbackValue,
  }) {
    final values = <String>{};
    for (final value in sourceValues) {
      final normalizedValue = value.trim();
      if (normalizedValue.isNotEmpty) {
        values.add(normalizedValue);
      }
    }

    final normalizedFallback = (fallbackValue ?? '').trim();
    if (normalizedFallback.isNotEmpty) {
      values.add(normalizedFallback);
    }

    final sortedValues = values.toList()
      ..sort(
        (first, second) => first.toLowerCase().compareTo(second.toLowerCase()),
      );
    return sortedValues;
  }

  String? _resolveInitialSelection(
    List<String> options, {
    String? preferredValue,
    String? preferredDefault,
  }) {
    if (options.isEmpty) {
      return null;
    }

    final normalizedPreferred = (preferredValue ?? '').trim();
    if (normalizedPreferred.isNotEmpty &&
        options.contains(normalizedPreferred)) {
      return normalizedPreferred;
    }

    final normalizedDefault = (preferredDefault ?? '').trim();
    if (normalizedDefault.isNotEmpty && options.contains(normalizedDefault)) {
      return normalizedDefault;
    }

    return options.first;
  }
}

class _MissingSettingField extends StatelessWidget {
  const _MissingSettingField({required this.label, required this.message});

  final String label;
  final String message;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(12, 12, 12, 10),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: AppPalette.border),
        color: AppPalette.surfaceMuted,
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: Theme.of(context).textTheme.labelLarge),
          const SizedBox(height: 8),
          Text(message, style: Theme.of(context).textTheme.bodySmall),
        ],
      ),
    );
  }
}
