import 'package:flutter/material.dart';
import 'package:flutter/foundation.dart';
import 'dart:math' as math;
import 'package:provider/provider.dart';

import 'package:music_music/features/player/equalizer/equalizer_models.dart';
import 'package:music_music/features/player/equalizer/equalizer_view_model.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';

class EqualizerSheet extends StatelessWidget {
  const EqualizerSheet({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return SafeArea(
      child: Consumer<EqualizerViewModel>(
        builder: (context, vm, _) {
          final currentGenre = context.select<PlaylistViewModel, String?>(
            (playlistVm) => playlistVm.currentGenre,
          );
          final isReprocessingGenres = context.select<PlaylistViewModel, bool>(
            (playlistVm) => playlistVm.isReprocessingGenres,
          );
          if (vm.autoGenrePresetEnabled) {
            vm.syncGenre(currentGenre);
          }
          final maxSheetHeight = MediaQuery.of(context).size.height * 0.88;
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
            child: ConstrainedBox(
              constraints: BoxConstraints(maxHeight: maxSheetHeight),
              child: SingleChildScrollView(
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Center(
                      child: Container(
                        width: 40,
                        height: 4,
                        margin: const EdgeInsets.only(bottom: 14),
                        decoration: BoxDecoration(
                          color: theme.colorScheme.onSurface.withValues(alpha: 0.2),
                          borderRadius: BorderRadius.circular(20),
                        ),
                      ),
                    ),
                    Row(
                      children: [
                        Text(
                          'Equalizador',
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        const Spacer(),
                        Switch(
                          value: vm.enabled,
                          onChanged: vm.setEnabled,
                        ),
                      ],
                    ),
                    const SizedBox(height: 10),
                    _ProfileRow(vm: vm),
                    const SizedBox(height: 10),
                    _PresetRow(vm: vm),
                    const SizedBox(height: 14),
                    _UserPresetSection(vm: vm),
                    const SizedBox(height: 10),
                    _LibraryToolsRow(isLoading: isReprocessingGenres),
                    const SizedBox(height: 8),
                    _AutomationRow(vm: vm),
                    if (!kIsWeb && defaultTargetPlatform == TargetPlatform.iOS) ...[
                      const SizedBox(height: 6),
                      _IosEqModeRow(vm: vm),
                    ],
                    if (vm.autoGenrePresetEnabled) ...[
                      const SizedBox(height: 4),
                      _GenreDebugChip(vm: vm),
                    ],
                    const SizedBox(height: 8),
                    _PreampSlider(vm: vm),
                    const SizedBox(height: 12),
                    SizedBox(
                      height: 250,
                      child: _EqVisualizer(vm: vm),
                    ),
                    const SizedBox(height: 10),
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: vm.reset,
                        icon: const Icon(Icons.restart_alt_rounded),
                        label: const Text('Resetar'),
                      ),
                    ),
                    Text(
                      'Apply: ${vm.lastApplyDuration.inMilliseconds} ms | '
                      'ok: ${vm.applyCount} | erros: ${vm.applyErrorCount}',
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: theme.colorScheme.onSurface.withValues(alpha: 0.7),
                      ),
                    ),
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

class _GenreDebugChip extends StatelessWidget {
  final EqualizerViewModel vm;
  const _GenreDebugChip({required this.vm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final detected = vm.lastDetectedGenreLabel?.isNotEmpty == true
        ? vm.lastDetectedGenreLabel!
        : 'n/a';
    final preset = vm.lastAutoAppliedPreset;
    final mapped = preset != null ? _presetLabel(preset) : 'sem mapeamento';
    final accent = _presetColor(theme, preset);
    final icon = _presetIcon(preset);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
      decoration: BoxDecoration(
        color: accent.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: accent.withValues(alpha: 0.35),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, size: 16, color: accent),
          const SizedBox(width: 8),
          Expanded(
            child: Text(
              'Auto genre: $detected -> $mapped',
              style: theme.textTheme.bodySmall?.copyWith(
                fontWeight: FontWeight.w600,
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 8),
          TextButton(
            onPressed: vm.lastAutoAppliedPreset == null ? null : vm.lockCurrentPreset,
            style: TextButton.styleFrom(
              minimumSize: const Size(0, 28),
              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 0),
            ),
            child: const Text('Fixar'),
          ),
        ],
      ),
    );
  }

  Color _presetColor(ThemeData theme, EqualizerPreset? preset) {
    switch (preset) {
      case EqualizerPreset.bassBoost:
        return Colors.deepOrangeAccent;
      case EqualizerPreset.vocalBoost:
        return Colors.lightBlueAccent;
      case EqualizerPreset.trebleBoost:
        return Colors.tealAccent.shade700;
      case EqualizerPreset.acoustic:
        return Colors.amber.shade700;
      case EqualizerPreset.party:
        return Colors.pinkAccent;
      case EqualizerPreset.flat:
        return theme.colorScheme.secondary;
      case EqualizerPreset.custom:
        return theme.colorScheme.primary;
      case null:
        return theme.colorScheme.outline;
    }
  }

  IconData _presetIcon(EqualizerPreset? preset) {
    switch (preset) {
      case EqualizerPreset.bassBoost:
        return Icons.graphic_eq_rounded;
      case EqualizerPreset.vocalBoost:
        return Icons.record_voice_over_rounded;
      case EqualizerPreset.trebleBoost:
        return Icons.multitrack_audio_rounded;
      case EqualizerPreset.acoustic:
        return Icons.piano_rounded;
      case EqualizerPreset.party:
        return Icons.celebration_rounded;
      case EqualizerPreset.flat:
        return Icons.horizontal_rule_rounded;
      case EqualizerPreset.custom:
        return Icons.tune_rounded;
      case null:
        return Icons.help_outline_rounded;
    }
  }

  String _presetLabel(EqualizerPreset preset) {
    switch (preset) {
      case EqualizerPreset.flat:
        return 'Flat';
      case EqualizerPreset.bassBoost:
        return 'Bass Boost';
      case EqualizerPreset.vocalBoost:
        return 'Vocal';
      case EqualizerPreset.trebleBoost:
        return 'Treble';
      case EqualizerPreset.acoustic:
        return 'Acoustic';
      case EqualizerPreset.party:
        return 'Party';
      case EqualizerPreset.custom:
        return 'Custom';
    }
  }
}

class _PresetRow extends StatelessWidget {
  final EqualizerViewModel vm;
  const _PresetRow({required this.vm});

  @override
  Widget build(BuildContext context) {
    final presets = EqualizerPreset.values
        .where((p) => p != EqualizerPreset.custom)
        .toList();

    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: presets.map((preset) {
          final selected = vm.preset == preset;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              label: Text(_presetLabel(preset)),
              selected: selected,
              onSelected: (_) => vm.applyPreset(preset),
            ),
          );
        }).toList(),
      ),
    );
  }

  String _presetLabel(EqualizerPreset preset) {
    switch (preset) {
      case EqualizerPreset.flat:
        return 'Flat';
      case EqualizerPreset.bassBoost:
        return 'Bass Boost';
      case EqualizerPreset.vocalBoost:
        return 'Vocal';
      case EqualizerPreset.trebleBoost:
        return 'Treble';
      case EqualizerPreset.acoustic:
        return 'Acoustic';
      case EqualizerPreset.party:
        return 'Party';
      case EqualizerPreset.custom:
        return 'Custom';
    }
  }
}

class _ProfileRow extends StatelessWidget {
  final EqualizerViewModel vm;
  const _ProfileRow({required this.vm});

