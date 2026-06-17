import 'dart:developer';
import 'package:dio/dio.dart';
import 'package:padel_mobile/data/request_models/createAndGetSlotHistoryModel.dart';
import 'package:padel_mobile/data/request_models/deleteSlotHistoryModel.dart';
import 'package:padel_mobile/data/request_models/home_models/get_category_model.dart';
import 'package:padel_mobile/data/request_models/slot_history_models/delete_bulk_slot_history_model.dart';
import 'package:padel_mobile/data/response_models/get_all_slot_prices_of_court_model.dart';
import 'package:padel_mobile/data/response_models/get_courts_by_duration_model.dart';
import 'package:padel_mobile/data/response_models/get_location_maps_model.dart';
import 'package:padel_mobile/data/response_models/get_pending_request_count_model.dart';
import 'package:padel_mobile/data/response_models/get_register_club_model.dart';
import 'package:padel_mobile/data/response_models/home_models/get_near_city_players_model.dart';
import 'package:padel_mobile/data/response_models/leaderBoard/get_customer_leader_board_rank_model.dart';
import 'package:padel_mobile/data/response_models/openmatch_model/get_customer_data_by_phone_number_model.dart';
import 'package:padel_mobile/handler/logger.dart';
import '../../core/endpoitns.dart';
import '../../core/network/dio_client.dart';
import '../../data/request_models/home_models/get_available_court.dart';
import '../../data/request_models/home_models/get_club_name_model.dart';
import '../../presentations/auth/forgot_password/widgets/forgot_password_exports.dart';

