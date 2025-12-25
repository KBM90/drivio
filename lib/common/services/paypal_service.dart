import 'package:flutter/material.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:webview_flutter/webview_flutter.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

/// Service to handle PayPal account linking for driver payouts
class PayPalService {
  // Load credentials from .env file
  static String get _sandboxClientId =>
      dotenv.env['PAYPAL_SANDBOX_CLIENT_ID'] ?? '';
  static String get _sandboxClientSecret =>
      dotenv.env['PAYPAL_SANDBOX_CLIENT_SECRET'] ?? '';
  static String get _sandboxBaseUrl =>
      dotenv.env['PAYPAL_SANDBOX_BASE_URL'] ?? 'https://www.sandbox.paypal.com';
  static String get _sandboxApiUrl =>
      dotenv.env['PAYPAL_SANDBOX_API_URL'] ??
      'https://api-m.sandbox.paypal.com';
  static String get _redirectUri => dotenv.env['PAYPAL_REDIRECT_URI'] ?? '';

  /// Initiates the PayPal account linking flow
  /// Returns the PayPal account details if successful, null otherwise
  static Future<Map<String, dynamic>?> linkPayPalAccount(
    BuildContext context,
  ) async {
    try {
      // Step 1: Generate OAuth authorization URL
      final authUrl = _generateAuthUrl();

      // Step 2: Open WebView for PayPal login
      final authCode = await _openPayPalOAuth(context, authUrl);

      if (authCode == null) {
        debugPrint('❌ PayPal OAuth cancelled by user');
        return null;
      }

      // Step 3: Exchange authorization code for access token
      final accessToken = await _exchangeCodeForToken(authCode);

      if (accessToken == null) {
        debugPrint('❌ Failed to exchange auth code for token');
        return null;
      }

      // Step 4: Get PayPal account information
      final accountInfo = await _getPayPalAccountInfo(accessToken);

      if (accountInfo == null) {
        debugPrint('❌ Failed to retrieve PayPal account info');
        return null;
      }

      return accountInfo;
    } catch (e) {
      debugPrint('❌ Error linking PayPal account: $e');
      return null;
    }
  }

  /// Generates the PayPal OAuth authorization URL
  static String _generateAuthUrl() {
    final params = {
      'client_id': _sandboxClientId,
      'response_type': 'code',
      'scope': 'openid profile email',
      'redirect_uri': _redirectUri,
    };

    final queryString = params.entries
        .map(
          (e) =>
              '${Uri.encodeComponent(e.key)}=${Uri.encodeComponent(e.value)}',
        )
        .join('&');

    return '$_sandboxBaseUrl/connect?$queryString';
  }

  /// Opens a WebView for PayPal OAuth login
  /// Returns the authorization code if successful, null otherwise
  static Future<String?> _openPayPalOAuth(
    BuildContext context,
    String authUrl,
  ) async {
    String? authCode;

    await Navigator.of(context).push(
      MaterialPageRoute(
        builder:
            (context) => _PayPalOAuthWebView(
              authUrl: authUrl,
              redirectUri: _redirectUri,
              onAuthCodeReceived: (code) {
                authCode = code;
              },
            ),
      ),
    );

    return authCode;
  }

