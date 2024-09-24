import 'dart:io';
import 'dart:isolate';

import 'package:dotenv/dotenv.dart';
import 'package:logging/logging.dart';
import 'package:platform_decoder/handler/general.dart';
import 'package:shelf_plus/shelf_plus.dart';

int numberOfIsolates = 8;

final logger = Logger('Decoder');

void loadConfig() {
  var env = DotEnv(includePlatformEnvironment: true)..load();

  numberOfIsolates =
      int.tryParse(env.getOrElse('NUMBER_OF_ISOLATES', () => '8')) ?? 8;
  int specPerIsolate =
      int.tryParse(env.getOrElse('SPEC_PER_ISOLATE', () => '4')) ?? 4;
  int specExpireDuration =
      int.tryParse(env.getOrElse('SPEC_EXPIRE_DURATION', () => '300')) ?? 300;

  logger.info('Starting Platform Decoder v2.1.1');
  logger.info('Number of isolates: $numberOfIsolates');
  logger.info('Spec per isolate: $specPerIsolate');
  logger.info('Spec expire duration: $specExpireDuration');
}

Future<void> main() async {
  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.time} [${record.level.name}] ${record.message}');
  });

  loadConfig();

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

  Logger.root.level = Level.ALL;
  Logger.root.onRecord.listen((record) {
    print('${record.time} [${record.level.name}] ${record.message}');
  });

  app.get('/', () => 'Ok');
  app.get('/health', () => {'status': 'healthy'});
  app.post('/', (Request request) async {
    return await handleRequest(request);
  });

  return app.call;
}
