import 'package:flutter_test/flutter_test.dart';
import 'package:worning_foold/config/env.dart';

void main() {
  test('reports missing keys when no env file is passed', () {
    expect(Env.missingKeys, ['SUPABASE_URL', 'SUPABASE_PUBLISHABLE_KEY']);
  });
}
