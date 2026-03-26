import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../configs/components/app_toast.dart';
import '../../repositories/support_repository/support_repository.dart';
import '../profile/profile_controller.dart';

class SupportController extends GetxController {
  final titleController = TextEditingController();
  final descriptionController = TextEditingController();
  final formKey = GlobalKey<FormState>();
  final isLoading = false.obs;
  final SupportRepository _repository = SupportRepository();

  Future<void> submitSupport() async {
    if (!formKey.currentState!.validate()) return;

    final profileController = Get.find<ProfileController>();
    final profile = profileController.profileModel.value?.response;

    if (profile == null) {
      AppToast.error("Profile data not available");
      return;
    }

    isLoading.value = true;
    try {
      final body = {
        "title": titleController.text.trim(),
        "msg": descriptionController.text.trim(),
        "email": profile.email ?? "",
        "phoneNumber": profile.phoneNumber?.toString() ?? "",
        "name": profile.name ?? "",
      };

      await _repository.sendSupportRequest(body);
      AppToast.success("Support request submitted successfully");
      titleController.clear();
      descriptionController.clear();
      Get.back();
    } catch (e) {
      AppToast.error("Failed to submit support request");
    } finally {
      isLoading.value = false;
    }
  }

  @override
  void onClose() {
    titleController.dispose();
    descriptionController.dispose();
    super.onClose();
  }
}