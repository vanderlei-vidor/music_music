import 'package:flutter/material.dart';

class AppStateView extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final bool isLoading;
  final String? actionLabel;
  final VoidCallback? onAction;

  const AppStateView.loading({
    super.key,
    this.title = 'Carregando...',
    this.subtitle,
  }) : icon = Icons.hourglass_top_rounded,
       isLoading = true,
       actionLabel = null,
       onAction = null;

  const AppStateView.empty({
    super.key,
    required this.icon,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  }) : isLoading = false;

  const AppStateView.error({
    super.key,
    this.icon = Icons.error_outline_rounded,
    required this.title,
    this.subtitle,
    this.actionLabel,
    this.onAction,
  }) : isLoading = false;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (isLoading)
              const SizedBox(
                width: 28,
                height: 28,
                child: CircularProgressIndicator(strokeWidth: 2.4),
              )
            else
              Icon(icon, size: 68, color: theme.colorScheme.primary),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: theme.textTheme.titleMedium?.copyWith(
                fontWeight: FontWeight.w700,
              ),
            ),
            if (subtitle != null) ...[
              const SizedBox(height: 8),
              Text(
                subtitle!,
                textAlign: TextAlign.center,
                style: theme.textTheme.bodyMedium?.copyWith(
                  color: theme.colorScheme.onSurface.withValues(alpha: 0.74),
                ),
              ),
            ],
            if (actionLabel != null && onAction != null) ...[
              const SizedBox(height: 14),
              FilledButton(
                onPressed: onAction,
                child: Text(actionLabel!),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
