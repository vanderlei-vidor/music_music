import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';

import 'package:music_music/core/theme/theme_manager.dart';
import 'package:music_music/core/theme/app_colors.dart';
import 'package:music_music/core/theme/app_shadows.dart';
import 'package:music_music/core/preferences/podcast_preferences.dart';

class ThemeSettingsView extends StatelessWidget {
  const ThemeSettingsView({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final manager = context.watch<ThemeManager>();
    final podcastPrefs = context.watch<PodcastPreferences>();

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        title: Text('Personalização', style: theme.textTheme.headlineSmall),
        backgroundColor: Colors.transparent,
        elevation: 0,
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: manager.preset == ThemePreset.neumorphicDark
              ? PremiumGradients.darkLiquid
              : null,
          color: manager.preset == ThemePreset.whiteMinimal
              ? theme.scaffoldBackgroundColor
              : null,
        ),
        child: ListView(
          padding: const EdgeInsets.fromLTRB(16, 120, 16, 16),
          children: [
            _ThemeCard(
              title: 'Pure White',
              subtitle: 'Minimalismo nórdico e clareza.',
              selected: manager.preset == ThemePreset.whiteMinimal,
              onTap: () {
                HapticFeedback.mediumImpact();
                manager.setPreset(ThemePreset.whiteMinimal);
              },
              preview: _ThemePreview.light(theme),
            ),
            const SizedBox(height: 20),
            _ThemeCard(
              title: 'Midnight Orange',
              subtitle: 'Profundidade cinematográfica com foco vibrante.',
              selected: manager.preset == ThemePreset.neumorphicDark,
              onTap: () {
                HapticFeedback.mediumImpact();
                manager.setPreset(ThemePreset.neumorphicDark);
              },
              preview: _ThemePreview.dark(theme),
            ),
            const SizedBox(height: 20),
            SwitchListTile.adaptive(
              value: podcastPrefs.enabled,
              onChanged: (v) => podcastPrefs.setEnabled(v),
              title: const Text('Mostrar aba Podcasts'),
              subtitle: const Text('Ativa podcasts na Home ao lado de Playlists.'),
            ),
          ],
        ),
      ),
    );
  }
}

class _ThemeCard extends StatelessWidget {
  final String title;
  final String subtitle;
  final bool selected;
  final VoidCallback onTap;
  final Widget preview;

  const _ThemeCard({
    required this.title,
    required this.subtitle,
    required this.selected,
    required this.onTap,
    required this.preview,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shadows = theme.extension<AppShadows>();

    return AnimatedContainer(
      duration: const Duration(milliseconds: 400),
      curve: Curves.easeInOutCubic,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24),
        boxShadow: selected
            ? (shadows?.elevated ??
                [
                  BoxShadow(
                    color: theme.colorScheme.primary.withValues(alpha: 0.25),
                    blurRadius: 24,
                    offset: const Offset(0, 12),
                  )
                ])
            : (shadows?.surface ?? []),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24),
        child: BackdropFilter(
          filter: ImageFilter.blur(sigmaX: 6, sigmaY: 6),
          child: InkWell(
            onTap: onTap,
            child: AnimatedContainer(
              duration: const Duration(milliseconds: 400),
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                color: selected
                    ? theme.colorScheme.primary.withValues(alpha: 0.12)
                    : theme.cardColor.withValues(alpha: 0.75),
                borderRadius: BorderRadius.circular(24),
                border: Border.all(
                  color: selected
                      ? theme.colorScheme.primary
                      : theme.dividerColor.withValues(alpha: 0.15),
                  width: selected ? 2 : 1,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          title,
                          style: theme.textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        const SizedBox(height: 6),
                        Text(
                          subtitle,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            color: theme.colorScheme.onSurface.withValues(alpha: 0.6),
                          ),
                        ),
                      ],
                    ),
                  ),
                  preview,
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
class _ThemePreview extends StatelessWidget {
  final Color bg;
  final Color surface;
  final Color primary;

  const _ThemePreview({
    required this.bg,
    required this.surface,
    required this.primary,
  });

  factory _ThemePreview.light(ThemeData theme) {
    return _ThemePreview(
      bg: const Color(0xFFF6F5F2),
      surface: const Color(0xFFFFFFFF),
      primary: theme.colorScheme.primary,
    );
  }

  factory _ThemePreview.dark(ThemeData theme) {
    return _ThemePreview(
      bg: const Color(0xFF1A1C21),
      surface: const Color(0xFF21242A),
      primary: const Color(0xFFFF6B2D),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 72,
      height: 56,
      decoration: BoxDecoration(
        color: bg,
        borderRadius: BorderRadius.circular(14),
      ),
      child: Center(
        child: Container(
          width: 44,
          height: 32,
          decoration: BoxDecoration(
            color: surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: Theme.of(context)
                    .extension<AppShadows>()
                    ?.surface ??
                [
                  BoxShadow(
                    color: Colors.black.withValues(alpha: 0.25),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ],
          ),
          child: Center(
            child: Container(
              width: 16,
              height: 16,
              decoration: BoxDecoration(
                color: primary,
                shape: BoxShape.circle,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
