import 'package:padel_mobile/presentations/americano/widgets/americano_exports.dart';
class RegistrationAmericanoBinding implements Bindings{
  @override
  void dependencies() {
    Get.put(RegistrationAmericanoController());
  }
}