import 'package:padel_mobile/presentations/americano/widgets/americano_exports.dart';

import 'americano_controller.dart';
class AmericanoBinding implements Bindings{
  @override
  void dependencies() {
    Get.put(AmericanoController());
  }
}