  /// Exchanges the authorization code for an access token
  static Future<String?> _exchangeCodeForToken(String authCode) async {
    try {
      final response = await http.post(
        Uri.parse('$_sandboxApiUrl/v1/oauth2/token'),
        headers: {
          'Content-Type': 'application/x-www-form-urlencoded',
          'Authorization': 'Basic ${_getBasicAuthHeader()}',
        },
        body: {
          'grant_type': 'authorization_code',
          'code': authCode,
          'redirect_uri': _redirectUri,
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return data['access_token'];
      } else {
        debugPrint(
          '❌ Token exchange failed: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error exchanging code for token: $e');
      return null;
    }
  }

  /// Gets PayPal account information using the access token
  static Future<Map<String, dynamic>?> _getPayPalAccountInfo(
    String accessToken,
  ) async {
    try {
      final response = await http.get(
        Uri.parse(
          '$_sandboxApiUrl/v1/identity/oauth2/userinfo?schema=paypalv1.1',
        ),
        headers: {
          'Authorization': 'Bearer $accessToken',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        return {
          'paypal_email': data['emails']?[0]?['value'] ?? data['email'],
          'paypal_payer_id': data['payer_id'] ?? data['user_id'],
          'paypal_name': data['name'] ?? '',
          'paypal_verified': data['verified_account'] ?? false,
          'linked_at': DateTime.now().toIso8601String(),
        };
      } else {
        debugPrint(
          '❌ Failed to get account info: ${response.statusCode} ${response.body}',
        );
        return null;
      }
    } catch (e) {
      debugPrint('❌ Error getting PayPal account info: $e');
      return null;
    }
  }

  /// Generates the Basic Auth header for PayPal API
  static String _getBasicAuthHeader() {
    final clientId = _sandboxClientId;
    final secret = _sandboxClientSecret;
    final credentials = '$clientId:$secret';
    return base64Encode(utf8.encode(credentials));
  }

  /// Saves PayPal payment method to the database
  static Future<bool> savePayPalPaymentMethod(
    Map<String, dynamic> paypalDetails,
  ) async {
    try {
      final userId = Supabase.instance.client.auth.currentUser?.id;
      if (userId == null) {
        debugPrint('❌ No authenticated user');
        return false;
      }

      // Get user's internal ID
      final userResponse =
          await Supabase.instance.client
              .from('users')
              .select('id')
              .eq('user_id', userId)
              .single();

      final internalUserId = userResponse['id'];

      // Get PayPal payment method ID
      final paymentMethodResponse =
          await Supabase.instance.client
              .from('payment_methods')
              .select('id')
              .eq('name', 'PayPal')
              .single();

      final paymentMethodId = paymentMethodResponse['id'];

      // Check if user already has a PayPal payment method
      final existingMethod =
          await Supabase.instance.client
              .from('user_payment_methods')
              .select()
              .eq('user_id', internalUserId)
              .eq('payment_method_id', paymentMethodId)
              .maybeSingle();

      if (existingMethod != null) {
        // Update existing PayPal payment method
        await Supabase.instance.client
            .from('user_payment_methods')
            .update({
              'details': paypalDetails,
              'updated_at': DateTime.now().toIso8601String(),
            })
            .eq('id', existingMethod['id']);
      } else {
        // Insert new PayPal payment method
        await Supabase.instance.client.from('user_payment_methods').insert({
          'user_id': internalUserId,
          'payment_method_id': paymentMethodId,
          'details': paypalDetails,
          'is_default': false,
        });
      }

      return true;
    } catch (e) {
      debugPrint('❌ Error saving PayPal payment method: $e');
      return false;
    }
  }
}

/// WebView widget for PayPal OAuth login
class _PayPalOAuthWebView extends StatefulWidget {
  final String authUrl;
  final String redirectUri;
  final Function(String) onAuthCodeReceived;

  const _PayPalOAuthWebView({
    required this.authUrl,
    required this.redirectUri,
    required this.onAuthCodeReceived,
  });

  @override
  State<_PayPalOAuthWebView> createState() => _PayPalOAuthWebViewState();
}

class _PayPalOAuthWebViewState extends State<_PayPalOAuthWebView> {
  late final WebViewController _controller;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _initializeWebView();
  }

  void _initializeWebView() {
    _controller =
        WebViewController()
          ..setJavaScriptMode(JavaScriptMode.unrestricted)
          ..setNavigationDelegate(
            NavigationDelegate(
              onPageStarted: (url) {
                setState(() => _isLoading = true);
                _checkForRedirect(url);
              },
              onPageFinished: (url) {
                setState(() => _isLoading = false);
              },
              onWebResourceError: (error) {
                debugPrint('❌ WebView error: ${error.description}');
              },
            ),
          )
          ..loadRequest(Uri.parse(widget.authUrl));
  }

  void _checkForRedirect(String url) {
    if (url.startsWith(widget.redirectUri)) {
      final uri = Uri.parse(url);
      final code = uri.queryParameters['code'];

      if (code != null) {
        widget.onAuthCodeReceived(code);
        Navigator.of(context).pop();
      } else {
        debugPrint('❌ No authorization code in redirect URL');
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Link PayPal Account'),
        leading: IconButton(
          icon: const Icon(Icons.close),
          onPressed: () => Navigator.of(context).pop(),
        ),
      ),
      body: Stack(
        children: [
          WebViewWidget(controller: _controller),
          if (_isLoading) const Center(child: CircularProgressIndicator()),
        ],
      ),
    );
  }
}
