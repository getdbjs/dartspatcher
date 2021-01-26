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

  /// Private constructor to provide a singleton
  Dartspatcher._internal();

  /// Set Virtual Directory path
  void setVirtualDirectory(String path) {
    virtualDirectory = VirtualDirectory(path);
  }

  /// Set server middlewares
  void setMiddleware(List<Function> callbacks, [Map<dynamic, dynamic> locals]) {
    _middlewares.add(Middleware(callbacks, locals));
  }

  /// Set error handler callback
  void setErrorHandler(Function callback) {
    errorHandler = callback;
  }

  /// Set global server response headers
  void setHeaders(Map<String, String> headers) {
    this.headers = headers;
  }

  /// Private method to set headers on specific request
  void _setResponseHeaders(HttpResponse response) {
    headers.forEach((String key, String value) {
      response.headers.add(key, value);
    });
  }

  /// Set listeners for server request paths
  void _setListeners(String method, String path, List<Function> callbacks,
      [Map<dynamic, dynamic> locals]) {
    String regExp =
        path.replaceAll(RegExp(r':[a-zA-Z0-9\.+]+'), '[a-zA-Z0-9\.+]+');
    _middlewares.add(Middleware.listener(
        callbacks, locals, method, path, RegExp(r'' + regExp + '')));
  }

  /// Match route requested with setted listeners
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

  /// Close http request
  void close(HttpRequest request, int statusCode, [dynamic body = '']) {
    request.response
      ..statusCode = statusCode
      ..write(body)
      ..close();
  }

  /// Set status code 200
  void _ok(HttpRequest request) {
    request.response.statusCode = HttpStatus.ok;
  }

  /// Set status code 404
  void _notFound(HttpRequest request) {
    request.response
      ..statusCode = HttpStatus.notFound
      ..close();
  }

  /// Set status code 500
  void _internalServerError(HttpRequest request, e, s) {
    request.response
      ..statusCode = HttpStatus.internalServerError
      ..write("Exception in handleRequest: $e.")
      ..write("StackTrace in handleRequest: $s.")
      ..close();
  }

  /// Set status code 405
  void _methodNotAllowed(HttpRequest request) {
    request.response
      ..statusCode = HttpStatus.methodNotAllowed
      ..write("Unsupported request: ${request.method}.")
      ..close();
  }

  /// Set listeners for GET request
  void get(String path, List<Function> callbacks,
      [Map<dynamic, dynamic> locals]) {
    _setListeners('GET', path, callbacks, locals);
  }

  /// Set listeners for HEAD request
  void head(String path, List<Function> callbacks,
      [Map<dynamic, dynamic> locals]) {
    _setListeners('HEAD', path, callbacks, locals);
  }

  /// Set listeners for POST request
  void post(String path, List<Function> callbacks,
      [Map<dynamic, dynamic> locals]) {
    _setListeners('POST', path, callbacks);
  }

  /// Set listeners for PUT request
  void put(String path, List<Function> callbacks,
      [Map<dynamic, dynamic> locals]) {
    _setListeners('PUT', path, callbacks);
  }

  /// Set listeners for DELETE request
  void delete(String path, List<Function> callbacks,
      [Map<dynamic, dynamic> locals]) {
    _setListeners('DELETE', path, callbacks);
  }

  /// Set listeners for CONNECT request
  void connect(String path, List<Function> callbacks,
      [Map<dynamic, dynamic> locals]) {
    _setListeners('CONNECT', path, callbacks, locals);
  }

  /// Set listeners for OPTIONS request
  void options(String path, List<Function> callbacks,
      [Map<dynamic, dynamic> locals]) {
    _setListeners('OPTIONS', path, callbacks, locals);
  }

  /// Set listeners for TRACE request
  void trace(String path, List<Function> callbacks,
      [Map<dynamic, dynamic> locals]) {
    _setListeners('TRACE', path, callbacks);
  }

  /// Set listeners for PATCH request
  void patch(String path, List<Function> callbacks,
      [Map<dynamic, dynamic> locals]) {
    _setListeners('PATCH', path, callbacks);
  }

  /// Listener for a request
  void _on(HttpRequest request, dynamic body) {
    try {
      _setResponseHeaders(request.response);
      if (!request.response.headers['access-control-allow-methods']
          .toString()
          .contains(request.method)) {
        _methodNotAllowed(request);
        return;
      }
      if (request.method == 'OPTIONS') {
        request.response
          ..statusCode = HttpStatus.ok
          ..close();
        return;
      }
      Map<String, dynamic> result = _parseRoute(request);
      result['params']['body'] = body;
      if (result['listener'] != null) {
        _ok(request);
        List<Function> middlewaresFunctionsChain = [];
        List<Map<dynamic, dynamic>> middlewaresLocalsChain = [];
        _middlewares.forEach((Middleware middleware) {
          if (middleware.method == null || middleware == result['listener']) {
            for (int i = 0; i < middleware.callbacks.length; i++) {
              middlewaresLocalsChain.add(middleware.locals);
            }
            middlewaresFunctionsChain.addAll(middleware.callbacks);
          }
        });
        Iterator<Function> functionsIterator =
            middlewaresFunctionsChain.iterator;
        Iterator<Map<dynamic, dynamic>> localsIterator =
            middlewaresLocalsChain.iterator;
        void next() {
          if (functionsIterator.moveNext()) {
            localsIterator.moveNext();
            functionsIterator.current(
                request, result['params'], next, localsIterator.current);
          }
        }

        functionsIterator.moveNext();
        localsIterator.moveNext();
        functionsIterator.current(
            request, result['params'], next, localsIterator.current);
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

  /// Server listen start
  void listen(InternetAddress internetAddress, int port,
      [Function callback]) async {
    server = await HttpServer.bind(internetAddress, port);
    callback(server);
    server.transform(HttpBodyHandler()).listen((HttpRequestBody body) {
      _on(body.request, body.body);
    });
  }
}
