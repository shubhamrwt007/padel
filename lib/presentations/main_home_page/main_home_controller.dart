import 'package:get/get.dart';
import 'package:padel_mobile/core/network/dio_client.dart';
import 'package:padel_mobile/presentations/profile/profile_controller.dart';
import 'package:padel_mobile/presentations/home/home_controller.dart';
import 'package:padel_mobile/repositories/home_repository/home_repository.dart';
import 'package:padel_mobile/data/response_models/home_models/get_near_city_players_model.dart';

class MainHomeController extends GetxController{
  final ProfileController profileController = Get.put(ProfileController());
  final HomeController homeController = Get.put(HomeController());
  final HomeRepository _homeRepository = HomeRepository();
  
  final Rx<GetNearCityPlayers?> nearCityPlayers = Rx<GetNearCityPlayers?>(null);
  final RxBool isLoadingPlayers = false.obs;
  
  @override
  void onInit()async {
    super.onInit();
    homeController.fetchBookings();
    await fetchNearCityPlayers();
  }
  
  Future<void> fetchNearCityPlayers() async {
    try {
      isLoadingPlayers.value = true;
      final userId = storage.read('userId')??"";
      if (userId != null) {
        final response = await _homeRepository.getNearCityPlayers(id: userId);
        nearCityPlayers.value = response;
      }
    } catch (e) {
      print('Error fetching near city players: $e');
    } finally {
      isLoadingPlayers.value = false;
    }
  }
}