# PayPal Configuration Template

## Instructions
1. Copy this file and create a new file called `paypal_config.dart` in `lib/common/config/`
2. Add `paypal_config.dart` to your `.gitignore` to keep credentials secure
3. Fill in your PayPal credentials from the PayPal Developer Dashboard

## Configuration File Template

Create: `lib/common/config/paypal_config.dart`

```dart
/// PayPal API Configuration
/// DO NOT commit this file to version control!
class PayPalConfig {
  // Sandbox credentials (for testing)
  static const String sandboxClientId = 'YOUR_SANDBOX_CLIENT_ID_HERE';
  static const String sandboxSecret = 'YOUR_SANDBOX_SECRET_HERE';
  
  // Production credentials (for live app)
  static const String liveClientId = 'YOUR_LIVE_CLIENT_ID_HERE';
  static const String liveSecret = 'YOUR_LIVE_SECRET_HERE';
  
  // Environment flag
  static const bool useSandbox = true; // Set to false for production
  
  // Get current credentials based on environment
  static String get clientId => useSandbox ? sandboxClientId : liveClientId;
  static String get secret => useSandbox ? sandboxSecret : liveSecret;
  static String get baseUrl => useSandbox 
      ? 'https://www.sandbox.paypal.com' 
      : 'https://www.paypal.com';
  static String get apiUrl => useSandbox 
      ? 'https://api-m.sandbox.paypal.com' 
      : 'https://api-m.paypal.com';
}
```

## Update .gitignore

Add this line to your `.gitignore` file:

```
lib/common/config/paypal_config.dart
```

## Update PayPalService

Once you create the config file, update `paypal_service.dart` to use it:

```dart
import 'package:drivio_app/common/config/paypal_config.dart';

class PayPalService {
  static String get _clientId => PayPalConfig.clientId;
  static String get _secret => PayPalConfig.secret;
  static String get _baseUrl => PayPalConfig.baseUrl;
  static String get _apiUrl => PayPalConfig.apiUrl;
  
  // ... rest of the code
}
```