  @override
  Widget build(BuildContext context) {
    return SingleChildScrollView(
      scrollDirection: Axis.horizontal,
      child: Row(
        children: vm.availableProfiles.map((profile) {
          final selected = vm.activeProfile == profile;
          return Padding(
            padding: const EdgeInsets.only(right: 8),
            child: ChoiceChip(
              selected: selected,
              label: Text(profile.label),
              onSelected: (_) => vm.setActiveProfile(profile),
            ),
          );
        }).toList(),
      ),
    );
  }
}

class _PreampSlider extends StatelessWidget {
  final EqualizerViewModel vm;
  const _PreampSlider({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Preamp: ${vm.preampDb.toStringAsFixed(1)} dB'),
        Text(
          'Efetivo: ${vm.effectivePreampDb.toStringAsFixed(1)} dB | '
          'Recomendado: ${vm.recommendedSafePreampDb.toStringAsFixed(1)} dB',
          style: Theme.of(context).textTheme.bodySmall,
        ),
        Slider(
          value: vm.preampDb,
          min: -12,
          max: 12,
          divisions: 48,
          onChanged: (v) => vm.setPreampDb(v, commit: false),
          onChangeEnd: (v) => vm.setPreampDb(v, commit: true),
        ),
      ],
    );
  }
}

