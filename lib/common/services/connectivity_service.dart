import 'dart:async';
import 'dart:io';

enum InternetStatus { connected, disconnected }

class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();

  factory ConnectivityService() {
    return _instance;
  }

  ConnectivityService._internal() {
    // Start polling
    _startMonitoring();
  }

  static ConnectivityService get instance => _instance;

  final StreamController<InternetStatus> _controller =
      StreamController<InternetStatus>.broadcast();

  Stream<InternetStatus> get onStatusChange => _controller.stream;

  InternetStatus _lastStatus = InternetStatus.connected;

  Timer? _timer;

  void _startMonitoring() {
    // Check immediately
    _checkConnection();

    // Poll every 5 seconds
    _timer = Timer.periodic(const Duration(seconds: 5), (timer) {
      _checkConnection();
    });
  }

  Future<void> _checkConnection() async {
    bool isConnected = false;
    try {
      final result = await InternetAddress.lookup('google.com');
      if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
        isConnected = true;
      }
    } on SocketException catch (_) {
      isConnected = false;
    }

    final newStatus =
        isConnected ? InternetStatus.connected : InternetStatus.disconnected;

    if (_lastStatus != newStatus) {
      _lastStatus = newStatus;
      _controller.add(newStatus);
    }
  }

  void dispose() {
    _timer?.cancel();
    _controller.close();
  }
}
