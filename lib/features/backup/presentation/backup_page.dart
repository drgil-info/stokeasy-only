import 'package:flutter/material.dart';

import '../../../app/theme/app_palette.dart';
import '../../../shared/widgets/app_surface_card.dart';
import '../../../shared/widgets/page_header.dart';
import 'backup_controller.dart';

class BackupPage extends StatelessWidget {
  const BackupPage({
    super.key,
    required this.controller,
    required this.onInventoryRestored,
  });

  final BackupController controller;
  final Future<void> Function() onInventoryRestored;

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: controller,
      builder: (context, child) {
        return SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(24, 18, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const PageHeader(
                title: 'Backup',
                subtitle:
                    'Proteja o banco local com copia manual em arquivo e restaure rapidamente quando precisar.',
              ),
              const SizedBox(height: 24),
              LayoutBuilder(
                builder: (context, constraints) {
                  final width = constraints.maxWidth;
                  final compact = width < 920;
                  final medium = width >= 920 && width < 1280;

                  final heroCard = const _BackupHeroCard();
                  final infoCard = _BackupInfoCard(controller: controller);
                  final statusCard = controller.statusMessage == null
                      ? null
                      : _StatusCard(message: controller.statusMessage!);
                  final createCard = _ActionCard(
                    title: 'Criar backup',
                    description:
                        'Selecione um local no computador para salvar uma copia do banco SQLite atual.',
                    buttonLabel: 'Salvar copia',
                    icon: Icons.download_rounded,
                    color: AppPalette.gold,
                    backgroundColor: AppPalette.surfaceMuted,
                    busy: controller.isBusy,
                    onPressed: () => _createBackup(context),
                  );
                  final restoreCard = _ActionCard(
                    title: 'Restaurar backup',
                    description:
                        'Substitua a base atual por um arquivo de backup previamente salvo.',
                    buttonLabel: 'Restaurar arquivo',
                    icon: Icons.upload_file_rounded,
                    color: AppPalette.navy,
                    backgroundColor: AppPalette.canvas,
                    busy: controller.isBusy,
                    onPressed: () => _restoreBackup(context),
                  );

                  if (compact) {
                    return Column(
                      children: [
                        heroCard,
                        if (statusCard != null) ...[
                          const SizedBox(height: 12),
                          statusCard,
                        ],
                        const SizedBox(height: 16),
                        createCard,
                        const SizedBox(height: 16),
                        restoreCard,
                        const SizedBox(height: 16),
                        infoCard,
                      ],
                    );
                  }

                  if (medium) {
                    return Column(
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 6, child: heroCard),
                            const SizedBox(width: 16),
                            Expanded(flex: 5, child: infoCard),
                          ],
                        ),
                        if (statusCard != null) ...[
                          const SizedBox(height: 12),
                          statusCard,
                        ],
                        const SizedBox(height: 16),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Expanded(flex: 5, child: createCard),
                            const SizedBox(width: 16),
                            Expanded(flex: 6, child: restoreCard),
                          ],
                        ),
                      ],
                    );
                  }

                  return Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 7,
                            child: Column(
                              children: [
                                heroCard,
                                if (statusCard != null) ...[
                                  const SizedBox(height: 12),
                                  statusCard,
                                ],
                              ],
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(flex: 5, child: infoCard),
                        ],
                      ),
                      const SizedBox(height: 16),
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(flex: 4, child: createCard),
                          const SizedBox(width: 16),
                          Expanded(flex: 6, child: restoreCard),
                        ],
                      ),
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

  Future<void> _createBackup(BuildContext context) async {
    try {
      final backupPath = await controller.createBackup();
      if (!context.mounted) {
        return;
      }

      final message = backupPath == null
          ? controller.statusMessage ?? 'Backup cancelado.'
          : 'Backup salvo em $backupPath';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      final message = error is StateError
          ? error.message
          : 'Nao foi possivel criar o backup.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppPalette.black),
      );
    }
  }

  Future<void> _restoreBackup(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: const Text('Restaurar backup'),
          content: const Text(
            'A base local atual sera substituida. Deseja continuar?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Restaurar'),
            ),
          ],
        );
      },
    );

    if (confirmed != true) {
      return;
    }

    try {
      final restorePath = await controller.restoreBackup();
      if (restorePath != null) {
        await onInventoryRestored();
      }

      if (!context.mounted) {
        return;
      }

      final message = restorePath == null
          ? controller.statusMessage ?? 'Restauracao cancelada.'
          : 'Backup restaurado de $restorePath';

      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text(message)));
    } catch (error) {
      if (!context.mounted) {
        return;
      }

      final message = error is StateError
          ? error.message
          : 'Nao foi possivel restaurar o backup.';
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(message), backgroundColor: AppPalette.black),
      );
    }
  }
}

