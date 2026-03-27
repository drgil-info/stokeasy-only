import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
import '../../../core/utils/formatters.dart';
import '../../../shared/widgets/empty_state_card.dart';
import '../../../shared/widgets/status_chip.dart';
import '../domain/stock_counts.dart';

class CountsSessionPanel extends StatelessWidget {
  const CountsSessionPanel({
    super.key,
    required this.counts,
    required this.selectedCountId,
    required this.isLoading,
    required this.isBusy,
    required this.onCreate,
    required this.onSelectCount,
  });

  final List<StockCountSession> counts;
  final int? selectedCountId;
  final bool isLoading;
  final bool isBusy;
  final Future<void> Function() onCreate;
  final Future<void> Function(int countId) onSelectCount;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Expanded(
              child: Text(
                'Sessoes de contagem',
                style: Theme.of(context).textTheme.titleLarge,
              ),
            ),
            if (isLoading)
              const SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(strokeWidth: 2.2),
              ),
          ],
        ),
        const SizedBox(height: 8),
        Text(
          'Escolha uma sessao para abrir os dados completos da contagem, com itens, divergencias e exportacoes.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        const SizedBox(height: 18),
        if (counts.isEmpty)
          EmptyStateCard(
            icon: Icons.fact_check_outlined,
            title: 'Nenhuma contagem aberta ainda',
            message:
                'Abra a primeira contagem para listar todos os itens ativos e acompanhar divergencias.',
            action: FilledButton.icon(
              onPressed: isBusy ? null : onCreate,
              icon: const Icon(Icons.fact_check_rounded),
              label: const Text('Abrir contagem'),
            ),
          )
        else
          Column(
            children: [
              for (var index = 0; index < counts.length; index++) ...[
                CountSessionTile(
                  session: counts[index],
                  selected: counts[index].id == selectedCountId,
                  enabled: !isBusy,
                  onTap: () => onSelectCount(counts[index].id!),
                ),
                if (index < counts.length - 1) const Divider(height: 28),
              ],
            ],
          ),
      ],
    );
  }
}

class CountDetailsPanel extends StatelessWidget {
  const CountDetailsPanel({
    super.key,
    required this.session,
    required this.lines,
    required this.lineFilter,
    required this.isBusy,
    required this.searchController,
    required this.onLineFilterChanged,
    required this.onLineSearchChanged,
    required this.onExportWorksheet,
    required this.onExportResult,
    required this.onCloseCount,
    required this.onOpenLine,
    required this.onToggleLineSelection,
  });

  final StockCountSession? session;
  final List<StockCountLine> lines;
  final StockCountLineFilter lineFilter;
  final bool isBusy;
  final TextEditingController searchController;
  final ValueChanged<StockCountLineFilter> onLineFilterChanged;
  final ValueChanged<String> onLineSearchChanged;
  final Future<void> Function() onExportWorksheet;
  final Future<void> Function() onExportResult;
  final Future<void> Function() onCloseCount;
  final Future<void> Function(StockCountLine line) onOpenLine;
  final Future<void> Function(StockCountLine line, bool selected)
  onToggleLineSelection;

