import 'dart:io';
import 'dart:isolate';

import 'package:platform_decoder/handler/general.dart';
import 'package:shelf_plus/shelf_plus.dart';

void main() {
  const numberOfIsolates = 8;

  for (var i = 0; i < numberOfIsolates - 1; i++) {
    Isolate.spawn(spawnServer, null, debugName: i.toString()); // isolate 0..7
  }
  spawnServer(null); // use main isolate as the 8th isolate
}

void spawnServer(_) => shelfRun(
      init,
      defaultBindAddress: InternetAddress.anyIPv4,
      defaultShared: true,
      defaultBindPort: 8090,
      defaultEnableHotReload: false,
    );

Handler init() {
  var app = Router().plus;
  app.use(logRequests());

  app.get('/', () => 'Ok');
  app.get('/health', () => {'status': 'healthy'});
  app.post('/', (Request request) async {
    return await handleRequest(request);
  });

  return app.call;
}
