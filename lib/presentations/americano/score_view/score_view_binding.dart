import 'package:padel_mobile/presentations/americano/widgets/americano_exports.dart';
class ScoreViewBinding implements Bindings{
  @override
  void dependencies() {
    Get.put(ScoreViewController());
  }
}