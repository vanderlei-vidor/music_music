import 'dart:io';

import 'package:mime/mime.dart';
import 'package:path_provider/path_provider.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;

class WifiUploadServer {
  HttpServer? _server;

  Future<String> start() async {
    final dir = await getApplicationDocumentsDirectory();

    Future<Response> handler(Request request) async {
      if (request.method == 'GET') {
        return Response.ok(
          _htmlPage(),
          headers: {'content-type': 'text/html; charset=utf-8'},
        );
      }

      if (request.method == 'POST') {
        try {
          final saved = await _saveUploadedFiles(request, dir.path);
          if (saved == 0) {
            return Response(400, body: 'Nenhum arquivo de audio foi recebido.');
          }
          return Response.ok('Upload concluido: $saved arquivo(s).');
        } catch (_) {
          return Response.internalServerError(
            body: 'Falha ao processar o upload.',
          );
        }
      }

      return Response.notFound('Not found');
    }

    _server = await io.serve(handler, InternetAddress.anyIPv4, 8080);
    final lanIp = await _resolveLanIPv4();
    return lanIp ?? _server!.address.address;
  }

  void stop() {
    _server?.close();
  }

  Future<int> _saveUploadedFiles(Request request, String targetDir) async {
    final contentTypeHeader = request.headers[HttpHeaders.contentTypeHeader];
    if (contentTypeHeader == null || contentTypeHeader.isEmpty) {
      return 0;
    }

    final contentType = ContentType.parse(contentTypeHeader);
    final boundary = contentType.parameters['boundary'];

    if (contentType.mimeType == 'multipart/form-data' &&
        boundary != null &&
        boundary.isNotEmpty) {
      final multipart = MimeMultipartTransformer(boundary).bind(request.read());
      var saved = 0;

      await for (final part in multipart) {
        final disposition = part.headers['content-disposition'] ?? '';
        final fileName = _extractFileName(disposition);
        if (fileName == null || fileName.isEmpty) {
          await part.drain<void>();
          continue;
        }

        final bytes = await _collectBytes(part);
        if (bytes.isEmpty) continue;

        final sanitized = _sanitizeFileName(fileName);
        final uniqueName =
            '${DateTime.now().millisecondsSinceEpoch}_$sanitized';
        final file = File('$targetDir/$uniqueName');
        await file.writeAsBytes(bytes, flush: true);
        saved++;
      }

      return saved;
    }

    final bytes = await _collectBytes(request.read());
    if (bytes.isEmpty) return 0;

    final extension = _extensionFor(contentType.mimeType);
    final file = File(
      '$targetDir/${DateTime.now().millisecondsSinceEpoch}.$extension',
    );
    await file.writeAsBytes(bytes, flush: true);
    return 1;
  }

  Future<List<int>> _collectBytes(Stream<List<int>> stream) async {
    final data = <int>[];
    await for (final chunk in stream) {
      data.addAll(chunk);
    }
    return data;
  }

  String? _extractFileName(String disposition) {
    final utf8Match = RegExp(
      r"filename\*=UTF-8''([^;]+)",
      caseSensitive: false,
    ).firstMatch(disposition);
    if (utf8Match != null) {
      return Uri.decodeComponent(utf8Match.group(1)!.trim());
    }

    final quotedMatch = RegExp(
      r'filename="([^"]+)"',
      caseSensitive: false,
    ).firstMatch(disposition);
    if (quotedMatch != null) return quotedMatch.group(1)!.trim();

    final plainMatch = RegExp(
      r'filename=([^;]+)',
      caseSensitive: false,
    ).firstMatch(disposition);
    if (plainMatch != null) {
      return plainMatch.group(1)!.trim().replaceAll('"', '');
    }

    return null;
  }

  String _sanitizeFileName(String input) {
    final normalized = input.trim();
    final safe = normalized.replaceAll(RegExp(r'[^\w\-.]'), '_');
    if (safe.isEmpty) return 'audio.mp3';
    return safe;
  }

  String _extensionFor(String mimeType) {
    switch (mimeType) {
      case 'audio/mpeg':
      case 'audio/mp3':
        return 'mp3';
      case 'audio/mp4':
      case 'audio/x-m4a':
        return 'm4a';
      case 'audio/wav':
      case 'audio/x-wav':
        return 'wav';
      case 'audio/aac':
        return 'aac';
      case 'audio/flac':
      case 'audio/x-flac':
        return 'flac';
      default:
        return 'bin';
    }
  }

  Future<String?> _resolveLanIPv4() async {
    final interfaces = await NetworkInterface.list(
      type: InternetAddressType.IPv4,
      includeLoopback: false,
    );

    for (final iface in interfaces) {
      for (final addr in iface.addresses) {
        final ip = addr.address;
        if (!ip.startsWith('169.254.')) {
          return ip;
        }
      }
    }
    return null;
  }

  String _htmlPage() {
    return '''
<!DOCTYPE html>
<html>
<head>
  <meta charset="utf-8" />
  <title>Importar musicas</title>
</head>
<body>
<h2>Enviar musicas</h2>
<form method="post" enctype="multipart/form-data">
<input type="file" name="file" multiple />
<button type="submit">Enviar</button>
</form>
</body>
</html>
''';
  }
}
