import 'package:get/get.dart';

import 'live_stream_americano_controller.dart';

class LiveStreamAmericanoBinding implements Bindings{
  @override
  void dependencies() {
    Get.put(LiveStreamAmericanoController());
  }

}