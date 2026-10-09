class AppConfig {
  static const supabaseUrl = String.fromEnvironment(
    'SUPABASE_URL',
    defaultValue: 'https://akkhcudeomnaxtplftmu.supabase.co',
  );
  static const supabasePublishableKey = String.fromEnvironment(
    'SUPABASE_PUBLISHABLE_KEY',
  );
  static const localDemo = bool.fromEnvironment(
    'EVENTTWIN_LOCAL_DEMO',
    defaultValue: false,
  );
}
