import 'dart:js_interop';
import 'package:flutter/material.dart';
import 'package:web/web.dart' as web;

class WebDragDropArea extends StatefulWidget {
  final void Function(List<dynamic>) onFiles;

  const WebDragDropArea({
    super.key,
    required this.onFiles,
  });

  @override
  State<WebDragDropArea> createState() => _WebDragDropAreaState();
}

class _WebDragDropAreaState extends State<WebDragDropArea> {
  late web.HTMLInputElement _input;
  bool _hover = false;

  List<dynamic> _toFileList(web.FileList? files) {
    if (files == null || files.length == 0) return <dynamic>[];
    final result = <dynamic>[];
    for (var i = 0; i < files.length; i++) {
      final file = files.item(i);
      if (file != null) result.add(file);
    }
    return result;
  }

  @override
  void initState() {
    super.initState();

    _input = web.HTMLInputElement()
      ..type = 'file'
      ..accept = '.mp3,.wav,.aac'
      ..multiple = true
      ..style.display = 'none';

    _input.addEventListener(
      'change',
      ((web.Event _) {
        final files = _toFileList(_input.files);
        if (files.isNotEmpty) {
          widget.onFiles(files);
        }
      }).toJS,
    );

    web.document.body?.append(_input);

    web.window.addEventListener(
      'dragover',
      ((web.Event event) {
        final dragEvent = event as web.DragEvent;
        dragEvent.preventDefault();
        if (!_hover && mounted) {
          setState(() => _hover = true);
        }
      }).toJS,
    );

    web.window.addEventListener(
      'dragleave',
      ((web.Event _) {
        if (mounted) setState(() => _hover = false);
      }).toJS,
    );

    web.window.addEventListener(
      'drop',
      ((web.Event event) {
        final dragEvent = event as web.DragEvent;
        dragEvent.preventDefault();
        if (mounted) setState(() => _hover = false);
        final files = _toFileList(dragEvent.dataTransfer?.files);
        if (files.isNotEmpty) {
          widget.onFiles(files);
        }
      }).toJS,
    );
  }

  @override
  void dispose() {
    _input.remove();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => _input.click(),
      child: MouseRegion(
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: _hover
                ? Colors.blue.withValues(alpha: 0.05)
                : Colors.transparent,
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: _hover ? Colors.blueAccent : Colors.grey.shade400,
              width: 2,
              style: BorderStyle.solid,
            ),
          ),
          child: const Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.cloud_upload, size: 42, color: Colors.blue),
                SizedBox(height: 12),
                Text('Arraste ou clique para enviar musicas'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