class _UserPresetSection extends StatelessWidget {
  final EqualizerViewModel vm;
  const _UserPresetSection({required this.vm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text(
              'Presets salvos',
              style: theme.textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            const Spacer(),
            IconButton(
              tooltip: 'Exportar presets',
              onPressed: () => _showExportDialog(context, vm),
              icon: const Icon(Icons.upload_file_rounded),
            ),
            IconButton(
              tooltip: 'Importar presets',
              onPressed: () => _showImportDialog(context, vm),
              icon: const Icon(Icons.download_rounded),
            ),
            TextButton.icon(
              onPressed: () => _showSavePresetDialog(context, vm),
              icon: const Icon(Icons.save_alt_rounded),
              label: const Text('Salvar atual'),
            ),
          ],
        ),
        if (vm.userPresets.isEmpty)
          Text(
            'Nenhum preset custom salvo',
            style: theme.textTheme.bodySmall,
          )
        else
          SizedBox(
            height: 46,
            child: ListView.separated(
              scrollDirection: Axis.horizontal,
              itemCount: vm.userPresets.length,
              separatorBuilder: (_, __) => const SizedBox(width: 8),
              itemBuilder: (context, index) {
                final preset = vm.userPresets[index];
                final selected = vm.selectedUserPresetId == preset.id;
                return InputChip(
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(preset.name),
                      PopupMenuButton<_PresetAction>(
                        tooltip: 'Ações',
                        padding: EdgeInsets.zero,
                        onSelected: (action) async {
                          if (action == _PresetAction.rename) {
                            await _showRenamePresetDialog(context, vm, preset);
                          } else {
                            await vm.deleteUserPreset(preset.id);
                          }
                        },
                        itemBuilder: (_) => const [
                          PopupMenuItem(
                            value: _PresetAction.rename,
                            child: Text('Renomear'),
                          ),
                          PopupMenuItem(
                            value: _PresetAction.delete,
                            child: Text('Excluir'),
                          ),
                        ],
                      ),
                    ],
                  ),
                  selected: selected,
                  onSelected: (_) => vm.applyUserPreset(preset.id),
                );
              },
            ),
          ),
      ],
    );
  }

  Future<void> _showSavePresetDialog(
    BuildContext context,
    EqualizerViewModel vm,
  ) async {
    final controller = TextEditingController();
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Salvar preset'),
        content: TextField(
          controller: controller,
          maxLength: 24,
          decoration: const InputDecoration(
            hintText: 'Ex: Grave punch',
          ),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (name == null) return;
    final ok = await vm.saveCurrentAsPreset(name);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nome inválido ou duplicado para preset.'),
        ),
      );
    }
  }

  Future<void> _showRenamePresetDialog(
    BuildContext context,
    EqualizerViewModel vm,
    EqualizerUserPreset preset,
  ) async {
    final controller = TextEditingController(text: preset.name);
    final name = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Renomear preset'),
        content: TextField(
          controller: controller,
          maxLength: 24,
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );
    if (name == null) return;
    final ok = await vm.renameUserPreset(preset.id, name);
    if (!context.mounted) return;
    if (!ok) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nome inválido ou duplicado para preset.'),
        ),
      );
    }
  }

  Future<void> _showExportDialog(
    BuildContext context,
    EqualizerViewModel vm,
  ) async {
    final json = vm.exportUserPresetsJson();
    await showDialog<void>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Exportar presets (JSON)'),
        content: SizedBox(
          width: 560,
          child: TextField(
            controller: TextEditingController(text: json),
            maxLines: 14,
            readOnly: true,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              helperText: 'Copie esse conteúdo para backup.',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Fechar'),
          ),
        ],
      ),
    );
  }

  Future<void> _showImportDialog(
    BuildContext context,
    EqualizerViewModel vm,
  ) async {
    final controller = TextEditingController();
    final rawJson = await showDialog<String>(
      context: context,
      builder: (_) => AlertDialog(
        title: const Text('Importar presets (JSON)'),
        content: SizedBox(
          width: 560,
          child: TextField(
            controller: controller,
            maxLines: 14,
            decoration: const InputDecoration(
              border: OutlineInputBorder(),
              hintText: 'Cole aqui o JSON exportado...',
            ),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(context).pop(controller.text),
            child: const Text('Importar'),
          ),
        ],
      ),
    );

    if (rawJson == null || rawJson.trim().isEmpty) return;
    try {
      final imported = await vm.importUserPresetsJson(rawJson);
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Importação concluída: $imported presets adicionados.'),
        ),
      );
    } catch (_) {
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('JSON inválido para importação de presets.'),
        ),
      );
    }
  }
}

