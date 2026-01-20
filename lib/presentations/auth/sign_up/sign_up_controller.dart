// SignUpController.dart
import 'dart:developer';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:padel_mobile/handler/text_formatter.dart';
import 'package:padel_mobile/data/request_models/authentication_models/sign_up_model.dart';
import 'package:padel_mobile/presentations/auth/sign_up/widgets/sign_up_exports.dart';
import 'package:padel_mobile/presentations/notification/notification_controller.dart';
import 'package:padel_mobile/repositories/openmatches/open_match_repository.dart';

class SignUpController extends GetxController {
  SignUpRepository signUpRepository = SignUpRepository();
  LoginRepository loginRepository = LoginRepository();

  final formKey = GlobalKey<FormState>();

  // final firstNameController = TextEditingController();
  // final lastNameController = TextEditingController();
  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = TextEditingController();
  // final passwordController = TextEditingController();
  // final confirmPasswordController = TextEditingController();

  final emailFocusNode = FocusNode();
  final phoneFocusNode = FocusNode();
  final passwordFocusNode = FocusNode();

  RxBool isLoading = false.obs;



  String? validateEmail() {
    if (emailController.text.isEmpty) {
      return "Email is required";
    } else if (!GetUtils.isEmail(emailController.text)) {
      return "Invalid email format";
    }
    return null;
  }

  String? validatePhone() {
    if (phoneController.text.isEmpty) {
      return "Phone number is required";
    } else if (!GetUtils.isPhoneNumber(phoneController.text)) {
      return "Invalid phone number";
    }
    return null;
  }

  // String? validatePassword() {
  //   if (passwordController.text.isEmpty) {
  //     return "Password is required";
  //   } else if (!passwordController.text.isValidPassword) {
  //     return "Invalid password format";
  //   }
  //   return null;
  // }
  void onFieldSubmit() async {
    if (phoneFocusNode.hasFocus) {
      phoneFocusNode.unfocus();
      emailFocusNode.requestFocus();
    } else if (emailFocusNode.hasFocus) {
      emailFocusNode.unfocus();
      passwordFocusNode.requestFocus();
    } else if (passwordFocusNode.hasFocus) {
      passwordFocusNode.unfocus();
    }
  }

  //Password--------------------------------------------------------------------
  var hasSpecialChar = false.obs;
  var hasNumber = false.obs;
  var hasCapitalLetter = false.obs;
  RxBool isVisiblePassword = true.obs;
  var isPasswordFocused = false.obs;
  void passwordToggle() => isVisiblePassword.value = !isVisiblePassword.value;
  void checkPasswordConditions(String password) {
    hasSpecialChar.value = RegExp(r'[!@#\$&*~]').hasMatch(password);
    hasNumber.value = RegExp(r'[0-9]').hasMatch(password);
    hasCapitalLetter.value = RegExp(r'[A-Z]').hasMatch(password);
  }
  @override
  void onInit() async{
    await fetchLocations();
    passwordFocusNode.addListener(() {
      isPasswordFocused.value = passwordFocusNode.hasFocus;
    });
    super.onInit();
  }
  @override
  void onClose() {
    phoneFocusNode.dispose();
    emailFocusNode.dispose();
    passwordFocusNode.dispose();
    // passwordController.dispose();
    super.onClose();
  }



  Future<void> onCreate() async {
    FocusManager.instance.primaryFocus!.unfocus();
    if (formKey.currentState!.validate()) {
      try {
        if (isLoading.value) return;

        isLoading.value = true;

        bool userExists = await getUserDataFromNumber(phoneController.text.trim());
        
        if (!userExists) {
          await sendOTP();
        } else {
          Fluttertoast.showToast(
            msg: "Phone number ${phoneController.text.trim()} already exists",
            toastLength: Toast.LENGTH_SHORT,
            gravity: ToastGravity.BOTTOM,
            backgroundColor: Colors.red,
            textColor: Colors.white,
            fontSize: 16.0,
            timeInSecForIosWeb: 3,
          );
        }
      } catch (e) {
        log(e.toString());
      } finally {
        isLoading.value = false;
      }
    }
  }

