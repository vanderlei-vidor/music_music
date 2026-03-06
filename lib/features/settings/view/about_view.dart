import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'package:music_music/app/app_info.dart';
import 'package:music_music/core/observability/app_logger.dart';

class AboutView extends StatelessWidget {
  const AboutView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Scaffold(
      appBar: AppBar(title: const Text('Sobre')),
      body: ListView(
        padding: const EdgeInsets.all(16),
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(16),
              color: theme.colorScheme.surfaceContainerHighest.withValues(
                alpha: 0.55,
              ),
              border: Border.all(
                color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
              ),
            ),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 26,
                  backgroundColor: theme.colorScheme.primary.withValues(
                    alpha: 0.15,
                  ),
                  child: Icon(
                    Icons.music_note_rounded,
                    color: theme.colorScheme.primary,
                    size: 28,
                  ),
                ),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        AppInfo.appName,
                        style: theme.textTheme.titleLarge?.copyWith(
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                      const SizedBox(height: 2),
                      Text(
                        'Versao ${AppInfo.appVersion}',
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.72),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 14),
          _AboutSection(
            title: 'Descricao',
            child: Text(
              AppInfo.packageDescription,
              style: theme.textTheme.bodyMedium,
            ),
          ),
          const SizedBox(height: 12),
          _AboutSection(
            title: 'Recursos principais',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: const [
                _FeatureLine('Player local com fila persistida'),
                _FeatureLine('Equalizador avancado com presets custom'),
                _FeatureLine('Perfis de audio por dispositivo'),
                _FeatureLine('Biblioteca com sincronizacao incremental'),
              ],
            ),
          ),
          const SizedBox(height: 12),
          _AboutSection(
            title: 'Informacoes tecnicas',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Plataformas: Android, iOS, Web e Desktop'),
                const SizedBox(height: 4),
                Text('Stack: Flutter + Provider + SQLite + just_audio'),
              ],
            ),
          ),
          const SizedBox(height: 14),
          FilledButton.icon(
            onPressed: () async {
              await Clipboard.setData(
                const ClipboardData(
                  text: 'Music Music 1.2.0+1 | Flutter app local audio player',
                ),
              );
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Informacoes copiadas para a area de transferencia.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.copy_rounded),
            label: const Text('Copiar informacoes do app'),
          ),
          const SizedBox(height: 8),
          OutlinedButton.icon(
            onPressed: () async {
              final logs = AppLogger.exportAsText(max: 250);
              await Clipboard.setData(ClipboardData(text: logs));
              if (!context.mounted) return;
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Logs recentes copiados para a area de transferencia.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.bug_report_outlined),
            label: const Text('Copiar logs recentes'),
          ),
          const SizedBox(height: 8),
          TextButton.icon(
            onPressed: () {
              AppLogger.clear();
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Buffer de logs limpo.'),
                  behavior: SnackBarBehavior.floating,
                ),
              );
            },
            icon: const Icon(Icons.delete_outline_rounded),
            label: const Text('Limpar logs'),
          ),
        ],
      ),
    );
  }
}

class _AboutSection extends StatelessWidget {
  final String title;
  final Widget child;

  const _AboutSection({required this.title, required this.child});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        color: theme.colorScheme.surface,
        border: Border.all(
          color: theme.colorScheme.onSurface.withValues(alpha: 0.08),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: theme.textTheme.titleSmall?.copyWith(fontWeight: FontWeight.w700),
          ),
          const SizedBox(height: 8),
          child,
        ],
      ),
    );
  }
}

class _FeatureLine extends StatelessWidget {
  final String label;
  const _FeatureLine(this.label);

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text('• '),
          Expanded(child: Text(label)),
        ],
      ),
    );
  }
}