  @override
  Widget build(BuildContext context) {
    final currentSession = session;
    if (currentSession == null) {
      return const EmptyStateCard(
        icon: Icons.fact_check_rounded,
        title: 'Selecione uma contagem',
        message:
            'Abra ou escolha uma sessao no painel ao lado para conferir os itens, revisar divergencias e exportar PDFs.',
      );
    }

    final showSystemValues =
        !currentSession.blindMode || !currentSession.isOpen;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        LayoutBuilder(
          builder: (context, constraints) {
            final compact = constraints.maxWidth < 860;

            final headerText = Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  currentSession.name,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 6),
                Text(
                  'Aberta por ${currentSession.openedBy} em ${AppFormatters.dateTime(currentSession.openedAt)}',
                  style: Theme.of(context).textTheme.bodyMedium,
                ),
                if (currentSession.closedAt != null) ...[
                  const SizedBox(height: 6),
                  Text(
                    'Fechada por ${currentSession.closedBy ?? '-'} em ${AppFormatters.dateTime(currentSession.closedAt!)}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                ],
              ],
            );

            final actions = Wrap(
              spacing: 10,
              runSpacing: 10,
              alignment: WrapAlignment.end,
              children: [
                OutlinedButton.icon(
                  onPressed: isBusy ? null : onExportWorksheet,
                  icon: const Icon(Icons.picture_as_pdf_outlined),
                  label: const Text('Folha PDF'),
                ),
                OutlinedButton.icon(
                  onPressed: isBusy ? null : onExportResult,
                  icon: const Icon(Icons.description_outlined),
                  label: const Text('Resultado PDF'),
                ),
                FilledButton.icon(
                  onPressed: isBusy || !currentSession.isOpen
                      ? null
                      : onCloseCount,
                  icon: const Icon(Icons.lock_rounded),
                  label: const Text('Fechar contagem'),
                ),
              ],
            );

            if (compact) {
              return Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [headerText, const SizedBox(height: 16), actions],
              );
            }

            return Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(child: headerText),
                const SizedBox(width: 16),
                Flexible(child: actions),
              ],
            );
          },
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            StatusChip(
              label: currentSession.status.label,
              color: currentSession.isOpen ? AppPalette.gold : AppPalette.navy,
            ),
            StatusChip(
              label:
                  'Conferidos: ${currentSession.countedItems}/${currentSession.totalItems}',
              color: AppPalette.navy,
              icon: Icons.fact_check_rounded,
            ),
            StatusChip(
              label: 'Divergencias: ${currentSession.divergentItems}',
              color: AppPalette.black,
              icon: Icons.rule_folder_rounded,
            ),
            StatusChip(
              label: 'Selecionados PDF: ${currentSession.selectedItems}',
              color: AppPalette.gold,
              icon: Icons.picture_as_pdf_rounded,
            ),
            if (currentSession.blindMode)
              StatusChip(
                label: currentSession.isOpen
                    ? 'Modo cego em andamento'
                    : 'Contagem cega finalizada',
                color: AppPalette.navy,
                icon: Icons.visibility_off_rounded,
              ),
          ],
        ),
        const SizedBox(height: 16),
        Wrap(
          spacing: 10,
          runSpacing: 10,
          children: [
            _SessionOverviewCard(
              title: 'Total de itens',
              value: '${currentSession.totalItems}',
              color: AppPalette.navy,
              icon: Icons.format_list_bulleted_rounded,
            ),
            _SessionOverviewCard(
              title: 'Conferidos',
              value: '${currentSession.countedItems}',
              color: AppPalette.navy,
              icon: Icons.fact_check_rounded,
            ),
            _SessionOverviewCard(
              title: 'Pendentes',
              value: '${currentSession.pendingItems}',
              color: AppPalette.gold,
              icon: Icons.pending_actions_rounded,
            ),
            _SessionOverviewCard(
              title: 'Divergencias',
              value: '${currentSession.divergentItems}',
              color: AppPalette.black,
              icon: Icons.rule_folder_rounded,
            ),
            _SessionOverviewCard(
              title: 'Selecionados PDF',
              value: '${currentSession.selectedItems}',
              color: AppPalette.gold,
              icon: Icons.picture_as_pdf_rounded,
            ),
            _SessionOverviewCard(
              title: 'Conclusao',
              value:
                  '${(currentSession.completionRate * 100).toStringAsFixed(0)}%',
              color: currentSession.isOpen ? AppPalette.gold : AppPalette.navy,
              icon: Icons.trending_up_rounded,
            ),
          ],
        ),
        if (currentSession.notes.trim().isNotEmpty) ...[
          const SizedBox(height: 16),
          InfoBanner(
            title: 'Observacoes de abertura',
            message: currentSession.notes.trim(),
            color: AppPalette.gold,
          ),
        ],
        if (currentSession.closedAt != null &&
            currentSession.closingNotes.trim().isNotEmpty) ...[
          const SizedBox(height: 12),
          InfoBanner(
            title: 'Observacoes de fechamento',
            message: currentSession.closingNotes.trim(),
            color: AppPalette.navy,
          ),
        ],
        const SizedBox(height: 20),
        Wrap(
          spacing: 12,
          runSpacing: 12,
          children: [
            SizedBox(
              width: 320,
              child: TextField(
                controller: searchController,
                onChanged: onLineSearchChanged,
                decoration: const InputDecoration(
                  prefixIcon: Icon(Icons.search_rounded),
                  hintText: 'Buscar por item, codigo ou observacao',
                ),
              ),
            ),
            SizedBox(
              width: 240,
              child: DropdownButtonFormField<StockCountLineFilter>(
                initialValue: lineFilter,
                decoration: const InputDecoration(labelText: 'Filtro da lista'),
                items: [
                  for (final option in StockCountLineFilter.values)
                    DropdownMenuItem(value: option, child: Text(option.label)),
                ],
                onChanged: (value) {
                  if (value == null) {
                    return;
                  }
                  onLineFilterChanged(value);
                },
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        Text(
          showSystemValues
              ? 'Cada item mostra saldo do sistema, quantidade contada e diferenca.'
              : 'Modo cego ativo: o saldo do sistema fica oculto ate o fechamento da sessao.',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        if (!currentSession.isOpen) ...[
          const SizedBox(height: 8),
          Text(
            'Contagem fechada: alteracoes de produto e selecao de PDF estao bloqueadas.',
            style: Theme.of(
              context,
            ).textTheme.bodySmall?.copyWith(color: AppPalette.navy),
          ),
        ],
        if (isBusy) ...[
          const SizedBox(height: 14),
          const LinearProgressIndicator(minHeight: 4),
        ],
        const SizedBox(height: 20),
        if (lines.isEmpty)
          const EmptyStateCard(
            icon: Icons.inventory_2_outlined,
            title: 'Nenhum item encontrado',
            message:
                'Ajuste a busca ou o filtro da lista para encontrar os itens desta contagem.',
          )
        else
          Column(
            children: [
              for (var index = 0; index < lines.length; index++) ...[
                StockCountLineTile(
                  line: lines[index],
                  session: currentSession,
                  showSystemValues: showSystemValues,
                  enabled: !isBusy,
                  onOpen: currentSession.isOpen
                      ? () => onOpenLine(lines[index])
                      : null,
                  onToggleSelection: (selected) =>
                      onToggleLineSelection(lines[index], selected),
                ),
                if (index < lines.length - 1) const SizedBox(height: 10),
              ],
            ],
          ),
      ],
    );
  }
}

class CountSessionTile extends StatelessWidget {
  const CountSessionTile({
    super.key,
    required this.session,
    required this.selected,
    required this.enabled,
    required this.onTap,
  });

  final StockCountSession session;
  final bool selected;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final accentColor = session.isOpen ? AppPalette.gold : AppPalette.navy;

    return InkWell(
      onTap: enabled ? onTap : null,
      borderRadius: BorderRadius.circular(24),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.all(18),
        decoration: BoxDecoration(
          color: selected
              ? accentColor.withValues(alpha: 0.08)
              : AppPalette.surfaceMuted,
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: selected ? accentColor : AppPalette.border),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        session.name,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Abertura: ${AppFormatters.dateTime(session.openedAt)}',
                        style: Theme.of(context).textTheme.bodyMedium,
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 12),
                StatusChip(label: session.status.label, color: accentColor),
              ],
            ),
            const SizedBox(height: 10),
            Wrap(
              spacing: 10,
              runSpacing: 10,
              children: [
                StatusChip(
                  label: 'Por ${session.openedBy}',
                  color: AppPalette.navy,
                  icon: Icons.person_rounded,
                ),
                if (session.blindMode)
                  const StatusChip(
                    label: 'Modo cego',
                    color: AppPalette.navy,
                    icon: Icons.visibility_off_rounded,
                  ),
                if (session.closedAt != null)
                  const StatusChip(
                    label: 'Fechada',
                    color: AppPalette.navy,
                    icon: Icons.lock_rounded,
                  ),
              ],
            ),
            if (session.closedAt != null) ...[
              const SizedBox(height: 10),
              Text(
                'Fechada por ${session.closedBy ?? '-'} em ${AppFormatters.dateTime(session.closedAt!)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            const SizedBox(height: 12),
            Text(
              'Toque para abrir os dados completos desta contagem.',
              style: Theme.of(
                context,
              ).textTheme.bodySmall?.copyWith(color: AppPalette.navy),
            ),
          ],
        ),
      ),
    );
  }
}

