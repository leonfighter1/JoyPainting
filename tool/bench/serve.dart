import 'dart:convert';
import 'dart:io';

/// Serves a web build on this computer and waits for the page to post its
/// results to /result, which are saved to [args][1]; then it stops.
///
///   dart run tool/bench/serve.dart build/bench_web build/bench/web.json [port]
Future<void> main(List<String> args) async {
  final root = Directory(args[0]).absolute.path;
  final out = File(args[1]);
  final port = args.length > 2 ? int.parse(args[2]) : 8123;
  final server = await HttpServer.bind(InternetAddress.loopbackIPv4, port);
  stdout.writeln('Serving $root on http://127.0.0.1:$port/');
  await for (final request in server) {
    final response = request.response;
    if (request.method == 'POST' && request.uri.path == '/result') {
      final body = await utf8.decodeStream(request);
      await out.parent.create(recursive: true);
      await out.writeAsString(body);
      response.statusCode = HttpStatus.noContent;
      await response.close();
      stdout.writeln('Result saved: ${out.path}');
      await server.close(force: true);
      break;
    }
    final path = request.uri.path == '/' ? '/index.html' : request.uri.path;
    final file = File('$root${Uri.decodeComponent(path)}'.replaceAll('/', Platform.pathSeparator));
    if (!file.absolute.path.startsWith(root) || !await file.exists()) {
      response.statusCode = HttpStatus.notFound;
      await response.close();
      continue;
    }
    response.headers.contentType = _types[path.split('.').last] ??
        ContentType.binary;
    await response.addStream(file.openRead());
    await response.close();
  }
}

final _types = {
  'html': ContentType.html,
  'js': ContentType('application', 'javascript', charset: 'utf-8'),
  'mjs': ContentType('application', 'javascript', charset: 'utf-8'),
  'json': ContentType.json,
  'wasm': ContentType('application', 'wasm'),
  'css': ContentType('text', 'css', charset: 'utf-8'),
  'png': ContentType('image', 'png'),
  'ttf': ContentType('font', 'ttf'),
  'otf': ContentType('font', 'otf'),
  'wav': ContentType('audio', 'wav'),
};
