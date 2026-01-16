import 'package:padel_mobile/data/request_models/score_board_models/add_guest_player_model.dart';
import 'package:padel_mobile/data/request_models/score_board_models/convert_match_to_open_match_model.dart';
import 'package:padel_mobile/data/request_models/score_board_models/push_open_match_into_score_board_model.dart';
import 'package:padel_mobile/data/request_models/score_board_models/scoreboard_model.dart';
import 'package:padel_mobile/data/request_models/score_board_models/update_booking_model.dart';
import 'package:padel_mobile/data/request_models/score_board_models/update_scoreboard_model.dart';
import 'package:padel_mobile/data/response_models/score_board_models/get_score_board_model.dart';

import '../../core/endpoitns.dart';
import '../../core/network/dio_client.dart';
import '../../handler/logger.dart';
class ScoreBoardRepository {
  static final ScoreBoardRepository _instance = ScoreBoardRepository._internal();
  final DioClient dioClient = DioClient();

  factory ScoreBoardRepository() {
    return _instance;
  }

  ScoreBoardRepository._internal();

  /// Create Score Board--------------------------------------------------------
  Future<CreateScoreBoardModel> createScoreBoard({
    required dynamic data,
  }) async {
    CustomLogger.logMessage(
      msg: "Create Score Board Body-> $data",
      level: LogLevel.info,
    );
    try {
      final response = await dioClient.post(
        AppEndpoints.createScoreBoard,
        data: data,
      );
      if (response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "created ScoreBoard successfully: ${response.data}",
          level: LogLevel.info,
        );

        return CreateScoreBoardModel.fromJson(response.data);
      } else {
        throw Exception("created ScoreBoard failed. Status code: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "created ScoreBoard failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }


  /// Update Score Board--------------------------------------------------------
  Future<UpdateScoreBoardModel> updateScoreBoard({
    required dynamic data,
    String? type

  }) async {
    CustomLogger.logMessage(
      msg: "Update Score Board Body-> $data",
      level: LogLevel.info,
    );
    try {
        final removeSet = (type != null && type.isNotEmpty) ? "?type=$type" : "";
        final response = await dioClient.put(
        "${AppEndpoints.updateScoreBoard}$removeSet",
        data: data,
      );
        if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Update ScoreBoard successfully: ${response.data}",
          level: LogLevel.info,
        );

        return UpdateScoreBoardModel.fromJson(response.data);
      } else {
        throw Exception("Update ScoreBoard failed. Status code: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Update ScoreBoard failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  ///Get Score Board------------------------------------------------------------
  Future<GetScoreBoardModel> getScoreBoard({required String bookingId}) async {
    try {
      final response = await dioClient.get(
        "${AppEndpoints.getScoreBoard}/$bookingId",
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        // Log the raw JSON to see what we're actually getting
        CustomLogger.logMessage(
          msg: "=== RAW API RESPONSE ===",
          level: LogLevel.info,
        );

        if (response.data['data'] != null && (response.data['data'] as List).isNotEmpty) {
          final firstItem = (response.data['data'] as List)[0];
          CustomLogger.logMessage(
            msg: "First scoreboard ID: ${firstItem['_id']}",
            level: LogLevel.info,
          );
          CustomLogger.logMessage(
            msg: "Teams array length: ${(firstItem['teams'] as List?)?.length ?? 0}",
            level: LogLevel.info,
          );

          if (firstItem['teams'] != null) {
            final teamsArray = firstItem['teams'] as List;
            for (int i = 0; i < teamsArray.length; i++) {
              CustomLogger.logMessage(
                msg: "Team $i: ${teamsArray[i]['name']}, players: ${(teamsArray[i]['players'] as List?)?.length ?? 0}",
                level: LogLevel.info,
              );
            }
          }
        }

        return GetScoreBoardModel.fromJson(response.data);
      } else {
        throw Exception("Get-Score-Board failed: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Get-Score-Board failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  //Add Guest Player------------------------------------------------------------
  Future<AddGuestPlayerModel?> addGuestPlayer({
    required Map<String, dynamic> body,
  }) async {
    try {
      CustomLogger.logMessage(
        msg: "Add Guest Player Request Body: $body",
        level: LogLevel.info,
      );

      final response = await dioClient.put(
        AppEndpoints.updateScoreBoard,
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Add Guest Player Success: ${response.data}",
          level: LogLevel.info,
        );
        return AddGuestPlayerModel.fromJson(response.data);
      } else {
        throw Exception("Add Guest Player Failed with status code: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Add Guest Player failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  //Booking Update---------------------------------------------------------------
  Future<UpdateBookingModel?> updateBooking({
    required Map<String, dynamic> body,
  }) async {
    try {
      CustomLogger.logMessage(
        msg: "Booking Update Request Body: $body",
        level: LogLevel.info,
      );

      final response = await dioClient.post(
        AppEndpoints.bookingUpdate,
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Booking Update Success: ${response.data}",
          level: LogLevel.info,
        );
        return UpdateBookingModel.fromJson(response.data);
      } else {
        throw Exception("Booking Update Failed with status code: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Booking Update failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  //Convert Match To Open Match-------------------------------------------------
  Future<ConvertMatchToOpenMatchModel?> convertBookingToOpenMatch({
    required Map<String, dynamic> body,
  }) async {
    try {
      CustomLogger.logMessage(
        msg: "Convert Match To Open Match Request Body: $body",
        level: LogLevel.info,
      );

      final response = await dioClient.post(
        AppEndpoints.convertBookingToOpenMatch,
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Convert Match To Open Match Success: ${response.data}",
          level: LogLevel.info,
        );
        return ConvertMatchToOpenMatchModel.fromJson(response.data);
      } else {
        throw Exception("Convert Match To Open Match Failed with status code: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Convert Match To Open Match failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  //Push open match into scoreboard-------------------------------------------------
  Future<PushOpenMatchInScoreBoardModel?> pushOpenMatchIntoScoreboard({
    required Map<String, dynamic> body,
  }) async {
    try {
      CustomLogger.logMessage(
        msg: "Push open match into scoreboard Request Body: $body",
        level: LogLevel.info,
      );

      final response = await dioClient.put(
        AppEndpoints.pushOpenMatchIdInScoreCard,
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Push open match into scoreboard Success: ${response.data}",
          level: LogLevel.info,
        );
        return PushOpenMatchInScoreBoardModel.fromJson(response.data);
      } else {
        throw Exception("Push open match into scoreboard Failed with status code: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Push open match into scoreboard failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  //Remove Player from Match----------------------------------------------------
  Future<UpdateScoreBoardModel?> removePlayerFromMatch({
    required Map<String, dynamic> body,
  }) async {
    try {
      CustomLogger.logMessage(
        msg: "Remove Player Request Body: $body",
        level: LogLevel.info,
      );

      final response = await dioClient.put(
        AppEndpoints.removePlayer,
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Remove Player Success: ${response.data}",
          level: LogLevel.info,
        );
        return UpdateScoreBoardModel.fromJson(response.data);
      } else {
        throw Exception("Remove Player Failed with status code: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Remove Player failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

}