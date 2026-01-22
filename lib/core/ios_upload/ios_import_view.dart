
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:music_music/core/ios_upload/wifi_upload_server.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:path_provider/path_provider.dart';


class IOSImportView extends StatefulWidget {
  const IOSImportView({super.key});

  @override
  State<IOSImportView> createState() => _IOSImportViewState();
}

class _IOSImportViewState extends State<IOSImportView> {
  String? address;
  final server = WifiUploadServer();

  @override
  void initState() {
    super.initState();
    _startServer();
  }

  Future<void> _startServer() async {
    final ip = await server.start();
    setState(() {
      address = 'http://$ip:8080';
    });
  }

  @override
  void dispose() {
    server.stop();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Importar músicas')),
      body: Center(
        child: address == null
            ? const CircularProgressIndicator()
            : Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text(
                    'Abra no navegador do seu computador:',
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 12),
                  SelectableText(
                    address!,
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              ),
      ),
    );
  }
}
