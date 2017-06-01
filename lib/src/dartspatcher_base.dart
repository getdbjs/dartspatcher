// Copyright (c) 2017, Davide Bausach. All rights reserved. Use of this source
// code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:async';
import 'dart:convert';
import 'dart:io';

/// Checks if you are awesome. Spoiler: you are.
class Dartspatcher {
  Map listeners = {
    'GET': [],
    'POST': [],
    'PUT': [],
    'DELETE': []
  };
  HttpRequest request;
  var body;
  Map headers = {};

  void _onSetHeaders(HttpResponse response) {
    headers.forEach((k, v){
      response.headers.add(k, v);
    });
  }

  void _setListeners(String method, String uri, Object callback) {
    String regExp = uri.replaceAll(new RegExp(r':[a-zA-Z0-9]+'), '[a-zA-Z0-9]+');
    listeners[method].add({
      'uri': uri,
      'callback': callback,
      'regExp': new RegExp(r'' + regExp + '')
    });
  }

  Map _parseRoute() {
    String uriQ = request.uri.toString();
    List uq = uriQ.split('?');
    String uri = uq[0];
    Map result = {
      'resultMap': {},
      'params': {
        'uri': {},
        'query': request.uri.queryParameters,
        'body': {},
        'text': ''
      }
    };

    for (final Map i in listeners[request.method]) {
      if (i.containsValue(uri)) {
        result['resultMap'] = i;
        break;
      }
    }

    if (result['resultMap'].isEmpty) {
      for (final Map i in listeners[request.method]) {
        var match = i['regExp'].stringMatch(uri);
        if (match == uri) {
          List<String> requestUriList = uri.split('/')
            ..removeAt(0);

          List<String> matchUriList = i['uri'].split('/')
            ..removeAt(0);

          for (int x = 0; x < requestUriList.length; x++) {
            if (matchUriList[x].startsWith(':')) {
              result['params']['uri'][matchUriList[x].replaceAll(':', '')] = requestUriList[x];
            }
          }

          result['resultMap'] = i;
          break;
        }

      }
    }

    return result;
  }

  void _onGet() {
    Map result = _parseRoute();
    if (result['resultMap'].isNotEmpty) {
      _ok();
      result['resultMap']['callback'](request, result['params']);
    } else {
      _notFound();
    }
  }

  Future _onPostPutDelete() async {
    Map result = _parseRoute();
    String chunks;
    ContentType contentType = request.headers.contentType;

    if (contentType != null && contentType.mimeType == 'application/json') {
      try {
        if (body != null) {
          result['params']['body'] = body.body;
        } else {
          chunks = await request.transform(UTF8.decoder).join();
          result['params']['body'] = JSON.decode(chunks);
        }
      } catch (e, s) {
        _internalServerError(e, s);
      }
    } else if(contentType.mimeType == 'application/x-www-form-urlencoded') {
      try {
        if (body != null) {
          result['params']['body'] = body.body;
        } else {
          chunks = await request.transform(UTF8.decoder).join();
          Map k__v = {};
          List<String> kv = chunks.split('&');
          for (int i = 0; i<kv.length; i++) {
            List<String> k_v = kv[i].split('=');
            k__v[k_v[0]] = k_v[1];
          }
          result['params']['body'] = k__v;
        }
      } catch (e, s) {
        _internalServerError(e, s);
      }
    } else if(contentType.mimeType == 'multipart/form-data') {
      try {
        if (body != null) {
          result['params']['body'] = body.body;
        } else {
          //var formData = await request.transform(UTF8.decoder).join();
          //print(formData);
        }
      } catch (e, s) {
        _internalServerError(e, s);
      }
    } else if(contentType.mimeType.contains('text/')) {
      try {
        if (body != null) {
          result['params']['text'] = body.body;
        } else {
          chunks = await request.transform(UTF8.decoder).join();
          result['params']['text'] = chunks;
        }
      } catch (e, s) {
        _internalServerError(e, s);
      }
    }

    if (result['resultMap'].isNotEmpty) {
      _ok();
      result['resultMap']['callback'](request, result['params']);
    } else {
      _notFound();
    }
  }

  void _ok() {
    request.response.statusCode = HttpStatus.OK;
  }

  void _notFound() {
    request.response.statusCode = HttpStatus.NOT_FOUND;
    request.response.close();
  }

  void _internalServerError(e, s) {
    request.response
      ..statusCode = HttpStatus.INTERNAL_SERVER_ERROR
      ..write("Exception during file I/O: $e.")
      ..write("StackTrace during file I/O: $s.")
      ..close();
  }

  void _methodNotAllowed() {
    request.response
      ..statusCode = HttpStatus.METHOD_NOT_ALLOWED
      ..write("Unsupported request: ${request.method}.")
      ..close();
  }

  void setHeaders(Map headers) {
    this.headers = headers;
  }

  void get(String uri, Object callback) {
    _setListeners('GET', uri, callback);
  }

  void post(String uri, Object callback) {
    _setListeners('POST', uri, callback);
  }

  void put(String uri, Object callback) {
    _setListeners('PUT', uri, callback);
  }

  void delete(String uri, Object callback) {
    _setListeners('DELETE', uri, callback);
  }

  void on(rb) {
    if(rb is! HttpRequest) {
      body = rb;
      request = rb.request;
    } else {
      request = rb;
    }
    _onSetHeaders(request.response);

    if (!request.response.headers['access-control-allow-methods'].toString().contains(request.method)) {
      _methodNotAllowed();
      return;
    }

    try {
      switch (request.method) {
        case 'GET':
          _onGet();
          break;
        case 'POST':
          _onPostPutDelete();
          break;
        case 'PUT':
          _onPostPutDelete();
          break;
        case 'DELETE':
          _onPostPutDelete();
          break;
        default:
          _onGet();
          break;
      }
    } catch (e, s) {
      print('Exception in handleRequest: $e');
      print('StackTrace in handleRequest: $s');
      request.response
        ..write('Exception in handleRequest: $e')
        ..write('\n\n')
        ..write('StackTrace in handleRequest: $s')
        ..close();
    }
  }
}
