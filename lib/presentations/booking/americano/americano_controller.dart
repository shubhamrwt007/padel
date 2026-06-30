import 'package:padel_mobile/presentations/booking/widgets/booking_exports.dart';
import '../../../data/response_models/americano_models/get_americano_model.dart';

class AmericanoController extends GetxController {
  RxList<AmericanoMatch> upcomingAmericanos = <AmericanoMatch>[].obs;
  RxList<AmericanoMatch> ongoingAmericanos = <AmericanoMatch>[].obs;
  RxBool isLoading = false.obs;

  @override
  void onInit() {
    super.onInit();
    fetchAmericanos();
  }

  Future<void> fetchAmericanos() async {
    // TODO: Replace with your actual API call
    // This is a placeholder - you need to implement the actual API call
    isLoading.value = true;
    try {
      // Example: 
      // final response = await yourApiService.getAmericanos();
      // upcomingAmericanos.value = response.data?.upcomingAmericanos ?? [];
      // ongoingAmericanos.value = response.data?.ongoingAmericanos ?? [];
    } catch (e) {
      print('Error fetching americanos: $e');
    } finally {
      isLoading.value = false;
    }
  }
}