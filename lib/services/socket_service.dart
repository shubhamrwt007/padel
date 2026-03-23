import 'dart:developer';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:get/get.dart';
import '../core/endpoitns.dart';

class SocketService extends GetxService {
  static SocketService get instance => Get.find<SocketService>();
  
  IO.Socket? _socket;
  final RxBool _isConnected = false.obs;
  final RxString _userId = ''.obs;
  
  bool get isConnected => _isConnected.value;
  IO.Socket? get socket => _socket;
  String get userId => _userId.value;

  @override
  void onInit() {
    super.onInit();
    _initSocket();
  }

  void _initSocket() {
    try {
      log('Initializing socket with URL: ${AppEndpoints.socketUrl}');
      
      // Prepare connection options with user ID if available
      final options = <String, dynamic>{
        'transports': ['websocket', 'polling'], // Add polling as fallback
        'autoConnect': false,
        'timeout': 20000,
        'reconnection': true,
        'reconnectionDelay': 1000,
        'reconnectionAttempts': 5,
        'forceNew': true, // Force new connection
      };
      
      // Add user ID to connection query if available
      if (_userId.value.isNotEmpty) {
        options['query'] = {
          'userId': _userId.value,
          'platform': 'mobile',
          'timestamp': DateTime.now().toIso8601String(),
        };
        log('📝 Socket initialized with user ID: ${_userId.value}');
      }
      
      // Use socket URL from endpoints configuration
      _socket = IO.io(AppEndpoints.socketUrl, options);

      _socket?.onConnect((_) {
        log('✅ Socket connected successfully to: ${AppEndpoints.socketUrl}');
        _isConnected.value = true;
        
        // Send connection confirmation with user data
        if (_userId.value.isNotEmpty) {
          final connectionData = {
            'userId': _userId.value,
            'platform': 'mobile',
            'timestamp': DateTime.now().toIso8601String(),
            'action': 'connected',
          };
          
          _socket?.emit('userConnected', connectionData);
          log('✅ userConnected event emitted: $connectionData');
        }
        
        // Also emit registerUser for backward compatibility
        if (_userId.value.isNotEmpty) {
          log('🔄 Auto-registering user on connection: ${_userId.value}');
          _emitRegisterUser(_userId.value);
        } else {
          log('⚠️ No user ID available for auto-registration');
        }
      });

      _socket?.onDisconnect((reason) {
        log('❌ Socket disconnected from: ${AppEndpoints.socketUrl}, reason: $reason');
        _isConnected.value = false;
      });

      _socket?.onError((error) {
        log('❌ Socket error: $error');
        _isConnected.value = false;
      });

      _socket?.onReconnect((attemptNumber) {
        log('🔄 Socket reconnected to: ${AppEndpoints.socketUrl}, attempt: $attemptNumber');
        _isConnected.value = true;
        
        // Send reconnection data with user ID
        if (_userId.value.isNotEmpty) {
          final reconnectionData = {
            'userId': _userId.value,
            'platform': 'mobile',
            'timestamp': DateTime.now().toIso8601String(),
            'action': 'reconnected',
            'attempt': attemptNumber,
          };
          
          _socket?.emit('userReconnected', reconnectionData);
          log('✅ userReconnected event emitted: $reconnectionData');
          
          // Re-register user on reconnection
          log('🔄 Re-registering user on reconnection: ${_userId.value}');
          _emitRegisterUser(_userId.value);
        }
      });

      _socket?.onReconnectAttempt((attemptNumber) {
        log('🔄 Socket reconnection attempt: $attemptNumber');
      });

      _socket?.onReconnectError((error) {
        log('❌ Socket reconnection error: $error');
      });

      _socket?.onReconnectFailed((_) {
        log('❌ Socket reconnection failed');
      });

      // Listen for user registration confirmation
      _socket?.on('userRegistered', (data) {
        log('✅ User registration confirmed: $data');
      });

      // Listen for user connection confirmation
      _socket?.on('userConnectedAck', (data) {
        log('✅ User connection acknowledged: $data');
      });

      // Listen for slot updates
      _socket?.on('slotUpdate', (data) {
        log('📡 Slot update received: $data');
        // Handle slot updates here
      });

      // Listen for courtsByDuration real-time updates
      _socket?.on('courtsByDuration:data', (response) {
        log('📡 courtsByDuration:data received: $response');
        log('📊 _onCourtsByDurationUpdate callback set: ${_onCourtsByDurationUpdate != null}');
        if (_onCourtsByDurationUpdate != null && response != null) {
          _onCourtsByDurationUpdate!(response);
        }
      });

      // Listen for slot-wise updates (same structure as getAllActiveCourtsForSlotWise API)
      _socket?.on('slotWise:update', (data) {
        log('📡 SlotWise update received: $data');
        // This will contain the same data structure as getAllActiveCourtsForSlotWise API response
        // Handle real-time slot updates here
      });

      // Listen for real-time slot data updates
      _socket?.on('slotWise:data', (res) {
        log('📡 SlotWise:data received: $res');
        // This contains updated slot data when bookings happen
        if (res != null && res['data'] != null) {
          log('📡 Processing slotWise:data with callback');
          // Handle real-time slot data updates
          _handleSlotDataUpdateWithCallback(res['data']);
        } else {
          log('⚠️ slotWise:data received but no data field found');
        }
      });

      // Listen for slot-wise subscription confirmation
      _socket?.on('slotWise:subscribed', (data) {
        log('✅ SlotWise subscription confirmed: $data');
      });

      // Listen for slot-wise unsubscription confirmation
      _socket?.on('slotWise:unsubscribed', (data) {
        log('✅ SlotWise unsubscription confirmed: $data');
      });

      // Listen for connection acknowledgment
      _socket?.on('connect_ack', (data) {
        log('✅ Connection acknowledged: $data');
      });

      log('Socket initialized successfully');

    } catch (e) {
      log('❌ Socket initialization error: $e');
    }
  }

