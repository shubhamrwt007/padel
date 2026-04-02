import 'package:padel_mobile/core/endpoitns.dart';
import 'package:padel_mobile/core/network/dio_client.dart';
import 'package:padel_mobile/data/request_models/league/cast_league_vote_model.dart';
import 'package:padel_mobile/data/response_models/league/get_all_schedule_live_matches_model.dart';
import 'package:padel_mobile/data/response_models/league/get_all_schedule_upcoming_matches_model.dart';
import 'package:padel_mobile/data/response_models/league/get_league_leader_board_model.dart';
import 'package:padel_mobile/data/response_models/league/get_league_list_model.dart';
import 'package:padel_mobile/data/response_models/league/get_league_match_details_model.dart';
import 'package:padel_mobile/data/response_models/league/get_league_poll_results_model.dart';
import 'package:padel_mobile/data/response_models/league/get_league_sponsors_model.dart';
import 'package:padel_mobile/data/response_models/league/get_stream_url_model.dart';
import 'package:padel_mobile/handler/logger.dart';

class LeagueRepository {
  static final LeagueRepository _instance = LeagueRepository
      ._internal();
  final DioClient dioClient = DioClient();

  factory LeagueRepository() {
    return _instance;
  }

  LeagueRepository._internal();

  ///Get All Schedule Live Matches---------------------------------------------------
  Future<GetAllScheduleLiveMatchesModel> getAllScheduleLiveMatches(
      {required String matchStatus,required String leagueId}) async {
    try {
      final response = await dioClient.get(
        "${AppEndpoints.getAllScheduleLiveMatches}matchStatus=$matchStatus&leagueId=$leagueId",
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Get All Schedule Live Matches Data: ${response.data}",
          level: LogLevel.info,
        );
        return GetAllScheduleLiveMatchesModel.fromJson(response.data);
      } else {
        throw Exception(
            "Get All Schedule Live Matches failed: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Get All Schedule Live Matches failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }



  ///Get League Sponsors--------------------------------------------------------
  Future<GetLeagueSponsorsModel> getLeagueSponsors({String? leagueId}) async {
    try {
      final url = leagueId != null && leagueId.isNotEmpty
          ? "${AppEndpoints.getLeagueSponsors}?leagueId=$leagueId"
          : AppEndpoints.getLeagueSponsors;
      final response = await dioClient.get(url);

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Get League Sponsors Data: ${response.data}",
          level: LogLevel.info,
        );
        return GetLeagueSponsorsModel.fromJson(response.data);
      } else {
        throw Exception(
            "Get League Sponsors failed: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Get League Sponsors failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  ///Get League Match Details---------------------------------------------------
  Future<GetLeagueMatchDetailsModel> getLeagueMatchDetails({required String matchId,required String type}) async {
    try {
      final response = await dioClient.get(
        "${AppEndpoints.getLeagueMatchDetails}/$matchId/$type",
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Get League Match Details Data: ${response.data}",
          level: LogLevel.info,
        );
        return GetLeagueMatchDetailsModel.fromJson(response.data);
      } else {
        throw Exception(
            "Get League Match Details failed: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Get League Match Details failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  ///Get League Leader Board----------------------------------------------------
  Future<GetLeagueLeaderBoardModel> getLeagueLeaderBoard({required String leagueId}) async {
    try {
      final response = await dioClient.get(
        "${AppEndpoints.getLeagueLeaderBoard}$leagueId/leaderboard",
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Get League Leader Board Data: ${response.data}",
          level: LogLevel.info,
        );
        return GetLeagueLeaderBoardModel.fromJson(response.data);
      } else {
        throw Exception(
            "Get League Leader Board failed: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Get League Leader Board failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  ///Get League List----------------------------------------------------
  Future<GetLeagueListModel> getLeagueList({required String status}) async {
    try {
      final response = await dioClient.get(
        "${AppEndpoints.getLeagueList}$status",
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Get League List Data: ${response.data}",
          level: LogLevel.info,
        );
        return GetLeagueListModel.fromJson(response.data);
      } else {
        throw Exception(
            "Get League List failed: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Get League List failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  ///Get Stream Url-------------------------------------------------------------
  Future<GetStreamUrlModel> getStreamUrl({required String matchId}) async {
    try {
      final response = await dioClient.get(
        "${AppEndpoints.getLeagueMatchDetails}/$matchId/stream-info",
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Get Stream Url Data: ${response.data}",
          level: LogLevel.info,
        );
        return GetStreamUrlModel.fromJson(response.data);
      } else {
        throw Exception(
            "Get Stream Url failed: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Get Stream Url failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }
  ///Get League Poll Result-----------------------------------------------------
  Future<GetLeaguePollResultsModel> getLeaguePollResult() async {
    try {
      final response = await dioClient.get(
        AppEndpoints.getLeaguePollResult,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Get League Poll Result Data: ${response.data}",
          level: LogLevel.info,
        );
        return GetLeaguePollResultsModel.fromJson(response.data);
      } else {
        throw Exception(
            "Get League Poll Result failed: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Get League Poll Result failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  /// Cast League Vote----------------------------------------------------------
  Future<CastLeagueVoteModel> castLeagueVote({
    required dynamic data,
  }) async {
    try {
      CustomLogger.logMessage(
        msg: "Wallet body $data",
        level: LogLevel.info,
      );
      final response = await dioClient.post(
        AppEndpoints.castLeaguePollVote,
        data: data,
      );
      if (response.statusCode == 200) {
        CustomLogger.logMessage(
          msg: "Cast League Vote successfully: ${response.data}",
          level: LogLevel.info,
        );

        return CastLeagueVoteModel.fromJson(response.data);
      } else {
        throw Exception("Cast League Vote failed. Status code: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Cast League Vote failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }
}
