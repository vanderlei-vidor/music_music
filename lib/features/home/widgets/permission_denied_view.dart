import 'package:flutter/material.dart';
import 'package:permission_handler/permission_handler.dart';

class PermissionDeniedView extends StatelessWidget {
  final VoidCallback? onRetry;

  const PermissionDeniedView({super.key, this.onRetry});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return Center(
      child: Padding(
        padding: const EdgeInsets.all(32),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.library_music,
              size: 96,
              color: theme.colorScheme.primary,
            ),
            const SizedBox(height: 24),
            Text(
              'Permissão necessária',
              style: theme.textTheme.headlineSmall,
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              'Para mostrar suas músicas, precisamos acessar o armazenamento do dispositivo.',
              textAlign: TextAlign.center,
              style: theme.textTheme.bodyMedium,
            ),
            const SizedBox(height: 28),
            ElevatedButton.icon(
              icon: const Icon(Icons.settings),
              label: const Text('Abrir configurações'),
              onPressed: () {
                openAppSettings();
              },
            ),
            const SizedBox(height: 12),
            OutlinedButton.icon(
              icon: const Icon(Icons.refresh),
              label: const Text('Tentar novamente'),
              onPressed: onRetry,
            ),
          ],
        ),
      ),
    );
  }
}