  void connect() {
    if (_socket == null) {
      log('❌ Socket is null, reinitializing...');
      _initSocket();
      return;
    }
    
    if (!_isConnected.value) {
      log('🔌 Attempting to connect socket to: ${AppEndpoints.socketUrl}');
      
      // Add user ID to connection query if available
      if (_userId.value.isNotEmpty) {
        log('📝 Connecting with user ID: ${_userId.value}');
        _socket?.io.options?['query'] = {
          'userId': _userId.value,
          'platform': 'mobile',
          'timestamp': DateTime.now().toIso8601String(),
        };
      }
      
      try {
        _socket?.connect();
        
        // Set a timeout to check connection status
        Future.delayed(const Duration(seconds: 5), () {
          if (!_isConnected.value) {
            log('⚠️ Socket connection timeout after 5 seconds');
          }
        });
      } catch (e) {
        log('❌ Error during socket connection: $e');
      }
    } else {
      log('✅ Socket already connected to: ${AppEndpoints.socketUrl}');
    }
  }

  void disconnect() {
    if (_socket != null && _isConnected.value) {
      log('Disconnecting socket from: ${AppEndpoints.socketUrl}');
      _socket?.disconnect();
      _userId.value = '';
    }
  }

  void registerUser(String userId) {
    if (userId.isEmpty) {
      log('❌ Cannot register user: userId is empty');
      return;
    }

    log('📝 Setting user ID: $userId');
    _userId.value = userId;
    
    if (_socket != null && _isConnected.value) {
      log('✅ Socket is connected, emitting registerUser immediately');
      _emitRegisterUser(userId);
    } else {
      log('⚠️ Socket not connected (connected: ${_isConnected.value}, socket null: ${_socket == null})');
      log('🔄 Will register user when socket connects');
      
      // Try to connect if not connected
      if (!_isConnected.value) {
        connect();
      }
    }
  }

  // Private method to emit registerUser event
  void _emitRegisterUser(String userId) {
    if (_socket == null || !_isConnected.value) {
      log('❌ Cannot emit registerUser: socket not ready');
      return;
    }

    final userData = {
      'userId': userId,
      'timestamp': DateTime.now().toIso8601String(),
      'platform': 'mobile',
      'action': 'register',
    };
    
    try {
      _socket?.emit('registerUser', userData);
      log('✅ registerUser event emitted successfully: $userData');
    } catch (e) {
      log('❌ Error emitting registerUser: $e');
    }
  }