  Future<void> sendOTP() async {
    if (selectedGender.value.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please select your gender",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
        timeInSecForIosWeb: 2,
      );
      return;
    }
    else if (selectedLocation.value.isEmpty) {
      Fluttertoast.showToast(
        msg: "Please select your Location",
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
        timeInSecForIosWeb: 2,
      );
      return;
    }
    Map<String, dynamic> body = {
      // "email": emailController.text.trim(),
      "phoneNumber": phoneController.text.trim(),
      "type": "Signup",
    };
    var result = await signUpRepository.sendOTP(body: body);
    if (result.status == "200") {
      Get.toNamed(
        RoutesName.otp,
        arguments: {
          // "email": emailController.text.trim(),
          "phoneNumber": phoneController.text.trim(),
          "type": OtpScreenType.createAccount,
          // "name": firstNameController.text.trim(),
          // "lastName": lastNameController.text.trim(),
        },
      );
    } else {
      Fluttertoast.showToast(
        msg: result.message!,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
        timeInSecForIosWeb: 3,
      );
    }
  }

  Future<void> createAccount() async {
    final body = {
      "email": emailController.text.trim(),
      "name": nameController.text.trim(),
      // "name": firstNameController.text.trim(),
      // "lastName": lastNameController.text.trim(),
      "countryCode": "+91",
      "phoneNumber": phoneController.text.trim(),
      // "password": passwordController.text.trim(),
      "city": selectedLocation.value,
      "gender": selectedGender.value,
      // "agreeTermsAndCondition": true,
      // "location": {
      //   "type": "Point",
      //   "coordinates": [77.5946, 12.9716],
      // },
    };

    log("Signup Body: $body");

    SignUpModel result = await signUpRepository.createAccount(body: body);

    if (result.status == "200") {
      /// 🔥 Get FCM token (same logic as login)
      final firebaseToken = await getFcmToken();

      /// Auto-login after signup
      final loginBody = {
        "phoneNumber": phoneController.text.trim(),
        // "password": passwordController.text.trim(),
      };
      
      if (firebaseToken != null && firebaseToken.isNotEmpty) {
        loginBody["fcmToken"] = firebaseToken;
      }
      
      LoginModel loginResult = await loginRepository.loginUser(body: loginBody);

      if (loginResult.status == "200") {
        storage.write('token', loginResult.response!.token);
        storage.write('userId', loginResult.response!.user!.id);
        Get.offAllNamed(RoutesName.bottomNav);
      }

    } else {
      Fluttertoast.showToast(
        msg: result.message!,
        toastLength: Toast.LENGTH_SHORT,
        gravity: ToastGravity.BOTTOM,
        backgroundColor: Colors.red,
        textColor: Colors.white,
        fontSize: 16.0,
        timeInSecForIosWeb: 3,
      );
    }
  }
  Future<String?> getFcmToken() async {
    // Try to read FCM token from storage
    String? firebaseToken = storage.read('firebase_token');

    // If empty → request permissions & refresh token
    if (firebaseToken == null || firebaseToken.isEmpty) {
      final notificationController = NotificationController.instance;
      await notificationController.requestPermissions();
      await notificationController.refreshToken();
      firebaseToken = notificationController.getStoredToken();
    }

    return firebaseToken;
  }

  var numberLoader = false.obs;
  OpenMatchRepository openMatchRepository = Get.put(OpenMatchRepository());
  Future<bool> getUserDataFromNumber(String phoneNumber) async {
    if (phoneNumber.length != 10) return false;

    try {
      numberLoader.value = true;
      final result = await openMatchRepository.getCustomerNameByPhoneNumber(
          phoneNumber: phoneNumber);

      if (result.result != null && result.result?.name != null && result.result!.name!.isNotEmpty) {
        return true; // User found
      } else {
        return false; // User not found
      }

    } catch (e, st) {
      CustomLogger.logMessage(
        msg: "Failed to fetch user data: ${e.toString()}",
        level: LogLevel.error,
        st: st,
      );
      return false; // Error means user not found
    } finally {
      numberLoader.value = false;
    }
  }
  
  ///Gender field----------------------------------------------------
  var selectedGender = ''.obs;
  final List<String> genderOptions = ['Male', 'Female', 'Others'];

  ///Get Location Api----------------------------------------------------
  var isLocationLoading = false.obs;
  var locations = <GetLocationData>[].obs;
  var selectedLocation = ''.obs;
  Future<void>fetchLocations()async{
    isLocationLoading.value = true;
    try{
      final response = await signUpRepository.getLocations();
      if(response.status == true){
        locations.assignAll(response.data?.toList()??[]);
      }
    }catch(e){
      CustomLogger.logMessage(msg: "Error :-> $e", level: LogLevel.error);
    }finally{
      isLocationLoading.value = false;
    }
  }

}
