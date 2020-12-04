import 'dart:io';

import 'package:http_server/http_server.dart';

import 'listener.dart';

class Dartspatcher {
  static final Dartspatcher _dartspatcher = Dartspatcher._internal();
  Map<String, List<Listener>> listeners = {'GET': [], 'DELETE': [], 'PATCH': [], 'POST': [], 'PUT': []};
  HttpServer server;
  HttpRequest request;
  dynamic body;
  Map<String, String> headers = {};
  Map<dynamic, dynamic> locals = {};

  factory Dartspatcher() {
    return _dartspatcher;
  }

  Dartspatcher._internal();

  void _setHeaders(HttpResponse response) {
    headers.forEach((key, value) {
      response.headers.add(key, value);
    });
  }

  void _setListeners(String method, String path, Function callback, [Map<dynamic, dynamic> locals]) {
    String regExp = path.replaceAll(RegExp(r':[a-zA-Z0-9]+'), '[a-zA-Z0-9]+');
    listeners[method].add(Listener(path, callback, RegExp(r'' + regExp + ''), locals));
  }

  Map<String, dynamic> _parseRoute() {
    String path = request.uri.path;
    Map<String, dynamic> params = {'uri': {}, 'query': request.uri.queryParameters, 'body': null};
    Map<String, dynamic> result = {'listener': null, 'params': params};
    for (final Listener listener in listeners[request.method]) {
      if (listener.path == path) {
        result['listener'] = listener;
        break;
      }
    }
    if (result['listener'] is! Listener) {
      for (final Listener listener in listeners[request.method]) {
        var match = listener.regExp.stringMatch(path);
        if (match == path) {
          List<String> requestUriList = path.split('/')..removeAt(0);
          List<String> matchUriList = listener.path.split('/')..removeAt(0);
          for (int x = 0; x < requestUriList.length; x++) {
            if (matchUriList[x].startsWith(':')) {
              result['params']['uri'][matchUriList[x].replaceAll(':', '')] = requestUriList[x];
            }
          }
          result['listener'] = listener;
          break;
        }
      }
    }
    return result;
  }

  void _ok() {
    request.response.statusCode = HttpStatus.ok;
  }

  void _notFound() {
    request.response
      ..statusCode = HttpStatus.notFound
      ..close();
  }

  void _internalServerError(e, s) {
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write("Exception in handleRequest: $e.")
      ..write("StackTrace in handleRequest: $s.")
      ..close();
  }

  void _methodNotAllowed() {
    request.response
      ..statusCode = HttpStatus.methodNotAllowed
      ..write("Unsupported request: ${request.method}.")
      ..close();
  }

  void setHeaders(Map<String, String> headers) {
    this.headers = headers;
  }

  void get(String path, Function callback, [Map<dynamic, dynamic> locals]) {
    _setListeners('GET', path, callback, locals);
  }

  void delete(String path, Function callback, [Map<dynamic, dynamic> locals]) {
    _setListeners('DELETE', path, callback);
  }

  void patch(String path, Function callback, [Map<dynamic, dynamic> locals]) {
    _setListeners('PATCH', path, callback);
  }

  void post(String path, Function callback, [Map<dynamic, dynamic> locals]) {
    _setListeners('POST', path, callback);
  }

  void put(String path, Function callback, [Map<dynamic, dynamic> locals]) {
    _setListeners('PUT', path, callback);
  }

  void _on() {
    try {
      _setHeaders(request.response);
      if (!request.response.headers['access-control-allow-methods'].toString().contains(request.method)) {
        _methodNotAllowed();
        return;
      }
      Map<String, dynamic> result = _parseRoute();
      result['params']['body'] = body;
      if (result['listener'] is Listener) {
        _ok();
        result['listener'].callback(request, result['params'], result['listener'].locals);
      } else {
        _notFound();
      }
    } catch (e, s) {
      print('Exception in handleRequest: $e');
      print('StackTrace in handleRequest: $s');
      _internalServerError(e, s);
    }
  }

  void listen(InternetAddress internetAddress, int port, [Function callback]) async {
    server = await HttpServer.bind(internetAddress, port);
    callback(server);
    server.transform(HttpBodyHandler()).listen((HttpRequestBody body) {
      this.body = body.body;
      request = body.request;
      _on();
    });
  }
}
