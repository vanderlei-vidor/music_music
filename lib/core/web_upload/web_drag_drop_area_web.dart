import 'dart:html' as html;
import 'package:flutter/material.dart';

class WebDragDropArea extends StatefulWidget {
  // Mudamos de html.File para dynamic para evitar erro de compilação no Windows
  final void Function(List<dynamic>) onFiles;
  

  const WebDragDropArea({
    super.key,
    required this.onFiles,
  });

  @override
  State<WebDragDropArea> createState() => _WebDragDropAreaState();
}

class _WebDragDropAreaState extends State<WebDragDropArea> {
  late html.FileUploadInputElement _input;
  bool _hover = false;

  @override
  void initState() {
    super.initState();

    _input = html.FileUploadInputElement()
      ..accept = '.mp3,.wav,.aac'
      ..multiple = true
      ..style.display = 'none';

    _input.onChange.listen((_) {
      final files = _input.files;
      if (files != null && files.isNotEmpty) {
        // Passamos a lista normalmente, o Dart cuidará do cast no destino
        widget.onFiles(files);
      }
    });

    html.document.body?.append(_input);

    // Evita que o navegador abra o arquivo ao arrastar para fora da área
    html.window.onDragOver.listen((e) {
      e.preventDefault();
      if (!_hover) setState(() => _hover = true);
    });
    
    html.window.onDragLeave.listen((e) => setState(() => _hover = false));

    html.window.onDrop.listen((e) {
      e.preventDefault();
      setState(() => _hover = false);
      final files = e.dataTransfer.files;
      if (files != null && files.isNotEmpty) {
        widget.onFiles(files);
      }
    });
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
      child: MouseRegion( // Adicionado para melhorar o feedback visual
        onEnter: (_) => setState(() => _hover = true),
        onExit: (_) => setState(() => _hover = false),
        child: Container(
          height: 180,
          decoration: BoxDecoration(
            color: _hover ? Colors.blue.withOpacity(0.05) : Colors.transparent,
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
                Text('Arraste ou clique para enviar músicas'),
              ],
            ),
          ),
        ),
      ),
    );
  }
}