enum _PresetAction { rename, delete }

class _AutomationRow extends StatelessWidget {
  final EqualizerViewModel vm;
  const _AutomationRow({required this.vm});

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text('Auto-headroom (anti-clipping)'),
          value: vm.autoHeadroomEnabled,
          onChanged: vm.setAutoHeadroomEnabled,
        ),
        SwitchListTile(
          dense: true,
          contentPadding: EdgeInsets.zero,
          title: const Text('Preset automático por gênero'),
          value: vm.autoGenrePresetEnabled,
          onChanged: vm.setAutoGenrePresetEnabled,
        ),
      ],
    );
  }
}

class _IosEqModeRow extends StatelessWidget {
  final EqualizerViewModel vm;
  const _IosEqModeRow({required this.vm});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'iOS EQ Mode (experimental)',
          style: theme.textTheme.labelLarge?.copyWith(
            fontWeight: FontWeight.w700,
          ),
        ),
        const SizedBox(height: 6),
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: IosEqProcessingMode.values.map((mode) {
              final selected = vm.iosEqProcessingMode == mode;
              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  selected: selected,
                  label: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Text(mode.label),
                      if (mode == IosEqProcessingMode.trueMultiband) ...[
                        const SizedBox(width: 6),
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 6,
                            vertical: 2,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.amber.withValues(alpha: 0.25),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            'WIP',
                            style: theme.textTheme.labelSmall?.copyWith(
                              fontWeight: FontWeight.w700,
                              color: Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                  onSelected: (_) => vm.setIosEqProcessingMode(mode),
                ),
              );
            }).toList(),
          ),
        ),
      ],
    );
  }
}

class _LibraryToolsRow extends StatelessWidget {
  final bool isLoading;
  const _LibraryToolsRow({required this.isLoading});

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        TextButton.icon(
          onPressed: isLoading
              ? null
              : () async {
                  final updated =
                      await context.read<PlaylistViewModel>().runGenreReprocess();
                  if (!context.mounted) return;
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(
                      content: Text('Reprocessamento concluído: $updated gêneros atualizados.'),
                    ),
                  );
                },
          icon: isLoading
              ? const SizedBox(
                  width: 14,
                  height: 14,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : const Icon(Icons.auto_fix_high_rounded),
          label: Text(isLoading ? 'Reprocessando...' : 'Reprocessar gêneros'),
        ),
      ],
    );
  }
}

