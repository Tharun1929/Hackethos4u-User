import 'dart:async';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class ConnectivityService extends GetxController {
  static ConnectivityService get to => Get.find();

  final _connectivity = Connectivity();
  final _isConnected = true.obs;
  final _connectionType = ConnectivityResult.none.obs;
  StreamSubscription<List<ConnectivityResult>>? _connectivitySubscription;

  bool get isConnected => _isConnected.value;
  ConnectivityResult get connectionType => _connectionType.value;

  @override
  void onInit() {
    super.onInit();
    _initConnectivity();
    _setupConnectivityStream();
  }

  @override
  void onClose() {
    _connectivitySubscription?.cancel();
    super.onClose();
  }

  Future<void> _initConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final result =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      _updateConnectionStatus(result);
    } catch (e) {
      // print('Error checking connectivity: $e');
      _isConnected.value = false;
    }
  }

  void _setupConnectivityStream() {
    _connectivitySubscription = _connectivity.onConnectivityChanged.listen(
      (List<ConnectivityResult> results) {
        final result =
            results.isNotEmpty ? results.first : ConnectivityResult.none;
        _updateConnectionStatus(result);
      },
      onError: (error) {
        // print('Connectivity stream error: $error');
        _isConnected.value = false;
      },
    );
  }

  void _updateConnectionStatus(ConnectivityResult result) {
    _connectionType.value = result;
    _isConnected.value = result != ConnectivityResult.none;

    if (!_isConnected.value) {
      _showNoConnectionMessage();
    } else {
      _hideNoConnectionMessage();
    }
  }

  void _showNoConnectionMessage() {
    if (!Get.isSnackbarOpen) {
      Get.snackbar(
        'No Internet Connection',
        'Please check your network connection and try again.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 4),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.wifi_off, color: Colors.white),
        mainButton: TextButton(
          onPressed: () {
            Get.back();
            _checkConnectivity();
          },
          child: const Text(
            'Retry',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  void _hideNoConnectionMessage() {
    if (Get.isSnackbarOpen) {
      Get.back();
    }
  }

  Future<bool> _checkConnectivity() async {
    try {
      final results = await _connectivity.checkConnectivity();
      final result =
          results.isNotEmpty ? results.first : ConnectivityResult.none;
      _updateConnectionStatus(result);
      return result != ConnectivityResult.none;
    } catch (e) {
      // print('Error checking connectivity: $e');
      return false;
    }
  }

  Future<bool> checkConnectivity() async {
    return await _checkConnectivity();
  }

  void showConnectionError() {
    if (!_isConnected.value) {
      Get.snackbar(
        'Network Connection Error',
        'Please connect to the internet to continue.',
        backgroundColor: Colors.red,
        colorText: Colors.white,
        duration: const Duration(seconds: 3),
        snackPosition: SnackPosition.TOP,
        margin: const EdgeInsets.all(16),
        borderRadius: 12,
        icon: const Icon(Icons.signal_wifi_off, color: Colors.white),
        mainButton: TextButton(
          onPressed: () {
            Get.back();
            _checkConnectivity();
          },
          child: const Text(
            'Check Connection',
            style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
          ),
        ),
      );
    }
  }

  String getConnectionTypeString() {
    switch (_connectionType.value) {
      case ConnectivityResult.wifi:
        return 'WiFi';
      case ConnectivityResult.mobile:
        return 'Mobile Data';
      case ConnectivityResult.ethernet:
        return 'Ethernet';
      case ConnectivityResult.vpn:
        return 'VPN';
      case ConnectivityResult.bluetooth:
        return 'Bluetooth';
      case ConnectivityResult.other:
        return 'Other';
      case ConnectivityResult.none:
      default:
        return 'No Connection';
    }
  }

  bool get isWifi => _connectionType.value == ConnectivityResult.wifi;
  bool get isMobileData => _connectionType.value == ConnectivityResult.mobile;
  bool get isEthernet => _connectionType.value == ConnectivityResult.ethernet;
}
