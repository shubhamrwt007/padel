import 'dart:developer';
import 'package:padel_mobile/configs/components/app_toast.dart';
import 'package:padel_mobile/data/request_models/create_review_model.dart';
import 'package:padel_mobile/data/response_models/get_location_maps_model.dart';
import 'package:padel_mobile/data/response_models/get_register_club_model.dart';
import 'package:padel_mobile/data/response_models/get_review_model.dart';
import 'package:padel_mobile/presentations/booking/widgets/booking_exports.dart';
import 'package:padel_mobile/repositories/home_repository/home_repository.dart';
import 'package:padel_mobile/repositories/review_repo/review_repository.dart';
import 'package:url_launcher/url_launcher.dart';
import '../../../data/request_models/home_models/get_club_name_model.dart' hide Data;

class HomeContentController extends GetxController{
  var selectedIndex = 0.obs;
  final isShowAllReviews = false.obs;
  final isShowAllPhotos = false.obs;
  final List<Map<String, dynamic>> homeOptionsList = [
    {'icon': Icons.directions, 'label': 'Direction', 'isSvg': false},
    {'icon': Icons.call_outlined, 'label': 'Call', 'isSvg': false},
    {'image': Assets.imagesIcReview, 'label': 'Reviews', 'isSvg': true},
    {'icon': Icons.photo_library_outlined, 'label': 'Photos', 'isSvg': false},
  ];

  ///Get Review Api-------------------------------------------------------------
  final ReviewRepository reviewRepository = Get.put(ReviewRepository());
  var reviewResponse = Rxn<GetReviewModel>();
  var isLoading = false.obs;

  // Get all reviews for current club
  List<Reviews> get displayedReviews {
    if (reviewResponse.value?.data == null || reviewResponse.value!.data!.isEmpty) return [];

    final clubId = Get.arguments['clubId'];
    final clubData = reviewResponse.value!.data!.firstWhere(
      (data) => data.registerClubId == clubId,
      orElse: () => GetReviewData(),
    );

    if (clubData.reviews == null) return [];

    return clubData.reviews!;
  }
  Future<void> fetchReview()async{
    isLoading.value = true;
    try{
      final response = await reviewRepository.getReview();
      reviewResponse.value = response;
      if(response.data != null){
        isLoading.value = false;
        CustomLogger.logMessage(msg: "Fetched Data ->${response.data}", level: LogLevel.debug);
      }
    }catch(e){
      CustomLogger.logMessage(msg: e, level: LogLevel.error);
    }finally{
      isLoading.value =false;
    }
  }

  ///Create Review Api----------------------------------------------------------
  var createResponse = Rxn<CreateReviewModel>();
  var isApiLoading = false.obs;
  Courts argument = Courts();
  TextEditingController reviewController = TextEditingController();
  var reviewRating = 0.0.obs;
  Future<void> createReview()async{
    isApiLoading.value =true;
    try{
      final body={
        "reviewComment":reviewController.text.trim(),
        "reviewRating":reviewRating.value,
        "register_club_id":argument.id!
      };
      final response = await reviewRepository.createReview(data: body);
      createResponse.value = response;
      if(response.review != null){
        log("FETCH SUCCESS->${response.message}");
       await fetchReview();
      }
    }catch(e){
      CustomLogger.logMessage(msg: e, level: LogLevel.error);
    }finally{
      isApiLoading.value =false;
    }
  }

  ///Get Register Club Find ById------------------------------------------------
  var registerClubResponse = Rxn<GetRegisterClubModel>();
  HomeRepository homeRepository = Get.put(HomeRepository());
  Future<void> fetchRegisterClub(String clubId, {String? courtId}) async {
    try {
      isLoading.value = true;

      final response = await homeRepository.getRegisterClub(clubId: clubId, courtId: courtId);
      registerClubResponse.value = response;
      address.value = response.data?.location?.address??"";
      if (response.success == true) {
        CustomLogger.logMessage(msg: "Fetching Register Club Successfully", level: LogLevel.info);
        // Call fetchLocationUrl after address is set
        if(address.value.isNotEmpty) {
          await fetchLocationUrl(address.value);
        }
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "ERROR-> $e", level: LogLevel.error);
    } finally {
      isLoading.value = false;
    }
  }

  ///Get Maps URL---------------------------------------------------------------
  var mapsUrl = Rxn<GetLocationMapsModel>();
  var address = ''.obs;
  var mapLatitude = 30.7333.obs;
  var mapLongitude = 76.7794.obs;
  var isIframeUrl = false.obs;
  var iframeUrl = ''.obs;
  Future<void> fetchLocationUrl(String address) async {
    try {
      isLoading.value = true;

      final response = await homeRepository.getLocationMaps(address: address);
      mapsUrl.value = response;

      if (response.status == 200) {
        final mapUrl = response.data?.mapUrl ?? '';
        final directLink = response.data?.directLink ?? '';
        
        // Convert search URL to embed URL
        String embedUrl = '';
        
        if (directLink.isNotEmpty) {
          embedUrl = _convertToEmbedUrl(directLink, address);
        } else if (mapUrl.isNotEmpty) {
          embedUrl = _convertToEmbedUrl(mapUrl, address);
        }
        
        if (embedUrl.isNotEmpty) {
          isIframeUrl.value = true;
          iframeUrl.value = embedUrl;
          CustomLogger.logMessage(msg: "Using embed URL: $embedUrl", level: LogLevel.info);
        } else {
          isIframeUrl.value = false;
          CustomLogger.logMessage(msg: "No valid map URL found", level: LogLevel.warning);
        }
        
        CustomLogger.logMessage(msg: "Fetching Maps Location Successfully", level: LogLevel.info);
      }
    } catch (e) {
      CustomLogger.logMessage(msg: "ERROR-> $e", level: LogLevel.error);
    } finally {
      isLoading.value = false;
    }
  }

