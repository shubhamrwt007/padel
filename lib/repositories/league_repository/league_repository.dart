import 'package:padel_mobile/core/endpoitns.dart';
import 'package:padel_mobile/core/network/dio_client.dart';
import 'package:padel_mobile/data/response_models/league/get_all_schedule_live_matches_model.dart';
import 'package:padel_mobile/data/response_models/league/get_all_schedule_upcoming_matches_model.dart';
import 'package:padel_mobile/data/response_models/league/get_league_match_details_model.dart';
import 'package:padel_mobile/data/response_models/league/get_league_sponsors_model.dart';
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
      {required String matchStatus}) async {
    try {
      final response = await dioClient.get(
        "${AppEndpoints.getAllScheduleLiveMatches}matchStatus=$matchStatus",
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
  Future<GetLeagueSponsorsModel> getLeagueSponsors() async {
    try {
      final response = await dioClient.get(
        AppEndpoints.getLeagueSponsors,
      );

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
}
