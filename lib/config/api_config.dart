class ApiConfig {
  // ============================================================================
  // BASE CONFIGURATION
  // ============================================================================

  static const String baseUrl = 'https://louercheznous.com/public/api';
  static const String apiVersion = 'v1';

  /// Returns the versioned base URL (e.g., https://yourapi.com/api/v1)
  static String get versionedBaseUrl => '$baseUrl/$apiVersion';

  // ============================================================================
  // AUTHENTICATION ENDPOINTS (Public)
  // ============================================================================

  static String get registerUrl => '$versionedBaseUrl/register';
  static String get loginUrl => '$versionedBaseUrl/login';
  static String get logoutUrl => '$versionedBaseUrl/logout';

  // ============================================================================
  // DRIVER STATUS ENDPOINTS
  // ============================================================================

  static String get goOnlineUrl => '$versionedBaseUrl/goOnline';
  static String get goOfflineUrl => '$versionedBaseUrl/goOffline';
  static String get toggleStatusUrl => '$versionedBaseUrl/toggleStatus';
  static String get stopNewRequestsUrl => '$versionedBaseUrl/stopNewRequests';
  static String get acceptNewRequestsUrl =>
      '$versionedBaseUrl/acceptNewRequests';

  // ============================================================================
  // DRIVER ENDPOINTS
  // ============================================================================

  static String get driverUrl => '$versionedBaseUrl/driver';
  static String get updateLocationUrl => '$versionedBaseUrl/updateLocation';
  static String get updateDropOffLocationUrl =>
      '$versionedBaseUrl/updateDropOffLocation';
  static String get acceptRideUrl => '$versionedBaseUrl/acceptRide';
  static String get cancelTripUrl => '$versionedBaseUrl/cancelTrip';

  // ============================================================================
  // WALLET ENDPOINTS
  // ============================================================================

  static String get getWalletUrl => '$versionedBaseUrl/getWallet';

  // ============================================================================
  // RIDE REQUEST ENDPOINTS (Driver Side)
  // ============================================================================

  static String get getRideRequestsUrl => '$versionedBaseUrl/getRideRequests';
  static String get getRideRequestByIdUrl =>
      '$versionedBaseUrl/getRideRequestById';

  // ============================================================================
  // PASSENGER ENDPOINTS (For Driver)
  // ============================================================================

  static String get getPassengerUrl => '$versionedBaseUrl/passenger';

  // ============================================================================
  // PASSENGER RIDE REQUEST ENDPOINTS
  // ============================================================================

  static String get createRideRequestUrl =>
      '$versionedBaseUrl/create-ride-request';
  static String get getRideRequestUrl => '$versionedBaseUrl/get-ride-request';
  static String get cancelRideRequestUrl =>
      '$versionedBaseUrl/cancel-ride-request';

  // ============================================================================
  // MAP REPORTS ENDPOINTS
  // ============================================================================

  static String get createMapReportUrl => '$versionedBaseUrl/create-map-report';
  static String get getMapReportsUrl => '$versionedBaseUrl/get-map-reports';
  static String get getUserReportsUrl => '$versionedBaseUrl/get-user-reports';

  // ============================================================================
  // USER ENDPOINTS (Common)
  // ============================================================================

  /// Get user by ID
  static String userUrl(String userId) => '$versionedBaseUrl/user/$userId';

  static String get getUserRatingsUrl => '$versionedBaseUrl/getUserRatings';

  // ============================================================================
  // MESSAGING ENDPOINTS
  // ============================================================================

  /// Get messages between current user and a specific receiver
  static String messagesUrl(String receiverId) =>
      '$versionedBaseUrl/messages/$receiverId';

  /// Send a message
  static String get sendMessageUrl => '$versionedBaseUrl/messages';

  // ============================================================================
  // NOTIFICATION ENDPOINTS
  // ============================================================================

  static String get createNotificationUrl =>
      '$versionedBaseUrl/create-notification';
  static String get getUnreadNotificationsUrl =>
      '$versionedBaseUrl/get-unread-notifications';
  static String get markAsReadUrl => '$versionedBaseUrl/mark-as-read';
  static String get markAllAsReadUrl => '$versionedBaseUrl/mark-all-as-read';

  // ============================================================================
  // PAYMENT METHOD ENDPOINTS
  // ============================================================================

  static String get getUserPaymentMethodsUrl =>
      '$versionedBaseUrl/get-user-payment-methods';

  // ============================================================================
  // HELPER METHODS
  // ============================================================================

  /// Get common headers for authenticated requests
  static Map<String, String> getAuthHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      'Content-Type': 'application/json',
    };
  }

  /// Get headers for requests without authentication
  static Map<String, String> getHeaders() {
    return {'Accept': 'application/json', 'Content-Type': 'application/json'};
  }

  /// Get headers for multipart/form-data requests (file uploads)
  static Map<String, String> getMultipartHeaders(String token) {
    return {
      'Authorization': 'Bearer $token',
      'Accept': 'application/json',
      // Don't set Content-Type for multipart, http package handles it
    };
  }
}
