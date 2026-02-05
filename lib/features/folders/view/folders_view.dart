import 'package:flutter/material.dart';
import 'package:music_music/app/routes.dart';
import 'package:music_music/features/home/widgets/folder_card.dart';
import 'package:provider/provider.dart';

import 'package:music_music/data/models/music_entity.dart';
import 'package:music_music/features/playlists/view_model/playlist_view_model.dart';

class FoldersView extends StatefulWidget {
  const FoldersView({super.key});

  @override
  State<FoldersView> createState() => _FoldersViewState();
}

class _FoldersViewState extends State<FoldersView>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;

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
    final folders = context.watch<PlaylistViewModel>().folders;
    final folderPaths = folders.keys.toList()..sort();

    if (folderPaths.isEmpty) {
      return const Center(
        child: Text('Nenhuma pasta encontrada'),
      );
    }

    return GridView.builder(
      padding: const EdgeInsets.all(16),
      physics: const BouncingScrollPhysics(),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2,
        mainAxisSpacing: 16,
        crossAxisSpacing: 16,
        childAspectRatio: 1,
      ),
      itemCount: folderPaths.length,
      itemBuilder: (context, index) {
        final path = folderPaths[index];
        final musics = folders[path]!;
        final folderName = path.split('/').last;

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
                (index / folderPaths.length).clamp(0.0, 1.0),
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
    );
  }
}



