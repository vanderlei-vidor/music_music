// lib/widgets/custom_button.dart

import 'package:flutter/material.dart';

class CustomButton extends StatelessWidget {
  final String text;
  final VoidCallback onPressed;

  const CustomButton({
    super.key,
    required this.text,
    required this.onPressed,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);

    return ElevatedButton(
      onPressed: onPressed,
      style: ElevatedButton.styleFrom(
        foregroundColor: theme.colorScheme.onPrimary, // âœ… Cor do texto sobre fundo primÃ¡rio
        backgroundColor: theme.colorScheme.primary,   // âœ… Cor de fundo do tema
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        shadowColor: theme.colorScheme.primary.withValues(alpha: 0.5), // âœ… Sombra adaptÃ¡vel
        elevation: 10,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          // NÃ£o precisa de cor aqui, pois `foregroundColor` jÃ¡ define
        ),
      ),
    );
  }
}
