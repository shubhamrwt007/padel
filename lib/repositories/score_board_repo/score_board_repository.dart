import 'package:padel_mobile/data/request_models/score_board_models/add_guest_player_model.dart';

import 'package:padel_mobile/data/request_models/score_board_models/convert_match_to_open_match_model.dart';

import 'package:padel_mobile/data/request_models/score_board_models/push_open_match_into_score_board_model.dart';

import 'package:padel_mobile/data/request_models/score_board_models/scoreboard_model.dart';

import 'package:padel_mobile/data/request_models/score_board_models/update_booking_model.dart';

import 'package:padel_mobile/data/request_models/score_board_models/update_scoreboard_model.dart';

import 'package:padel_mobile/data/response_models/score_board_models/get_score_board_model.dart';

import 'package:socket_io_client/socket_io_client.dart' as IO;

import 'package:get_storage/get_storage.dart';

import '../../core/endpoitns.dart';

import '../../core/network/dio_client.dart';

import '../../handler/logger.dart';

class ScoreBoardRepository {

  static final ScoreBoardRepository _instance = ScoreBoardRepository._internal();

  final DioClient dioClient = DioClient();

  static IO.Socket? _socket;

  final storage = GetStorage();

  factory ScoreBoardRepository() {

    return _instance;

  }

  ScoreBoardRepository._internal();

  /// Create Score Board

  Future<CreateScoreBoardModel> createScoreBoard({required dynamic data}) async {

    CustomLogger.logMessage(msg: "Create Score Board Body-> $data", level: LogLevel.info);

    try {

      final response = await dioClient.post(AppEndpoints.createScoreBoard, data: data);

      if (response.statusCode == 201) {

        return CreateScoreBoardModel.fromJson(response.data);

      } else {

        throw Exception("created ScoreBoard failed. Status code: ${response.statusCode}");

      }

    } catch (e, st) {

      CustomLogger.logMessage(msg: "created ScoreBoard failed: ${e.toString()}", level: LogLevel.error, st: st);

      rethrow;

    }

  }

  /// Update Score Board

  Future<UpdateScoreBoardModel> updateScoreBoard({required dynamic data, String? type}) async {

    CustomLogger.logMessage(msg: "Update Score Board Body-> $data", level: LogLevel.info);

    try {

      final removeSet = (type != null && type.isNotEmpty) ? "?type=$type" : "";

      final response = await dioClient.put("${AppEndpoints.updateScoreBoard}$removeSet", data: data);

      if (response.statusCode == 200 || response.statusCode == 201) {

        return UpdateScoreBoardModel.fromJson(response.data);

      } else {

        throw Exception("Update ScoreBoard failed. Status code: ${response.statusCode}");

      }

    } catch (e, st) {

      CustomLogger.logMessage(msg: "Update ScoreBoard failed: ${e.toString()}", level: LogLevel.error, st: st);

      rethrow;

    }

  }

  /// Get Score Board

  Future<GetScoreBoardModel> getScoreBoard({required String bookingId}) async {

    try {

      final response = await dioClient.get("${AppEndpoints.getScoreBoard}/$bookingId");

      if (response.statusCode == 200 || response.statusCode == 201) {

        return GetScoreBoardModel.fromJson(response.data);

      } else {

        throw Exception("Get-Score-Board failed: ${response.statusCode}");

      }

    } catch (e, st) {

      CustomLogger.logMessage(msg: "Get-Score-Board failed: ${e.toString()}", level: LogLevel.error, st: st);

      rethrow;

    }

  }

  /// Add Guest Player

  Future<AddGuestPlayerModel?> addGuestPlayer({required Map<String, dynamic> body}) async {

    try {

      final response = await dioClient.put(AppEndpoints.updateScoreBoard, data: body);

      if (response.statusCode == 200 || response.statusCode == 201) {

        return AddGuestPlayerModel.fromJson(response.data);

      } else {

        throw Exception("Add Guest Player Failed: ${response.statusCode}");

      }

    } catch (e, st) {

      CustomLogger.logMessage(msg: "Add Guest Player failed: ${e.toString()}", level: LogLevel.error, st: st);

      rethrow;

    }

  }

