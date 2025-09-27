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
        foregroundColor: theme.colorScheme.onPrimary, // ✅ Cor do texto sobre fundo primário
        backgroundColor: theme.colorScheme.primary,   // ✅ Cor de fundo do tema
        padding: const EdgeInsets.symmetric(horizontal: 40, vertical: 15),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(30),
        ),
        shadowColor: theme.colorScheme.primary.withOpacity(0.5), // ✅ Sombra adaptável
        elevation: 10,
      ),
      child: Text(
        text,
        style: TextStyle(
          fontSize: 16,
          fontWeight: FontWeight.bold,
          // Não precisa de cor aqui, pois `foregroundColor` já define
        ),
      ),
    );
  }
}