import 'package:get/get.dart';
import 'package:padel_mobile/presentations/booking/widgets/booking_exports.dart';
import 'package:padel_mobile/data/response_models/openmatch_model/get_requests_player_open_match_model.dart';

class YourMatchRequestsController extends GetxController {
  RxInt expandedIndex = (-1).obs;

  void toggleExpand(int index) {
    expandedIndex.value =
        expandedIndex.value == index ? -1 : index;
  }

  final OpenMatchRepository repository = Get.put(OpenMatchRepository());
  RxList<Requests> joinRequests = <Requests>[].obs;
  RxBool isLoadingRequests = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchJoinRequests();
  }

  Future<void> fetchJoinRequests() async {
    try {
      isLoadingRequests.value = true;
      joinRequests.clear();

      final response = await repository.getRequestPlayersOpenMatch();

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
}