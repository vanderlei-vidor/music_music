import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as io;
import 'package:path_provider/path_provider.dart';

class WifiUploadServer {
  HttpServer? _server;

  Future<String> start() async {
    final dir = await getApplicationDocumentsDirectory();

    final handler = (Request request) async {
      if (request.method == 'GET') {
        return Response.ok(_htmlPage(),
            headers: {'content-type': 'text/html'});
      }

      if (request.method == 'POST') {
        final content = await request.read().expand((i) => i).toList();
        final file = File(
          '${dir.path}/${DateTime.now().millisecondsSinceEpoch}.mp3',
        );
        await file.writeAsBytes(content);
        return Response.ok('Upload concluído');
      }

      return Response.notFound('Not found');
    };

    _server = await io.serve(handler, InternetAddress.anyIPv4, 8080);

    return _server!.address.address;
  }

  void stop() {
    _server?.close();
  }

  String _htmlPage() {
    return '''
<!DOCTYPE html>
<html>
<body>
<h2>Enviar músicas</h2>
<form method="post" enctype="multipart/form-data">
<input type="file" name="file" multiple />
<button type="submit">Enviar</button>
</form>
</body>
</html>
''';
  }
}
