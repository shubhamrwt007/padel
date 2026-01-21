import 'package:padel_mobile/core/endpoitns.dart';
import 'package:padel_mobile/core/network/dio_client.dart';
import 'package:padel_mobile/data/response_models/leaderBoard/get_leaderBoard_model.dart';
import 'package:padel_mobile/handler/logger.dart';

class LeaderboardRepository {
  static final LeaderboardRepository _instance = LeaderboardRepository._internal();
  final DioClient dioClient = DioClient();

  factory LeaderboardRepository() {
    return _instance;
  }

  LeaderboardRepository._internal();

  ///Get LeaderBoard------------------------------------------------------------
  Future<GetLeaderBoardModel> getLeaderBoard({required id,required int page,required int limit, String? type}) async {
    try {
      String url = "${AppEndpoints.getLeaderBoard}?_id=$id&page=$page&limit=$limit";
      if (type != null && type.isNotEmpty) {
        url += "&type=$type";
      }
      final response = await dioClient.get(url);

      if (response.statusCode == 200) {
        CustomLogger.logMessage(
          msg: "Get LeaderBoard successful: ${response.data}",
          level: LogLevel.info,
        );
        return GetLeaderBoardModel.fromJson(response.data);
      } else if (response.statusCode == 404) {
        return GetLeaderBoardModel.fromJson(response.data);
      } else {
        throw Exception("Error");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Get LeaderBoard failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }
}