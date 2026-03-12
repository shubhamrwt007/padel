import 'package:padel_mobile/core/endpoitns.dart';
import 'package:padel_mobile/core/network/dio_client.dart';
import 'package:padel_mobile/data/response_models/league/get_all_schedule_matches_model.dart';
import 'package:padel_mobile/handler/logger.dart';

class LeagueRepository {
  static final LeagueRepository _instance = LeagueRepository
      ._internal();
  final DioClient dioClient = DioClient();

  factory LeagueRepository() {
    return _instance;
  }

  LeagueRepository._internal();

  ///Get All Schedule Matches---------------------------------------------------
  Future<GetAllScheduleMatchesModel> getAllScheduleMatches(
      {required String matchStatus}) async {
    try {
      final response = await dioClient.get(
        "${AppEndpoints.getAllScheduleMatches}matchStatus=$matchStatus",
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Get All Schedule Matches Data: ${response.data}",
          level: LogLevel.info,
        );
        return GetAllScheduleMatchesModel.fromJson(response.data);
      } else {
        throw Exception(
            "Get All Schedule Matches failed: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Get All Schedule Matches failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }
}
