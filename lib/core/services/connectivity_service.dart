import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/foundation.dart';

/// Service to monitor internet connectivity
class ConnectivityService {
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  final Connectivity _connectivity = Connectivity();
  final _connectivityController = StreamController<bool>.broadcast();
  StreamSubscription<List<ConnectivityResult>>? _subscription;

  bool _isConnected = true;
  bool _isInitialized = false;

  /// Stream of connectivity status
  Stream<bool> get onConnectivityChanged => _connectivityController.stream;

  /// Current connectivity status
  bool get isConnected => _isConnected;

  /// Initialize the service
  Future<void> initialize() async {
    if (_isInitialized) return;
    _isInitialized = true;

    // Check initial connectivity
    await _checkConnectivity();

    // Listen to connectivity changes
    _subscription = _connectivity.onConnectivityChanged.listen((results) async {
      // When connectivity changes, verify with actual internet check
      await _checkConnectivity();
    });
  }

  /// Check actual internet connectivity by pinging reliable servers
  Future<bool> _checkConnectivity() async {
    final wasConnected = _isConnected;

    try {
      // Try multiple reliable hosts
      final hosts = ['google.com', 'cloudflare.com', '8.8.8.8'];

      for (final host in hosts) {
        try {
          final result = await InternetAddress.lookup(host)
              .timeout(const Duration(seconds: 3));
          if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
            _isConnected = true;
            if (!wasConnected) {
              debugPrint('🌐 Internet connected');
              _connectivityController.add(true);
            }
            return true;
          }
        } catch (_) {
          continue;
        }
      }

      _isConnected = false;
      if (wasConnected) {
        debugPrint('📴 Internet disconnected');
        _connectivityController.add(false);
      }
      return false;
    } catch (e) {
      _isConnected = false;
      if (wasConnected) {
        debugPrint('📴 Internet disconnected: $e');
        _connectivityController.add(false);
      }
      return false;
    }
  }

  /// Force check connectivity
  Future<bool> checkNow() => _checkConnectivity();

  /// Dispose the service
  void dispose() {
    _subscription?.cancel();
    _connectivityController.close();
  }
}