  void emitSlotSelection(Map<String, dynamic> slotData) {
    if (_socket != null && _isConnected.value) {
      _socket?.emit('slotSelected', slotData);
      log('Slot selection emitted: $slotData');
    }
  }

  void emitSlotDeselection(Map<String, dynamic> slotData) {
    if (_socket != null && _isConnected.value) {
      _socket?.emit('slotDeselected', slotData);
      log('📤 Slot deselection emitted: $slotData');
    } else {
      log('⚠️ Cannot emit slot deselection - socket not connected');
    }
  }

  // Test connection method
  void testConnection() {
    log('🧪 Testing socket connection...');
    log('Socket URL: ${AppEndpoints.socketUrl}');
    log('Socket null: ${_socket == null}');
    log('Is connected: ${_isConnected.value}');
    log('User ID: ${_userId.value}');
    
    if (_socket != null) {
      log('Socket connected: ${_socket!.connected}');
      log('Socket disconnected: ${_socket!.disconnected}');
    }
    
    // Try to emit a test event
    if (_socket != null && _isConnected.value) {
      _socket?.emit('test', {'message': 'Test connection', 'timestamp': DateTime.now().toIso8601String()});
      log('📡 Test event emitted');
    }
  }

  // Force reconnect method
  void forceReconnect() {
    log('🔄 Force reconnecting socket...');
    disconnect();
    Future.delayed(const Duration(seconds: 1), () {
      connect();
    });
  }

  // Set user ID and connect if needed
  void setUserIdAndConnect(String userId) {
    if (userId.isEmpty) {
      log('❌ Cannot set empty user ID');
      return;
    }

    log('📝 Setting user ID and ensuring connection: $userId');
    _userId.value = userId;
    
    // If socket exists, update its query parameters
    if (_socket != null) {
      _socket?.io.options?['query'] = {
        'userId': userId,
        'platform': 'mobile',
        'timestamp': DateTime.now().toIso8601String(),
      };
    }
    
    // Connect if not already connected
    if (!_isConnected.value) {
      // Reinitialize socket with user ID in query
      _initSocket();
      connect();
    } else {
      // If already connected, emit user connected event and register
      final connectionData = {
        'userId': userId,
        'platform': 'mobile',
        'timestamp': DateTime.now().toIso8601String(),
        'action': 'user_updated',
      };
      
      _socket?.emit('userConnected', connectionData);
      log('✅ userConnected event emitted for existing connection: $connectionData');
      
      // Also register user
      _emitRegisterUser(userId);
    }
  }

  // Subscribe to slot-wise updates with acknowledgment callback
  void subscribeToSlotWiseUpdates({
    required String clubId,
    required String locationId,
    required String categoryId,
    required String sId,
    required String date,
    required String day,
    String? locId,
    Function(dynamic)? onInitialData,
  }) {
    if (_socket == null || !_isConnected.value) {
      log('❌ Cannot subscribe to slot updates: socket not connected');
      return;
    }

    final subscriptionData = {
      'query': {
        'register_club_id': clubId,
        'date': date,
        'locationId': locationId,
        'categoryId': categoryId,
        'sId': sId,
        'day': day,
        'locId': locId ?? '',
      },
      'userId': _userId.value,
      'timestamp': DateTime.now().toIso8601String(),
    };

    try {
      _socket?.emitWithAck('slotWise:subscribe', subscriptionData, ack: (data) {
        log('✅ slotWise:subscribe acknowledgment received: $data');
        
        // Handle initial slot data from acknowledgment
        if (data != null && data['data'] != null) {
          log('📡 Initial slot data received in ack: ${data['data']}');
          onInitialData?.call(data['data']);
        }
      });
      
      log('✅ slotWise:subscribe event emitted with ack: $subscriptionData');
    } catch (e) {
      log('❌ Error emitting slotWise:subscribe: $e');
    }
  }

