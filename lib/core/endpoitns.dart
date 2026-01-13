class AppEndpoints {
  AppEndpoints._();
  // /// -----------------------Live URL-------------------------------------------
  // static const String baseUrl = "http://103.185.212.117:5070/api/customer/";
  // static const String socketUrl = "http://103.185.212.117:5070";

  /// -----------------------Staging URL-------------------------------------------
  static const String baseUrl = "http://103.142.118.40:5080/api/customer/";
  static const String socketUrl = "http://103.142.118.40:5080";

  /// -----------------------New Live URL-------------------------------------------
  // static const String baseUrl = "https://apimobile.swootapp.com/api/customer/";
  // static const String socketUrl = "https://apimobile.swootapp.com";

  // ///-----------------------Local URL-------------------------------------------
  // static const String baseUrl = "http://192.168.0.129:5070/api/customer/";
  // static const String socketUrl = "http://192.168.0.129:5070";


  // static const String login = "${baseUrl}customerLogin";
  static const String login = "${baseUrl}customerLoginByPhoneNumber";
  static const String deleteAccount = "${baseUrl}deleteCustomer";

  static const String signUp = "${baseUrl}customerSignup";
  static const String fetchUserProfile = "${baseUrl}getCustomer";
  static const String updateUserProfile = "${baseUrl}updateCustomer";
  static const String sendOTP = "${baseUrl}sentOtp";

  static const String verifyOTP = "${baseUrl}verifyOtp";
  static const String resetPassword = "${baseUrl}forgotPassword";
  ///Home Register Club---------------------------------------------------------
  static const String getRegisterClub = "${baseUrl}court/registerCourt/getClubById?";
  static const String getClub ="${baseUrl}court/registerCourt/getAllRegisteredCourts?limit=";
  static const String getAllActiveCourtsForSlotWise = "${baseUrl}court/saveCourt/getAllActiveCourtsForSlotWise?";
  static const String getAllSlotPricesOfCourt = "${baseUrl}court/price/prices?";
  static const String getCourtsByDuration = "${baseUrl}court/saveCourt/getCourtsByDuration?";
  static const String getLocations = "${baseUrl}court/state/getStates";
  ///Cart Urls------------------------------------------------------------------
  static const String getCartItems = "${baseUrl}court/cart/getCartForUser";
  static const String addCartItems = "${baseUrl}court/cart/createCarts";
  static const String removeCartItems = "${baseUrl}court/cart/removeUserCart";
  static const String cancelBooking = "${baseUrl}court/booking/updateBookingStatus";
  static const String carteBooking = "${baseUrl}court/booking/createBooking";
  static const String bookingHistory = "${baseUrl}court/booking/getUserBookings";
  static const String bookingConfirmation = "${baseUrl}court/booking/findById";
  static const String createAndGetSlotHistory = "${baseUrl}court/booking/createOrGetSlotHistory";
  static const String deleteSlotHistory = "${baseUrl}court/booking/deleteSlotHistory";
  static const String deleteBulkSlotHistory = "${baseUrl}court/booking/deleteBluckSlotHistory";
  ///Review---------------------------------------------------------------------
  static const String getReview = "${baseUrl}court/review/getReviews";
  static const String createReview = "${baseUrl}court/review/saveCustomerReview";
  ///Open Matches---------------------------------------------------------------
  static const String createMatches = "${baseUrl}court/openmatch/createOpenMatch";
  static const String findNearByPlayer = "${baseUrl}court/openmatch/findNearByPLayers";
  static const String getCustomerNameByPhoneNumber = "${baseUrl}court/booking/getCustomerDataByPhoneNumber?";
  static const String withdrawRequest = "${baseUrl}court/openmatch/withDrawMatchRequest/";
  // static const String getParticularMatch = "${BASE_URL}court/openmatch/findByOpenMatchId?_id=68d2300a723257df65e574ab";
  static const String getOpenMatches = "${baseUrl}court/openmatch/getOpenMatches";
  static const String createUserForOpenMatch = "${baseUrl}customerSignupWithOutPassword";
  static const String addUserForOpenMatch = "${baseUrl}court/openmatch/addPlayerToMatch";
  static const String requestUserForOpenMatch = "${baseUrl}court/openmatch/requestToJoin";
  static const String acceptOrRejectRequestUserForOpenMatch = "${baseUrl}court/openmatch/respondToRequest";
  static const String getRequestUserForOpenMatch = "${baseUrl}court/openmatch/pendingRequests?";
  static const String openMatchBooking = "${baseUrl}court/openmatch/getAllOpenMatches";
  static const String getPlayersLevel = "${baseUrl}getPlayerLevelBySKillLevel";
  ///Notification---------------------------------------------------------------
  static const String getNotification = "${baseUrl}court/userNotification/readNotification";
  static const String getNotificationMarkAsRead = "${baseUrl}court/userNotification/markAsRead";
  static const String getNotificationMarkAsReadALl = "${baseUrl}court/userNotification/markAsAllAsRead";
  static const String getNotificationCount = "${baseUrl}court/userNotification/ureadCountData";
  ///ScoreBoard-----------------------------------------------------------------
  static const String createScoreBoard = "${baseUrl}court/scoreboard/createScoreboard";
  static const String getScoreBoard = "${baseUrl}court/scoreboard/getScoreboards";
  static const String updateScoreBoard = "${baseUrl}court/scoreboard/updateScoreboard";

  ///Google Maps Api------------------------------------------------------------
  static const String getLocationMaps = "${baseUrl}GetgoogleMap?";

  ///Wallet---------------------------------------------------------------------
  static const String getTransaction = "${baseUrl}wallet/getWalletTransaction";
  static const String getWallet = "${baseUrl}wallet/getWallet";
  static const String testWalletCreate = "${baseUrl}wallet/testWalletCreate";

  ///LeaderBoard----------------------------------------------------------------
  static const String getLeaderBoard = "${baseUrl}court/leaderBoard/player";
}
