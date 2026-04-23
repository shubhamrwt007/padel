import 'package:padel_mobile/core/endpoitns.dart';
import 'package:padel_mobile/core/network/dio_client.dart';
import 'package:padel_mobile/data/request_models/league/cast_league_vote_model.dart';
import 'package:padel_mobile/data/response_models/ipt_tournament/get_all_schedule_live_matches_ipt_tournament_model.dart';
import 'package:padel_mobile/data/response_models/ipt_tournament/get_ipt_tournament__url_model.dart';
import 'package:padel_mobile/data/response_models/ipt_tournament/get_ipt_tournament_leader_board_model.dart';
import 'package:padel_mobile/data/response_models/ipt_tournament/get_ipt_tournament_list_model.dart';
import 'package:padel_mobile/data/response_models/ipt_tournament/get_ipt_tournament_match_details_model.dart';
import 'package:padel_mobile/data/response_models/ipt_tournament/get_ipt_tournament_poll_results_model.dart';
import 'package:padel_mobile/data/response_models/ipt_tournament/get_ipt_tournament_sponsors_model.dart';
import 'package:padel_mobile/data/response_models/ipt_tournament/get_schedule_dates_ipt_tournament_model.dart';
import 'package:padel_mobile/data/response_models/league/get_all_schedule_live_matches_model.dart';
import 'package:padel_mobile/data/response_models/league/get_all_schedule_upcoming_matches_model.dart';
import 'package:padel_mobile/data/response_models/league/get_league_leader_board_model.dart';
import 'package:padel_mobile/data/response_models/league/get_league_list_model.dart';
import 'package:padel_mobile/data/response_models/league/get_league_match_details_model.dart';
import 'package:padel_mobile/data/response_models/league/get_league_poll_results_model.dart';
import 'package:padel_mobile/data/response_models/league/get_league_sponsors_model.dart';
import 'package:padel_mobile/data/response_models/league/get_schedule_dates_model.dart';
import 'package:padel_mobile/data/response_models/league/get_stream_url_model.dart';
import 'package:padel_mobile/handler/logger.dart';

class IptTournamentRepository {
  static final IptTournamentRepository _instance = IptTournamentRepository
      ._internal();
  final DioClient dioClient = DioClient();

  factory IptTournamentRepository() {
    return _instance;
  }

  IptTournamentRepository._internal();

