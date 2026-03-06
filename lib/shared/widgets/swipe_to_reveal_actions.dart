import 'package:flutter/material.dart';

class SwipeToRevealActions extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;
  final bool isFavorite;
  final double height;
  final String deleteDialogTitle;
  final String deleteDialogMessage;
  final String deleteConfirmLabel;

  const SwipeToRevealActions({
    super.key,
    required this.child,
    required this.onDelete,
    required this.onToggleFavorite,
    required this.isFavorite,
    this.height = 72,
    this.deleteDialogTitle = 'Remover musica',
    this.deleteDialogMessage = 'Deseja remover esta musica da playlist?',
    this.deleteConfirmLabel = 'Remover',
  });

  @override
  State<SwipeToRevealActions> createState() => _SwipeToRevealActionsState();
}

class _SwipeToRevealActionsState extends State<SwipeToRevealActions> {
  double _offset = 0;
  static const double _maxOffset = -144;

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _offset += details.delta.dx;
      _offset = _offset.clamp(_maxOffset, 0);
    });
  }

  void _onDragEnd(_) {
    setState(() {
      _offset = _offset < _maxOffset / 2 ? _maxOffset : 0;
    });
  }

  Future<void> _confirmDelete() async {
    final result = await showDialog<bool>(
      context: context,
      builder: (_) => AlertDialog(
        title: Text(widget.deleteDialogTitle),
        content: Text(widget.deleteDialogMessage),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: Text(widget.deleteConfirmLabel),
          ),
        ],
      ),
    );

    if (result == true) {
      widget.onDelete();
      setState(() => _offset = 0);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final revealFraction = (-_offset / _maxOffset.abs()).clamp(0.0, 1.0);

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
              child: ClipRect(
                child: Align(
                  alignment: Alignment.centerRight,
                  widthFactor: revealFraction,
                  child: IgnorePointer(
                    ignoring: revealFraction < 0.35,
                    child: Container(
                      width: 144,
                      height: widget.height,
                      decoration: BoxDecoration(
                        color: theme.colorScheme.surfaceContainerHighest,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
                          IconButton(
                            icon: AnimatedSwitcher(
                              duration: const Duration(milliseconds: 180),
                              transitionBuilder: (child, animation) {
                                return ScaleTransition(
                                  scale: animation,
                                  child: child,
                                );
                              },
                              child: Icon(
                                widget.isFavorite
                                    ? Icons.favorite
                                    : Icons.favorite_border,
                                key: ValueKey<bool>(widget.isFavorite),
                                color: widget.isFavorite
                                    ? Colors.redAccent
                                    : theme.colorScheme.onSurfaceVariant,
                              ),
                            ),
                            onPressed: widget.onToggleFavorite,
                          ),
                          IconButton(
                            icon: const Icon(Icons.delete),
                            color: Colors.redAccent,
                            onPressed: _confirmDelete,
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ),
          GestureDetector(
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: Transform.translate(
              offset: Offset(_offset, 0),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
