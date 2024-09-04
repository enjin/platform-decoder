import 'package:polkadart_scale_codec/io/io.dart';
import 'package:substrate_metadata/types/metadata_types.dart';

import 'chain_info.dart';

dynamic decodeExtrinsic(raw, network, specVersion) {
  final input = Input.fromHex(raw);
  final chainInfo = getChainInfo(network, specVersion);

  return ExtrinsicsCodec(chainInfo: chainInfo).decode(input);
}

dynamic decodeEvents(raw, network, specVersion) {
  final input = Input.fromHex(raw);
  final chainInfo = getChainInfo(network, specVersion);

  return chainInfo.scaleCodec.decode('EventCodec', input);
}
