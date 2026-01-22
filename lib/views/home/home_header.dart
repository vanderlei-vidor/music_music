// lib/views/home/widgets/home_header.dart

import 'package:flutter/material.dart';
import 'package:music_music/views/home/home_view_model.dart';
import 'package:provider/provider.dart';

class HomeHeader extends StatelessWidget {
  const HomeHeader({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final vm = context.watch<HomeViewModel>();

    return Padding(
      padding: const EdgeInsets.fromLTRB(20, 16, 20, 12),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // 🎧 TÍTULO
          Text(
            'Sua Música',
            style: theme.textTheme.headlineMedium?.copyWith(
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 16),

          // 🔍 BUSCA
          TextField(
            onChanged: (value) {
              // No passo 2 vamos ligar com PageView
              vm.searchMusics(value);
            },
            decoration: InputDecoration(
              hintText: 'Buscar músicas, artistas...',
              prefixIcon: const Icon(Icons.search),
              filled: true,
              fillColor: theme.colorScheme.surface,
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
