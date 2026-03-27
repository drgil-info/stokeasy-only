import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
import '../../../shared/widgets/app_surface_card.dart';
import '../../../shared/widgets/empty_state_card.dart';
import '../../../shared/widgets/page_header.dart';
import 'settings_controller.dart';

class SettingsPage extends StatefulWidget {
  const SettingsPage({super.key, required this.controller});

  final SettingsController controller;

  @override
  State<SettingsPage> createState() => _SettingsPageState();
}

class _SettingsPageState extends State<SettingsPage> {
  late final TextEditingController _categoryController;
  late final TextEditingController _unitController;

  @override
  void initState() {
    super.initState();
    _categoryController = TextEditingController();
    _unitController = TextEditingController();
  }

  @override
  void dispose() {
    _categoryController.dispose();
    _unitController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: widget.controller,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Configuracoes',
                subtitle:
                    'Cadastre as categorias e unidades de medida que serao usadas no cadastro de itens.',
              ),
              const SizedBox(height: 24),
              if (widget.controller.errorMessage != null)
                Padding(
                  padding: const EdgeInsets.only(bottom: 16),
                  child: Text(
                    widget.controller.errorMessage!,
                    style: const TextStyle(color: AppPalette.black),
                  ),
                ),
              if (widget.controller.isLoading &&
                  widget.controller.categories.isEmpty &&
                  widget.controller.units.isEmpty)
                const Center(
                  child: Padding(
                    padding: EdgeInsets.symmetric(vertical: 36),
                    child: CircularProgressIndicator(),
                  ),
                )
              else
                LayoutBuilder(
                  builder: (context, constraints) {
                    final compact = constraints.maxWidth < 980;

                    final categoryCard = _SettingsValuesCard(
                      title: 'Categorias',
                      subtitle:
                          'Defina os tipos de categoria para escolha rapida no cadastro dos itens.',
                      fieldLabel: 'Nova categoria',
                      fieldHint: 'Ex.: Limpeza, Escritorio, Alimentos',
                      addButtonLabel: 'Adicionar categoria',
                      controller: _categoryController,
                      values: widget.controller.categories,
                      emptyMessage:
                          'Nenhuma categoria cadastrada. Adicione a primeira para liberar o cadastro de itens.',
                      onAddPressed: _addCategory,
                      onRemovePressed: _removeCategory,
                    );

                    final unitCard = _SettingsValuesCard(
                      title: 'Unidades de medida',
                      subtitle:
                          'Cadastre as unidades que poderao ser selecionadas no cadastro dos itens.',
                      fieldLabel: 'Nova unidade',
                      fieldHint: 'Ex.: un, kg, caixa, litro',
                      addButtonLabel: 'Adicionar unidade',
                      controller: _unitController,
                      values: widget.controller.units,
                      emptyMessage:
                          'Nenhuma unidade cadastrada. Adicione pelo menos uma para cadastrar itens.',
                      onAddPressed: _addUnit,
                      onRemovePressed: _removeUnit,
                    );

                    if (compact) {
                      return Column(
                        children: [
                          categoryCard,
                          const SizedBox(height: 16),
                          unitCard,
                        ],
                      );
                    }

                    return Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Expanded(child: categoryCard),
                        const SizedBox(width: 16),
                        Expanded(child: unitCard),
                      ],
                    );
                  },
                ),
            ],
          ),
        );
      },
    );
  }

  Future<void> _addCategory() async {
    final value = _categoryController.text;

    try {
      await widget.controller.addCategory(value);
      _categoryController.clear();
      if (!mounted) {
        return;
      }
      _showMessage('Categoria cadastrada com sucesso.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_humanizeError(error), error: true);
    }
  }

  Future<void> _removeCategory(String category) async {
    final confirmed = await _confirmRemoval(
      title: 'Remover categoria',
      content:
          'Deseja remover "$category"? A categoria precisa estar sem uso para ser excluida.',
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await widget.controller.removeCategory(category);
      if (!mounted) {
        return;
      }
      _showMessage('Categoria removida.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_humanizeError(error), error: true);
    }
  }

  Future<void> _addUnit() async {
    final value = _unitController.text;

    try {
      await widget.controller.addUnit(value);
      _unitController.clear();
      if (!mounted) {
        return;
      }
      _showMessage('Unidade cadastrada com sucesso.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_humanizeError(error), error: true);
    }
  }

  Future<void> _removeUnit(String unit) async {
    final confirmed = await _confirmRemoval(
      title: 'Remover unidade',
      content:
          'Deseja remover "$unit"? A unidade precisa estar sem uso para ser excluida.',
    );
    if (confirmed != true || !mounted) {
      return;
    }

    try {
      await widget.controller.removeUnit(unit);
      if (!mounted) {
        return;
      }
      _showMessage('Unidade removida.');
    } catch (error) {
      if (!mounted) {
        return;
      }
      _showMessage(_humanizeError(error), error: true);
    }
  }

  Future<bool?> _confirmRemoval({
    required String title,
    required String content,
  }) {
    return showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text(title),
          content: Text(content),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Remover'),
            ),
          ],
        );
      },
    );
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
}

class _SettingsValuesCard extends StatelessWidget {
  const _SettingsValuesCard({
    required this.title,
    required this.subtitle,
    required this.fieldLabel,
    required this.fieldHint,
    required this.addButtonLabel,
    required this.controller,
    required this.values,
    required this.emptyMessage,
    required this.onAddPressed,
    required this.onRemovePressed,
  });

  final String title;
  final String subtitle;
  final String fieldLabel;
  final String fieldHint;
  final String addButtonLabel;
  final TextEditingController controller;
  final List<String> values;
  final String emptyMessage;
  final Future<void> Function() onAddPressed;
  final Future<void> Function(String value) onRemovePressed;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(subtitle, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 18),
          TextField(
            controller: controller,
            onSubmitted: (_) => onAddPressed(),
            decoration: InputDecoration(
              labelText: fieldLabel,
              hintText: fieldHint,
            ),
          ),
          const SizedBox(height: 12),
          FilledButton.icon(
            onPressed: onAddPressed,
            icon: const Icon(Icons.add_rounded),
            label: Text(addButtonLabel),
          ),
          const SizedBox(height: 18),
          Text(
            'Cadastros ativos: ${values.length}',
            style: Theme.of(context).textTheme.bodySmall,
          ),
          const SizedBox(height: 12),
          if (values.isEmpty)
            EmptyStateCard(
              icon: Icons.tune_rounded,
              title: 'Sem registros',
              message: emptyMessage,
            )
          else
            Column(
              children: [
                for (var index = 0; index < values.length; index++) ...[
                  _ValueTile(
                    value: values[index],
                    onRemove: () => onRemovePressed(values[index]),
                  ),
                  if (index < values.length - 1) const Divider(height: 20),
                ],
              ],
            ),
        ],
      ),
    );
  }
}

class _ValueTile extends StatelessWidget {
  const _ValueTile({required this.value, required this.onRemove});

  final String value;
  final VoidCallback onRemove;

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Expanded(
          child: Text(value, style: Theme.of(context).textTheme.titleMedium),
        ),
        IconButton.filledTonal(
          onPressed: onRemove,
          icon: const Icon(Icons.delete_outline_rounded),
          tooltip: 'Remover',
        ),
      ],
    );
  }
}
