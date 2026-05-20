import 'package:get/get.dart';
import 'package:flutter/material.dart';
import 'package:padel_mobile/handler/logger.dart';
import 'package:padel_mobile/core/endpoitns.dart';
import 'package:padel_mobile/presentations/booking/details_page/details_page_controller.dart';
import 'package:socket_io_client/socket_io_client.dart' as IO;
import 'package:get_storage/get_storage.dart';

class ChatController extends GetxController {
  static IO.Socket? _sharedSocket;
  IO.Socket get socket => _sharedSocket!;
  final storage = GetStorage();
  final TextEditingController messageController = TextEditingController();
  final ScrollController scrollController = ScrollController();
  final RxList<Map<String, dynamic>> messages = <Map<String, dynamic>>[].obs;
  final RxBool isConnected = false.obs;
  final RxBool showDateHeader = false.obs;
  final RxString currentScrollDate = ''.obs;
  final RxList<String> connectedPlayers = <String>[].obs;
  final RxList<Map<String, dynamic>> allMatchPlayers = <Map<String, dynamic>>[].obs;
  final RxBool isChatScreenActive = false.obs;

  
  // Static cache to persist messages across controller recreations
  static final Map<String, List<Map<String, dynamic>>> _messageCache = {};
  
  /// Clear static message cache (used during logout)
  static void clearMessageCache() {
    _messageCache.clear();
  }
  
  /// Disconnect shared socket (used during logout)
  static void disconnectSharedSocket() {
    if (_sharedSocket != null) {
      CustomLogger.logMessage(
        msg: '🔌 CHAT: Disconnecting shared socket and leaving all matches',
        level: LogLevel.info,
      );
      // Leave all matches before disconnecting
      _sharedSocket!.emit('leaveAllMatches');
      _sharedSocket!.disconnect();
      _sharedSocket = null;
      CustomLogger.logMessage(
        msg: '✅ CHAT: Shared socket disconnected',
        level: LogLevel.info,
      );
    }
  }

  /// Get unique player names from messages as fallback (excluding current user)
  List<String> get playersFromMessages {
    final uniquePlayers = <String>{};
    for (final message in messages) {
      final sender = message['sender']?.toString();
      final isCurrentUser = message['isMe'] == true;
      
      if (sender != null && sender.isNotEmpty && !isCurrentUser) {
        uniquePlayers.add(sender);
      }
    }
    
    return uniquePlayers.take(4).toList();
  }

  /// Get formatted player names with "You" always first, then other players
  List<String> get formattedPlayersForTitle {
    final result = <String>['You'];
    final currentUserId = userId;
    
    // Always prioritize all match players if available
    if (allMatchPlayers.isNotEmpty) {
      CustomLogger.logMessage(
        msg: '👥 formattedPlayersForTitle: allMatchPlayers has ${allMatchPlayers.length} players, current userId: $currentUserId',
        level: LogLevel.debug,
      );
      
      final otherPlayers = allMatchPlayers
          .where((player) {
            final playerId = player['userId']?.toString() ?? player['_id']?.toString() ?? '';
            final isNotCurrentUser = playerId != currentUserId && playerId.isNotEmpty;
            CustomLogger.logMessage(
              msg: '👥 Checking player: id=$playerId, name=${player['name']}, isNotCurrentUser=$isNotCurrentUser',
              level: LogLevel.debug,
            );
            return isNotCurrentUser;
          })
          .map((player) {
            final firstName = player['name']?.toString() ?? '';
            final lastName = player['lastName']?.toString() ?? '';
            final fullName = '$firstName $lastName'.trim();
            final formatted = _toTitleCase(fullName);
            CustomLogger.logMessage(
              msg: '👥 Formatted name: "$fullName" -> "$formatted"',
              level: LogLevel.debug,
            );
            return formatted;
          })
          .where((name) => name.isNotEmpty)
          .toList();
      
      result.addAll(otherPlayers);
      CustomLogger.logMessage(
        msg: '👥 Using ${otherPlayers.length} other players for title: $otherPlayers (Total: ${result.length})',
        level: LogLevel.info,
      );
    } else {
      // Fallback: add other players after "You"
      final players = connectedPlayers.isNotEmpty 
          ? connectedPlayers 
          : playersFromMessages;
      result.addAll(players.take(3));
      CustomLogger.logMessage(
        msg: '👥 Using fallback players for title (allMatchPlayers is empty): $result',
        level: LogLevel.info,
      );
    }
    
    return result;
  }
  // Always treat userId as String so comparison with senderId works reliably.
  // Use a getter so that after logout/login the latest value from storage is used.
  String get userId => storage.read("userId")?.toString() ?? '';
  String get userTeam {
    final team = storage.read("userTeam") ?? 
                 storage.read("team") ?? 
                 Get.arguments?['userTeam'] ?? 
                 Get.arguments?['team'] ?? 
                 '';
    CustomLogger.logMessage(msg: 'DEBUG: userTeam = $team',level: LogLevel.debug);
    return _normalizeTeam(team);
  }
  var matchId = ''.obs;
  var matchCreatedAt = DateTime.now().obs;
  // If your backend uses different keys, adjust the mapping in
  // `_handleMessages` and `_handleNewMessage` accordingly.

