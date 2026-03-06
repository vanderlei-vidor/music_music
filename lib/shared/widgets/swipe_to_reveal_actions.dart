import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

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
  bool _isDragging = false;
  bool _isOpen = false;
  static const double _maxOffset = -144;
  static const double _openThresholdFactor = 0.35;
  static const double _openVelocity = -420;
  static const double _closeVelocity = 420;
  static const Duration _snapDuration = Duration(milliseconds: 220);

  void _onDragStart(DragStartDetails _) {
    _isDragging = true;
  }

  void _onDragUpdate(DragUpdateDetails details) {
    setState(() {
      _offset += details.delta.dx;
      _offset = _offset.clamp(_maxOffset, 0);
    });
  }

  void _onDragEnd(DragEndDetails details) {
    final velocity = details.primaryVelocity ?? 0;
    final openThreshold = _maxOffset * _openThresholdFactor;

    final shouldOpen =
        velocity <= _openVelocity ||
        (velocity < _closeVelocity && _offset <= openThreshold);
    final target = shouldOpen ? _maxOffset : 0.0;
    final nextIsOpen = target == _maxOffset;
    final changed = nextIsOpen != _isOpen;

    setState(() {
      _isDragging = false;
      _isOpen = nextIsOpen;
      _offset = target;
    });

    if (changed) {
      HapticFeedback.selectionClick();
    }
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
            onHorizontalDragStart: _onDragStart,
            onHorizontalDragUpdate: _onDragUpdate,
            onHorizontalDragEnd: _onDragEnd,
            child: AnimatedContainer(
              duration: _isDragging ? Duration.zero : _snapDuration,
              curve: Curves.easeOutCubic,
              transform: Matrix4.translationValues(_offset, 0, 0),
              child: widget.child,
            ),
          ),
        ],
      ),
    );
  }
}
