// Copyright (c) 2017, Davide Bausach. All rights reserved. Use of this source
// code is governed by a BSD-style license that can be found in the LICENSE file.

import 'dart:io';
import 'package:dartspatcher/dartspatcher.dart';

Future main() async {
  Dartspatcher dartspatcher = Dartspatcher();

  /// Response Headers settings
  dartspatcher.setHeaders({
    'Charset': 'utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers':
        'Origin, X-Requested-With, Content-Type, Accept',
    'Content-Type': 'text/plain; charset=utf-8'
  });

  /// Setting a Map of global variables valid for the whole life of the dartspatcher application
  dartspatcher.locals['var'] = 'value';

  /// Setting a virtual directory for serving static file content with options.
  /// - allowDirectoryListing: Setting a Map of global variables valid for the whole life of the dartspatcher application
  /// - followLinks: Whether to allow reading resources via a link.
  /// - jailRoot: Whether to prevent access outside of [root] via relative paths or links.
  dartspatcher.setVirtualDirectory('web');
  dartspatcher.virtualDirectory.allowDirectoryListing = false;
  dartspatcher.virtualDirectory.followLinks = true;
  dartspatcher.virtualDirectory.jailRoot = true;

  /// It is possible to set middlewares before or after the path listeners
  dartspatcher.setMiddleware([
    (HttpRequest request, Map<String, dynamic> params,
        [Map<dynamic, dynamic> locals]) {
      print('middlware');
    }
  ], {
    'local': 'variable'
  });

  /// Setting of listeners for specific path.
  ///
  /// The first param is a path.
  ///
  /// The second param is a callback that receive three params:
  /// - request: the server HttpRequest object
  /// - params: the Map of params that there are in the request
  /// - locals: the optiona Map of locals variables
  /// {
  ///   "uri": {},
  ///   "query": {},
  ///   "body": {}
  /// }
  ///
  /// The third param is a Map<dynamic, dynamic> to set the locals variables valid for that request.
  ///
  dartspatcher.get('/', [
    (HttpRequest request, Map<String, dynamic> params,
        [Map<dynamic, dynamic> locals]) {
      request.response.close();

      /// Setting a Map of specific variables valid for this request
    }
  ], {
    'var': 'value'
  });

  /// Listener path with params and query string
  dartspatcher.get('/path/:param?var=value', [
    (HttpRequest request, Map<String, dynamic> params,
        [Map<dynamic, dynamic> locals]) {
      request.response.close();
    }
  ]);

  /// Listener simple path
  dartspatcher.post('/path', [
    (HttpRequest request, Map<String, dynamic> params,
        [Map<dynamic, dynamic> locals]) {
      request.response.close();
    }
  ]);

  /// Error Handler Middleware
  dartspatcher.setErrorHandler((HttpRequest request, dynamic e, StackTrace s) {
    print('Error Handler');
    dartspatcher.close(request, HttpStatus.internalServerError);
  });

  /// Dartspatcher Server Listener
  dartspatcher.listen(InternetAddress.loopbackIPv4, 4040, (HttpServer server) {
    print('Listening on localhost:${server.port}');
  });
}
