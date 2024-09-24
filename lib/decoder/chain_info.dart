import 'package:dotenv/dotenv.dart';
import 'package:logging/logging.dart';
import 'package:lru_memory_cache/lru_memory_cache.dart';
import 'package:platform_decoder/consts/enjin/enjin.dart' as enjin;
import 'package:platform_decoder/consts/matrix/matrix.dart' as matrix;
import 'package:substrate_metadata/core/metadata_decoder.dart';
import 'package:substrate_metadata/models/models.dart';

final logger = Logger('Decoder');

var env = DotEnv(includePlatformEnvironment: true)..load();
int specPerIsolate =
    int.tryParse(env.getOrElse('SPEC_PER_ISOLATE', () => '4')) ?? 4;
int specExpireDuration =
    int.tryParse(env.getOrElse('SPEC_EXPIRE_DURATION', () => '300')) ?? 300;

LRUMemoryCache<String, ChainInfo> cache = LRUMemoryCache(
  generateKey: (k) =>
      "${k.constants['System']!['Version']!.value['spec_name']}-${k.constants['System']!['Version']!.value['spec_version']}",
  capacity: specPerIsolate,
  expireMode: ExpireMode.onInteraction,
);

String getSpecName(String network, int specVersion) {
  if (network == 'canary-matrixchain') {
    return 'matrix-$specVersion';
  }
  if (network == 'enjin-matrixchain') {
    return 'matrix-enjin-$specVersion';
  }
  if (network == 'canary-relaychain') {
    return 'canary-$specVersion';
  }

  return 'enjin-$specVersion';
}

DecodedMetadata getDecodedMetadata(String network, int specVersion) {
  if (network == 'canary-relaychain' || network == 'enjin-relaychain') {
    return MetadataDecoder.instance
        .decode(enjin.metadata(network, specVersion));
  }

  return MetadataDecoder.instance.decode(matrix.metadata(network, specVersion));
}

ChainInfo getChainInfo(network, specVersion) {
  ChainInfo? chainInfo = cache.get(getSpecName(network, specVersion));

  if (chainInfo == null) {
    logger.info("Metadata $network v$specVersion instantiated");

    final metadata = getDecodedMetadata(network, specVersion);
    chainInfo = ChainInfo.fromMetadata(metadata);
  }

  cache.add(chainInfo, expiryDuration: Duration(seconds: specExpireDuration));

  return chainInfo;
}
