import 'package:get/get.dart';
import 'package:padel_mobile/presentations/tournaments/tournaments_controller.dart';

class TournamentsBinding implements Bindings{
  @override
  void dependencies() {
    Get.put(TournamentsController());
  }

}