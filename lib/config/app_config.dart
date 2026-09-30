// App configuration — client-safe values only.
// The service_role key NEVER goes here — backend (Cloud Run) only.
class AppConfig {
  // Supabase
  static const String supabaseUrl = 'https://reatiysbzhbmkvxichmp.supabase.co';
  static const String supabaseAnonKey =
      'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9'
      '.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InJlYXRpeXNiemhibWt2eGljaG1wIiwicm9sZSI6ImFub24iLCJpYXQiOjE3Nzc0NjM2ODUsImV4cCI6MjA5MzAzOTY4NX0'
      '.SZjJgF_9gaT4PEkGsShQOAQCvxsrqz8cgnWh2qdV1wQ';

  // Google Places + Maps SDK (same key)
  static const String googleApiKey = 'AIzaSyCn6UQS-FDDlbTdkmL2RWhdR3xDTf68Yf8';

  // Base URLs
  static const String placesBaseUrl =
      'https://places.googleapis.com/v1';
}