  // Unsubscribe from slot-wise updates
  void unsubscribeFromSlotWiseUpdates({
    required String clubId,
    required String date,
  }) {
    if (_socket == null || !_isConnected.value) {
      log('❌ Cannot unsubscribe from slot updates: socket not connected');
      return;
    }

    final unsubscriptionData = {
      'clubId': clubId,
      'date': date,
    };

    try {
      _socket?.emitWithAck('slotWise:unsubscribe', unsubscriptionData, ack: (response) {
        log('✅ slotWise:unsubscribe response: $response');
      });
      log('✅ slotWise:unsubscribe event emitted: $unsubscriptionData');
    } catch (e) {
      log('❌ Error emitting slotWise:unsubscribe: $e');
    }
  }

  @override
  void onClose() {
    disconnect();
    _socket?.dispose();
    super.onClose();
  }

  // Handle real-time slot data updates
  void _handleSlotDataUpdate(dynamic slotData) {
    try {
      log('🔄 Processing real-time slot data update');
      // This method can be overridden or use callbacks to handle slot data updates
      // For now, just log the data - BookSessionController will handle the actual updates
    } catch (e) {
      log('❌ Error handling slot data update: $e');
    }
  }

  // courtsByDuration callback
  Function(dynamic)? _onCourtsByDurationUpdate;

  void setCourtsByDurationCallback(Function(dynamic) callback) {
    _onCourtsByDurationUpdate = callback;
  }

  void clearCourtsByDurationCallback() {
    _onCourtsByDurationUpdate = null;
  }

  void subscribeToCourtsByDuration({
    required String date,
    required String duration,
    String? time,
    String? categoryId,
    // String? location,
    String? queryKey,
    String? userId,
    Function(dynamic)? onInitialData,
  }) {
    if (_socket == null || !_isConnected.value) {
      log('❌ Cannot subscribe to courtsByDuration: socket not connected');
      return;
    }
    final payload = {
      'query': {
        'date': date,
        'duration': duration,
        if (time != null && time.isNotEmpty) 'time': time,
        if (categoryId != null && categoryId.isNotEmpty) 'categoryId': categoryId,
        // if (location != null && location.isNotEmpty) 'location': location,
      },
      if (queryKey != null) 'queryKey': queryKey,
      if (userId != null && userId.isNotEmpty) 'userId': userId,
    };
    try {
      _socket?.emitWithAck('courtsByDuration:subscribe', payload, ack: (response) {
        log('✅ courtsByDuration:subscribe ack: $response');
        if (response != null && response['success'] == true && response['data'] != null) {
          onInitialData?.call(response['data']);
        }
      });
      log('📤 courtsByDuration:subscribe emitted: $payload');
    } catch (e) {
      log('❌ Error emitting courtsByDuration:subscribe: $e');
    }
  }

  void unsubscribeFromCourtsByDuration({
    required String date,
    required String duration,
  }) {
    if (_socket == null || !_isConnected.value) return;
    try {
      _socket?.emitWithAck(
        'courtsByDuration:unsubscribe',
        {'date': date, 'duration': duration},
        ack: (response) => log('✅ courtsByDuration:unsubscribe: $response'),
      );
    } catch (e) {
      log('❌ Error emitting courtsByDuration:unsubscribe: $e');
    }
  }

  // Set callback for slot data updates
  Function(dynamic)? _onSlotDataUpdate;
  
  void setSlotDataUpdateCallback(Function(dynamic) callback) {
    log('📌 Setting slot data update callback');
    _onSlotDataUpdate = callback;
    log('✅ Slot data update callback set successfully');
  }
  
  void clearSlotDataUpdateCallback() {
    log('📌 Clearing slot data update callback');
    _onSlotDataUpdate = null;
  }
  
  void _handleSlotDataUpdateWithCallback(dynamic slotData) {
    try {
      log('🔄 Processing real-time slot data update with callback');
      log('📊 Callback set: ${_onSlotDataUpdate != null}');
      log('📊 Slot data: $slotData');
      
      if (_onSlotDataUpdate != null) {
        _onSlotDataUpdate!(slotData);
        log('✅ Callback executed successfully');
      } else {
        log('⚠️ No callback set for slot data updates');
      }
    } catch (e) {
      log('❌ Error handling slot data update with callback: $e');
    }
  }
}