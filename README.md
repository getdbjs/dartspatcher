# Dispatcher for HTTP server

A simple dispatcher for HTTP server like expressjs using `http_server` package.
The following content types are recognized:

- text/*
- application/json
- application/x-www-form-urlencoded
- multipart/form-data

View documentation in example file

**NOTE:** This package works for server-side Dart applications.
In other words, if the app imports `dart:io`, it can use this
package.

The following content types are recognized:

## Example usage

```
import 'dart:io';
import 'package:dartspatcher/dartspatcher.dart';

Future main() async {
  Dartspatcher dartspatcher = Dartspatcher();

  dartspatcher.setHeaders({
    'Charset': 'utf-8',
    'Access-Control-Allow-Origin': '*',
    'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
    'Access-Control-Allow-Headers': 'Origin, X-Requested-With, Content-Type, Accept',
    'Content-Type': 'text/plain; charset=utf-8'
  });

  dartspatcher.locals['var'] = 'value';

  dartspatcher.get('/', (HttpRequest request, Map<String, dynamic> params, [Map<dynamic, dynamic> locals]) {
    ...
    request.response.close();
  }, {'var': 'value'});

  dartspatcher.get('/path/:param?var=value', (HttpRequest request, Map<String, dynamic> params, [Map<dynamic, dynamic> locals]) {
    ...
    request.response.close();
  });

  dartspatcher.post('/path', (HttpRequest request, Map<String, dynamic> params, [Map<dynamic, dynamic> locals]) {
    ...
    request.response.close();
  });

  dartspatcher.listen(InternetAddress.loopbackIPv4, 4040, (HttpServer server) {
    print('Listening on localhost:${server.port}');
  });
}
```

#### Set Headers
```
...

dartspatcher.setHeaders({
  'Charset': 'utf-8',
  'Access-Control-Allow-Origin': '*',
  'Access-Control-Allow-Methods': 'GET, POST, PUT, DELETE, OPTIONS',
  'Access-Control-Allow-Headers': 'Origin, X-Requested-With, Content-Type, Accept',
  'Content-Type': 'text/plain; charset=utf-8'
});

...
```
#### Params Map<String, dynamic>
```
{
  "uri": {},
  "query": {},
  "body": {}
}
```
## Features and bugs

Please file feature requests and bugs at the [issue tracker][tracker].

[tracker]: https://github.com/getdbjs/dartspatcher/issues
