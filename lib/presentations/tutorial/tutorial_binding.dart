import 'package:get/get.dart';
import 'package:padel_mobile/presentations/tutorial/tutorial_controller.dart';

class TutorialBinding implements Bindings{
  @override
  void dependencies() {
    Get.put(TutorialController());
  }
}