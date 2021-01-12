import 'dart:io';

import 'package:http_server/http_server.dart';

import 'middleware.dart';

class Dartspatcher {
  static final Dartspatcher _dartspatcher = Dartspatcher._internal();
  List<Middleware> _middlewares = [];
  Function errorHandler;
  HttpServer server;
  Map<String, String> headers = {};
  Map<dynamic, dynamic> locals = {};
  VirtualDirectory virtualDirectory;

  factory Dartspatcher() {
    return _dartspatcher;
  }

  Dartspatcher._internal();

  void setVirtualDirectory(String path) {
    virtualDirectory = VirtualDirectory(path);
  }

  void setMiddleware(List<Function> callbacks, [Map<dynamic, dynamic> locals]) {
    _middlewares.add(Middleware(callbacks, locals));
  }

  void setErrorHandler(Function callback) {
    errorHandler = callback;
  }

  void setHeaders(Map<String, String> headers) {
    this.headers = headers;
  }

  void _setResponseHeaders(HttpResponse response) {
    headers.forEach((String key, String value) {
      response.headers.add(key, value);
    });
  }

  void _setListeners(String method, String path, List<Function> callbacks,
      [Map<dynamic, dynamic> locals]) {
    String regExp = path.replaceAll(RegExp(r':[a-zA-Z0-9\.+]+'), '[a-zA-Z0-9\.+]+');
    _middlewares.add(Middleware.listener(
        callbacks, locals, method, path, RegExp(r'' + regExp + '')));
  }

  Map<String, dynamic> _parseRoute(HttpRequest request) {
    String path = request.uri.path;
    Map<String, dynamic> params = {
      'uri': {},
      'query': request.uri.queryParameters,
      'body': null
    };
    Map<String, dynamic> result = {'listener': null, 'params': params};
    for (final Middleware middleware in _middlewares) {
      if (request.method == middleware.method && middleware.path == path) {
        result['listener'] = middleware;
        break;
      }
    }
    if (result['listener'] is! Middleware) {
      for (final Middleware middleware in _middlewares) {
        if (request.method == middleware.method) {
          var match = middleware.regExp.stringMatch(path);
          if (match == path) {
            List<String> requestUriList = path.split('/')..removeAt(0);
            List<String> matchUriList = middleware.path.split('/')..removeAt(0);
            for (int x = 0; x < requestUriList.length; x++) {
              if (matchUriList[x].startsWith(':')) {
                result['params']['uri'][matchUriList[x].replaceAll(':', '')] =
                    requestUriList[x];
              }
            }
            result['listener'] = middleware;
            break;
          }
        }
      }
    }
    return result;
  }

  void close(HttpRequest request, int statusCode, [dynamic body = '']) {
    request.response
      ..statusCode = statusCode
      ..write(body)
      ..close();
  }

  void _ok(HttpRequest request) {
    request.response.statusCode = HttpStatus.ok;
  }

  void _notFound(HttpRequest request) {
    request.response
      ..statusCode = HttpStatus.notFound
      ..close();
  }

  void _internalServerError(HttpRequest request, e, s) {
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write("Exception in handleRequest: $e.")
      ..write("StackTrace in handleRequest: $s.")
      ..close();
  }

  void _methodNotAllowed(HttpRequest request) {
    request.response
      ..statusCode = HttpStatus.methodNotAllowed
      ..write("Unsupported request: ${request.method}.")
      ..close();
  }

  void get(String path, List<Function> callbacks,
      [Map<dynamic, dynamic> locals]) {
    _setListeners('GET', path, callbacks, locals);
  }

  void head(String path, List<Function> callbacks,
      [Map<dynamic, dynamic> locals]) {
    _setListeners('HEAD', path, callbacks, locals);
  }

  void post(String path, List<Function> callbacks,
      [Map<dynamic, dynamic> locals]) {
    _setListeners('POST', path, callbacks);
  }

  void put(String path, List<Function> callbacks,
      [Map<dynamic, dynamic> locals]) {
    _setListeners('PUT', path, callbacks);
  }

  void delete(String path, List<Function> callbacks,
      [Map<dynamic, dynamic> locals]) {
    _setListeners('DELETE', path, callbacks);
  }

  void connect(String path, List<Function> callbacks,
      [Map<dynamic, dynamic> locals]) {
    _setListeners('CONNECT', path, callbacks, locals);
  }

  void options(String path, List<Function> callbacks,
      [Map<dynamic, dynamic> locals]) {
    _setListeners('OPTIONS', path, callbacks, locals);
  }

  void trace(String path, List<Function> callbacks,
      [Map<dynamic, dynamic> locals]) {
    _setListeners('TRACE', path, callbacks);
  }

  void patch(String path, List<Function> callbacks,
      [Map<dynamic, dynamic> locals]) {
    _setListeners('PATCH', path, callbacks);
  }

  void _on(HttpRequest request, dynamic body) {
    try {
      _setResponseHeaders(request.response);
      if (!request.response.headers['access-control-allow-methods']
          .toString()
          .contains(request.method)) {
        _methodNotAllowed(request);
        return;
      }
      Map<String, dynamic> result = _parseRoute(request);
      result['params']['body'] = body;
      if (result['listener'] != null) {
        _ok(request);

        List<Middleware> middlewaresChain = [];
        _middlewares.forEach((Middleware middleware) {
          if (middleware.method == null || middleware == result['listener']) {
            middlewaresChain.add(middleware);
          }
        });
        middlewaresChain.forEach((Middleware middleware) {
          middleware.callbacks.forEach((Function callback) {
            callback(request, result['params'], middleware.locals);
          });
        });
      } else {
        if (virtualDirectory != null) {
          virtualDirectory.serveRequest(request);
        } else {
          _notFound(request);
        }
      }
    } catch (e, s) {
      if (errorHandler != null) {
        errorHandler(request, e, s);
      } else {
        print('Exception in handleRequest: $e');
        print('StackTrace in handleRequest: $s');
        _internalServerError(request, e, s);
      }
    }
  }

  void listen(InternetAddress internetAddress, int port,
      [Function callback]) async {
    server = await HttpServer.bind(internetAddress, port);
    callback(server);
    server.transform(HttpBodyHandler()).listen((HttpRequestBody body) {
      _on(body.request, body.body);
    });
  }
}
