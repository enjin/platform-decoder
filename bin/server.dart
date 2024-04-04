import 'dart:convert';

import 'package:platform_decoder/consts/enjin/enjin.dart' as enjin;
import 'package:platform_decoder/consts/matrix/matrix.dart' as matrix;
import 'package:polkadart_scale_codec/io/io.dart';
import 'package:substrate_metadata/core/metadata_decoder.dart';
import 'package:substrate_metadata/models/models.dart';
import 'dart:io';
import 'dart:isolate';

import 'package:substrate_metadata/types/metadata_types.dart';
import 'package:substrate_metadata/utils/utils.dart';

final DecodedMetadata matrixMetadata =
    MetadataDecoder.instance.decode(matrix.production());
final ChainInfo matrixChain = ChainInfo.fromMetadata(matrixMetadata);

final DecodedMetadata matrixCanaryMetadata =
    MetadataDecoder.instance.decode(matrix.canary());
final ChainInfo matrixCanaryChain =
    ChainInfo.fromMetadata(matrixCanaryMetadata);

final DecodedMetadata enjinMetadata =
    MetadataDecoder.instance.decode(enjin.production());
final ChainInfo enjinChain = ChainInfo.fromMetadata(enjinMetadata);

final DecodedMetadata enjinCanaryMetadata =
    MetadataDecoder.instance.decode(enjin.canary());
final ChainInfo enjinCanaryChain = ChainInfo.fromMetadata(enjinCanaryMetadata);

void main() async {
  for (var i = 1; i < 8; i++) {
    Isolate.spawn(_startServer, []);
  }

  _startServer([]);
  print('Serving at http://0.0.0.0:8090/');
  await ProcessSignal.sigterm.watch().first;
}

void _startServer(List args) async {
  final server = await HttpServer.bind(
    InternetAddress.anyIPv4,
    8090,
    shared: true,
  );

  await for (final request in server) {
    _handleRequest(request);
  }
}

void _handleRequest(HttpRequest request) async {
  HttpResponse res = request.response;
  String content = await utf8.decoder.bind(request).join();

  if (request.method == 'GET') {
    res
      ..statusCode = HttpStatus.ok
      ..write('Ok');

    await res.close();
    return;
  }

  final Map<String, dynamic> body = jsonDecode(content);
  final network = body['network'] ?? 'enjin';

  if (body['extrinsic'] != null) {
    try {
      final Map<String, dynamic> decoded =
          decodeExtrinsic(body['extrinsic'], network);
      final extrinsic = decoded.toJson();
      extrinsic['extrinsic_hash'] = extrinsic['hash'];

      res
        ..headers.contentType = ContentType.json
        ..statusCode = HttpStatus.ok
        ..write(jsonEncode(extrinsic));
    } catch (e) {
      res
        ..headers.contentType = ContentType.json
        ..statusCode = HttpStatus.badRequest
        ..write('{"error": "Failed to decode extrinsic"}');
    }
  }

  if (body['extrinsics'] != null) {
    try {
      final extrinsics = (body['extrinsics'] as List).map((e) {
        final Map<String, dynamic> decoded = decodeExtrinsic(e, network);
        final extrinsic = decoded.toJson();
        extrinsic['extrinsic_hash'] = extrinsic['hash'];

        return extrinsic;
      });

      res
        ..headers.contentType = ContentType.json
        ..statusCode = HttpStatus.ok
        ..write(jsonEncode(extrinsics.toList()));
    } catch (e) {
      res
        ..headers.contentType = ContentType.json
        ..statusCode = HttpStatus.badRequest
        ..write('{"error": "Failed to decode extrinsics"}');
    }
  }

  if (body['events'] != null) {
    try {
      final decoded = (decodeEvents(body['events'], network) as List).map((e) {
        final event = e as Map<String, dynamic>;
        return event.toJson();
      });

      res
        ..headers.contentType = ContentType.json
        ..statusCode = HttpStatus.ok
        ..write(jsonEncode(decoded.toList()));
    } catch (e) {
      res
        ..headers.contentType = ContentType.json
        ..statusCode = HttpStatus.badRequest
        ..write('{"error": "Failed to decode events"}');
    }
  }

  await res.close();
}

dynamic decodeExtrinsic(raw, network) {
  final input = Input.fromHex(raw);

  if (network == 'canary' || network == 'canary-matrixchain') {
    final dynamic decoded =
        ExtrinsicsCodec(chainInfo: matrixCanaryChain).decode(input);
    return decoded;
  }

  if (network == 'enjin-relaychain') {
    final dynamic decoded =
        ExtrinsicsCodec(chainInfo: enjinChain).decode(input);
    return decoded;
  }

  if (network == 'canary-relaychain') {
    final dynamic decoded =
        ExtrinsicsCodec(chainInfo: enjinCanaryChain).decode(input);
    return decoded;
  }

  final dynamic decoded = ExtrinsicsCodec(chainInfo: matrixChain).decode(input);
  return decoded;
}

dynamic decodeEvents(raw, network) {
  final input = Input.fromHex(raw);

  if (network == 'canary' || network == 'canary-matrixchain') {
    final List<dynamic> decoded =
        matrixCanaryChain.scaleCodec.decode('EventCodec', input);
    return decoded;
  }

  if (network == 'enjin-relaychain') {
    final List<dynamic> decoded =
        enjinChain.scaleCodec.decode('EventCodec', input);
    return decoded;
  }

  if (network == 'canary-relaychain') {
    final List<dynamic> decoded =
        enjinCanaryChain.scaleCodec.decode('EventCodec', input);
    return decoded;
  }

  final decoded = matrixChain.scaleCodec.decode('EventCodec', input);
  return decoded;
}
