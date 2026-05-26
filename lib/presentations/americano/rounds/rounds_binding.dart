import 'package:padel_mobile/presentations/americano/widgets/americano_exports.dart';
class RoundsBinding implements Bindings{
  @override
  void dependencies() {
    Get.put(RoundsController());
  }
}