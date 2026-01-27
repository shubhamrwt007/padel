
import 'package:padel_mobile/core/endpoitns.dart';
import 'package:padel_mobile/core/network/dio_client.dart';
import 'package:padel_mobile/data/response_models/xp_points_model/get_xp_points_model.dart';
import 'package:padel_mobile/handler/logger.dart';

class XpPointsRepository {
  static final XpPointsRepository _instance = XpPointsRepository._internal();
  final DioClient dioClient = DioClient();

  factory XpPointsRepository() {
    return _instance;
  }

  XpPointsRepository._internal();

  ///Get XP Points--------------------------------------------------------------
  Future<GetXpPointsModel> getXpPoints({
    String? userId,
    String? fromDate,
    String? toDate,
    int? page,
    int? limit,
  }) async {
    try {
      final List<String> queryParts = [];

      if (userId != null && userId.isNotEmpty) {
        queryParts.add("userId=$userId");
      }
      if (fromDate != null && fromDate.isNotEmpty) {
        queryParts.add("fromDate=$fromDate");
      }
      if (toDate != null && toDate.isNotEmpty) {
        queryParts.add("toDate=$toDate");
      }
      if (page != null) {
        queryParts.add("page=$page");
      }
      if (limit != null) {
        queryParts.add("limit=$limit");
      }

      final String queryString =
      queryParts.isNotEmpty ? "?${queryParts.join("&")}" : "";

      final response = await dioClient.get(
        "${AppEndpoints.getXpPoints}$queryString",
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Get-XP Points Data: ${response.data}",
          level: LogLevel.info,
        );
        return GetXpPointsModel.fromJson(response.data);
      } else {
        throw Exception("Get-XP Points failed: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Get-XP Points failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

}