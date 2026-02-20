import 'package:dio/dio.dart';
import 'package:get_storage/get_storage.dart';
import 'package:padel_mobile/configs/components/app_toast.dart';
import 'package:padel_mobile/presentations/booking/open_matches/all_open_matches/all_open_match_controller.dart';
import 'package:padel_mobile/presentations/open_match_for_all_court/open_match_for_all_court_controller.dart';
import 'package:padel_mobile/presentations/openmatchbooking/openmatch_booking_controller.dart';
import 'package:padel_mobile/presentations/score_board/score_board_controller.dart';
import 'package:padel_mobile/presentations/wallet/widgets/payment_for_wallet.dart';
import 'package:padel_mobile/repositories/score_board_repo/score_board_repository.dart';
import 'package:padel_mobile/presentations/profile/profile_controller.dart';
import 'package:padel_mobile/presentations/bookinghistory/booking_history_controller.dart';
import '../../widgets/booking_exports.dart';

class AddPlayerController extends GetxController {
  final storage = GetStorage();
  OpenMatchesController? openMatchesController;
  AllOpenMatchController? allOpenMatchController;
  OpenMatchBookingController? openMatchBookingController;
  ScoreBoardController? scoreBoardController;
  OpenMatchForAllCourtController? openMatchForAllCourtController;
  BookingHistoryController? bookingHistoryController;

  // final firstNameController = TextEditingController();
  // final lastNameController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  RxString gender = ''.obs;
  RxString playerLevel = ''.obs;

  /// Player levels from API
  var playerLevels = <Map<String, String>>[].obs;
  var isLoading = false.obs;
  var isLoadingLevels = false.obs;
  OpenMatchRepository repository = Get.put(OpenMatchRepository());
  var playerId = "".obs;
  var selectedTeam = "".obs;
  var matchId = "".obs;
  var requestId = "".obs;
  var isLoginUserAdding = false.obs;
  var isMatchCreator = false.obs;

