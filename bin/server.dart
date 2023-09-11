import 'dart:convert';
import 'package:decoder/consts/efinity/production_metadata.dart'
    as efinity_prod;
import 'package:decoder/consts/enjin/production_metadata.dart' as enjin_prod;
import 'package:decoder/consts/enjin/canary_metadata.dart' as enjin_canary;
import 'package:decoder/consts/matrix/production_metadata.dart' as matrix_prod;
import 'package:decoder/consts/matrix/canary_metadata.dart' as matrix_canary;
import 'package:polkadart_scale_codec/polkadart_scale_codec.dart';
import 'package:substrate_metadata/chain_description/chain_description.model.dart';
import 'package:substrate_metadata/extrinsic.dart';
import 'package:substrate_metadata/metadata_decoder.dart';
import 'package:substrate_metadata/models/models.dart';
import 'dart:io';
import 'dart:isolate';

final efinityDecoder = MetadataDecoder();
final Metadata efinityMetadata =
    efinityDecoder.decodeAsMetadata(efinity_prod.v3014);
final ChainDescription efinityChainDescription =
    ChainDescription.fromMetadata(efinityMetadata);
final Codec efinityCodec = Codec(efinityChainDescription.types);

final matrixDecoder = MetadataDecoder();
final Metadata matrixMetadata =
    matrixDecoder.decodeAsMetadata(matrix_prod.v603);
final ChainDescription matrixChainDescription =
    ChainDescription.fromMetadata(matrixMetadata);
final Codec matrixCodec = Codec(matrixChainDescription.types);

final matrixCanaryDecoder = MetadataDecoder();
final Metadata matrixCanaryMetadata =
    matrixCanaryDecoder.decodeAsMetadata(matrix_canary.v604);
final ChainDescription matrixCanaryChainDescription =
    ChainDescription.fromMetadata(matrixCanaryMetadata);
final Codec matrixCanaryCodec = Codec(matrixCanaryChainDescription.types);

final enjinDecoder = MetadataDecoder();
final Metadata enjinMetadata = enjinDecoder.decodeAsMetadata(enjin_prod.v100);
final ChainDescription enjinChainDescription =
    ChainDescription.fromMetadata(enjinMetadata);
final Codec enjinCodec = Codec(enjinChainDescription.types);

final enjinCanaryDecoder = MetadataDecoder();
final Metadata enjinCanaryMetadata =
    enjinCanaryDecoder.decodeAsMetadata(enjin_canary.v106);
final ChainDescription enjinCanaryChainDescription =
    ChainDescription.fromMetadata(enjinCanaryMetadata);
final Codec enjinCanaryCodec = Codec(enjinCanaryChainDescription.types);

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
  final network = body['network'] ?? 'developer';

  if (body['extrinsic'] != null) {
    try {
      final decoded = decodeExtrinsic(body['extrinsic'], network);
      decoded['extrinsic_hash'] = Extrinsic.computeHash(body['extrinsic']);
      String extrinsic = toJson(decoded);

      res
        ..headers.contentType = ContentType.json
        ..statusCode = HttpStatus.ok
        ..write(extrinsic);
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
        final decoded = decodeExtrinsic(e, network);
        decoded['extrinsic_hash'] = Extrinsic.computeHash(e);

        return toJson(decoded);
      });

      res
        ..headers.contentType = ContentType.json
        ..statusCode = HttpStatus.ok
        ..write(extrinsics.toList());
    } catch (e) {
      res
        ..headers.contentType = ContentType.json
        ..statusCode = HttpStatus.badRequest
        ..write('{"error": "Failed to decode extrinsics"}');
    }
  }

  if (body['events'] != null) {
    try {
      final decoded = decodeEvents(body['events'], network);
      String events = toJson(decoded);

      res
        ..headers.contentType = ContentType.json
        ..statusCode = HttpStatus.ok
        ..write(events);
    } catch (e) {
      res
        ..headers.contentType = ContentType.json
        ..statusCode = HttpStatus.badRequest
        ..write('{"error": "Failed to decode events"}');
    }
  }

  await res.close();
}

String toJson(dynamic decoded) {
  return jsonEncode(decoded, toEncodable: (dynamic obj) {
    if (obj is BigInt) {
      return obj.toString();
    }
    if (obj is Some) {
      return {'Some': obj.value};
    }
    if (obj is NoneOption) {
      return {'None': null};
    }
    return obj;
  });
}

dynamic decodeExtrinsic(raw, network) {
  if (network == 'enjin' || network == 'enjin-matrixchain') {
    final dynamic decoded =
        Extrinsic.decodeExtrinsic(raw, matrixChainDescription);
    return decoded;
  }

  if (network == 'canary' || network == 'canary-matrixchain') {
    final dynamic decoded =
        Extrinsic.decodeExtrinsic(raw, matrixCanaryChainDescription);
    return decoded;
  }

  if (network == 'enjin-relaychain') {
    final dynamic decoded =
        Extrinsic.decodeExtrinsic(raw, enjinChainDescription);
    return decoded;
  }

  if (network == 'canary-relaychain') {
    final dynamic decoded =
        Extrinsic.decodeExtrinsic(raw, enjinCanaryChainDescription);
    return decoded;
  }

  final dynamic decoded =
      Extrinsic.decodeExtrinsic(raw, efinityChainDescription);
  return decoded;
}

dynamic decodeEvents(raw, network) {
  if (network == 'enjin' || network == 'enjin-matrixchain') {
    final dynamic decoded =
        matrixCodec.decode(matrixChainDescription.eventRecordList, raw);
    return decoded;
  }

  if (network == 'canary' || network == 'canary-matrixchain') {
    final dynamic decoded = matrixCanaryCodec.decode(
        matrixCanaryChainDescription.eventRecordList, raw);
    return decoded;
  }

  if (network == 'enjin-relaychain') {
    final dynamic decoded =
        enjinCodec.decode(enjinChainDescription.eventRecordList, raw);
    return decoded;
  }

  if (network == 'canary-relaychain') {
    final dynamic decoded = enjinCanaryCodec.decode(
        enjinCanaryChainDescription.eventRecordList, raw);
    return decoded;
  }

  final dynamic decoded =
      efinityCodec.decode(efinityChainDescription.eventRecordList, raw);
  return decoded;
}
