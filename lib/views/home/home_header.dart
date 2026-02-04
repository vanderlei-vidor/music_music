// lib/views/home/home_header.dart
import 'package:flutter/material.dart';
import 'package:music_music/views/home/home_view_model.dart';
import 'package:provider/provider.dart';

class HomeHeader extends StatefulWidget {
  final bool canPlay;
  final Future<void> Function()? onPlayAll;
  final Future<void> Function()? onShuffleAll;
  final VoidCallback? onClearSearch;

  const HomeHeader({
    super.key,
    required this.canPlay,
    this.onPlayAll,
    this.onShuffleAll,
    this.onClearSearch,
  });

  @override
  State<HomeHeader> createState() => _HomeHeaderState();
}

class _HomeHeaderState extends State<HomeHeader> {
  final TextEditingController _controller = TextEditingController();
  bool _hasText = false;

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _clearSearch(HomeViewModel vm) {
    _controller.clear();
    vm.searchMusics('');
    setState(() => _hasText = false);
    widget.onClearSearch?.call();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.watch<HomeViewModel>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Sua MÃºsica',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 16),
          TextField(
            controller: _controller,
            onChanged: (value) {
              setState(() => _hasText = value.isNotEmpty);
              vm.searchMusics(value);
            },
            decoration: InputDecoration(
              hintText: 'Buscar mÃºsicas, artistas...',
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _hasText
                  ? IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => _clearSearch(vm),
                    )
                  : null,
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
          const SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  onPressed: widget.canPlay
                      ? () => widget.onPlayAll?.call()
                      : null,
                  icon: const Icon(Icons.play_arrow),
                  label: const Text('Tocar tudo'),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: OutlinedButton.icon(
                  onPressed: widget.canPlay
                      ? () => widget.onShuffleAll?.call()
                      : null,
                  icon: const Icon(Icons.shuffle),
                  label: const Text('AleatÃ³rio'),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
