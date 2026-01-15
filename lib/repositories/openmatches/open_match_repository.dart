import 'package:padel_mobile/data/request_models/open%20matches/accept_or_reject_request_players_model.dart';
import 'package:padel_mobile/data/request_models/open%20matches/request_player_to_open_match_model.dart';
import 'package:padel_mobile/data/request_models/open%20matches/withdraw_request_model.dart';
import 'package:padel_mobile/data/response_models/get_players_level_model.dart';
import 'package:padel_mobile/data/response_models/openmatch_model/find_near_by_player_model.dart';
import 'package:padel_mobile/data/response_models/openmatch_model/get_customer_data_by_phone_number_model.dart';
import 'package:padel_mobile/data/response_models/openmatch_model/get_requests_player_open_match_model.dart';
import '../../core/endpoitns.dart';
import '../../core/network/dio_client.dart';
import '../../data/request_models/open matches/add_player_to_open_match_model.dart';
import '../../data/request_models/open matches/create_user_for_open_match_model.dart';
import '../../data/response_models/openmatch_model/all_open_matches.dart';
import '../../data/response_models/openmatch_model/open_match_booking_model.dart';
import '../../data/response_models/openmatch_model/open_match_model.dart';
import '../../handler/logger.dart';
class OpenMatchRepository {
  static final OpenMatchRepository _instance = OpenMatchRepository._internal();
  final DioClient dioClient = DioClient();

  factory OpenMatchRepository() {
    return _instance;
  }

  OpenMatchRepository._internal();