  String _convertToEmbedUrl(String url, String address) {
    try {
      // If already an embed URL, return as is
      if (url.contains('/embed')) {
        return url;
      }
      
      // Extract query from search URL
      String query = '';
      if (url.contains('query=')) {
        final uri = Uri.parse(url);
        query = uri.queryParameters['query'] ?? address;
      } else {
        query = Uri.encodeComponent(address);
      }
      
      // Create embed URL
      return 'https://www.google.com/maps/embed/v1/place?key=AIzaSyBFw0Qbyq9zTFTd-tUY6dZWTgaQzuU17R8&q=$query';
    } catch (e) {
      CustomLogger.logMessage(msg: "Error converting to embed URL: $e", level: LogLevel.error);
      return '';
    }
  }

  String _extractIframeUrl(String mapUrl) {
    try {
      // Extract src from iframe
      RegExp iframeRegex = RegExp(r'src="([^"]+)"');
      Match? match = iframeRegex.firstMatch(mapUrl);
      if (match != null) {
        return match.group(1)!;
      }
      // If it's already a direct URL
      if (mapUrl.startsWith('http')) {
        return mapUrl;
      }
      return '';
    } catch (e) {
      CustomLogger.logMessage(msg: "Error extracting iframe URL: $e", level: LogLevel.error);
      return '';
    }
  }

  void _extractCoordinatesFromUrl(String mapUrl) {
    try {
      if (mapUrl.isEmpty) return;

      // Parse different Google Maps URL formats
      List<RegExp> patterns = [
        RegExp(r'@(-?\d+\.\d+),(-?\d+\.\d+)'),           // @lat,lng
        RegExp(r'q=(-?\d+\.\d+),(-?\d+\.\d+)'),           // q=lat,lng
        RegExp(r'll=(-?\d+\.\d+),(-?\d+\.\d+)'),          // ll=lat,lng
        RegExp(r'center=(-?\d+\.\d+),(-?\d+\.\d+)'),      // center=lat,lng
        RegExp(r'destination=(-?\d+\.\d+),(-?\d+\.\d+)'), // destination=lat,lng
        RegExp(r'place/[^/]+/@(-?\d+\.\d+),(-?\d+\.\d+)'), // place/@lat,lng
        RegExp(r'maps/place/[^/]+/(-?\d+\.\d+),(-?\d+\.\d+)'), // maps/place/lat,lng
        RegExp(r'(-?\d+\.\d+),(-?\d+\.\d+)'),           // Simple lat,lng
      ];

      for (RegExp pattern in patterns) {
        Match? match = pattern.firstMatch(mapUrl);
        if (match != null) {
          mapLatitude.value = double.parse(match.group(1)!);
          mapLongitude.value = double.parse(match.group(2)!);
          CustomLogger.logMessage(msg: "Extracted coordinates: ${mapLatitude.value}, ${mapLongitude.value}", level: LogLevel.info);
          return;
        }
      }

      // If no pattern matches, try iframe extraction as fallback
      String extractedUrl = _extractIframeUrl(mapUrl);
      if (extractedUrl.isNotEmpty) {
        isIframeUrl.value = true;
        iframeUrl.value = extractedUrl;
      } else {
        mapLatitude.value = 30.7333;
        mapLongitude.value = 76.7794;
        CustomLogger.logMessage(msg: "No coordinates found in URL, using fallback", level: LogLevel.info);
      }

    } catch (e) {
      mapLatitude.value = 30.7333;
      mapLongitude.value = 76.7794;
      CustomLogger.logMessage(msg: "Error extracting coordinates: $e", level: LogLevel.error);
    }
  }

  // Future<void> openGoogleMaps() async {
  //   final encodedAddress = Uri.encodeComponent(address.value);
  //   final url = 'https://www.google.com/maps/search/?api=1&query=$encodedAddress';
  //
  //   if (await canLaunchUrl(Uri.parse(url))) {
  //     await launchUrl(Uri.parse(url), mode: LaunchMode.externalApplication);
  //   } else {
  //     CustomLogger.logMessage(msg: "Could not launch Google Maps", level: LogLevel.error);
  //   }
  // }

  Future<void> makePhoneCall() async {
    final phoneNumber = registerClubResponse.value?.data?.ownerPhoneNumber;
    if (phoneNumber == null) {
      AppToast.error("Phone number not available");
      CustomLogger.logMessage(msg: "Phone number not available", level: LogLevel.error);
      return;
    }
    
    final url = 'tel:$phoneNumber';
    if (await canLaunchUrl(Uri.parse(url))) {
      await launchUrl(Uri.parse(url));
    } else {
      CustomLogger.logMessage(msg: "Could not launch phone dialer", level: LogLevel.error);
    }
  }

  @override
  void onInit()async {
    argument = Get.arguments['data'];
    log("Register club id = >${argument.id!}");
   final clubId = Get.arguments['clubId'];
   final courtId = argument.courts?.isNotEmpty == true ? argument.courts!.first.id : null;
   await fetchReview();
   await fetchRegisterClub(clubId, courtId: courtId);
    super.onInit();
  }
}





