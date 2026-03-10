import 'package:flutter/material.dart';
import 'package:music_music/core/services/music_widget_manager.dart';

/// Tela de configurações de Widgets e Lock Screen
class WidgetSettingsView extends StatelessWidget {
  const WidgetSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Widgets e Controles'),
        centerTitle: false,
        actions: [
          // 🧪 Botão de Teste de Widgets
          IconButton(
            icon: const Icon(Icons.bug_report),
            tooltip: 'Testar Widgets',
            onPressed: () async {
              debugPrint('🧪 Teste de widgets iniciado!');
              await MusicWidgetManager.testWidgets();
              
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('✅ Teste de widgets executado! Verifique os logs.'),
                  backgroundColor: Colors.green,
                ),
              );
            },
          ),
          // 🔍 Botão de Debug
          IconButton(
            icon: const Icon(Icons.search),
            tooltip: 'Ler Dados dos Widgets',
            onPressed: () async {
              debugPrint('🔍 Lendo dados dos widgets...');
              final data = await MusicWidgetManager.getWidgetData();
              
              if (!context.mounted) return;
              
              // Mostra dados em dialog
              showDialog(
                context: context,
                builder: (_) => AlertDialog(
                  title: const Text('🔍 Dados dos Widgets'),
                  content: SingleChildScrollView(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: data.entries.map((e) {
                        return Padding(
                          padding: const EdgeInsets.symmetric(vertical: 4),
                          child: Text('${e.key}: ${e.value ?? "null"}'),
                        );
                      }).toList(),
                    ),
                  ),
                  actions: [
                    TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Fechar'),
                    ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: ListView(
        padding: const EdgeInsets.symmetric(vertical: 8),
        children: [
          _SectionHeader(title: 'Lock Screen'),
          
          // Lock Screen Controls
          ListTile(
            leading: Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Icon(
                Icons.lock_outline,
                color: Theme.of(context).colorScheme.primary,
              ),
            ),
            title: const Text('Controles na Tela de Bloqueio'),
            subtitle: const Text('Controles de reproducao na lock screen'),
            trailing: const Chip(
              label: Text('Ativo'),
              backgroundColor: Colors.green,
              labelStyle: TextStyle(color: Colors.white, fontSize: 12),
            ),
          ),

          const Divider(height: 24),

          _SectionHeader(title: 'Como funciona'),
          
          // Info card Lock Screen
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lock_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Tela de Bloqueio',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Os controles de reprodução aparecem automaticamente quando você:\n'
                    '• Inicia uma música\n'
                    '• Bloqueia a tela\n'
                    '• Acessa a central de controles\n\n'
                    'Compatível com:\n'
                    '• Controles físicos (fones com botão)\n'
                    '• Fones Bluetooth\n'
                    '• Android Auto\n'
                    '• Wear OS (relógios)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Info card Android Auto
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.directions_car,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Android Auto',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'O app é compatível com Android Auto! Conecte seu celular ao carro e use:\n'
                    '• Controles na tela do veículo\n'
                    '• Comandos de voz do Google Assistant\n'
                    '• Metadados completos (título, artista, album)',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // Info card Wear OS
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.5),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.watch,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Wear OS',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    'Use no seu relógio Wear OS:\n'
                    '• Controle a reprodução pelo relógio\n'
                    '• Veja título e artista\n'
                    '• Pule faixas sem pegar o celular',
                    style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: Theme.of(context).colorScheme.onSurface.withValues(alpha: 0.7),
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),

          _SectionHeader(title: 'Dicas'),
          
          // Dicas
          Padding(
            padding: const EdgeInsets.all(16),
            child: Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Theme.of(context).colorScheme.primaryContainer.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Icon(
                        Icons.lightbulb_outline,
                        size: 20,
                        color: Theme.of(context).colorScheme.primary,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        'Dicas Pro',
                        style: Theme.of(context).textTheme.titleSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Text(
                    '💡 Use fones Bluetooth com controles para pular faixas\n\n'
                    '🎵 Ative o Gapless/Crossfade para transições suaves\n\n'
                    '🚗 Conecte ao Android Auto para usar no carro\n\n'
                    '⌚ Use Wear OS para controlar pelo relógio',
                    style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      height: 1.4,
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeader extends StatelessWidget {
  final String title;

  const _SectionHeader({required this.title});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      child: Text(
        title.toUpperCase(),
        style: Theme.of(context).textTheme.labelMedium?.copyWith(
          fontWeight: FontWeight.w700,
          letterSpacing: 0.8,
          color: Theme.of(context).colorScheme.primary,
        ),
      ),
    );
  }
}
