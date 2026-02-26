import 'package:flutter/material.dart';
import 'package:music_music/app/routes.dart';
import 'package:music_music/features/home/widgets/folder_card.dart';
import 'package:provider/provider.dart';

import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/features/home/view_model/home_view_model.dart';
import 'package:music_music/core/theme/app_shadows.dart';
import 'package:music_music/core/ui/responsive.dart';
import 'package:music_music/shared/widgets/skeleton.dart';

class FoldersView extends StatefulWidget {
  const FoldersView({super.key});

  @override
  State<FoldersView> createState() => _FoldersViewState();
}

class _FoldersViewState extends State<FoldersView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  String _query = '';
  _FolderSort _sort = _FolderSort.az;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 700),
    );

    _controller.forward();
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final musics = context.watch<HomeViewModel>().musics;
    final folders = <String, List<MusicEntity>>{};

    for (final music in musics) {
      final folder = (music.folderPath == null || music.folderPath!.isEmpty)
          ? 'Desconhecido'
          : music.folderPath!;
      folders.putIfAbsent(folder, () => []).add(music);
    }

    final folderPaths = folders.keys.toList();
    final filteredPaths = folderPaths
        .where(
          (path) => path
              .split(RegExp(r'[\\/]'))
              .last
              .toLowerCase()
              .contains(_query.trim().toLowerCase()),
        )
        .toList();
    filteredPaths.sort((a, b) {
      switch (_sort) {
        case _FolderSort.az:
          return a.toLowerCase().compareTo(b.toLowerCase());
        case _FolderSort.mostSongs:
          return folders[b]!.length.compareTo(folders[a]!.length);
      }
    });
    final columns = Responsive.value(
      context,
      compact: 2,
      medium: 3,
      expanded: 4,
    );
    final crossSpacing = Responsive.value(
      context,
      compact: 12.0,
      medium: 14.0,
      expanded: 16.0,
    );
    final mainSpacing = Responsive.value(
      context,
      compact: 14.0,
      medium: 16.0,
      expanded: 18.0,
    );
    final mainExtent =
        Responsive.value(
          context,
          compact: 172.0,
          medium: 184.0,
          expanded: 196.0,
        ) +
        ((MediaQuery.textScalerOf(context).scale(1.0) - 1.0).clamp(0.0, 0.6) *
            34);

    if (folderPaths.isEmpty) {
      return const _FoldersSkeleton();
    }

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (value) => setState(() => _query = value),
            decoration: InputDecoration(
              hintText: 'Buscar pasta (${filteredPaths.length})',
              prefixIcon: const Icon(Icons.search_rounded),
              isDense: true,
              filled: true,
              fillColor: Theme.of(context).colorScheme.surfaceContainerHighest,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ),
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
          child: Row(
            children: [
              ChoiceChip(
                label: const Text('A-Z'),
                selected: _sort == _FolderSort.az,
                onSelected: (_) => setState(() => _sort = _FolderSort.az),
              ),
              const SizedBox(width: 8),
              ChoiceChip(
                label: const Text('Mais músicas'),
                selected: _sort == _FolderSort.mostSongs,
                onSelected: (_) => setState(() => _sort = _FolderSort.mostSongs),
              ),
            ],
          ),
        ),
        Expanded(
          child: filteredPaths.isEmpty
              ? const _FoldersEmptyState()
              : GridView.builder(
                  padding: const EdgeInsets.all(16),
                  physics: const BouncingScrollPhysics(),
                  gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: columns,
                    mainAxisSpacing: mainSpacing,
                    crossAxisSpacing: crossSpacing,
                    mainAxisExtent: mainExtent,
                  ),
                  itemCount: filteredPaths.length,
                  itemBuilder: (context, index) {
                    final path = filteredPaths[index];
                    final musics = folders[path]!;
                    final folderName = path.split(RegExp(r'[\\/]')).last;

                    return AnimatedBuilder(
                      animation: _controller,
                      child: FolderCard(
                        folderName: folderName,
                        musics: musics,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRoutes.folderDetail,
                            arguments: FolderDetailArgs(
                              folderName: folderName,
                              musics: musics,
                            ),
                          );
                        },
                      ),
                      builder: (context, child) {
                        final animation = CurvedAnimation(
                          parent: _controller,
                          curve: Interval(
                            (index / filteredPaths.length).clamp(0.0, 1.0),
                            1.0,
                            curve: Curves.easeOutCubic,
                          ),
                        );

                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0, 0.15),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                    );
                  },
                ),
        ),
      ],
    );
  }
}

enum _FolderSort { az, mostSongs }

class _FoldersEmptyState extends StatelessWidget {
  const _FoldersEmptyState();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Text(
        'Nenhuma pasta encontrada',
        style: Theme.of(context).textTheme.bodyMedium,
      ),
    );
  }
}

class _FoldersSkeleton extends StatelessWidget {
  const _FoldersSkeleton();

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final shadows = theme.extension<AppShadows>()?.elevated ?? [];
    final columns = Responsive.value(
      context,
      compact: 2,
      medium: 3,
      expanded: 4,
    );
    final crossSpacing = Responsive.value(
      context,
      compact: 12.0,
      medium: 14.0,
      expanded: 16.0,
    );
    final mainSpacing = Responsive.value(
      context,
      compact: 14.0,
      medium: 16.0,
      expanded: 18.0,
    );
    final mainExtent = Responsive.value(
      context,
      compact: 172.0,
      medium: 184.0,
      expanded: 196.0,
    );

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: columns,
        mainAxisSpacing: mainSpacing,
        crossAxisSpacing: crossSpacing,
        mainAxisExtent: mainExtent,
      ),
      itemCount: 6,
      itemBuilder: (_, __) {
        return Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              decoration: BoxDecoration(
                color: theme.colorScheme.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(16),
                boxShadow: shadows,
              ),
              child: const Skeleton(
                width: double.infinity,
                height: 140,
                borderRadius: BorderRadius.all(Radius.circular(16)),
              ),
            ),
            const SizedBox(height: 10),
            const Skeleton(width: double.infinity, height: 12),
            const SizedBox(height: 6),
            const Skeleton(width: 80, height: 10),
          ],
        );
      },
    );
  }
}
