import 'package:flutter/material.dart';

class SwipeToRevealActions extends StatefulWidget {
  final Widget child;
  final VoidCallback onDelete;
  final VoidCallback onToggleFavorite;
  final bool isFavorite;
  final double height;

  const SwipeToRevealActions({
    super.key,
    required this.child,
    required this.onDelete,
    required this.onToggleFavorite,
    required this.isFavorite,
    this.height = 72,
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
        title: const Text('Remover mÃºsica'),
        content: const Text('Deseja remover esta mÃºsica da playlist?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Remover'),
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

    return SizedBox(
      height: widget.height,
      child: Stack(
        children: [
          // ðŸŽ¯ GAVETA FIXA
          Positioned.fill(
            child: Align(
              alignment: Alignment.centerRight,
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
                    // â­ FAVORITO
                    IconButton(
                      icon: Icon(
                        widget.isFavorite
                            ? Icons.favorite
                            : Icons.favorite_border,
                        color: widget.isFavorite
                            ? Colors.redAccent
                            : theme.colorScheme.onSurfaceVariant,
                      ),
                      onPressed: widget.onToggleFavorite,
                    ),

                    // ðŸ—‘ï¸ DELETE
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

          // ðŸŽµ ITEM DESLIZÃVEL
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

