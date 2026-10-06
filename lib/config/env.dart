/// Compile-time config, injected with `--dart-define-from-file=env.json`.
///
/// Only put values here that are safe to ship inside the app binary.
/// Server secrets (e.g. Firebase service account) belong in Supabase secrets.
abstract final class Env {
  static const supabaseUrl = String.fromEnvironment('SUPABASE_URL');
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );

  static List<String> get missingKeys => [
    if (supabaseUrl.isEmpty) 'SUPABASE_URL',
    if (supabasePublishableKey.isEmpty) 'SUPABASE_PUBLISHABLE_KEY',
  ];
}
