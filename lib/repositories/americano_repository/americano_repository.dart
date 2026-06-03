import 'package:dio/dio.dart';
import 'package:padel_mobile/core/endpoitns.dart';
import 'package:padel_mobile/core/network/dio_client.dart';
import 'package:padel_mobile/data/response_models/americano_models/get_americano_model.dart';
import 'package:padel_mobile/handler/logger.dart';

class AmericanoRepository {
  static final AmericanoRepository _instance = AmericanoRepository._internal();
  final DioClient dioClient = DioClient();

  factory AmericanoRepository() {
    return _instance;
  }

  AmericanoRepository._internal();

  /// Get Americano Matches with Pagination-------------------------------------
  Future<GetAmericanoModel?> getAmericanos({
    int page = 1,
    int limit = 10,
    String? matchDate,
  }) async {
    try {
      final queryParams = {
        'page': page,
        'limit': limit,
        if (matchDate != null && matchDate.isNotEmpty) 'matchDate': matchDate,
        if (matchDate != null && matchDate.isNotEmpty) 'date': matchDate,
      };

      CustomLogger.logMessage(
        msg: "Fetching Americano Matches: $queryParams",
        level: LogLevel.info,
      );

      final response = await dioClient.get(
        AppEndpoints.getAmericanos,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Americano Matches fetched successfully: ${response.data}",
          level: LogLevel.info,
        );
        return GetAmericanoModel.fromJson(response.data);
      } else {
        throw Exception(
          "Failed to fetch Americano matches. Status code: ${response.statusCode}",
        );
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Error fetching Americano matches: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  /// Register player for Americano Match---------------------------------------
  Future<Response> registerPlayer({
    required String americanoMatchId,
    String? razorpayPaymentId,
    String? razorpayOrderId,
    String? razorpaySignature,
  }) async {
    try {
      final Map<String, dynamic> data = {
        "americanoMatchId": americanoMatchId,
      };

      if (razorpayPaymentId != null) {
        data['razorpay_payment_id'] = razorpayPaymentId;
      }
      if (razorpayOrderId != null) {
        data['razorpay_order_id'] = razorpayOrderId;
      }
      if (razorpaySignature != null) {
        data['razorpay_signature'] = razorpaySignature;
      }

      CustomLogger.logMessage(
        msg: "Registering player for Americano Match: $data",
        level: LogLevel.info,
      );

      final Response response = await dioClient.post(
        AppEndpoints.registerPlayer,
        data: data,
      );

      return response;
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Error registering player for Americano Match: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  /// Get Americano Leaderboard------------------------------------------------
  Future<AmericanoLeaderboardResponse> getAmericanoLeaderboard(String matchId) async {
    try {
      CustomLogger.logMessage(
        msg: "Fetching Americano Leaderboard for matchId: $matchId",
        level: LogLevel.info,
      );

      final response = await dioClient.get(
        AppEndpoints.getAmericanoLeaderboard(matchId),
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Americano Leaderboard fetched successfully: ${response.data}",
          level: LogLevel.info,
        );

        final data = response.data;
        List<AmericanoPlayer> players = [];
        MyRankInfo? myRankInfo;

        if (data != null && data is Map<String, dynamic>) {
          if (data['myRankInfo'] != null && data['myRankInfo'] is Map<String, dynamic>) {
            myRankInfo = MyRankInfo.fromJson(data['myRankInfo']);
          } else if (data['data'] != null && data['data'] is Map<String, dynamic> && data['data']['myRankInfo'] != null) {
            myRankInfo = MyRankInfo.fromJson(data['data']['myRankInfo']);
          }

          final dynamic rawData = data['data'];
          if (rawData is List) {
            players = rawData
                .map((e) => AmericanoPlayer.fromJson(e as Map<String, dynamic>))
                .toList();
          } else if (rawData is Map) {
            if (rawData['leaderboard'] is List) {
              players = (rawData['leaderboard'] as List)
                  .map((e) => AmericanoPlayer.fromJson(e as Map<String, dynamic>))
                  .toList();
            }
            if (rawData['myRankInfo'] != null && rawData['myRankInfo'] is Map<String, dynamic>) {
              myRankInfo = MyRankInfo.fromJson(rawData['myRankInfo']);
            }
          }
        }
        return AmericanoLeaderboardResponse(players: players, myRankInfo: myRankInfo);
      } else {
        throw Exception(
          "Failed to fetch Americano leaderboard. Status code: ${response.statusCode}",
        );
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Error fetching Americano leaderboard: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }
}