  /// Update Booking

  Future<UpdateBookingModel?> updateBooking({required Map<String, dynamic> body}) async {

    try {

      final response = await dioClient.post(AppEndpoints.bookingUpdate, data: body);

      if (response.statusCode == 200 || response.statusCode == 201) {

        return UpdateBookingModel.fromJson(response.data);

      } else {

        throw Exception("Booking Update Failed: ${response.statusCode}");

      }

    } catch (e, st) {

      CustomLogger.logMessage(msg: "Booking Update failed: ${e.toString()}", level: LogLevel.error, st: st);

      rethrow;

    }

  }

  /// Convert Match To Open Match

  Future<ConvertMatchToOpenMatchModel?> convertBookingToOpenMatch({required Map<String, dynamic> body}) async {

    try {

      final response = await dioClient.post(AppEndpoints.convertBookingToOpenMatch, data: body);

      if (response.statusCode == 200 || response.statusCode == 201) {

        return ConvertMatchToOpenMatchModel.fromJson(response.data);

      } else {

        throw Exception("Convert Match Failed: ${response.statusCode}");

      }

    } catch (e, st) {

      CustomLogger.logMessage(msg: "Convert Match failed: ${e.toString()}", level: LogLevel.error, st: st);

      rethrow;

    }

  }

  /// Push Open Match Into Scoreboard

  Future<PushOpenMatchInScoreBoardModel?> pushOpenMatchIntoScoreboard({required Map<String, dynamic> body}) async {

    try {

      final response = await dioClient.put(AppEndpoints.pushOpenMatchIdInScoreCard, data: body);

      if (response.statusCode == 200 || response.statusCode == 201) {

        return PushOpenMatchInScoreBoardModel.fromJson(response.data);

      } else {

        throw Exception("Push open match failed: ${response.statusCode}");

      }

    } catch (e, st) {

      CustomLogger.logMessage(msg: "Push open match failed: ${e.toString()}", level: LogLevel.error, st: st);

      rethrow;

    }

  }

  /// Remove Player From Match

  Future<UpdateScoreBoardModel?> removePlayerFromMatch({required Map<String, dynamic> body}) async {

    try {

      final response = await dioClient.put(AppEndpoints.removePlayer, data: body);

      if (response.statusCode == 200 || response.statusCode == 201) {

        return UpdateScoreBoardModel.fromJson(response.data);

      } else {

        throw Exception("Remove Player Failed: ${response.statusCode}");

      }

    } catch (e, st) {

      CustomLogger.logMessage(msg: "Remove Player failed: ${e.toString()}", level: LogLevel.error, st: st);

      rethrow;

    }

  }

  /// Update Teams

  Future<UpdateScoreBoardModel?> updateTeams({required Map<String, dynamic> body}) async {

    try {

      final response = await dioClient.put(AppEndpoints.updateScoreBoard, data: body);

      if (response.statusCode == 200 || response.statusCode == 201) {

        return UpdateScoreBoardModel.fromJson(response.data);

      } else {

        throw Exception("Update Teams Failed: ${response.statusCode}");

      }

    } catch (e, st) {

      CustomLogger.logMessage(msg: "Update Teams failed: ${e.toString()}", level: LogLevel.error, st: st);

      rethrow;

    }

  }

  // ===================== SOCKET METHODS =====================

  void _connectSocket() {

    if (_socket != null && _socket!.connected) {

      print('✅ SOCKET: Already connected');

      return;

    }

    print('🔌 SOCKET: Connecting to ${AppEndpoints.socketUrl}');

    final userId = storage.read('userId')?.toString() ?? '';

    _socket = IO.io(

      AppEndpoints.socketUrl,

      IO.OptionBuilder()

          .setTransports(['websocket'])

          .disableAutoConnect()

          .setAuth({'userId': userId})

          .build(),

    );

    _socket!.onConnect((_) {

      print('✅ SOCKET: Connected! ID: ${_socket?.id}');

    });

    _socket!.onDisconnect((_) {

      print('❌ SOCKET: Disconnected');

    });

    _socket!.onError((error) {

      print('❌ SOCKET ERROR: $error');

    });

    _socket!.onAny((event, data) {

      print('🔔 SOCKET ANY EVENT: $event -> $data');

    });

    _socket!.connect();

  }

