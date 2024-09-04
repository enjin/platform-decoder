// The first time a metadata is requested we instantiate it and keep it on memory to speed up the decoder
// Otherwise we would have to decode the metadata every time we decode an extrinsic or event
// TODO: Later we can make some kind of LRU cache so it doesn't stays there forever

import 'package:platform_decoder/consts/enjin/enjin.dart' as enjin;
import 'package:platform_decoder/consts/matrix/matrix.dart' as matrix;
import 'package:substrate_metadata/core/metadata_decoder.dart';
import 'package:substrate_metadata/models/models.dart';

// {
//   "enjin-matrixchain": {
//     1000: ChainInfo,
//     1001: ChainInfo,
//   }
// }
final Map<String, Map<int, ChainInfo>> chainInfos = {};

ChainInfo getChainInfo(network, specVersion) {
  final chainInfoMetadata = chainInfos[network]?[specVersion];

  if (chainInfoMetadata != null) {
    return chainInfoMetadata;
  }

  // Instantiate a new metadata for relaychains
  if (network == 'canary-relaychain' || network == 'enjin-relaychain') {
    final metadata =
        MetadataDecoder.instance.decode(enjin.metadata(network, specVersion));
    final ChainInfo chain = ChainInfo.fromMetadata(metadata);

    if (chainInfos[network] == null) {
      chainInfos[network] = {specVersion: chain};
    } else {
      chainInfos[network]![specVersion] = chain;
    }

    print("Instantiated new metadata for $network $specVersion");

    return chain;
  }

  // Instantiate a new metadata for matrixchains
  final metadata =
      MetadataDecoder.instance.decode(matrix.metadata(network, specVersion));
  final ChainInfo chain = ChainInfo.fromMetadata(metadata);

  if (chainInfos[network] == null) {
    chainInfos[network] = {specVersion: chain};
  } else {
    chainInfos[network]![specVersion] = chain;
  }

  print("Instantiated new metadata for $network $specVersion");

  return chain;
}
