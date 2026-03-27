import 'package:flutter/material.dart';

enum AppSection {
  dashboard,
  items,
  movements,
  counts,
  reports,
  settings,
  backup,
}

extension AppSectionView on AppSection {
  String get label => switch (this) {
    AppSection.dashboard => 'Dashboard',
    AppSection.items => 'Itens',
    AppSection.movements => 'Movimentacoes',
    AppSection.counts => 'Contagem',
    AppSection.reports => 'Relatorios',
    AppSection.settings => 'Configuracoes',
    AppSection.backup => 'Backup',
  };

  String get headline => switch (this) {
    AppSection.dashboard => 'Visao geral do estoque',
    AppSection.items => 'Cadastro e consulta de itens',
    AppSection.movements => 'Entradas, saidas e ajustes',
    AppSection.counts => 'Inventario fisico e conferencias',
    AppSection.reports => 'Indicadores operacionais',
    AppSection.settings => 'Categorias e unidades dos itens',
    AppSection.backup => 'Seguranca do banco local',
  };

  IconData get icon => switch (this) {
    AppSection.dashboard => Icons.space_dashboard_rounded,
    AppSection.items => Icons.inventory_2_rounded,
    AppSection.movements => Icons.swap_horiz_rounded,
    AppSection.counts => Icons.fact_check_rounded,
    AppSection.reports => Icons.bar_chart_rounded,
    AppSection.settings => Icons.tune_rounded,
    AppSection.backup => Icons.backup_rounded,
  };
}
