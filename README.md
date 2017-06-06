# dartspatcher

A simple http dispatcher for Dart server.

## Usage

Usage example with http_server package:

    import 'package:http_server/http_server.dart';
    import 'package:dartspatcher/dartspatcher.dart';

    main() {
      Dartspatcher dartspatcher = new Dartspatcher();
      
      HttpServer.bind(InternetAddress.LOOPBACK_IP_V4, 4040).then((server) {
        server.transform(new HttpBodyHandler()).listen((HttpRequestBody body) {
          dartspatcher.on(body);
        });
        print('listening on localhost, port 4040');
      });
      
      dartspatcher.setHeaders({
        'Access-Control-Allow-Origin': '*',
        'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
        'Access-Control-Allow-Headers': 'Origin, X-Requested-With, Content-Type, Accept',
        'Content-Type': 'text/plain; charset=utf-8'
      });
    
      dartspatcher.get('/', (HttpRequest request, Map params) {
        ...
        request.response.close();
      });
      
      dartspatcher.get('/:uriParam?queryParam=example', (HttpRequest request, Map params) {
        ...
        request.response.close();
      });
      
      ...
    }
    
#### Set Headers

    ...
    
    dartspatcher.setHeaders({
      'Access-Control-Allow-Origin': '*',
      'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
      'Access-Control-Allow-Headers': 'Origin, X-Requested-With, Content-Type, Accept',
      'Content-Type': 'text/plain; charset=utf-8'
    });
    
    ...
    
#### Params Map

    {
      "uri": {},
      "query": {},
      "body": {},
      "text": ""
    }

## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/getdbjs/dartspatcher/issues
