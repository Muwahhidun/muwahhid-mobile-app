/// API configuration for the application.
class ApiConfig {
  /// Base URL for the API
  /// Change this to your backend server URL
  static const String baseUrl = 'http://localhost:8000';

  /// API version prefix
  static const String apiPrefix = '/api';

  /// Full API base URL
  static String get apiBaseUrl => '$baseUrl$apiPrefix';

  /// Auth endpoints
  static const String loginEndpoint = '/auth/login';
  static const String registerEndpoint = '/auth/register';
  static const String meEndpoint = '/auth/me';

  /// Content endpoints
  static const String themesEndpoint = '/themes';
  static const String teachersEndpoint = '/teachers';
  static const String seriesEndpoint = '/series';
  static const String lessonsEndpoint = '/lessons';

  /// API timeouts
  static const Duration connectTimeout = Duration(seconds: 30);
  static const Duration receiveTimeout = Duration(seconds: 30);
  static const Duration sendTimeout = Duration(seconds: 30);
}
