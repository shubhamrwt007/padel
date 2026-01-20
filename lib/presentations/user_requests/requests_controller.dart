import 'package:get/get.dart';
import 'package:padel_mobile/presentations/booking/widgets/booking_exports.dart';
import 'package:padel_mobile/data/response_models/openmatch_model/get_requests_player_open_match_model.dart';

class RequestsController extends GetxController {
  RxInt expandedIndex = (-1).obs;

  void toggleExpand(int index) {
    expandedIndex.value = expandedIndex.value == index ? -1 : index;
  }

  RxInt selectedTab = 0.obs; // 0 = Join, 1 = My
  void changeTab(int index) => selectedTab.value = index;

  final OpenMatchRepository repository = Get.put(OpenMatchRepository());
  RxList<Requests> joinRequests = <Requests>[].obs;
  RxList<Requests> myRequests = <Requests>[].obs;
  RxBool isLoadingRequests = false.obs;

  void deleteRequest(int index) {
    if (selectedTab.value == 0) {
      if (index >= 0 && index < joinRequests.length) {
        joinRequests.removeAt(index);
        // Reset expanded index if needed
        if (expandedIndex.value == index) {
          expandedIndex.value = -1;
        } else if (expandedIndex.value > index) {
          expandedIndex.value = expandedIndex.value - 1;
        }
      }
    } else {
      if (index >= 0 && index < myRequests.length) {
        myRequests.removeAt(index);
        // Reset expanded index if needed
        if (expandedIndex.value == index) {
          expandedIndex.value = -1;
        } else if (expandedIndex.value > index) {
          expandedIndex.value = expandedIndex.value - 1;
        }
      }
    }
  }

  @override
  void onInit() {
    super.onInit();
    fetchJoinRequests();
    fetchMyRequests();
  }
  Future<void> fetchJoinRequests() async {
    try {
      isLoadingRequests.value = true;
      joinRequests.clear();

      final response = await repository.getRequestPlayersOpenMatch(type: "both",filter: "request");

      if (response != null && response.requests != null) {
        joinRequests.addAll(response.requests!);
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Error fetching join requests: $e", level: LogLevel.error);
      // Get.snackbar("Error", "Failed to fetch join requests");
    } finally {
      isLoadingRequests.value = false;
    }
  }

  Future<void> fetchMyRequests() async {
    try {
      isLoadingRequests.value = true;
      myRequests.clear();

      final response = await repository.getRequestPlayersOpenMatch(type: "both",filter: "invitation");

      if (response != null && response.requests != null) {
        requestIds.clear();
        requestIds.addAll(response.requests!.map((request) => request.id ?? "").where((id) => id.isNotEmpty));
        myRequests.addAll(response.requests!);
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Error fetching my requests: $e", level: LogLevel.error);
      // Get.snackbar("Error", "Failed to fetch my requests");
    } finally {
      isLoadingRequests.value = false;
    }
  }

  Future<void> acceptPlayerRequest(String requestId, String matchId, String team) async {
    try {
      isLoadingRequests.value = true;
      final body = {
        "requestId": requestId,
        "action": "accept",
        "type": "MatchCreator"
      };
      final response = await repository.acceptOrRejectRequestPlayer(body:  body,);
      
      if (response != null) {
        // Remove the accepted request from the list
        joinRequests.removeWhere((request) => request.id == requestId);
        // Get.snackbar("Success", "Player request accepted successfully");
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "Error accepting player request: $e", level: LogLevel.error);
    } finally {
      isLoadingRequests.value = false;
    }
  }

  RxList<String> requestIds = <String>[].obs;
  Future<void> withdrawRequest(String requestId) async {
    if (requestId.isNotEmpty) {
      try {
        isLoadingRequests.value = true;
        final response = await repository.withdrawRequest(id: requestId);

        if (response.status == 200) {
          CustomLogger.logMessage(msg: response.message ?? "", level: LogLevel.debug);
          // Remove the request from the list after successful withdrawal
          myRequests.removeWhere((request) => request.id == requestId);
          // Get.snackbar("Success", "Request withdrawn successfully");
        }
      } catch (e) {
        CustomLogger.logMessage(msg: "Error request: $e", level: LogLevel.error);
        // Get.snackbar("Error", "Failed to withdraw request");
      } finally {
        isLoadingRequests.value = false;
      }
    }
  }

  Future<void> refreshData() async {
    if (selectedTab.value == 0) {
      await fetchJoinRequests();
    } else {
      await fetchMyRequests();
    }
  }
}