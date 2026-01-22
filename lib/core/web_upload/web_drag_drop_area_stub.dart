import 'package:flutter/material.dart';

class WebDragDropArea extends StatelessWidget {
  const WebDragDropArea({
    super.key,
    required this.onFiles,
  });

  final void Function(List<dynamic>) onFiles;

  @override
  Widget build(BuildContext context) {
    return const SizedBox.shrink();
  }
}
