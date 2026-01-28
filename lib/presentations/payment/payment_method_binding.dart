import 'package:get/get.dart';
import 'package:padel_mobile/presentations/payment/payment_method_controller.dart';

class PaymentMethodBinding implements Bindings {
  @override
  void dependencies() {
    // Keep existing controller when coming from book session or cart (they put before navigate).
    if (!Get.isRegistered<PaymentMethodController>()) {
      Get.put(PaymentMethodController());
    }
  }
}