import 'canary/canary.dart' as c;
import 'production/production.dart' as p;

String canaryLatest() {
  return c.v1023;
}

String productionLatest() {
  return p.v1022;
}

String metadata(network, specVersion) {
  if (network == 'canary-matrixchain' || network == 'canary') {
    return canarySpec(specVersion);
  }

  return productionSpec(specVersion);
}

String canarySpec(specVersion) {
  switch (specVersion) {
    case 500:
      return c.v500;
    case 600:
      return c.v600;
    case 601:
      return c.v601;
    case 602:
      return c.v602;
    case 604:
      return c.v604;
    case 605:
      return c.v605;
    case 1000:
      return c.v1000;
    case 1001:
      return c.v1001;
    case 1002:
      return c.v1002;
    case 1003:
      return c.v1003;
    case 1004:
      return c.v1004;
    case 1005:
      return c.v1005;
    case 1006:
      return c.v1006;
    case 1010:
      return c.v1010;
    case 1011:
      return c.v1011;
    case 1012:
      return c.v1012;
    case 1013:
      return c.v1013;
    case 1020:
      return c.v1020;
    case 1021:
      return c.v1021;
    case 1022:
      return c.v1022;
    case 1023:
      return c.v1023;
    default:
      return canaryLatest();
  }
}

String productionSpec(specVersion) {
  switch (specVersion) {
    case 603:
      return p.v603;
    case 604:
      return p.v604;
    case 605:
      return p.v605;
    case 1000:
      return p.v1000;
    case 1002:
      return p.v1002;
    case 1003:
      return p.v1003;
    case 1004:
      return p.v1004;
    case 1005:
      return p.v1005;
    case 1006:
      return p.v1006;
    case 1012:
      return p.v1012;
    case 1014:
      return p.v1014;
    case 1022:
      return p.v1022;
    default:
      return productionLatest();
  }
}
