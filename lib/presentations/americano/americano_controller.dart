import 'package:padel_mobile/presentations/americano/widgets/americano_exports.dart';
import 'package:padel_mobile/repositories/americano_repository/americano_repository.dart';
import 'package:padel_mobile/data/response_models/americano_models/get_americano_model.dart';
import 'package:padel_mobile/handler/logger.dart';
import 'package:padel_mobile/presentations/main_home_page/main_home_controller.dart';

class AmericanoController extends GetxController {

  final AmericanoRepository _repository = AmericanoRepository();
  final ScrollController scrollController = ScrollController();

  RxList<AmericanoMatch> ongoingMatches = <AmericanoMatch>[].obs;
  RxList<AmericanoMatch> upcomingMatches = <AmericanoMatch>[].obs;

  RxBool isLoading = false.obs;
  RxBool isLoadingMore = false.obs;
  RxInt currentPage = 1.obs;
  RxBool hasMore = true.obs;
  final int limit = 10;

  bool get isEmpty => ongoingMatches.isEmpty && upcomingMatches.isEmpty;

  @override
  void onInit() {
    super.onInit();
    scrollController.addListener(_scrollListener);
    fetchAmericanoMatches(isRefresh: true);
  }

  void _scrollListener() {
    if (scrollController.position.pixels >= scrollController.position.maxScrollExtent - 200) {
      if (!isLoading.value && !isLoadingMore.value && hasMore.value) {
        loadMoreAmericanoMatches();
      }
    }
  }

  Future<void> fetchAmericanoMatches({bool isRefresh = false}) async {
    // If it is a pull-to-refresh (lists are not empty), do not show fullscreen loader
    final bool isPullToRefresh = isRefresh && (ongoingMatches.isNotEmpty || upcomingMatches.isNotEmpty);

    if (isRefresh) {
      currentPage.value = 1;
      hasMore.value = true;
      if (!isPullToRefresh) {
        isLoading.value = true;
        ongoingMatches.clear();
        upcomingMatches.clear();
      }
    } else {
      if (isLoading.value || isLoadingMore.value || !hasMore.value) return;
      isLoadingMore.value = true;
    }

    try {
      final response = await _repository.getAmericanos(
        page: currentPage.value,
        limit: limit,
      );

      if (response != null && response.data != null) {
        final data = response.data!;
        final upcoming = data.upcomingAmericanos ?? [];
        final ongoing = data.ongoingAmericanos ?? [];

        if (upcoming.isEmpty && ongoing.isEmpty) {
          hasMore.value = false;
          if (isRefresh) {
            ongoingMatches.clear();
            upcomingMatches.clear();
          }
        } else {
          if (isRefresh) {
            ongoingMatches.assignAll(ongoing);
            upcomingMatches.assignAll(upcoming);
          } else {
            ongoingMatches.addAll(ongoing);
            upcomingMatches.addAll(upcoming);
          }
          
          final totalP = response.pagination?.totalPages ?? 1;
          hasMore.value = currentPage.value < totalP;
        }
      } else {
        hasMore.value = false;
        if (isRefresh) {
          ongoingMatches.clear();
          upcomingMatches.clear();
        }
      }
      
      if (Get.isRegistered<MainHomeController>()) {
        Get.find<MainHomeController>().hasAmericanoMatches.value = !isEmpty;
      }
    } catch (e) {
      CustomLogger.logMessage(
        msg: "Error fetching Americanos: $e",
        level: LogLevel.error,
      );
    } finally {
      isLoading.value = false;
      isLoadingMore.value = false;
    }
  }

  Future<void> loadMoreAmericanoMatches() async {
    if (isLoadingMore.value || !hasMore.value) return;
    currentPage.value++;
    await fetchAmericanoMatches(isRefresh: false);
  }

  @override
  void onClose() {
    scrollController.dispose();
    super.onClose();
  }
}