  Future<void> createUser() async {
    if (isLoading.value) return;

    // If login user is adding themselves, skip API call and add directly
    if (isLoginUserAdding.value) {
      await addLoginUserDirectly();
      return;
    }
    if (phoneController.text.isEmpty) {
      AppToast.error("Please Enter Phone Number");
    }
    else if (nameController.text.isEmpty) {
      AppToast.error("Please Enter Full Name");
    }
    else if (gender.value.isEmpty) {
      AppToast.error("Please Select Gender");
    }

    isLoading.value = true;
    try {
      final body = {
        "name": nameController.text.trim(),
        // "lastName": lastNameController.text.trim(),
        "email": emailController.text.trim(),
        "phoneNumber": phoneController.text.trim(),
        "gender": gender.value,
        // "level": playerLevel.value,
      };

      final response = await repository.createUserForOpenMatch(body: body);

      if (response?.status == "200" && response?.response?.sId != null) {
        playerId.value = response!.response!.sId!;

        // ---------- Add Player For Open Matches ----------
        if (allOpenMatchController != null) {
          final added = await addPlayer();
          if (added) {
            CustomLogger.logMessage(
              msg: "User Created & Player Added $body",
              level: LogLevel.info,
            );
          }
        } else if (openMatchesController != null) {
          if (isMatchCreator.value) {
            final added = await addPlayer();
            if (added) {
              CustomLogger.logMessage(
                msg: "User Created & Player Added $body",
                level: LogLevel.info,
              );
            }
          } else {
            final requested = await requestPlayerForOpenMatch();
            if (requested) {
              CustomLogger.logMessage(
                msg: "User Created & Player Requested $body",
                level: LogLevel.info,
              );
            }
          }
        } else if (openMatchBookingController != null) {
          final requested = await requestPlayerForOpenMatch();
          if (requested) {
            CustomLogger.logMessage(
              msg: "User Created & Player Requested $body",
              level: LogLevel.info,
            );
          }
        } else if (openMatchForAllCourtController != null) {
          if (isMatchCreator.value) {
            final added = await addPlayer();
            if (added) {
              CustomLogger.logMessage(
                msg: "User Created & Player Added $body",
                level: LogLevel.info,
              );
            }
          } else {
            final requested = await requestPlayerForOpenMatch(bookingId: bookingId.value);
            if (requested) {
              CustomLogger.logMessage(
                msg: "User Created & Player Requested $body",
                level: LogLevel.info,
              );
            }
          }
        }

        // ---------- Add Player As Guest ----------
        else if (scoreBoardController != null) {
          final added = await addPlayer();
          if (added) {
            CustomLogger.logMessage(
              msg: "Guest User Created & Added $body",
              level: LogLevel.info,
            );
          }
        }
   else if (bookingHistoryController != null) {
          final added = await addPlayer();
          if (added) {
            CustomLogger.logMessage(
              msg: "Guest User Created & Added $body",
              level: LogLevel.info,
            );
          }
        }

        return;
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Error :-> $e", level: LogLevel.error);
    } finally {
      isLoading.value = false;
    }
  }

  // Add login user directly without API call
  Future<void> addLoginUserDirectly() async {
    isLoading.value = true;
    try {
      final userId = storage.read('userId');
      if (userId != null) {
        playerId.value = userId;
        
        // Add player to match
        if (allOpenMatchController != null) {
          final added = await addPlayer();
          if (added) {
            CustomLogger.logMessage(
              msg: "Login User Added Directly",
              level: LogLevel.info,
            );
          }
        } else if (openMatchesController != null) {
          if (isMatchCreator.value) {
            final added = await addPlayer();
            if (added) {
              CustomLogger.logMessage(
                msg: "Login User Added Directly",
                level: LogLevel.info,
              );
            }
          } else {
            final requested = await requestPlayerForOpenMatch(bookingId: bookingId.value);
            if (requested) {
              CustomLogger.logMessage(
                msg: "Login User Requested Directly",
                level: LogLevel.info,
              );
            }
          }
        } else if (openMatchBookingController != null) {
          final requested = await requestPlayerForOpenMatch(bookingId: bookingId.value);
          if (requested) {
            CustomLogger.logMessage(
              msg: "Login User Requested Directly",
              level: LogLevel.info,
            );
          }
        } else if (openMatchForAllCourtController != null) {
          if (isMatchCreator.value) {
            final added = await addPlayer();
            if (added) {
              CustomLogger.logMessage(
                msg: "Login User Added Directly",
                level: LogLevel.info,
              );
            }
          } else {
            final requested = await requestPlayerForOpenMatch(bookingId: bookingId.value);
            if (requested) {
              CustomLogger.logMessage(
                msg: "Login User Requested Directly",
                level: LogLevel.info,
              );
            }
          }
        }
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Error adding login user: $e", level: LogLevel.error);
    } finally {
      isLoading.value = false;
    }
  }

  ///Add Player In Open Match Api-----------------------------------------------
  Future<bool> addPlayer() async {
    try {
      // Normalize team name: "Team A" -> "teamA", "Team B" -> "teamB"
      String normalizedTeam = selectedTeam.value.trim().toLowerCase() == 'team a' ? 'teamA' : 'teamB';
      
      final body = {
        "matchId": matchId.value,
        "playerId": playerId.value,
        "team": normalizedTeam
      };
      final response = await repository.addPlayerForOpenMatch(body: body);

      if (response?.match != null) {
        await openMatchesController?.fetchMatchesForSelection();
        await allOpenMatchController?.fetchOpenMatches();
        await openMatchBookingController?.fetchOpenMatchesBooking(type: "upcoming");
        await openMatchForAllCourtController?.fetchMatchesForSelection();
        await scoreBoardController?.fetchScoreBoard();
        if (bookingHistoryController != null) {
          bookingHistoryController!.fetchBookings("upcoming");
          CustomLogger.logMessage(
            msg: "BookingHistoryController fetchBookings called",
            level: LogLevel.info,
          );
        } else {
          CustomLogger.logMessage(
            msg: "BookingHistoryController is null",
            level: LogLevel.warning,
          );
        }

        // Return success to caller so it can refresh immediately
        Get.back(result: true);
        Get.back();
        CustomLogger.logMessage(
          msg: "Player Added To the Match $body",
          level: LogLevel.info,
        );
        return true;
      } else {
        CustomLogger.logMessage(msg: response?.message ?? "Failed to add player", level: LogLevel.error);
        return false;
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Error :-> $e", level: LogLevel.error);
      return false;
    }
  }

  ///Request Player For Open Match Api-----------------------------------------------
  Future<bool> requestPlayerForOpenMatch({
    String? type,
    String? bookingId,
    dynamic price
  }) async {
    try {
      final body = {
        "matchId": matchId.value,
        "bookingId": bookingId,
        // "preferredTeam": selectedTeam.value,
      };

      if (type != null) {
        body["type"] = type;
        body["playerId"] = playerId.value;
      } else {
        body["requesterId"] = playerId.value;
      }

      final response =
      await repository.requestPlayerForOpenMatch(body: body);

      if (response != null) {
        await openMatchBookingController
            ?.fetchOpenMatchesBooking(type: "upcoming");

        // Get.back(result: true);
        CustomLogger.logMessage(
          msg: "Player Request Sent $body",
          level: LogLevel.info,
        );
        return true;
      } else {
        CustomLogger.logMessage(msg: "Failed to send player request", level: LogLevel.error);
        return false;
      }
    } on DioException catch (e) {
      /// ✅ Handle 404 error
      if (e.response?.statusCode == 404) {
        Get.to(() => PaymentForWallet(
          totalAmount: price??0,
          title: "Match Request",
        ), arguments: {
          'requestMatchId': matchId.value,
          'requestBookingId': bookingId,
          'requestTeam': selectedTeam.value,
          'requestPrice': price,
        });
      } else {
        CustomLogger.logMessage(msg: e.response?.data?['message'] ?? "Something went wrong", level: LogLevel.error);
      }

      CustomLogger.logMessage(
        msg: "Dio Error :-> ${e.response?.data}",
        level: LogLevel.error,
      );
      return false;
    } catch (e) {
      CustomLogger.logMessage(
        msg: "Error :-> $e",
        level: LogLevel.error,
      );
      return false;
    }
  }


  ///Accept Request For Open Match Api-----------------------------------------------
  Future<bool> acceptRequest() async {
    try {
      final body = {
        "requestId": requestId.value,
        "action": "accept",
      };

      final response =
      await repository.acceptOrRejectRequestPlayer(body: body);

      if (response != null) {
        Get.back(result: true);
        CustomLogger.logMessage(
          msg: "Request Accepted $body",
          level: LogLevel.info,
        );
        return true;
      }

      return false;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        // _showInsufficientBalanceDialog(
        //   e.response?.data?['message'] ?? "Resource not found",
        // );
      } else {
        CustomLogger.logMessage(msg: "Something went wrong", level: LogLevel.error);
      }

      CustomLogger.logMessage(msg: "Error :-> $e", level: LogLevel.error);
      return false;
    }
  }

  ///Respond To Booking Request Api-----------------------------------------------
  Future<bool> respondToBookingRequest() async {
    try {
      final body = {
        "requestId": requestId.value,
        "action": "accept",
      };

      final response = await repository.respondToBookingRequest(body: body);

      if (response != null) {
        Get.back(result: true);
        CustomLogger.logMessage(
          msg: "Booking Request Accepted $body",
          level: LogLevel.info,
        );
        return true;
      }
      return false;
    } catch (e) {
      if (e is DioException && e.response?.statusCode == 404) {
        // _showInsufficientBalanceDialog(
        //   e.response?.data?['message'] ?? "Resource not found",
        // );
      } else {
      }
      CustomLogger.logMessage(msg: "Error :-> $e", level: LogLevel.error);
      return false;
    }
  }


    ///Add Guest Player in the Simple Match---------------------------------------
  ScoreBoardRepository scoreBoardRepository = Get.put(ScoreBoardRepository());
  var scoreboardId = ''.obs;
  var openMatchId = ''.obs;
  Future<bool> addGuestPlayer() async {
    try {
      // Normalize team name: "Team A" -> "teamA", "Team B" -> "teamB"
      String normalizedTeam = selectedTeam.value.trim().toLowerCase() == 'team a' ? 'teamA' : 'teamB';

      final body = {
        "bookingId":bookingId.value,
        "scoreboardId": scoreboardId.value,
        if (openMatchId.value.isNotEmpty) "openMatchId": openMatchId.value,
        "teams": [
          {
            "name": normalizedTeam,
            "players": [
              {
                "playerId": playerId.value
              }
            ]
          }
        ]
      };
      final response = await scoreBoardRepository.addGuestPlayer(body: body);

      if (response?.data != null) {
        await scoreBoardController?.fetchScoreBoard();
        // await bookingHistoryController?.fetchBookings();
        Get.back(result: true);
        Get.back();
        CustomLogger.logMessage(
          msg: "Player Added To the Match $body",
          level: LogLevel.info,
        );
        return true;
      } else {
        CustomLogger.logMessage(msg: response?.message ?? "Failed to add player", level: LogLevel.error);
        return false;
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Error :-> $e", level: LogLevel.error);
      return false;
    }
  }
  void preloadLoginUserData() {
    if (Get.isRegistered<ProfileController>()) {
      final profileController = Get.find<ProfileController>();
      final profile = profileController.profileModel.value;

      if (profile?.response != null) {
        final user = profile!.response!;
        nameController.text = user.name?.capitalizeFirst ?? '';
        // lastNameController.text = user.lastName?.capitalizeFirst ?? '';
        emailController.text = user.email ?? '';
        phoneController.text = "${user.phoneNumber ?? ''}";
        gender.value = user.gender ?? '';

        // Extract level code from full level string
        final userLevel = user.playerLevel ?? user.level ?? '';
        final levelCode = _extractLevelCode(userLevel);
        playerLevel.value = levelCode;

        isLoginUserAdding.value = true;
      }
    }
  }

  String _extractLevelCode(String value) {
    if (value.isEmpty) return '';
    final parts = value.split(RegExp(r"\s*[–-]\s*"));
    final code = parts.isNotEmpty ? parts.first.trim() : '';
    return code;
  }

  ////
  var numberLoader = false.obs;
  var isNameFromApi = false.obs;
  var isGenderFromApi = false.obs;
  void resetNameField() {
    if (isNameFromApi.value) {
      nameController.clear();
      isNameFromApi.value = false;
    }
    if (isGenderFromApi.value) {
      gender.value = '';
      isGenderFromApi.value = false;
    }
  }

  Future<void> getUserDataFromNumber(String phoneNumber) async {
    if (phoneNumber.length != 10) return;

    try {
      numberLoader.value = true;
      final result = await repository.getCustomerNameByPhoneNumber(
          phoneNumber: phoneNumber);

      if (result.result?.name != null && result.result!.name!.isNotEmpty) {
        nameController.text = result.result?.name ??"";
        isNameFromApi.value = true;

        if (result.result?.gender != null && result.result!.gender!.isNotEmpty) {
          gender.value = result.result?.gender ??"";
          isGenderFromApi.value = true;
        } else {
          isGenderFromApi.value = false;
        }
      } else {
        isNameFromApi.value = false;
        isGenderFromApi.value = false;
      }

    } catch (e, st) {
        CustomLogger.logMessage(
          msg: "Failed to fetch user data: ${e.toString()}",
          level: LogLevel.error,
          st: st,
        );
        isNameFromApi.value = false;
        isGenderFromApi.value = false;
      } finally {
    numberLoader.value = false;
    }
  }

  ///Get Players Level Api------------------------------------------------------
  var matchLevel = ''.obs;
  var bookingId = ''.obs;
  var requestType = ''.obs;
  Future<void> fetchPlayerLevels() async {
    isLoadingLevels.value = true;
    try {
      final response = await repository.getPlayerLevels(type: matchLevel.value);
      if (response?.status == 200 && response?.data != null) {
        playerLevels.clear();
        for (var levelGroup in response!.data!) {
          for (var level in levelGroup.levelIds ?? []) {
            playerLevels.add({
              "label": "${level.code} - ${level.question}",
              "value": level.code ?? ""
            });
          }
        }
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Error-> $e", level: LogLevel.debug);
    } finally {
      isLoadingLevels.value = false;
    }
  }
  void initializeWithArguments(Map<String, dynamic> args) {
    matchId.value = args["matchId"] ?? "";
    selectedTeam.value = args["team"] ?? "";
    bookingId.value = args["bookingId"]??"";
    scoreboardId.value = args["scoreBoardId"] ?? "";
    openMatchId.value = args["openMatchId"] ?? "";
    matchLevel.value = args["matchLevel"] ?? "";
    requestId.value = args["requestId"] ?? "";
    requestType.value = args["requestType"] ?? "";
    isMatchCreator.value = args["isMatchCreator"] ?? false;

    if (args["needAllOpenMatches"] == true &&
        Get.isRegistered<AllOpenMatchController>()) {
      allOpenMatchController = Get.find<AllOpenMatchController>();
    }
    if (args["needBottomAllOpenMatches"] == true &&
        Get.isRegistered<OpenMatchBookingController>()) {
      openMatchBookingController = Get.find<OpenMatchBookingController>();
    }

    if (args["needOpenMatches"] == true &&
        Get.isRegistered<OpenMatchesController>()) {
      openMatchesController = Get.find<OpenMatchesController>();
    }

    if (args["needAsGuest"] == true &&
        Get.isRegistered<ScoreBoardController>()) {
      scoreBoardController = Get.find<ScoreBoardController>();
    }
    if (args["needOpenMatchesForAllCourts"] == true &&
        Get.isRegistered<OpenMatchForAllCourtController>()) {
      openMatchForAllCourtController = Get.find<OpenMatchForAllCourtController>();
    }

    if (args["needBookingHistory"] == true &&
        Get.isRegistered<BookingHistoryController>(tag: 'booking_history')) {
      bookingHistoryController = Get.find<BookingHistoryController>(tag: 'booking_history');
    }

    // Check if login user wants to add themselves
    final userId = storage.read('userId');
    if (args["isLoginUser"] == true && userId != null) {
      preloadLoginUserData();
    }

    // fetchPlayerLevels();
  }

  void clearTextFields() {
    nameController.clear();
    emailController.clear();
    phoneController.clear();
    gender.value = '';
    isNameFromApi.value = false;
    isGenderFromApi.value = false;
    isLoginUserAdding.value = false;
  }

  @override
  void onInit() {
    final args = Get.arguments;
    if (args != null) {
      initializeWithArguments(args);
    }
    super.onInit();
  }
}