  /// Create a new match
  Future<OpenMatchModel> createMatch({
    required dynamic data,
  }) async {
    try {
      CustomLogger.logMessage(
        msg: "Open Match Body: $data",
        level: LogLevel.info,
      );
      final response = await dioClient.post(
        AppEndpoints.createMatches,
        data: data,
      );
      if (response.statusCode == 200) {
        CustomLogger.logMessage(
          msg: "Match created successfully: ${response.data}",
          level: LogLevel.info,
        );

        return OpenMatchModel.fromJson(response.data);
      } else {
        throw Exception("Match creation failed. Status code: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Match creation failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }
  ///Get Open Match Bookings by Type (Upcoming / Completed)---------------------------
  Future<OpenMatchBookingModel?> getOpenMatchBookings({
    required String type, // "upcoming" or "completed"
    int page = 1,
    int limit = 10,
    String? matchDate,
  }) async {
    try {
      final queryParams = <String, dynamic>{
        'type': type,
        'page': page,
        'limit': limit,
        if (matchDate != null) 'matchDate': matchDate,
      };

      CustomLogger.logMessage(
        msg: "Fetching Open Match Bookings: $queryParams",
        level: LogLevel.info,
      );

      final response = await dioClient.get(
        AppEndpoints.openMatchBooking,
        queryParameters: queryParams,
      );

      if (response.statusCode == 200) {
        CustomLogger.logMessage(
          msg: "Open Match Bookings fetched successfully: ${response.data}",
          level: LogLevel.info,
        );
        return OpenMatchBookingModel.fromJson(response.data);
      } else {
        throw Exception(
          "Failed to fetch open match bookings. Status: ${response.statusCode}",
        );
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Error fetching open match bookings: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }


  Future<AllOpenMatches> getMatchesByDateTime({
    required String matchDate,
    String? matchTime,
    required String cubId,
    String? search
  }) async {
    try {
      // Encode matchTime properly (space → %20)
      final encodedTime = Uri.encodeComponent(matchTime!);

      final url =
          "${AppEndpoints.getOpenMatches}?clubId=$cubId&matchDate=$matchDate&matchTime=$encodedTime&search=$search";

      final response = await dioClient.get(url);

      if (response.statusCode == 200) {
        return AllOpenMatches.fromJson(response.data);
      } else {
        throw Exception("Failed to fetch matches. Status: ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }
  Future<FindNearByPlayerModel> findNearByPlayer({dynamic? search}) async {
    try {
      final response = await dioClient.get(
        AppEndpoints.findNearByPlayer,
        queryParameters: {
          if (search != null && search.isNotEmpty) "search": search,
        },
      );

      if (response.statusCode == 200) {
        CustomLogger.logMessage(
          msg: "Find Near By Players fetched successfully: ${response.data}",
          level: LogLevel.info,
        );

        return FindNearByPlayerModel.fromJson(response.data);
      } else {
        throw Exception("Failed to fetch Near By Players: ${response.statusCode}");
      }
    } catch (e) {
      rethrow;
    }
  }

  // Future<OpenMatchDetailsModel> getParticularMatch(String clubId) async {
  //   log("mes 2");
  //   try {
  //     log(AppEndpoints.getParticularMatch);
  //     final response = await dioClient.get(AppEndpoints.getParticularMatch);
  //     log("mes 3 ${response.data} ");
  //
  //     return  OpenMatchDetailsModel.fromJson(response.data);
  //
  //
  //
  //   } catch (e, st) {
  //     log("mes 4 ");
  //     CustomLogger.logMessage(
  //       msg: "details error 2: ${e.toString()}",
  //       level: LogLevel.error,
  //       st: st,
  //     );
  //     rethrow;
  //   }
  // }

  ///Create User For Open Match Api--------------------------------------------------------
  Future<CreateUserForOpenMatchModel?> createUserForOpenMatch({
    required Map<String, dynamic> body,
  }) async {
    try {
      CustomLogger.logMessage(
        msg: "Create User For Open Match request body: $body",
        level: LogLevel.info,
      );

      final response = await dioClient.post(
        AppEndpoints.createUserForOpenMatch,
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Create User For Open Match Success: ${response.data}",
          level: LogLevel.info,
        );
        return CreateUserForOpenMatchModel.fromJson(response.data);
      } else {
        throw Exception("Create User For Open Match Failed with status code: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Create User For Open Match failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  ///Add Player For Open Match Api--------------------------------------------------------
  Future<AddPlayerToOpenMatchModel?> addPlayerForOpenMatch({
    required Map<String, dynamic> body,
  }) async {
    try {
      CustomLogger.logMessage(
        msg: "Add Player For Open Match request body: $body",
        level: LogLevel.info,
      );

      final response = await dioClient.put(
        AppEndpoints.addUserForOpenMatch,
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Add Player For Open Match Success: ${response.data}",
          level: LogLevel.info,
        );
        return AddPlayerToOpenMatchModel.fromJson(response.data);
      } else {
        throw Exception("Add Player For Open Match Failed with status code: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Add Player For Open Match failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  ///Request Player For Open Match Api--------------------------------------------------------
  Future<RequestPlayerToOpenMatchModel?> requestPlayerForOpenMatch({
    required Map<String, dynamic> body,
  }) async {
    try {
      CustomLogger.logMessage(
        msg: "Request Player For Open Match request body: $body",
        level: LogLevel.info,
      );

      final response = await dioClient.post(
        AppEndpoints.requestUserForOpenMatch,
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Request Player For Open Match Success: ${response.data}",
          level: LogLevel.info,
        );
        return RequestPlayerToOpenMatchModel.fromJson(response.data);
      } else {
        throw Exception("Request Player For Open Match Failed with status code: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Request Player For Open Match failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  ///Get Request Players Open Match --------------------------------------------
  Future<GetRequestPlayersOpenMatchModel?> getRequestPlayersOpenMatch({
    String? matchId,
    String? type,
    String? filter
  }) async {
    try {
      final url = "${AppEndpoints.getRequestUserForOpenMatch}matchId=$matchId&type=$type&filter=$filter";

      CustomLogger.logMessage(
        msg: "Get Request Player For Open Match Bookings: $url",
        level: LogLevel.info,
      );

      final response = await dioClient.get(url);

      if (response.statusCode == 200) {
        CustomLogger.logMessage(
          msg: "Get Request Player For Open Match fetched successfully: ${response.data}",
          level: LogLevel.info,
        );
        return GetRequestPlayersOpenMatchModel.fromJson(response.data);
      } else {
        throw Exception(
            "Failed to fetch Get Request Player For Open Match Status: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Error fetching Get Request Player For Open Match: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  ///Accept Or Reject Request Player For Open Match Api--------------------------------------------------------
  Future<AcceptOrRejectRequestPlayersModel?> acceptOrRejectRequestPlayer({
    required Map<String, dynamic> body,
  }) async {
    try {
      CustomLogger.logMessage(
        msg: "Accept Or Reject Request Player For Open Match request body: $body",
        level: LogLevel.info,
      );

      final response = await dioClient.put(
        AppEndpoints.acceptOrRejectRequestUserForOpenMatch,
        data: body,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Accept Or Reject Request Player For Open Match Success: ${response.data}",
          level: LogLevel.info,
        );
        return AcceptOrRejectRequestPlayersModel.fromJson(response.data);
      } else {
        throw Exception("Accept Or Reject Request Player For Open Match Failed with status code: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Accept Or Reject Request Player For Open Match failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  ///Get Players Levels --------------------------------------------------------
  Future<GetPlayersLevelModel?> getPlayerLevels({
    required String type,
  }) async {
    try {
      // base URL
      String url = AppEndpoints.getPlayersLevel;

      // only add type if not empty
      if (type.isNotEmpty) {
        url += "?type=$type";
      }

      final response = await dioClient.get(url);

      if (response.statusCode == 200) {
        CustomLogger.logMessage(
          msg: "Get Players Levels fetched successfully: ${response.data}",
          level: LogLevel.info,
        );
        return GetPlayersLevelModel.fromJson(response.data);
      } else {
        throw Exception(
            "Failed to fetch Get Players Levels Status: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Error fetching Get Players Levels: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }
  ///Get Customer Name By Phone Number------------------------------------------
  Future<GetCustomerDataByPhoneNumberModel> getCustomerNameByPhoneNumber({
    required String phoneNumber,
  }) async {
    try {
      final response = await dioClient.get(
        "${AppEndpoints.getCustomerNameByPhoneNumber}phoneNumber=$phoneNumber",
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Get-Customer Name By Phone Number Data: ${response.data}",
          level: LogLevel.info,
        );
        return GetCustomerDataByPhoneNumberModel.fromJson(response.data);
      } else {
        throw Exception("Get-Customer Name By Phone Number failed: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Get-Customer Name By Phone Number failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }
  ///WithDraw Request-----------------------------------------------------------
  Future<WithdrawRequestModel> withdrawRequest({
    required id,
  }) async {
    try {
      final response = await dioClient.delete(
        "${AppEndpoints.withdrawRequest}$id", data: {},
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Withdraw Request Data: ${response.data}",
          level: LogLevel.info,
        );
        return WithdrawRequestModel.fromJson(response.data);
      } else {
        throw Exception("Withdraw Request failed: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Withdraw Request failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

}