class HomeRepository {
  final DioClient dioClient = DioClient();
  Future<CourtsModel> fetchClubData({
    String limit = "10",
    required String page,
    String search = "",
    String? categoryId,
    // String? locationId
  }) async {
     try {
      String url = "${AppEndpoints.getClub}$limit&page=$page&search=$search";
      
      if (categoryId != null && categoryId.isNotEmpty) {
        url += "&categoryId=$categoryId";
      }
      
      // if (locationId != null && locationId.isNotEmpty) {
      //   url += "&location=$locationId";
      // }
      
      final response = await dioClient.get(url);
      if (response.statusCode == 200) {
        log("Response Data: ${response.data}");
        return CourtsModel.fromJson(response.data);
      } else {
        ////
        throw
        Exception("Failed to load club data - status code: ${response.statusCode}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        debugPrint("Dio Error: ${e.response?.statusMessage}");
        throw Exception("Server error: ${e.response?.statusCode}");
      } else {
        debugPrint("Dio Error: ${e.message}");
        throw Exception("Network error: ${e.message}");
      }
    }
  }

  Future<GetAllActiveCourtsForSlotWiseModel> fetchAvailableCourtsSlotWise({
    required String registerClubId,       // club id
    required String day,
     String? date,
    String? sID,
    // String? location,
    String? categoryId,
    String? locId
    // String? duration
  }) async {
    String url = "${AppEndpoints.getAllActiveCourtsForSlotWise}register_club_id=$registerClubId&day=$day&date=$date&_id=$sID&categoryId=$categoryId&locId=$locId";

    try {
      final response = await dioClient.get(url);

      if (response.statusCode == 200) {
        debugPrint("Available Courts Responsedfr: ${response.data}");
        return GetAllActiveCourtsForSlotWiseModel.fromJson(response.data);
      } else {
        throw Exception("Failed to load available courts - status code: ${response.statusCode}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        debugPrint("Dio Error: ${e.response?.data}");
        throw Exception("Server error: ${e.response?.statusMessage}");
      } else {
        debugPrint("Dio Network Error: ${e.message}");
        throw Exception("Network error: ${e.message}");
      }
    }
  }

  ///Get Register Club Data-----------------------------------------------------
  Future<GetRegisterClubModel> getRegisterClub({required String clubId, String? courtId}) async {
    try {
      String url = "${AppEndpoints.getRegisterClub}clubId=$clubId";
      if (courtId != null && courtId.isNotEmpty) {
        url += "&courtId=$courtId";
      }

      final response = await dioClient.get(url);

      if (response.statusCode == 200) {
        log("Response Register Club Data: ${response.data}");
        return GetRegisterClubModel.fromJson(response.data);
      } else {
        throw Exception("Failed to load Register Club data - status code: ${response.statusCode}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        debugPrint("Dio Error: ${e.response?.statusMessage}");
        throw Exception("Server error: ${e.response?.statusCode}");
      } else {
        debugPrint("Dio Error: ${e.message}");
        throw Exception("Network error: ${e.message}");
      }
    }
  }

  ///Get Map Location-----------------------------------------------------------
  Future<GetLocationMapsModel> getLocationMaps({required String address}) async {
    try {
      final url = "${AppEndpoints.getLocationMaps}address=$address";
      final response = await dioClient.get(url);
      if (response.statusCode == 200) {
        log("Response Maps Location Data: ${response.data}");
        return GetLocationMapsModel.fromJson(response.data);
      } else {
        throw Exception("Failed to load Maps Location data - status code: ${response.statusCode}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        debugPrint("Dio Error: ${e.response?.statusMessage}");
        throw Exception("Server error: ${e.response?.statusCode}");
      } else {
        debugPrint("Dio Error: ${e.message}");
        throw Exception("Network error: ${e.message}");
      }
    }
  }

  ///Get All Slot Prices Of Court------------------------------------------------
  Future<GetAllSlotPricesOfCourtModel> getAllSlotPricesOfCourt({required registerClubId,required duration,required day,required timePeriod,String? categoryId,String? locationId,String? lockId}) async {
    try {
      final response = await dioClient.get("${AppEndpoints.getAllSlotPricesOfCourt}register_club_id=$registerClubId&duration=$duration&day=$day&timePeriod=$timePeriod&categoryId=$categoryId&location=$locationId&lockId=$lockId",);
      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Get All Slot Prices Of Court Data: ${response.data}",
          level: LogLevel.info,
        );
        return GetAllSlotPricesOfCourtModel.fromJson(response.data);
      } else {
        throw Exception("Get All Slot Prices Of Court Data failed: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Get All Slot Prices Of Court Data failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  ///Get Courts By Duration Court------------------------------------------------
  Future<GetCourtsByDurationModel> getCourtsByDuration({
    required String duration,
    required String date,
    required String time,
    // String? locationId,
    String? categoryId,
    int? page=1,
    int? limit=15,
  }) async {
    try {
      final response = await dioClient.get("${AppEndpoints.getCourtsByDuration}duration=$duration&date=$date&time=$time&categoryId=$categoryId&page=$page&limit=$limit",);
      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Get Courts By Durationt Data: ${response.data}",
          level: LogLevel.info,
        );
        return GetCourtsByDurationModel.fromJson(response.data);
      } else {
        throw Exception("Get Courts By Duration Data failed: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Get Courts By Duration Data failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  Future<CreateAndGetSlotHistoryResponse> createAndGetSlotHistory({
    required dynamic data,
  }) async {
    try {
      final response = await dioClient.post(
        AppEndpoints.createAndGetSlotHistory,
        data: data,
      );

      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Create and Get Slot History Data: ${response.data}",
          level: LogLevel.info,
        );

        return CreateAndGetSlotHistoryResponse.fromJson(
          response.data as Map<String, dynamic>,
        );
      } else {
        throw Exception("Create and Get Slot History failed: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Create and Get Slot History failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  ///Delete Slot History--------------------------------------------------------

  Future<DeleteSlotHistoryModel> deleteSlotHistory({
    required dynamic data,
  }) async {
    try {
      final response = await dioClient.delete(AppEndpoints.deleteSlotHistory, data: data,);
      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Delete Slot History Data: ${response.data}",
          level: LogLevel.info,
        );
        return DeleteSlotHistoryModel.fromJson(response.data);
      } else {
        throw Exception("Delete Slot History failed: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Delete Slot History failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }
  ///Delete Bulk Slot History---------------------------------------------------
  Future<DeleteBulkSlotHistoryModel> deleteBulkSlotHistory({
    required dynamic data,
  }) async {
    try {
      final response = await dioClient.delete(AppEndpoints.deleteBulkSlotHistory, data: data,);
      if (response.statusCode == 200 || response.statusCode == 201) {
        CustomLogger.logMessage(
          msg: "Delete Bulk Slot History Data: ${response.data}",
          level: LogLevel.info,
        );
        return DeleteBulkSlotHistoryModel.fromJson(response.data);
      } else {
        throw Exception("Delete Bulk Slot History failed: ${response.statusCode}");
      }
    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Delete Bulk Slot History failed with error: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      rethrow;
    }
  }

  ///Get Near City Players------------------------------------------------------
  Future<GetNearCityPlayers> getNearCityPlayers({required id}) async {
    try {
      final url = "${AppEndpoints.geNaerCityPlayer}?_id=$id";

      final response = await dioClient.get(url);

      if (response.statusCode == 200) {
        log("Get Near City Players: ${response.data}");
        return GetNearCityPlayers.fromJson(response.data);
      } else {
        throw Exception("Failed to load Get Near City Players - status code: ${response.statusCode}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        debugPrint("Dio Error: ${e.response?.statusMessage}");
        throw Exception("Server error: ${e.response?.statusCode}");
      } else {
        debugPrint("Dio Error: ${e.message}");
        throw Exception("Network error: ${e.message}");
      }
    }
  }

  ///Get Customer LeaderBord Rank-----------------------------------------------
  Future<GetCustomerLeaderBoardRankModel> getCustomerLeaderBoardRank({required categoryId}) async {
    try {
      final url = "${AppEndpoints.getMyRankGenderWise}?categoryId=$categoryId";

      final response = await dioClient.get(url);

      if (response.statusCode == 200) {
        log("Get Customer LeaderBord Rank: ${response.data}");
        return GetCustomerLeaderBoardRankModel.fromJson(response.data);
      } else {
        throw Exception("Failed to load Get Customer LeaderBord Rank - status code: ${response.statusCode}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        debugPrint("Dio Error: ${e.response?.statusMessage}");
        throw Exception("Server error: ${e.response?.statusCode}");
      } else {
        debugPrint("Dio Error: ${e.message}");
        throw Exception("Network error: ${e.message}");
      }
    }
  }

  ///Get Pending Request Count--------------------------------------------------
  Future<GetPendingRequestCountModel> getPendingRequestCount() async {
    try {
      final url = AppEndpoints.getPendingRequestCount;

      final response = await dioClient.get(url);

      if (response.statusCode == 200) {
        log("Get Pending Request Count: ${response.data}");
        return GetPendingRequestCountModel.fromJson(response.data);
      } else {
        throw Exception("Failed to load Get Pending Request Count - status code: ${response.statusCode}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        debugPrint("Dio Error: ${e.response?.statusMessage}");
        throw Exception("Server error: ${e.response?.statusCode}");
      } else {
        debugPrint("Dio Error: ${e.message}");
        throw Exception("Network error: ${e.message}");
      }
    }
  }

  ///Get Category---------------------------------------------------------------
  Future<GetCategoryModel> getCategory() async {
    try {
      final url = AppEndpoints.getCategory;
      final response = await dioClient.get(url);
      if (response.statusCode == 200) {
        log("Get Category: ${response.data}");
        return GetCategoryModel.fromJson(response.data);
      } else {
        throw Exception("Failed to load Get Category - status code: ${response.statusCode}");
      }
    } on DioException catch (e) {
      if (e.response != null) {
        debugPrint("Dio Error: ${e.response?.statusMessage}");
        throw Exception("Server error: ${e.response?.statusCode}");
      } else {
        debugPrint("Dio Error: ${e.message}");
        throw Exception("Network error: ${e.message}");
      }
    }
  }
}
