import 'package:platform_decoder/consts/enjin/enjin.dart' as enjin;
import 'package:platform_decoder/consts/matrix/matrix.dart' as matrix;
import 'package:polkadart_scale_codec/io/io.dart';
import 'package:substrate_metadata/core/metadata_decoder.dart';
import 'package:substrate_metadata/models/models.dart';
import 'package:substrate_metadata/types/metadata_types.dart';

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
