/// Application environment and external service configuration.
/// Values can be overridden at build time via `--dart-define`:
/// e.g. `flutter run --dart-define=SUPABASE_URL=https://xyz.supabase.co`
class AppConfig {
  AppConfig._();

  static const String supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://gkjgwbwmucotqftbhgyn.supabase.co',
  );

  static const String supabaseAnonKey = String.fromEnvironment(
    'SUPABASE_ANON_KEY',
    defaultValue: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6Imdramd3YndtdWNvdHFmdGJoZ3luIiwicm9sZSI6ImFub24iLCJpYXQiOjE3ODk1OTg3NjgsImV4cCI6MjEwNTE3NDc2OH0.8POIXCLUtOch0W4frnUbC29dbsbSQb_Gud3aRcd6QYA',
  );

  static const String adminPasscode = String.fromEnvironment(
    'ADMIN_PASSCODE',
    defaultValue: '123456',
  );
}
