import 'dart:async';
import 'dart:convert';

import 'package:platform_decoder/decoder/decoder.dart';
import 'package:shelf/shelf.dart';
import 'package:substrate_metadata/utils/utils.dart';

Future<dynamic> handleRequest(Request request) async {
  String content = await utf8.decoder.bind(request.read()).join();
  final Map<String, dynamic> body = jsonDecode(content);
  final network = body['network'] ?? 'enjin';

  if (body['extrinsic'] != null) {
    try {
      final Map<String, dynamic> decoded =
          decodeExtrinsic(body['extrinsic'], network);
      final extrinsic = decoded.toJson();
      extrinsic['extrinsic_hash'] = extrinsic['hash'];

      return extrinsic;
    } catch (e) {
      return {"error": "Failed to decode extrinsic"};
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

      return extrinsics.toList();
    } catch (e) {
      return {"error": "Failed to decode extrinsics"};
    }
  }

  if (body['events'] != null) {
    try {
      final decoded = (decodeEvents(body['events'], network) as List).map((e) {
        final event = e as Map<String, dynamic>;
        return event.toJson();
      });

      return decoded.toList();
    } catch (e) {
      return {"error": "Failed to decode events"};
    }
  }

  return {"error": "Invalid request"};
}