  void joinScoreboard(String scoreboardId) {

    _connectSocket();

    print('🔵 SOCKET: Joining scoreboard: $scoreboardId');

    if (_socket!.connected) {

      _socket?.emit('joinScoreboard', {'scoreboardId': scoreboardId});

      print('✅ SOCKET: joinScoreboard emitted immediately');

    } else {

      _socket?.onConnect((_) {

        _socket?.emit('joinScoreboard', {'scoreboardId': scoreboardId});

        print('✅ SOCKET: joinScoreboard emitted after connect');

      });

    }

  }

  void leaveScoreboard(String scoreboardId) {

    _socket?.emit('leaveScoreboard', {'scoreboardId': scoreboardId});

    print('🚪 SOCKET: Left scoreboard: $scoreboardId');

  }

  void onScoreboardUpdate(Function(dynamic) callback) {

    _socket?.off('scoreboardUpdate');

    _socket?.on('scoreboardUpdate', (data) {

      print('🔔 SOCKET: scoreboardUpdate received: $data');

      callback(data);

    });

  }

  void onMatchCompleted(Function(dynamic) callback) {

    _socket?.off('matchCompleted');

    _socket?.on('matchCompleted', (data) {

      print('🏆 SOCKET: matchCompleted received: $data');

      callback(data);

    });

  }

  void onSwapPlayer(Function(dynamic) callback) {

    _socket?.off('swapPlayer');

    _socket?.on('swapPlayer', (data) {

      print('🔄 SOCKET: swapPlayer received: $data');

      if (data != null && data is Map) {

        print('🔄 swapWinner: ${data['swapWinner']}');

        print('🔄 totalScore: ${data['totalScore']}');

        print('🔄 xpChanges: ${data['xpChanges']}');

        print('🔄 teams: ${data['teams']}');

      }

      callback(data);

    });

  }

  void onScoreboardSwapped(Function(dynamic) callback) {

    _socket?.off('scoreboardSwapped');

    _socket?.on('scoreboardSwapped', (data) {

      print('🔄 SOCKET: scoreboardSwapped received: $data');

      callback(data);

    });

  }

  void onTeamShuffleResult(Function(dynamic) callback) {

    _socket?.off('teamShuffleResult');

    _socket?.on('teamShuffleResult', (data) {

      print('🏆 SOCKET: teamShuffleResult received: $data');

      callback(data);

    });

  }

  void emitScoreboardSwapped(Map<String, dynamic> data) {

    _socket?.emit('scoreboardSwapped', data);

    print('📤 SOCKET: scoreboardSwapped emitted: $data');

  }

  void emitSwapPlayer(Map<String, dynamic> data) {

    if (_socket == null || !_socket!.connected) {

      print('❌ SOCKET: Cannot emit swapPlayer - not connected');

      return;

    }

    _socket?.emit('swapPlayer', data);

    print('📤 SOCKET: swapPlayer emitted: $data');

  }

  void emitTeamShuffleResult(Map<String, dynamic> data) {

    if (_socket == null || !_socket!.connected) {

      print('❌ SOCKET: Cannot emit teamShuffleResult - not connected');

      return;

    }

    _socket?.emit('teamShuffleResult', data);

    print('📤 SOCKET: teamShuffleResult emitted: $data');

  }

  void emitMatchCompleted(Map<String, dynamic> data) {

    if (_socket == null || !_socket!.connected) {

      print('❌ SOCKET: Cannot emit matchCompleted - not connected');

      return;

    }

    _socket?.emit('matchCompleted', data);

    print('📤 SOCKET: matchCompleted emitted: $data');

  }

}