  /// Convert a full name into title case.
  /// e.g. "sanjay bhandari" / "SANJAY BHANDARI" -> "Sanjay Bhandari"
  String _toTitleCase(String? value) {
    if (value == null) return '';
    final trimmed = value.trim();
    if (trimmed.isEmpty) return '';

    final parts = trimmed.split(RegExp(r'\s+'));
    final capitalized = parts.map((word) {
      if (word.isEmpty) return '';
      if (word.length == 1) return word.toUpperCase();
      return '${word[0].toUpperCase()}${word.substring(1).toLowerCase()}';
    }).where((w) => w.isNotEmpty).join(' ');

    return capitalized;
  }

  /// Normalize team code coming from backend (e.g. "teamA") into a
  /// user‑friendly label used by the UI (e.g. "Team A").
  String _normalizeTeam(dynamic rawTeam) {
    final value = rawTeam?.toString().trim();
    if (value == null || value.isEmpty) return '';

    final lower = value.toLowerCase();
    switch (lower) {
      case 'teama':
      case 'team a':
        return 'Team A';
      case 'teamb':
      case 'team b':
        return 'Team B';
      default:
        return value; // fallback to original
    }
  }

  /// Format any incoming timestamp to a time-only string like "2:00pm".
  /// - Accepts `DateTime`, ISO string, or raw string.
  /// - Falls back gracefully to the original value if parsing fails.
  String _formatTimestamp(dynamic raw) {
    try {
      DateTime? dt;

      if (raw is DateTime) {
        dt = raw;
      } else if (raw is String && raw.isNotEmpty) {
        // Try to parse ISO / standard datetime strings
        dt = DateTime.tryParse(raw);
      }

      if (dt == null) {
        // If we can't parse, just return the original string (or empty)
        return raw?.toString() ?? '';
      }

      // Convert to a 12-hour format like "2:05pm"
      final int hour = dt.hour;
      final int minute = dt.minute;
      final int hourOfPeriod =
          hour == 0 ? 12 : (hour > 12 ? hour - 12 : hour);
      final String minuteStr = minute.toString().padLeft(2, '0');
      final String period = hour >= 12 ? 'pm' : 'am';
      return '$hourOfPeriod:$minuteStr$period';
    } catch (_) {
      return raw?.toString() ?? '';
    }
  }

  /// Parse timestamp and return DateTime object for date grouping
  DateTime? _parseDateTime(dynamic raw) {
    try {
      if (raw is DateTime) {
        return raw;
      } else if (raw is String && raw.isNotEmpty) {
        return DateTime.tryParse(raw);
      }
      return null;
    } catch (_) {
      return null;
    }
  }

  /// Format date for chat headers like WhatsApp (Today, Yesterday, or date)
  String formatDateHeader(DateTime date) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final yesterday = today.subtract(const Duration(days: 1));
    final messageDate = DateTime(date.year, date.month, date.day);