class _SessionOverviewCard extends StatelessWidget {
  const _SessionOverviewCard({
    required this.title,
    required this.value,
    required this.color,
    required this.icon,
  });

  final String title;
  final String value;
  final Color color;
  final IconData icon;

  @override
  Widget build(BuildContext context) {
    return Container(
      constraints: const BoxConstraints(minWidth: 150),
      padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: color.withValues(alpha: 0.16)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, color: color, size: 18),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(title, style: Theme.of(context).textTheme.bodySmall),
              const SizedBox(height: 2),
              Text(
                value,
                style: Theme.of(
                  context,
                ).textTheme.titleSmall?.copyWith(color: color),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class StockCountLineTile extends StatelessWidget {
  const StockCountLineTile({
    super.key,
    required this.line,
    required this.session,
    required this.showSystemValues,
    required this.enabled,
    required this.onToggleSelection,
    this.onOpen,
  });

  final StockCountLine line;
  final StockCountSession session;
  final bool showSystemValues;
  final bool enabled;
  final ValueChanged<bool> onToggleSelection;
  final VoidCallback? onOpen;

  @override
  Widget build(BuildContext context) {
    final statusColor = switch (line.status) {
      StockCountLineStatus.pending => AppPalette.gold,
      StockCountLineStatus.counted => AppPalette.navy,
      StockCountLineStatus.divergent => AppPalette.black,
    };
    final isEditable = enabled && session.isOpen;

    return LayoutBuilder(
      builder: (context, constraints) {
        final compact = constraints.maxWidth < 900;

        final leading = Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Checkbox(
              value: line.selectedForExport,
              onChanged: isEditable
                  ? (value) {
                      if (value == null) {
                        return;
                      }
                      onToggleSelection(value);
                    }
                  : null,
            ),
            const SizedBox(width: 4),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    line.itemName,
                    style: Theme.of(context).textTheme.titleMedium,
                  ),
                  const SizedBox(height: 6),
                  Text(
                    '${line.itemSku} | ${line.category} | ${line.unit}',
                    style: Theme.of(context).textTheme.bodyMedium,
                  ),
                  const SizedBox(height: 10),
                  Wrap(
                    spacing: 10,
                    runSpacing: 10,
                    children: [
                      StatusChip(label: line.status.label, color: statusColor),
                      if (line.selectedForExport)
                        const StatusChip(
                          label: 'PDF',
                          color: AppPalette.gold,
                          icon: Icons.picture_as_pdf_rounded,
                        ),
                      if (line.countedBy != null)
                        StatusChip(
                          label: 'Por ${line.countedBy}',
                          color: AppPalette.navy,
                          icon: Icons.person_rounded,
                        ),
                    ],
                  ),
                  if (line.lineNote.trim().isNotEmpty) ...[
                    const SizedBox(height: 10),
                    Text(
                      line.lineNote.trim(),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ],
              ),
            ),
          ],
        );

        final trailing = Column(
          crossAxisAlignment: compact
              ? CrossAxisAlignment.start
              : CrossAxisAlignment.end,
          children: [
            if (showSystemValues) ...[
              Text(
                'Sistema: ${AppFormatters.quantity(line.systemQuantity)} ${line.unit}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Contado: ${line.countedQuantity == null ? '-' : '${AppFormatters.quantity(line.countedQuantity!)} ${line.unit}'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Diferenca: ${line.difference == null ? '-' : '${AppFormatters.quantity(line.difference!)} ${line.unit}'}',
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: line.isDivergent ? AppPalette.black : null,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                'Impacto: ${AppFormatters.currency(line.divergenceValue)}',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ] else ...[
              Text(
                line.countedQuantity == null
                    ? 'Quantidade contada ainda nao informada.'
                    : 'Contado: ${AppFormatters.quantity(line.countedQuantity!)} ${line.unit}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 6),
              Text(
                'Saldo do sistema oculto ate o fechamento.',
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (line.countedAt != null) ...[
              const SizedBox(height: 10),
              Text(
                AppFormatters.dateTime(line.countedAt!),
                style: Theme.of(context).textTheme.bodySmall,
              ),
            ],
            if (onOpen != null) ...[
              const SizedBox(height: 10),
              FilledButton.tonalIcon(
                onPressed: isEditable ? onOpen : null,
                icon: const Icon(Icons.edit_note_rounded),
                label: Text(line.isPending ? 'Contar item' : 'Editar contagem'),
              ),
            ],
          ],
        );

        final content = compact
            ? Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [leading, const SizedBox(height: 10), trailing],
              )
            : Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(child: leading),
                  const SizedBox(width: 12),
                  trailing,
                ],
              );

        return Container(
          width: double.infinity,
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppPalette.surfaceMuted,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(color: AppPalette.border),
          ),
          child: Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: AppPalette.canvas,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: AppPalette.border.withValues(alpha: 0.8),
              ),
            ),
            child: content,
          ),
        );
      },
    );
  }
}

class InfoBanner extends StatelessWidget {
  const InfoBanner({
    super.key,
    required this.title,
    required this.message,
    required this.color,
  });

  final String title;
  final String message;
  final Color color;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.08),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: color.withValues(alpha: 0.18)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(
              context,
            ).textTheme.titleSmall?.copyWith(color: color),
          ),
          const SizedBox(height: 6),
          Text(message, style: Theme.of(context).textTheme.bodyMedium),
        ],
      ),
    );
  }
}
