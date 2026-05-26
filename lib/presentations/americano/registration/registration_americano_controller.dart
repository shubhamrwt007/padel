import 'package:flutter/material.dart';
import 'package:get/get.dart';

class RegistrationAmericanoController extends GetxController {
  final int playerCount = 2;

  final fullNameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();

  RxString selectedGender = ''.obs;
  RxString playerLevel = ''.obs;

  final Map<String, String> playerLevelMap = {
    'A': 'A – Top Player',
    'B1': 'B1 – Experienced Player',
    'B2': 'B2 – Advanced Player',
    'C1': 'C1 – Confident Player',
    'C2': 'C2 – Intermediate Player',
    'D1': 'D1 – Amateur Player',
    'D2': 'D2 – Novice Player',
    'E': 'E – Entry Level',
  };

  @override
  void onInit() {
    super.onInit();
  }
}
