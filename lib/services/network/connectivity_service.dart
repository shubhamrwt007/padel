import 'dart:async';
import 'dart:io';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:get/get.dart';
import 'package:flutter/material.dart';

import '../../configs/components/snack_bars.dart';

class ConnectivityService extends GetxService {
  // Singleton pattern
  static final ConnectivityService _instance = ConnectivityService._internal();
  factory ConnectivityService() => _instance;
  ConnectivityService._internal();

  // Observable connectivity status
  final Rx<ConnectivityResult> connectivity = ConnectivityResult.none.obs;
  final RxBool isConnected = false.obs;
  
  // Stream subscription
  StreamSubscription<List<ConnectivityResult>>? _subscription;
  
  // Flag to track if no internet snackbar is currently showing
  bool _isShowingNoInternetSnackBar = false;
  Timer? _snackBarCooldownTimer;
  Timer? _retryCheckTimer;
  static const int _snackBarCooldown = 5000; // milliseconds
  
  // Add a flag to track initialization status
  bool _isInitialized = false;

  Future<ConnectivityService> init() async {
    // Prevent duplicate initialization
    if (_isInitialized) {
      return this;
    }
    
    _isInitialized = true;
    
    // Get initial connectivity status
    connectivity.value = (await Connectivity().checkConnectivity())[0];

    // Schedule a connectivity check after UI has settled (important for hot restart)
    _scheduleConnectivityCheck();
    
    // Set up listeners for connectivity changes
    _setupConnectivityListener();
    
    return this;
  }
  
  void _setupConnectivityListener() {
    // Cancel any existing subscription
    _subscription?.cancel();
    
    // Listen for connectivity changes
    _subscription = Connectivity().onConnectivityChanged.listen((result) {
      connectivity.value = result[0];
      
      // Schedule a check when connectivity changes
      _scheduleConnectivityCheck();
    });
  }
  
  void _scheduleConnectivityCheck() {
    // Cancel any existing scheduled check
    _retryCheckTimer?.cancel();
    
    // Check after a short delay to allow network to stabilize
    _retryCheckTimer = Timer(Duration(milliseconds: 1000), () async {
      final wasConnected = isConnected.value;
      final hasConnection = await _hasRealInternetConnectivity();
      
      isConnected.value = hasConnection;
      
      // Show snackbar if connection was lost
      if (wasConnected && !hasConnection) {
        _showNoInternetSnackBar();
      }
      
      // Show snackbar if no connection at startup (after the delay)
      if (!hasConnection && connectivity.value != ConnectivityResult.none) {
        _showNoInternetSnackBar();
      }
    });
  }
  
  // Check for actual internet connectivity by trying multiple reliable domains
  Future<bool> _hasRealInternetConnectivity() async {
    if (connectivity.value == ConnectivityResult.none) {
      return false;
    }
    
    // List of reliable domains to try
    final domains = [
      'google.com',   // Google
      'apple.com',    // Apple
      '1.1.1.1',      // Cloudflare DNS
      '8.8.8.8',      // Google DNS
    ];
    
    for (final domain in domains) {
      try {
        // Set a timeout to avoid hanging
        final result = await InternetAddress.lookup(domain)
            .timeout(Duration(seconds: 2));
            
        if (result.isNotEmpty && result[0].rawAddress.isNotEmpty) {
          return true;
        }
      } on SocketException catch (_) {
        continue; // Try next domain
      } on TimeoutException catch (_) {
        continue; // Try next domain
      } catch (e) {
        continue; // Try next domain
      }
    }
    
    return false;
  }
  
  // Show "No internet" snackbar with cooldown
  void _showNoInternetSnackBar() {
    if (_isShowingNoInternetSnackBar) return;
    
    _isShowingNoInternetSnackBar = true;
    // SnackBarUtils.showErrorSnackBar('. Please check your network settings.');
    Fluttertoast.showToast(
      msg: "No internet connection",
      toastLength: Toast.LENGTH_SHORT,
      gravity: ToastGravity.TOP,
      backgroundColor: Colors.red,
      textColor: Colors.white,
      fontSize: 16.0,
      timeInSecForIosWeb: 3,
    );
    
    // Start cooldown timer
    _snackBarCooldownTimer?.cancel();
    _snackBarCooldownTimer = Timer(
      Duration(milliseconds: _snackBarCooldown),
      () => _isShowingNoInternetSnackBar = false
    );
  }

  // Check if currently connected - can be called from outside
  Future<bool> checkConnectivity() async {
    // First check the device connectivity
    final result = await Connectivity().checkConnectivity();
    connectivity.value = result[0];
    

    // Then verify actual internet connection
    final hasConnection = await _hasRealInternetConnectivity();
    isConnected.value = hasConnection;
    
    // If there's no connection, show the snackbar
    if (!hasConnection) {
      _showNoInternetSnackBar();
    }
    
    return hasConnection;
  }

  // Force an immediate connectivity check
  Future<bool> forceConnectivityCheck() async {
    return await checkConnectivity();
  }

  @override
  void onClose() {
    _subscription?.cancel();
    _snackBarCooldownTimer?.cancel();
    _retryCheckTimer?.cancel();
    super.onClose();
  }
} 