import 'dart:async';
import 'dart:convert';

import 'package:logging/logging.dart';
import 'package:platform_decoder/decoder/decoder.dart';
import 'package:shelf/shelf.dart';
import 'package:substrate_metadata/utils/utils.dart';

final logger = Logger('Decoder');

int getLatestSpecVersion(network) {
  if (network == 'enjin-relaychain') {
    return 1050;
  }
  if (network == 'canary-relaychain') {
    return 1050;
  }
  if (network == 'canary' || network == 'canary-matrixchain') {
    return 1022;
  }
  return 1014;
}

Future<dynamic> handleRequest(Request request) async {
  String content = await utf8.decoder.bind(request.read()).join();
  final Map<String, dynamic> body = jsonDecode(content);
  final network = body['network'] ?? 'enjin-matrixchain';
  final int specVersion = body['spec_version'] ?? getLatestSpecVersion(network);

  if (body['extrinsic'] != null) {
    try {
      final Map<String, dynamic> decoded =
          decodeExtrinsic(body['extrinsic'], network, specVersion);
      final extrinsic = decoded.toJson();
      extrinsic['extrinsic_hash'] = extrinsic['hash'];

      return extrinsic;
    } catch (e) {
      logger.warning('Failed to decode extrinsic with reason: $e');
      logger.warning('Extrinsic $network v$specVersion: ${body['extrinsic']}');
      return {"error": "Failed to decode extrinsic"};
    }
  }

  if (body['extrinsics'] != null) {
    try {
      final extrinsics = (body['extrinsics'] as List).map((e) {
        final Map<String, dynamic> decoded =
            decodeExtrinsic(e, network, specVersion);
        final extrinsic = decoded.toJson();
        extrinsic['extrinsic_hash'] = extrinsic['hash'];

        return extrinsic;
      });

      return extrinsics.toList();
    } catch (e) {
      logger.warning('Failed to decode extrinsics with reason: $e');
      logger.warning('Extrinsic $network v$specVersion: ${body['extrinsics']}');
      return {"error": "Failed to decode extrinsics"};
    }
  }

  if (body['events'] != null) {
    try {
      final decoded =
          (decodeEvents(body['events'], network, specVersion) as List).map((e) {
        final event = e as Map<String, dynamic>;
        return event.toJson();
      });

      return decoded.toList();
    } catch (e) {
      logger.warning('Failed to decode events with reason: $e');
      logger.warning('Extrinsic $network v$specVersion: ${body['events']}');
      return {"error": "Failed to decode events"};
    }
  }

  return {"error": "Invalid request"};
}
