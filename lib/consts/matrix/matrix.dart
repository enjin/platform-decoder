import 'canary/canary.dart' as c;
import 'production/production.dart' as p;

String canary() {
  return c.v605;
}

String production() {
  return p.v605;
}