class _EqVisualizer extends StatefulWidget {
  final EqualizerViewModel vm;
  const _EqVisualizer({required this.vm});

  @override
  State<_EqVisualizer> createState() => _EqVisualizerState();
}

class _EqVisualizerState extends State<_EqVisualizer>
    with SingleTickerProviderStateMixin {
  late final AnimationController _pulseController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1700),
  )..repeat();
  List<double> _trailValues = const [];

  @override
  void dispose() {
    _pulseController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final vm = widget.vm;
    final theme = Theme.of(context);
    final values = [
      for (final band in vm.bands) vm.gainFor(band.frequencyHz),
    ];

    return Column(
      children: [
        Expanded(
          child: Row(
            children: [
              _DbScale(color: theme.colorScheme.onSurface.withValues(alpha: 0.65)),
              const SizedBox(width: 8),
              Expanded(
                child: AnimatedBuilder(
                  animation: _pulseController,
                  builder: (_, __) {
                    _syncTrail(values);
                    return DecoratedBox(
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(18),
                        gradient: LinearGradient(
                          begin: Alignment.topLeft,
                          end: Alignment.bottomRight,
                          colors: [
                            theme.colorScheme.primary.withValues(alpha: 0.13),
                            theme.colorScheme.primary.withValues(alpha: 0.05),
                          ],
                        ),
                        border: Border.all(
                          color: theme.colorScheme.primary.withValues(alpha: 0.18),
                        ),
                      ),
                      child: CustomPaint(
                        painter: _EqCurvePainter(
                          values: values,
                          trailValues: _trailValues,
                          phase: _pulseController.value,
                          color: theme.colorScheme.primary,
                        ),
                        child: const SizedBox.expand(),
                      ),
                    );
                  },
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 12),
        SizedBox(
          height: 120,
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: vm.bands.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final band = vm.bands[index];
              final value = vm.gainFor(band.frequencyHz);
              return SizedBox(
                width: 36,
                child: Column(
                  children: [
                    Text(
                      value.toStringAsFixed(0),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                    Expanded(
                      child: RotatedBox(
                        quarterTurns: 3,
                        child: Slider(
                          value: value,
                          min: band.minDb,
                          max: band.maxDb,
                          divisions: 48,
                          onChanged: (v) => vm.setBandGainDb(
                            band.frequencyHz,
                            v,
                            commit: false,
                          ),
                          onChangeEnd: (v) => vm.setBandGainDb(
                            band.frequencyHz,
                            v,
                            commit: true,
                          ),
                        ),
                      ),
                    ),
                    Text(
                      _shortBandLabel(band.label),
                      style: Theme.of(context).textTheme.labelSmall,
                    ),
                  ],
                ),
              );
            },
          ),
        ),
      ],
    );
  }

  String _shortBandLabel(String label) {
    final normalized = label.replaceAll(' Hz', '').replaceAll(' kHz', 'k');
    if (normalized.length <= 4) return normalized;
    return normalized.substring(0, 4);
  }

  void _syncTrail(List<double> current) {
    if (_trailValues.length != current.length) {
      _trailValues = List<double>.from(current);
      return;
    }
    for (var i = 0; i < current.length; i++) {
      final delta = current[i] - _trailValues[i];
      _trailValues[i] += delta * 0.14;
    }
  }
}

class _DbScale extends StatelessWidget {
  final Color color;
  const _DbScale({required this.color});

  @override
  Widget build(BuildContext context) {
    final style = Theme.of(context).textTheme.labelSmall?.copyWith(
      color: color,
      fontWeight: FontWeight.w600,
    );
    return SizedBox(
      width: 34,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Text('+12', style: style),
          Text('0', style: style),
          Text('-12', style: style),
        ],
      ),
    );
  }
}

class _EqCurvePainter extends CustomPainter {
  final List<double> values;
  final List<double> trailValues;
  final double phase;
  final Color color;

