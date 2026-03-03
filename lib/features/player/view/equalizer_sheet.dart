import 'package:flutter/material.dart';
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
          if (vm.autoGenrePresetEnabled) {
            vm.syncGenre(currentGenre);
          }
          return Padding(
            padding: EdgeInsets.fromLTRB(
              16,
              12,
              16,
              16 + MediaQuery.of(context).viewInsets.bottom,
            ),
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
                _PresetRow(vm: vm),
                const SizedBox(height: 14),
                _AutomationRow(vm: vm),
                if (vm.autoGenrePresetEnabled) ...[
                  const SizedBox(height: 4),
                  _GenreDebugChip(vm: vm),
                ],
                const SizedBox(height: 8),
                _PreampSlider(vm: vm),
                const SizedBox(height: 12),
                Flexible(
                  child: ListView.builder(
                    shrinkWrap: true,
                    itemCount: vm.bands.length,
                    itemBuilder: (context, index) {
                      final band = vm.bands[index];
                      final value = vm.gainFor(band.frequencyHz);
                      return _BandSlider(
                        band: band,
                        value: value,
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
                      );
                    },
                  ),
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

class _BandSlider extends StatelessWidget {
  final EqualizerBand band;
  final double value;
  final ValueChanged<double> onChanged;
  final ValueChanged<double> onChangeEnd;

  const _BandSlider({
    required this.band,
    required this.value,
    required this.onChanged,
    required this.onChangeEnd,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 2),
      child: Row(
        children: [
          SizedBox(width: 64, child: Text(band.label)),
          Expanded(
            child: Slider(
              value: value,
              min: band.minDb,
              max: band.maxDb,
              divisions: 48,
              onChanged: onChanged,
              onChangeEnd: onChangeEnd,
            ),
          ),
          SizedBox(
            width: 54,
            child: Text(
              '${value >= 0 ? '+' : ''}${value.toStringAsFixed(1)}',
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }
}
