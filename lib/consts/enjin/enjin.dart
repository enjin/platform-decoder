import 'canary/canary.dart' as c;
import 'production/production.dart' as p;

String canaryLatest() {
  return c.v1033;
}

String productionLatest() {
  return p.v1032;
}

String metadata(network, specVersion) {
  if (network == 'canary-relaychain') {
    return canarySpec(specVersion);
  }

  return productionSpec(specVersion);
}

String canarySpec(specVersion) {
  switch (specVersion) {
    case 100:
      return c.v100;
    case 101:
      return c.v101;
    case 102:
      return c.v102;
    case 103:
      return c.v103;
    case 104:
      return c.v104;
    case 105:
      return c.v105;
    case 106:
      return c.v106;
    case 107:
      return c.v107;
    case 110:
      return c.v110;
    case 120:
      return c.v120;
    case 1021:
      return c.v1021;
    case 1022:
      return c.v1022;
    case 1023:
      return c.v1023;
    case 1024:
      return c.v1024;
    case 1025:
      return c.v1025;
    case 1026:
      return c.v1026;
    case 1030:
      return c.v1030;
    case 1031:
      return c.v1031;
    case 1032:
      return c.v1032;
    case 1033:
      return c.v1033;
    default:
      return canaryLatest();
  }
}

String productionSpec(specVersion) {
  switch (specVersion) {
    case 100:
      return p.v100;
    case 101:
      return p.v101;
    case 102:
      return p.v102;
    case 110:
      return p.v110;
    case 120:
      return p.v120;
    case 1021:
      return p.v1021;
    case 1022:
      return p.v1022;
    case 1023:
      return p.v1023;
    case 1024:
      return p.v1024;
    case 1025:
      return p.v1025;
    case 1026:
      return p.v1026;
    case 1032:
      return p.v1032;
    default:
      return productionLatest();
  }
}