    if (messageDate == today) {
      return 'Today';
    } else if (messageDate == yesterday) {
      return 'Yesterday';
    } else {
      return '${date.day}/${date.month}/${date.year.toString().substring(2)}';
    }
  }

  /// Get messages grouped by date
  List<Map<String, dynamic>> get groupedMessages {
    final grouped = <Map<String, dynamic>>[];
    
    if (messages.isEmpty) {
      // Add group creation message when no messages exist
      final creationDate = matchCreatedAt.value;
      grouped.add({
        'isDateHeader': true,
        'dateText': formatDateHeader(creationDate),
        'dateTime': creationDate,
      });
      grouped.add({
        'isGroupCreated': true,
        'message': 'Group created',
        'timestamp': _formatTimestamp(creationDate),
        'dateTime': creationDate,
        'isDateHeader': false,
      });
      return grouped;
    }
    
    String? lastDateStr;
    
    for (int i = 0; i < messages.length; i++) {
      final message = messages[i];
      final messageDate = message['dateTime'] as DateTime? ?? DateTime.now();
      final dateStr = formatDateHeader(messageDate);
      
      // Add date header if this is a new date
      if (lastDateStr != dateStr) {
        grouped.add({
          'isDateHeader': true,
          'dateText': dateStr,
          'dateTime': messageDate,
        });
        lastDateStr = dateStr;
      }
      
      // Add the actual message
      grouped.add({...message, 'isDateHeader': false});
    }
    
    return grouped;
  }

  /// Get current date header for scroll display
  String get currentDateHeader {
    return currentScrollDate.value.isNotEmpty 
        ? currentScrollDate.value 
        : formatDateHeader(DateTime.now());
  }

  @override
  void onInit() {
    super.onInit();
    final matchID = Get.arguments['matchID'];
    matchId.value = matchID;
    
    // Set match creation date from arguments or use current time
    final createdAt = Get.arguments['createdAt'];
    if (createdAt != null) {
      matchCreatedAt.value = _parseDateTime(createdAt) ?? DateTime.now();
    }
    
    // Try to load players from arguments first (if passed from open matches screen)
    _loadPlayersFromArguments();
    
    // Get all match players from DetailsController
    _loadAllMatchPlayers();
    
    // Load cached messages if available
    if (_messageCache.containsKey(matchID)) {
      messages.assignAll(_messageCache[matchID]!);
      // Auto-scroll to bottom after loading cached messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom();
      });
    }
    
    CustomLogger.logMessage(msg: "matchID-> ${matchId.value}",level: LogLevel.debug);
    CustomLogger.logMessage(msg: "UserID-> ${storage.read("userId")}",level: LogLevel.debug);
    CustomLogger.logMessage(msg: "UserTeam-> $userTeam",level: LogLevel.debug);
    CustomLogger.logMessage(msg: "Arguments-> ${Get.arguments}",level: LogLevel.debug);
    CustomLogger.logMessage(msg: "AllMatchPlayers-> ${allMatchPlayers.length} players",level: LogLevel.debug);
    _setupScrollListener();
    connectSocket();
  }

  @override
  void onReady() {
    super.onReady();
    isChatScreenActive.value = true;
    // Mark messages as read when the chat screen is fully loaded and visible
    Future.delayed(const Duration(milliseconds: 1500), () {
      if (isChatScreenActive.value) {
        markAllMessagesAsRead();
      }
    });
  }

  /// Mark all messages as read for this match
  void markAllMessagesAsRead() {
    if (!isChatScreenActive.value) {
      return;
    }
    if (socket.connected && matchId.value.isNotEmpty) {
      socket.emit('markMessageRead', {'matchId': matchId.value});
      CustomLogger.logMessage(
        msg: '📖 Marked all messages as read for match: ${matchId.value}',
        level: LogLevel.info,
      );
    }
  }

  void _setupScrollListener() {
    // This will be handled by NotificationListener in the UI
  }

  void onScrollStart() {
    showDateHeader.value = true;
    updateCurrentScrollDate();
  }

  void onScrollEnd() {
    Future.delayed(const Duration(seconds: 2), () {
      showDateHeader.value = false;
    });
  }

  void updateCurrentScrollDate() {
    if (!scrollController.hasClients || messages.isEmpty) return;
    
    // Find the message at current scroll position
    final scrollOffset = scrollController.offset;
    final itemHeight = 80.0; // Approximate message height
    final visibleIndex = (scrollOffset / itemHeight).floor();
    
    if (visibleIndex >= 0 && visibleIndex < messages.length) {
      final message = messages[visibleIndex];
      final messageDate = message['dateTime'] as DateTime? ?? DateTime.now();
      currentScrollDate.value = formatDateHeader(messageDate);
    }
  }

  void scrollToBottom() {
    if (scrollController.hasClients) {
      Future.delayed(const Duration(milliseconds: 100), () {
        if (scrollController.hasClients && scrollController.position.maxScrollExtent > 0) {
          scrollController.animateTo(
            scrollController.position.maxScrollExtent + 100,
            duration: const Duration(milliseconds: 300),
            curve: Curves.easeOut,
          );
        }
      });
    }
  }

  // /// Mark individual message as read
  // void markMessageAsRead(String messageId) {
  //   if (socket.connected && messageId.isNotEmpty) {
  //     socket.emit('markMessageRead', {'messageId': messageId});
  //   }
  // }

  void onTextFieldFocus() {
    if (scrollController.hasClients && scrollController.position.maxScrollExtent > 0) {
      final isAtBottom = scrollController.position.pixels >= 
          scrollController.position.maxScrollExtent - 50;
      if (isAtBottom) {
        Future.delayed(const Duration(milliseconds: 300), () {
          scrollToBottom();
        });
      }
    }
  }

  void connectSocket() {
    // Check if we need to create a new socket connection for a different user
    final currentUserId = userId;
    CustomLogger.logMessage(msg: "🔍 CHAT: connectSocket called with userId: $currentUserId", level: LogLevel.info);
    
    // Always create fresh socket connection to avoid stale authentication
    if (_sharedSocket != null) {
      final socketUserId = _sharedSocket!.auth?['userId']?.toString() ?? '';
      CustomLogger.logMessage(msg: "🔄 CHAT: Existing socket found for user: $socketUserId, current user: $currentUserId", level: LogLevel.info);
      
      if (socketUserId != currentUserId || !_sharedSocket!.connected) {
        CustomLogger.logMessage(msg: "🔌 CHAT: Disconnecting existing socket (different user or not connected)", level: LogLevel.info);
        _sharedSocket!.disconnect();
        _sharedSocket = null;
      } else {
        CustomLogger.logMessage(msg: "♻️ CHAT: Reusing existing socket for same user", level: LogLevel.info);
        isConnected.value = _sharedSocket!.connected;
        
        if (!_sharedSocket!.connected) {
          CustomLogger.logMessage(msg: "🔄 CHAT: Socket exists but not connected, reconnecting...", level: LogLevel.warning);
          _sharedSocket!.connect();
        }
        
        // Bind listeners FIRST before joining match to catch all events
        _bindSocketListeners();
        // Then join the match
        _sharedSocket!.emit('joinMatch', matchId.value);
        CustomLogger.logMessage(
            msg: '🚪 Joined match (reused socket): ${matchId.value}', level: LogLevel.info);
        _sharedSocket!.emit('getConnectedPlayers', {'matchId': matchId.value});
        getMatchPlayers();
        if (messages.isEmpty) {
          getMessages();
        }
        return;
      }
    }
    
    CustomLogger.logMessage(msg: "🆕 CHAT: Creating NEW socket connection for user: $currentUserId", level: LogLevel.info);
    _sharedSocket = IO.io(
      "${AppEndpoints.socketUrl}/match",
      IO.OptionBuilder()
          .setTransports(['websocket'])
          .disableAutoConnect()
          .enableForceNew() // Force new connection
          .setAuth({'userId': currentUserId})
          .build(),
    );
    CustomLogger.logMessage(msg: "🔗 CHAT: Socket created with auth userId: $currentUserId",level: LogLevel.info);
    
    // Bind listeners BEFORE connecting to ensure we catch all events
    _bindSocketListeners();
    
    _sharedSocket!.connect();

    // Log all incoming events to understand what the backend is sending
    _sharedSocket!.onAny((event, data) {
      CustomLogger.logMessage(
        msg: '🔔 Socket event: $event -> $data',
        level: LogLevel.info,
      );
    });

    _sharedSocket!.on('connect', (_) {
      CustomLogger.logMessage(
          msg: '✅ Socket connected successfully', level: LogLevel.info);
      isConnected.value = true;
      
      // Ensure listeners are bound (in case of reconnection)
      _bindSocketListeners();
      
      // Join the match once connected
      _sharedSocket!.emit('joinMatch', matchId.value);
      CustomLogger.logMessage(
          msg: '🚪 Joined match: ${matchId.value}', level: LogLevel.info);
      // Request connected players
      _sharedSocket!.emit('getConnectedPlayers', {'matchId': matchId.value});
      // Request all match players
      getMatchPlayers();
      // Only fetch messages if we don't have any yet
      if (messages.isEmpty) {
        CustomLogger.logMessage(
            msg: '📥 Fetching initial messages', level: LogLevel.info);
        getMessages();
      } else {
        CustomLogger.logMessage(
            msg: '✅ Already have ${messages.length} messages, relying on real-time updates', level: LogLevel.info);
      }
    });
    
    // Don't bind listeners here again - already bound before connect

    _sharedSocket!.on('disconnect', (reason) {
      CustomLogger.logMessage(
          msg: '❌ Socket disconnected: $reason', level: LogLevel.error);
      isConnected.value = false;
      // Auto-reconnect if not intentional disconnect
      if (reason != 'io client disconnect') {
        CustomLogger.logMessage(
            msg: '🔄 Attempting to reconnect...', level: LogLevel.info);
        Future.delayed(const Duration(seconds: 2), () {
          if (_sharedSocket != null && !_sharedSocket!.connected) {
            _sharedSocket!.connect();
          }
        });
      }
    });

    _sharedSocket!.on('connect_error', (error) {
      CustomLogger.logMessage(msg: '🔥 Connection error: $error',level: LogLevel.debug);
      isConnected.value = false;
    });

    _sharedSocket!.on('error', (error) {
      CustomLogger.logMessage(msg: '🔥 Socket error: $error',level: LogLevel.debug);
    });

  }

  /// Bind socket event listeners to this controller instance.
  /// We always `off` first to avoid handlers from an old controller
  /// instance consuming events when we reuse the shared socket.
  void _bindSocketListeners() {
    if (_sharedSocket == null) return;

    CustomLogger.logMessage(
      msg: '🔗 Binding socket listeners for match: ${matchId.value}',
      level: LogLevel.info,
    );

    // Remove previous bindings for these events to prevent duplicate handlers
    _sharedSocket!
      ..off('messagesReceived')
      ..off('newMessage')
      ..off('playersUpdate')
      ..off('matchPlayersReceived')
      ..off('playersReceived')
      ..off('allPlayersReceived')
      ..off('matchPlayers');

    // Handle initial list of messages for this match
    _sharedSocket!.on('messagesReceived', _handleMessages);

    // Handle new incoming single message (when someone sends a message)
    _sharedSocket!.on('newMessage', _handleNewMessage);

    // Handle connected players updates
    _sharedSocket!.on('playersUpdate', _handlePlayersUpdate);
    
    // Handle match players response - try multiple possible event names
    _sharedSocket!.on('matchPlayersReceived', _handleMatchPlayers);
    _sharedSocket!.on('playersReceived', _handleMatchPlayers);
    _sharedSocket!.on('allPlayersReceived', _handleMatchPlayers);
    _sharedSocket!.on('matchPlayers', _handleMatchPlayers);
    
    CustomLogger.logMessage(
      msg: '✅ Socket listeners bound successfully',
      level: LogLevel.info,
    );
  }

  void sendMessage() {
    if (messageController.text.trim().isEmpty) return;
    
    // Mark all messages as read when user sends a message
    markAllMessagesAsRead();
    print("Send Message -- ");
    socket.emit('sendMessage', {
      'matchId': matchId.value,
      'message': messageController.text.trim()
    });

    // Optionally append the message locally so it shows immediately.
    // You can remove this if your backend echoes the message back via `newMessage`.
    final now = DateTime.now();
    final newMessage = {
      'isMe': true,
      'message': messageController.text.trim(),
      'team': userTeam,
      'sender': 'You',
      'timestamp': _formatTimestamp(now),
      'dateTime': now,

    };
    
    messages.add(newMessage);
    // Update cache
    _messageCache[matchId.value] = List.from(messages);

    messageController.clear();
    
    // Only scroll if content exceeds screen
    WidgetsBinding.instance.addPostFrameCallback((_) {
      scrollToBottom();
    });
  }
  void getMessages() {
    if (!socket.connected) {
      CustomLogger.logMessage(
        msg: '⚠️ Cannot get messages - socket not connected',
        level: LogLevel.warning,
      );
      // Retry after connection
      Future.delayed(const Duration(milliseconds: 500), () {
        if (socket.connected) {
          getMessages();
        }
      });
      return;
    }
    
    socket.emit('getMessages', {
      'matchId': matchId.value,
    });

    // Just to confirm the request was fired
    CustomLogger.logMessage(
      msg: '📤 getMessages emitted for matchId=${matchId.value}',
      level: LogLevel.info,
    );
  }

  /// Load players from navigation arguments (if passed from open matches screen)
  void _loadPlayersFromArguments() {
    try {
      final args = Get.arguments;
      if (args is Map && (args['teamA'] != null || args['teamB'] != null)) {
        final allPlayers = <Map<String, dynamic>>[];
        
        // Load teamA players from arguments
        if (args['teamA'] is List) {
          final teamA = args['teamA'] as List;
          for (final player in teamA) {
            if (player is Map) {
              final playerMap = Map<String, dynamic>.from(player);
              final userId = playerMap['userId']?.toString() ?? '';
              final name = playerMap['name']?.toString() ?? '';
              final lastName = playerMap['lastName']?.toString() ?? '';
              
              // Only add if we have at least userId or name
              if (userId.isNotEmpty || name.isNotEmpty) {
                allPlayers.add({
                  '_id': userId,
                  'userId': userId,
                  'name': name,
                  'lastName': lastName,
                });
              }
            }
          }
        }
        
        // Load teamB players from arguments
        if (args['teamB'] is List) {
          final teamB = args['teamB'] as List;
          for (final player in teamB) {
            if (player is Map) {
              final playerMap = Map<String, dynamic>.from(player);
              final userId = playerMap['userId']?.toString() ?? '';
              final name = playerMap['name']?.toString() ?? '';
              final lastName = playerMap['lastName']?.toString() ?? '';
              
              // Only add if we have at least userId or name
              if (userId.isNotEmpty || name.isNotEmpty) {
                allPlayers.add({
                  '_id': userId,
                  'userId': userId,
                  'name': name,
                  'lastName': lastName,
                });
              }
            }
          }
        }
        
        if (allPlayers.isNotEmpty) {
          allMatchPlayers.assignAll(allPlayers);
          CustomLogger.logMessage(
            msg: '📥 Loaded ${allPlayers.length} players from arguments: ${allPlayers.map((p) => '${p['name']} ${p['lastName']}').join(', ')}',
            level: LogLevel.info,
          );
        } else {
          CustomLogger.logMessage(
            msg: '⚠️ No valid players found in arguments',
            level: LogLevel.warning,
          );
        }
      }
    } catch (e) {
      CustomLogger.logMessage(
        msg: '❌ Error loading players from arguments: $e',
        level: LogLevel.error,
      );
    }
  }

  /// Load all match players from DetailsController
  void _loadAllMatchPlayers() {
    // Only load from DetailsController if we don't already have players
    if (allMatchPlayers.isNotEmpty) {
      CustomLogger.logMessage(
        msg: '✅ Players already loaded, skipping DetailsController load',
        level: LogLevel.debug,
      );
      return;
    }
    
    try {
      // Try to get DetailsController if it exists
      if (Get.isRegistered<DetailsController>()) {
        final detailsController = Get.find<DetailsController>();
        final allPlayers = <Map<String, dynamic>>[];
        
        // Add all players from teamA
        for (final player in detailsController.teamA) {
          if (player.isNotEmpty && 
              (player['name']?.toString().isNotEmpty == true || 
               player['userId']?.toString().isNotEmpty == true)) {
            allPlayers.add({
              '_id': player['userId'] ?? player['_id'] ?? '',
              'userId': player['userId'] ?? player['_id'] ?? '',
              'name': player['name'] ?? '',
              'lastName': player['lastName'] ?? '',
            });
          }
        }
        
        // Add all players from teamB
        for (final player in detailsController.teamB) {
          if (player.isNotEmpty && 
              (player['name']?.toString().isNotEmpty == true || 
               player['userId']?.toString().isNotEmpty == true)) {
            allPlayers.add({
              '_id': player['userId'] ?? player['_id'] ?? '',
              'userId': player['userId'] ?? player['_id'] ?? '',
              'name': player['name'] ?? '',
              'lastName': player['lastName'] ?? '',
            });
          }
        }
        
        if (allPlayers.isNotEmpty) {
          allMatchPlayers.assignAll(allPlayers);
          CustomLogger.logMessage(
            msg: '📥 Loaded ${allPlayers.length} players from DetailsController: ${allPlayers.map((p) => '${p['name']} ${p['lastName']}').join(', ')}',
            level: LogLevel.info,
          );
        }
      } else {
        CustomLogger.logMessage(
          msg: '⚠️ DetailsController not found, will try to get players from backend or messages',
          level: LogLevel.warning,
        );
      }
    } catch (e) {
      CustomLogger.logMessage(
        msg: '❌ Error loading players from DetailsController: $e',
        level: LogLevel.error,
      );
    }
  }
  
  /// Request all players in this match from backend (fallback)
  void getMatchPlayers() {
    if (socket.connected && matchId.value.isNotEmpty) {
      // Try multiple possible event names that backend might use
      socket.emit('getMatchPlayers', {'matchId': matchId.value});
      socket.emit('getPlayers', {'matchId': matchId.value});
      socket.emit('getAllPlayers', {'matchId': matchId.value});
      CustomLogger.logMessage(
        msg: '📤 Match players requests emitted for matchId=${matchId.value}',
        level: LogLevel.info,
      );
    }
  }

  /// Map the list of messages received from the backend into the UI model.
  /// Adjust the keys below (`text`, `team`, `senderName`, `createdAt`, `userId`)
  /// to match your actual API / socket payload.
  void _handleMessages(dynamic data) {
    try {
      CustomLogger.logMessage(
        msg: '📨 _handleMessages raw payload (${data.runtimeType}): $data',
        level: LogLevel.info,
      );

      // Support multiple possible payload shapes:
      // 1) data is already a List
      // 2) { "messages": [...] }
      // 3) { "data": [...] }
      // 4) anything else -> just log and return
      List<dynamic> rawList;
      if (data is List) {
        rawList = data;
      } else if (data is Map && data['messages'] is List) {
        rawList = data['messages'] as List;
      } else if (data is Map && data['data'] is List) {
        rawList = data['data'] as List;
      } else {
        CustomLogger.logMessage(
          msg: '⚠️ _handleMessages received unsupported format: $data',
          level: LogLevel.error,
        );

        return;
      }

      final mapped = rawList.map<Map<String, dynamic>>((m) {
        final map = Map<String, dynamic>.from(m as Map);

        // Sender can be:
        // - a plain id:  senderId: "abc"
        // - an object:   senderId: { _id: "...", name: "...", lastName: "..." }
        final dynamic senderField =
            map['senderId'] ?? map['userId'] ?? map['senderid'];
        String senderId;
        if (senderField is Map && senderField['_id'] != null) {
          senderId = senderField['_id'].toString();
        } else {
          senderId = (senderField ?? '').toString();
        }

        final String senderNameFromObject = senderField is Map
            ? [
                senderField['name']?.toString() ?? '',
                senderField['lastName']?.toString() ?? ''
              ].where((e) => e.isNotEmpty).join(' ')
            : '';

        final rawSenderName = map['senderName'] ??
            senderNameFromObject ??
            map['playerName'] ??
            'Player';

        final rawTimestamp = map['createdAt'] ?? map['time'] ?? '';
        final dateTime = _parseDateTime(rawTimestamp) ?? DateTime.now();
        
        final messageId = map['_id'] ?? map['id'];
        


        return {
          'isMe': senderId == userId,
          // Backend example uses `message` for text
          'message': map['message'] ?? map['text'] ?? '',
          // Normalize backend team code into UI label (e.g. "teamA" -> "Team A")
          'team': _normalizeTeam(map['senderTeam'] ?? map['team'] ?? ''),
          // Prefer explicit senderName, then build from senderId object, then fallback
          'sender': _toTitleCase(rawSenderName),
          // Preserve senderId for player extraction
          'senderId': senderId,
          // Backend example uses `createdAt` – format to time-only
          'timestamp': _formatTimestamp(rawTimestamp),
          'dateTime': dateTime,
          'messageId': messageId,

        };
      }).toList();

      // Load messages and update cache
      messages.assignAll(mapped);
      _messageCache[matchId.value] = List.from(mapped);

      
      // Update connected players from messages if backend doesn't provide them
      if (connectedPlayers.isEmpty) {
        connectedPlayers.assignAll(playersFromMessages);
      }
      
      // If we still don't have match players, try to extract from messages
      if (allMatchPlayers.isEmpty && messages.isNotEmpty) {
        final uniquePlayerIds = <String>{};
        final playersFromMsgs = <Map<String, dynamic>>[];
        final currentUserId = userId;
        
        for (final message in messages) {
          final senderId = message['senderId']?.toString() ?? message['userId']?.toString();
          final senderName = message['sender']?.toString() ?? '';
          
          // Skip if no senderId, if it's the current user, or if we already added this player
          if (senderId == null || senderId.isEmpty || senderId == currentUserId || uniquePlayerIds.contains(senderId)) {
            continue;
          }
          
          uniquePlayerIds.add(senderId);
          final nameParts = senderName.trim().split(' ');
          final firstName = nameParts.isNotEmpty ? nameParts.first : 'Player';
          final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
          
          if (firstName.isNotEmpty && firstName != 'Player') {
            playersFromMsgs.add({
              '_id': senderId,
              'userId': senderId,
              'name': firstName,
              'lastName': lastName,
            });
          }
        }
        
        if (playersFromMsgs.isNotEmpty) {
          allMatchPlayers.assignAll(playersFromMsgs);
          CustomLogger.logMessage(
            msg: '📥 Extracted ${playersFromMsgs.length} players from messages: ${playersFromMsgs.map((p) => '${p['name']} ${p['lastName']}').join(', ')}',
            level: LogLevel.info,
          );
        } else {
          CustomLogger.logMessage(
            msg: '⚠️ No players extracted from messages. Total messages: ${messages.length}, Current userId: $currentUserId',
            level: LogLevel.warning,
          );
        }
      }
      
      // Auto-scroll to bottom after loading messages
      WidgetsBinding.instance.addPostFrameCallback((_) {
        scrollToBottom();
      });

      // PRINT / LOG ALL MESSAGES AFTER MAPPING
      CustomLogger.logMessage(
        msg: '✅ Mapped messages (${messages.length}): $messages',
        level: LogLevel.info,
      );
    } catch (e) {
      CustomLogger.logMessage(
        msg: '❌ Error parsing messages: $e',
        level: LogLevel.error,
      );

    }
  }

  /// Handle a single new message pushed from the backend.
  void _handleNewMessage(dynamic data) {
    try {
      CustomLogger.logMessage(
        msg: '🆕 _handleNewMessage received: $data',
        level: LogLevel.info,
      );
      
      final map = Map<String, dynamic>.from(
          data is Map ? data : (data['message'] as Map));
      // Handle both flat and nested senderId (same as in _handleMessages)
      final dynamic senderField =
          map['senderId'] ?? map['userId'] ?? map['senderid'] ?? map['fromUserId'];
      String senderId;
      if (senderField is Map && senderField['_id'] != null) {
        senderId = senderField['_id'].toString();
      } else {
        senderId = (senderField ?? '').toString();
      }

      final String senderNameFromObject = senderField is Map
          ? [
              senderField['name']?.toString() ?? '',
              senderField['lastName']?.toString() ?? ''
            ].where((e) => e.isNotEmpty).join(' ')
          : '';

      // If this is **our** own message coming back from the server,
      // we already added it optimistically in `sendMessage()`.
      // Skip adding again to avoid showing the same text on both sides.
      if (senderId == userId) {
        CustomLogger.logMessage(
          msg: '⏭️ Skipping own message from server (already added locally)',
          level: LogLevel.info,
        );
        return;
      }

      final rawSenderName = map['senderName'] ??
          senderNameFromObject ??
          map['playerName'] ??
          'Player';

      final senderName = _toTitleCase(rawSenderName);

      final rawTimestamp = map['createdAt'] ?? map['time'] ?? '';
      final dateTime = _parseDateTime(rawTimestamp) ?? DateTime.now();
      final messageId = map['_id'] ?? map['id'];



      final newMessage = {
        'isMe': senderId == userId,
        'message': map['message'] ?? map['text'] ?? '',
        'team': _normalizeTeam(map['senderTeam'] ?? map['team'] ?? ''),
        'sender': senderName,
        'senderId': senderId,
        'timestamp': _formatTimestamp(rawTimestamp),
        'dateTime': dateTime,
        'messageId': messageId,
      };
      
      CustomLogger.logMessage(
        msg: '✅ Adding new message from ${senderName}: ${newMessage['message']}',
        level: LogLevel.info,
      );
      
      messages.add(newMessage);
      messages.refresh();
      // Update cache
      _messageCache[matchId.value] = List.from(messages);
      
      // Add new player to title if not already present
      if (senderName.isNotEmpty && !connectedPlayers.contains(senderName)) {
        connectedPlayers.add(senderName);
      }
      
      // Also add to allMatchPlayers if not already present
      final existingPlayerIndex = allMatchPlayers.indexWhere((p) => 
        (p['userId']?.toString() ?? p['_id']?.toString()) == senderId
      );
      
      if (existingPlayerIndex == -1 && senderId.isNotEmpty && senderId != userId) {
        final nameParts = senderName.split(' ');
        final firstName = nameParts.isNotEmpty ? nameParts.first : 'Player';
        final lastName = nameParts.length > 1 ? nameParts.skip(1).join(' ') : '';
        
        allMatchPlayers.add({
          '_id': senderId,
          'userId': senderId,
          'name': firstName,
          'lastName': lastName,
        });
        CustomLogger.logMessage(
          msg: '📥 Added new player to allMatchPlayers from message: $firstName $lastName',
          level: LogLevel.info,
        );
      }
      
      // Mark new message as read after a delay
      Future.delayed(const Duration(seconds: 1), () {
        if (isChatScreenActive.value) {
          markAllMessagesAsRead();
        }
      });
      
      // Only scroll to bottom if user is already near bottom
      WidgetsBinding.instance.addPostFrameCallback((_) {
        if (scrollController.hasClients) {
          final isNearBottom = scrollController.position.pixels >= 
              scrollController.position.maxScrollExtent - 100;
          if (isNearBottom) {
            scrollToBottom();
          }
        }
      });
    } catch (e) {
      CustomLogger.logMessage(
        msg: '❌ Error parsing newMessage: $e',
        level: LogLevel.error,
      );
    }
  }

  /// Handle players update from backend
  void _handlePlayersUpdate(dynamic data) {
    try {
      CustomLogger.logMessage(
        msg: '📥 Received playersUpdate: $data',
        level: LogLevel.info,
      );
      
      if (data is Map && data['players'] is List) {
        final players = (data['players'] as List)
            .map((p) => _toTitleCase(p['name']?.toString() ?? 'Player'))
            .toList();
        connectedPlayers.assignAll(players);
      } else if (data is List) {
        final players = data
            .map((p) => _toTitleCase(p['name']?.toString() ?? 'Player'))
            .toList();
        connectedPlayers.assignAll(players);
      }
    } catch (e) {
      CustomLogger.logMessage(
        msg: '❌ Error parsing players update: $e',
        level: LogLevel.error,
      );
    }
  }

  /// Handle match players response from backend
  void _handleMatchPlayers(dynamic data) {
    try {
      CustomLogger.logMessage(
        msg: '📥 Received match players data: $data',
        level: LogLevel.info,
      );
      
      List<dynamic> playersList = [];
      
      if (data is Map) {
        if (data['players'] is List) {
          playersList = data['players'] as List;
        } else if (data['data'] is List) {
          playersList = data['data'] as List;
        } else if (data['users'] is List) {
          playersList = data['users'] as List;
        } else if (data['teamA'] is List || data['teamB'] is List) {
          // Handle team-based structure
          final teamA = (data['teamA'] as List?) ?? [];
          final teamB = (data['teamB'] as List?) ?? [];
          playersList = [...teamA, ...teamB];
        }
      } else if (data is List) {
        playersList = data;
      }
      
      if (playersList.isEmpty) {
        CustomLogger.logMessage(
          msg: '⚠️ No players found in response: $data',
          level: LogLevel.warning,
        );
        return;
      }
      
      final players = playersList.map((p) {
        final playerMap = Map<String, dynamic>.from(p as Map);
        
        // Handle different possible structures
        // Structure 1: Direct fields
        if (playerMap.containsKey('name')) {
          return {
            '_id': playerMap['_id'] ?? playerMap['userId'] ?? playerMap['sId'] ?? '',
            'userId': playerMap['userId'] ?? playerMap['_id'] ?? playerMap['sId'] ?? '',
            'name': playerMap['name'] ?? '',
            'lastName': playerMap['lastName'] ?? '',
          };
        }
        
        // Structure 2: Nested userId object
        if (playerMap.containsKey('userId') && playerMap['userId'] is Map) {
          final userIdObj = playerMap['userId'] as Map;
          return {
            '_id': userIdObj['_id'] ?? userIdObj['sId'] ?? playerMap['_id'] ?? '',
            'userId': userIdObj['_id'] ?? userIdObj['sId'] ?? playerMap['_id'] ?? '',
            'name': userIdObj['name'] ?? '',
            'lastName': userIdObj['lastName'] ?? '',
          };
        }
        
        // Fallback
        return {
          '_id': playerMap['_id'] ?? playerMap['userId'] ?? playerMap['sId'] ?? '',
          'userId': playerMap['userId'] ?? playerMap['_id'] ?? playerMap['sId'] ?? '',
          'name': playerMap['name'] ?? '',
          'lastName': playerMap['lastName'] ?? '',
        };
      }).where((p) => 
        p['_id'] != null && p['_id'].toString().isNotEmpty &&
        (p['name'] != null && p['name'].toString().isNotEmpty || 
         p['lastName'] != null && p['lastName'].toString().isNotEmpty)
      ).toList();
      
      if (players.isNotEmpty) {
        allMatchPlayers.assignAll(players);
        CustomLogger.logMessage(
          msg: '✅ Updated allMatchPlayers: ${allMatchPlayers.length} players - ${players.map((p) => '${p['name']} ${p['lastName']}').join(', ')}',
          level: LogLevel.info,
        );
      } else {
        CustomLogger.logMessage(
          msg: '⚠️ No valid players parsed from response',
          level: LogLevel.warning,
        );
      }
    } catch (e) {
      CustomLogger.logMessage(
        msg: '❌ Error parsing match players: $e',
        level: LogLevel.error,
      );
    }
  }

  void onChatScreenClosed() {
    isChatScreenActive.value = false;
    CustomLogger.logMessage(
      msg: '🚪 Chat screen closed, stopping message read marking',
      level: LogLevel.info,
    );
    // Leave the match when chat screen closes
    if (_sharedSocket != null && _sharedSocket!.connected && matchId.value.isNotEmpty) {
      _sharedSocket!.emit('leaveMatch', matchId.value);
      CustomLogger.logMessage(
        msg: '📝 Left match ${matchId.value} when chat screen closed',
        level: LogLevel.info,
      );
    }
  }

  @override
  void onClose() {
    isChatScreenActive.value = false;
    
    // Leave the match when controller is disposed
    if (_sharedSocket != null && _sharedSocket!.connected && matchId.value.isNotEmpty) {
      _sharedSocket!.emit('leaveMatch', matchId.value);
      CustomLogger.logMessage(
        msg: '📝 Left match ${matchId.value} when chat controller closed',
        level: LogLevel.info,
      );
    }
    
    // messageController.dispose();
    scrollController.dispose();
    super.onClose();
  }
}