class _BackupHeroCard extends StatelessWidget {
  const _BackupHeroCard();

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.fromLTRB(24, 22, 24, 22),
      gradient: const LinearGradient(
        begin: Alignment.topLeft,
        end: Alignment.bottomRight,
        colors: [AppPalette.gold, AppPalette.navy],
      ),
      child: Stack(
        children: [
          Positioned(
            top: -46,
            right: -24,
            child: Container(
              width: 140,
              height: 140,
              decoration: BoxDecoration(
                color: AppPalette.white.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            bottom: -52,
            left: -24,
            child: Container(
              width: 120,
              height: 120,
              decoration: BoxDecoration(
                color: AppPalette.black.withValues(alpha: 0.12),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 12,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: AppPalette.white.withValues(alpha: 0.22),
                  borderRadius: BorderRadius.circular(999),
                ),
                child: const Text(
                  'Seguranca do banco local',
                  style: TextStyle(
                    color: AppPalette.black,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
              const SizedBox(height: 14),
              Text(
                'Gere copias do SQLite em arquivo e restaure a base quando precisar.',
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                  color: AppPalette.black,
                  height: 1.2,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                'O processo trabalha direto com o banco local. Antes de restaurar, confirme se o arquivo selecionado esta correto.',
                style: Theme.of(
                  context,
                ).textTheme.bodyLarge?.copyWith(color: AppPalette.navy),
              ),
              const SizedBox(height: 14),
              Wrap(
                spacing: 10,
                runSpacing: 10,
                children: const [
                  _HeroTag(
                    icon: Icons.shield_rounded,
                    label: 'Fluxo seguro local',
                  ),
                  _HeroTag(
                    icon: Icons.file_copy_rounded,
                    label: 'Backup manual em arquivo',
                  ),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _HeroTag extends StatelessWidget {
  const _HeroTag({required this.icon, required this.label});

  final IconData icon;
  final String label;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: AppPalette.white.withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(999),
        border: Border.all(color: AppPalette.white.withValues(alpha: 0.24)),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 16, color: AppPalette.black),
          const SizedBox(width: 6),
          Text(
            label,
            style: Theme.of(
              context,
            ).textTheme.labelLarge?.copyWith(color: AppPalette.black),
          ),
        ],
      ),
    );
  }
}

class _BackupInfoCard extends StatelessWidget {
  const _BackupInfoCard({required this.controller});

  final BackupController controller;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      backgroundColor: AppPalette.canvas,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Informacoes atuais',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 18),
          _InfoLine(
            label: 'Banco local',
            value: controller.databasePath ?? 'Carregando...',
          ),
          const SizedBox(height: 14),
          _InfoLine(
            label: 'Ultimo backup salvo',
            value:
                controller.lastBackupPath ??
                'Nenhum backup criado nesta sessao.',
          ),
          const SizedBox(height: 14),
          _InfoLine(
            label: 'Ultima restauracao',
            value:
                controller.lastRestorePath ??
                'Nenhuma restauracao realizada nesta sessao.',
          ),
        ],
      ),
    );
  }
}

class _StatusCard extends StatelessWidget {
  const _StatusCard({required this.message});

  final String message;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      padding: const EdgeInsets.all(18),
      backgroundColor: AppPalette.surfaceMuted,
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 34,
            height: 34,
            decoration: BoxDecoration(
              color: AppPalette.navy.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(10),
            ),
            child: const Icon(
              Icons.info_outline_rounded,
              color: AppPalette.navy,
              size: 18,
            ),
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(message, style: Theme.of(context).textTheme.bodyMedium),
          ),
        ],
      ),
    );
  }
}

class _ActionCard extends StatelessWidget {
  const _ActionCard({
    required this.title,
    required this.description,
    required this.buttonLabel,
    required this.icon,
    required this.color,
    required this.backgroundColor,
    required this.busy,
    required this.onPressed,
  });

  final String title;
  final String description;
  final String buttonLabel;
  final IconData icon;
  final Color color;
  final Color backgroundColor;
  final bool busy;
  final VoidCallback onPressed;

  @override
  Widget build(BuildContext context) {
    return AppSurfaceCard(
      backgroundColor: backgroundColor,
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 52,
            height: 52,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(18),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(height: 14),
          Text(title, style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 8),
          Text(description, style: Theme.of(context).textTheme.bodyMedium),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: busy ? null : onPressed,
            icon: busy
                ? const SizedBox(
                    width: 16,
                    height: 16,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : Icon(icon),
            label: Text(buttonLabel),
          ),
        ],
      ),
    );
  }
}

class _InfoLine extends StatelessWidget {
  const _InfoLine({required this.label, required this.value});

  final String label;
  final String value;

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: Theme.of(
            context,
          ).textTheme.labelLarge?.copyWith(color: AppPalette.textMuted),
        ),
        const SizedBox(height: 6),
        SelectableText(value, style: Theme.of(context).textTheme.bodyMedium),
      ],
    );
  }
}
