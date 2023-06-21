import 'dart:convert';
import 'package:decoder/consts.dart';
import 'package:polkadart_scale_codec/polkadart_scale_codec.dart';
import 'package:substrate_metadata/chain_description/chain_description.model.dart';
import 'package:substrate_metadata/extrinsic.dart';
import 'package:substrate_metadata/metadata_decoder.dart';
import 'package:substrate_metadata/models/models.dart';
import 'dart:io';
import 'dart:isolate';

final stagingDecoder = MetadataDecoder();
final Metadata stagingMetadata = stagingDecoder.decodeAsMetadata(matrixCanary602);
final ChainDescription stagingChainDescription = ChainDescription.fromMetadata(stagingMetadata);
final Codec stagingCodec = Codec(stagingChainDescription.types);

final mainDecoder = MetadataDecoder();
final Metadata mainMetadata = mainDecoder.decodeAsMetadata(efinityMainnet3014);
final ChainDescription mainChainDescription = ChainDescription.fromMetadata(mainMetadata);
final Codec mainCodec = Codec(mainChainDescription.types);

final canaryDecoder = MetadataDecoder();
final Metadata canaryMetadata = canaryDecoder.decodeAsMetadata(matrixCanary602);
final ChainDescription canaryChainDescription = ChainDescription.fromMetadata(canaryMetadata);
final Codec canaryCodec = Codec(canaryChainDescription.types);

final enjinDecoder = MetadataDecoder();
final Metadata enjinMetadata = enjinDecoder.decodeAsMetadata(matrixProd);
final ChainDescription enjinChainDescription = ChainDescription.fromMetadata(enjinMetadata);
final Codec enjinCodec = Codec(enjinChainDescription.types);

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
    res..statusCode = HttpStatus.ok
       ..write('Ok');

    await res.close();
    return;
  }

  final Map<String, dynamic> body = jsonDecode(content);
  final network = body['network'] ?? 'developer';

  if (body['extrinsic'] != null) {
    final decoded = decodeExtrinsic(body['extrinsic'], network);
    decoded['extrinsic_hash'] = Extrinsic.computeHash(body['extrinsic']);
    String extrinsic = toJson(decoded);

    res..headers.contentType = ContentType.json
      ..statusCode = HttpStatus.ok
      ..write(extrinsic);
  }

  if (body['extrinsics'] != null) {
    final extrinsics = (body['extrinsics'] as List).map((e) {
        final decoded = decodeExtrinsic(e, network);
        decoded['extrinsic_hash'] = Extrinsic.computeHash(e);
        return toJson(decoded);
    });

    res..headers.contentType = ContentType.json
      ..statusCode = HttpStatus.ok
      ..write(extrinsics.toList());
  }

  if (body['events'] != null) {
    final decoded = decodeEvents(body['events'], network);
    String events = toJson(decoded);

    res..headers.contentType = ContentType.json
      ..statusCode = HttpStatus.ok
      ..write(events);
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
  if (network == 'enjin') {
    final dynamic decoded = Extrinsic.decodeExtrinsic(raw, enjinChainDescription);
    return decoded;
  }

  if (network == 'polkadot') {
    final dynamic decoded = Extrinsic.decodeExtrinsic(raw, mainChainDescription);
    return decoded;
  }

  if (network == 'canary') {
    final dynamic decoded = Extrinsic.decodeExtrinsic(raw, canaryChainDescription);
    return decoded;
  }

  final dynamic decoded = Extrinsic.decodeExtrinsic(raw, stagingChainDescription);
  return decoded;
}

dynamic decodeEvents(raw, network) {
  if (network == 'enjin') {
    final dynamic decoded = enjinCodec.decode(enjinChainDescription.eventRecordList, raw);
    return decoded;
  }

  if (network == 'polkadot') {
    final dynamic decoded = mainCodec.decode(mainChainDescription.eventRecordList, raw);
    return decoded;
  }

  if (network == 'canary') {
    final dynamic decoded = canaryCodec.decode(canaryChainDescription.eventRecordList, raw);
    return decoded;
  }

  final dynamic decoded = stagingCodec.decode(stagingChainDescription.eventRecordList, raw);
  return decoded;
}