  ///Get All Schedule Live Matches IptTournament--------------------------------
  Future<GetAllScheduleLiveMatchesIptTournamentModel> getAllScheduleLiveMatchesIptTournament({
    String? matchStatus,
    required String tournamentId,
    String? userId,
    String? date,
    String? categoryType,
    int? page,
    int? limit
  }) async {
    try {
      final queryParams = {
        "tournamentId": tournamentId,
        if (matchStatus != null && matchStatus.isNotEmpty) "matchStatus": matchStatus,
        if (userId != null && userId.isNotEmpty) "userId": userId,
        if (date != null && date.isNotEmpty) "date": date,
        if (categoryType != null && categoryType.isNotEmpty) "categoryType": categoryType,
        if (limit != null) "limit": limit,
        if (page != null) "page": page,
      };

      final response = await dioClient.get(
        AppEndpoints.getAllScheduleLiveMatchesIptTournament,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Get IptTournament All Schedule Live Matches Data: ${response.data}",
          level: LogLevel.info,
        );
        return GetAllScheduleLiveMatchesIptTournamentModel.fromJson(response.data);
      } else {
        throw Exception(
            "Get IptTournament All Schedule Live Matches failed: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Get IptTournament All Schedule Live Matches failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  ///Get Schedule Dates IptTournament-------------------------------------------
  Future<GetScheduleDatesIptTournamentModel> getScheduleDatesIptTournament({
    required String tournamentId,
    String? matchStatus,
  }) async {
    try {
      final queryParams = {
        "tournamentId": tournamentId,
        if (matchStatus != null && matchStatus.isNotEmpty)
          "matchStatus": matchStatus,
      };

      final response = await dioClient.get(
        AppEndpoints.getScheduleDatesIptTournament,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Get IptTournament Schedule Dates Data: ${response.data}",
          level: LogLevel.info,
        );
        return GetScheduleDatesIptTournamentModel.fromJson(response.data);
      } else {
        throw Exception(
          "Get IptTournament Schedule Dates failed: ${response.statusCode}",
        );
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Get IptTournament Schedule Dates failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }



  ///Get IptTournament Sponsors-------------------------------------------------
  Future<GetIptTournamentSponsorsModel> getIptTournamentSponsors({String? leagueId}) async {
    try {
      final url = leagueId != null && leagueId.isNotEmpty
          ? "${AppEndpoints.getIptTournamentSponsors}?leagueId=$leagueId"
          : AppEndpoints.getIptTournamentSponsors;
      final response = await dioClient.get(url);

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Get IptTournament Sponsors Data: ${response.data}",
          level: LogLevel.info,
        );
        return GetIptTournamentSponsorsModel.fromJson(response.data);
      } else {
        throw Exception(
            "Get IptTournament Sponsors failed: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Get IptTournament Sponsors failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  ///Get IptTournament Match Details--------------------------------------------
  Future<GetIptTournamentMatchDetailsModel> getIptTournamentMatchDetails({required String matchId,required String type}) async {
    try {
      final response = await dioClient.get(
        "${AppEndpoints.getIptTournamentMatchDetails}/$matchId/$type",
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Get IptTournament Match Details Data: ${response.data}",
          level: LogLevel.info,
        );
        return GetIptTournamentMatchDetailsModel.fromJson(response.data);
      } else {
        throw Exception(
            "Get IptTournament Match Details failed: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Get IptTournament Match Details failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  ///Get IptTournament Leader Board---------------------------------------------
  Future<GetIptTournamentLeaderBoardModel> getIptTournamentLeaderBoard({
    required String tournamentId,
    String? categoryType,
  }) async {
    try {
      final queryParams = {
        if (categoryType != null && categoryType.isNotEmpty) "categoryType": categoryType,
      };
      
      final response = await dioClient.get(
        "${AppEndpoints.getIptTournamentLeaderBoard}$tournamentId/leaderboard",
        queryParameters: queryParams.isNotEmpty ? queryParams : null,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Get IptTournament Leader Board Data: ${response.data}",
          level: LogLevel.info,
        );
        return GetIptTournamentLeaderBoardModel.fromJson(response.data);
      } else {
        throw Exception(
            "Get IptTournament Leader Board failed: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Get IptTournament Leader Board failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  ///Get IptTournament List-----------------------------------------------------
  Future<GetIptTournamentListModel> getIptTournamentList({required String status}) async {
    try {
      final response = await dioClient.get(
        "${AppEndpoints.getIptTournamentList}$status",
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Get IptTournament List Data: ${response.data}",
          level: LogLevel.info,
        );
        return GetIptTournamentListModel.fromJson(response.data);
      } else {
        throw Exception(
            "Get IptTournament List failed: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Get IptTournament List failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  ///Get IptTournament Stream Url-----------------------------------------------
  Future<GetIptTournamentStreamUrlModel> getIptTournamentStreamUrl({required String matchId}) async {
    try {
      final response = await dioClient.get(
        "${AppEndpoints.getIptTournamentMatchDetails}/$matchId/stream-info",
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Get IptTournament Stream Url Data: ${response.data}",
          level: LogLevel.info,
        );
        return GetIptTournamentStreamUrlModel.fromJson(response.data);
      } else {
        return GetIptTournamentStreamUrlModel(success: false);
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Get IptTournament Stream Url failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      return GetIptTournamentStreamUrlModel(success: false);
    }
  }

}