  const _EqCurvePainter({
    required this.values,
    required this.trailValues,
    required this.phase,
    required this.color,
  });

  @override
  void paint(Canvas canvas, Size size) {
    if (values.isEmpty) return;
    final centerY = size.height / 2;
    final maxAbs = values.map((e) => e.abs()).fold<double>(1.0, math.max);
    final normalized = values.map((v) => v / maxAbs).toList();
    final normalizedTrail = (trailValues.length == values.length
            ? trailValues
            : values)
        .map((v) => v / maxAbs)
        .toList();

    final gridPaint = Paint()
      ..color = color.withValues(alpha: 0.14)
      ..strokeWidth = 1;
    for (var i = 1; i < 4; i++) {
      final y = size.height * (i / 4);
      canvas.drawLine(Offset(0, y), Offset(size.width, y), gridPaint);
    }

    final points = <Offset>[];
    final steps = math.max(1, normalized.length - 1);
    for (var i = 0; i < normalized.length; i++) {
      final x = (size.width / steps) * i;
      final y = centerY - (normalized[i] * (size.height * 0.36));
      points.add(Offset(x, y));
    }

    final path = Path()..moveTo(points.first.dx, points.first.dy);
    final trailPath = Path()..moveTo(points.first.dx, points.first.dy);
    for (var i = 1; i < points.length; i++) {
      final p0 = points[i - 1];
      final p1 = points[i];
      final cpX = (p0.dx + p1.dx) / 2;
      path.cubicTo(cpX, p0.dy, cpX, p1.dy, p1.dx, p1.dy);

      final tx0 = (size.width / steps) * (i - 1);
      final ty0 = centerY - (normalizedTrail[i - 1] * (size.height * 0.36));
      final tx1 = (size.width / steps) * i;
      final ty1 = centerY - (normalizedTrail[i] * (size.height * 0.36));
      final tcpX = (tx0 + tx1) / 2;
      trailPath.cubicTo(tcpX, ty0, tcpX, ty1, tx1, ty1);
    }

    final trailPaint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 1.5
      ..color = color.withValues(alpha: 0.28);
    canvas.drawPath(trailPath, trailPaint);

    final areaPath = Path.from(path)
      ..lineTo(points.last.dx, centerY)
      ..lineTo(points.first.dx, centerY)
      ..close();
    final areaPaint = Paint()
      ..shader = LinearGradient(
        begin: Alignment.topCenter,
        end: Alignment.bottomCenter,
        colors: [
          color.withValues(alpha: 0.28),
          color.withValues(alpha: 0.06),
        ],
      ).createShader(Rect.fromLTWH(0, 0, size.width, size.height));
    canvas.drawPath(areaPath, areaPaint);

    final glow = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 10 + (3 * math.sin(phase * 2 * math.pi))
      ..color = color.withValues(alpha: 0.12)
      ..maskFilter = const MaskFilter.blur(BlurStyle.normal, 10);
    canvas.drawPath(path, glow);

    final line = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = 2.5
      ..color = color.withValues(alpha: 0.95);
    canvas.drawPath(path, line);

    final scanX = size.width * phase;
    final scanPaint = Paint()
      ..shader = LinearGradient(
        colors: [
          Colors.transparent,
          color.withValues(alpha: 0.22),
          Colors.transparent,
        ],
      ).createShader(Rect.fromLTWH(scanX - 18, 0, 36, size.height));
    canvas.drawRect(Rect.fromLTWH(scanX - 18, 0, 36, size.height), scanPaint);
  }

  @override
  bool shouldRepaint(covariant _EqCurvePainter oldDelegate) {
    if (oldDelegate.phase != phase || oldDelegate.color != color) return true;
    if (oldDelegate.values.length != values.length) return true;
    if (oldDelegate.trailValues.length != trailValues.length) return true;
    for (var i = 0; i < values.length; i++) {
      if (oldDelegate.values[i] != values[i]) return true;
      if (oldDelegate.trailValues[i] != trailValues[i]) return true;
    }
    return false;
  }
}
