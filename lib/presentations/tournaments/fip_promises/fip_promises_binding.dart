import 'package:get/get.dart';
import 'package:padel_mobile/presentations/tournaments/fip_promises/fip_promises_controller.dart';

class FipPromisesBinding implements Bindings{
  @override
  void dependencies() {
    Get.put(FipPromisesController());
  }

}