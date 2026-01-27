import 'package:get/get.dart';
import 'package:padel_mobile/presentations/xp_points/xp_points_controller.dart';

class XpPointsBinding implements Bindings{
  @override
  void dependencies() {
    Get.put(XpPointsController());
  }

}