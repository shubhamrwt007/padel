import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:padel_mobile/presentations/auth/forgot_password/forgot_password_binding.dart';
import 'package:padel_mobile/presentations/auth/forgot_password/forgot_password_screen.dart';
import 'package:padel_mobile/presentations/auth/otp/otp_binding.dart';
import 'package:padel_mobile/presentations/auth/otp/otp_screen.dart';
import 'package:padel_mobile/presentations/auth/sign_up/sign_up_binding.dart';
import 'package:padel_mobile/presentations/auth/sign_up/sign_up_screen.dart';
import 'package:padel_mobile/presentations/book_a_court/book_a_court_binding.dart';
import 'package:padel_mobile/presentations/book_a_court/book_a_court_screen.dart';
import 'package:padel_mobile/presentations/booking/americano/americano_binding.dart';
import 'package:padel_mobile/presentations/booking/americano/americano_screen.dart';
import 'package:padel_mobile/presentations/booking/open_matches/all_open_matches/all_open_match_binding.dart';
import 'package:padel_mobile/presentations/booking/open_matches/all_open_matches/all_open_match_screen.dart';
import 'package:padel_mobile/presentations/booking/open_matches/create_open_matches/create_open_matches_binding.dart';
import 'package:padel_mobile/presentations/booking/open_matches/create_open_matches/create_open_matches_screen.dart';
import 'package:padel_mobile/presentations/bookinghistory/booking_history_binding.dart';
import 'package:padel_mobile/presentations/bookinghistory/booking_history_screen.dart';
import 'package:padel_mobile/presentations/booking/booking_binding.dart';
import 'package:padel_mobile/presentations/booking/booking_confirmation/booking_confirm_and_cancel_binding.dart';
import 'package:padel_mobile/presentations/booking/booking_confirmation/booking_confirm_and_cancel_screen.dart';
import 'package:padel_mobile/presentations/booking/booking_screen.dart';
import 'package:padel_mobile/presentations/bottomnav/bottom_nav.dart';
import 'package:padel_mobile/presentations/chat/chat_screen.dart';
import 'package:padel_mobile/presentations/home/home_binding.dart';
import 'package:padel_mobile/presentations/home/home_screen.dart';
import 'package:padel_mobile/presentations/leaderBoard/leader_board_binding.dart';
import 'package:padel_mobile/presentations/leaderBoard/leader_board_screen.dart';
import 'package:padel_mobile/presentations/league/league_binding.dart';
import 'package:padel_mobile/presentations/league/league_match_lists/league_match_list_binding.dart';
import 'package:padel_mobile/presentations/league/league_match_lists/league_match_list_screen.dart';
import 'package:padel_mobile/presentations/league/league_screen.dart';
import 'package:padel_mobile/presentations/league/live_and_complete_league_match_details/live_and_complete_league_match_binding.dart';
import 'package:padel_mobile/presentations/league/live_and_complete_league_match_details/live_and_complete_league_match_screen.dart';
import 'package:padel_mobile/presentations/main_home_page/main_home_binding.dart';
import 'package:padel_mobile/presentations/main_home_page/main_home_screen.dart';
import 'package:padel_mobile/presentations/notification/notification_binding.dart';
import 'package:padel_mobile/presentations/notification/notification_ui.dart';
import 'package:padel_mobile/presentations/open_match_for_all_court/create_open_match_for_all_courts/create_open_match_for_all_courts_binding.dart';
import 'package:padel_mobile/presentations/open_match_for_all_court/create_open_match_for_all_courts/create_open_match_for_all_courts_screen.dart';
import 'package:padel_mobile/presentations/open_match_for_all_court/open_match_for_all_court_binding.dart';
import 'package:padel_mobile/presentations/open_match_for_all_court/open_match_for_all_court_screen.dart';
import 'package:padel_mobile/presentations/packages/packages_binding.dart';
import 'package:padel_mobile/presentations/packages/packages_screen.dart';
import 'package:padel_mobile/presentations/payment_filter/payment_filter.dart';
import 'package:padel_mobile/presentations/payment_filter/payment_filter_binding.dart';
import 'package:padel_mobile/presentations/paymentwallet/payment_wallet_binding.dart';
import 'package:padel_mobile/presentations/paymentwallet/payment_wallet_screen.dart';
import 'package:padel_mobile/presentations/profile/edit_profile/edit_profile_binding.dart';
import 'package:padel_mobile/presentations/profile/edit_profile/edit_profile_screen.dart';
import 'package:padel_mobile/presentations/profile/profile_binding.dart';
import 'package:padel_mobile/presentations/cart/cart_binding.dart';
import 'package:padel_mobile/presentations/cart/cart_screen.dart';
import 'package:padel_mobile/presentations/payment/payment_method_binding.dart';
import 'package:padel_mobile/presentations/payment/payment_method_screen.dart';
import 'package:padel_mobile/presentations/registration/registration_binding.dart';
import 'package:padel_mobile/presentations/rounds/rounds_binding.dart';
import 'package:padel_mobile/presentations/rounds/rounds_screen.dart';
import 'package:padel_mobile/presentations/score_board/score_board_binding.dart';
import 'package:padel_mobile/presentations/score_board/score_board_screen.dart';
import 'package:padel_mobile/presentations/scoreview/score_view_binding.dart';
import 'package:padel_mobile/presentations/splash/splash_screen.dart';
import 'package:padel_mobile/presentations/support/support_binding.dart';
import 'package:padel_mobile/presentations/support/support_screen.dart';
import 'package:padel_mobile/presentations/tournaments/fip_promises/fip_promises_binding.dart';
import 'package:padel_mobile/presentations/tournaments/fip_promises/fip_promises_screen.dart';
import 'package:padel_mobile/presentations/tournaments/join_tournament/join_tournament_binding.dart';
import 'package:padel_mobile/presentations/tournaments/join_tournament/join_tournament_screen.dart';
import 'package:padel_mobile/presentations/tournaments/live_tournament/live_tournament_binding.dart';
import 'package:padel_mobile/presentations/tournaments/live_tournament/live_tournament_screen.dart';
import 'package:padel_mobile/presentations/tournaments/tournaments_binding.dart';
import 'package:padel_mobile/presentations/tournaments/tournaments_screen.dart';
import 'package:padel_mobile/presentations/tutorial/tutorial_binding.dart';
import 'package:padel_mobile/presentations/tutorial/tutorial_screen.dart';
import 'package:padel_mobile/presentations/user_requests/requests_binding.dart';
import 'package:padel_mobile/presentations/user_requests/requests_screen.dart';
import 'package:padel_mobile/presentations/wallet/wallet_binding.dart';
import 'package:padel_mobile/presentations/wallet/wallet_screen.dart';
import 'package:padel_mobile/presentations/xp_points/xp_points_binding.dart';
import 'package:padel_mobile/presentations/xp_points/xp_points_screen.dart';
import '../../presentations/auth/login/login_binding.dart';
import '../../presentations/auth/login/login_screen.dart';
import '../../presentations/booking/open_matches/open_match_screen.dart';
import '../../presentations/booking/open_matches/questions/create_question_binding.dart';
import '../../presentations/booking/open_matches/questions/create_question_screen.dart';
import '../../presentations/bottomnav/bottom_nav_binding.dart';
import '../../presentations/chat/chat_binding.dart';
import '../../presentations/booking/open_matches/open_match_binding.dart';
import '../../presentations/openmatchbooking/openmatch_booking_binding.dart';
import '../../presentations/openmatchbooking/openmatch_booking_screen.dart';
import '../../presentations/profile/profile_screen.dart';
import '../../presentations/registration/registration_americano_screen.dart';
import '../../presentations/scoreview/score_view_screen.dart';
import '../../presentations/splash/splash_binding.dart';
import 'routes_name.dart';
class Routes {
  static const String initialRoute = RoutesName.bottomNav;
  static const Duration defaultDuration = Duration(milliseconds: 300);
  static final route = [
    GetPage(
      name: RoutesName.splash,
      page: () => const SplashScreen(),
      binding: SplashBinding(),
      transition: Transition.fadeIn,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.login,
      page: () => LoginScreen(),
      binding: LoginBinding(),
      transition: Transition.fadeIn,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.otp,
      page: () => const OtpScreen(),
      binding: OtpBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.signUp,
      page: () => const SignUpScreen(),
      binding: SignUpBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.forgotPassword,
      curve: Curves.easeIn,
      page: () => const ForgotPasswordScreen(),
      binding: ForgotPasswordBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.home,
      page: () => HomeScreen(),
      binding: HomeBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.mainHomePage,
      page: () => MainHomeScreen(),
      binding: MainHomeBinding(),
      transition: Transition.fadeIn,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.bottomNav,
      page: () => BottomNavUi(),
      binding: BottomNavigationBinding(),
      transition: Transition.fadeIn,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.profile,
      page: () => ProfileUi(),
      binding: ProfileBinding(),
      transition: Transition.fadeIn,
      transitionDuration: defaultDuration,
    ),
     GetPage(
      name: RoutesName.editProfile,
      page: () => EditProfileUi(),
      binding: EditProfileBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.booking,
      page: () => BookingScreen(),
      binding: BookingBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.cart,
      page: () => CartScreen(buttonType: ''),
      binding: CartBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.paymentMethod,
      page: () => PaymentMethodScreen(),
      binding: PaymentMethodBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.bookingHistory,
      page: () => BookingHistoryUi(),
      binding: BookingHistoryBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.paymentWallet,
      page: () => PaymentWalletScreen(),
      binding: PaymentWalletBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.bookingConfirmAndCancel,
      page: () => BookingConfirmAndCancelScreen(),
      binding: BookingConfirmAndCancelBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.paymentFilter,
      page: () => PaymentFilterUi(),
      binding: PaymentFilterBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.support,
      page: () => SupportScreen(),
      binding: SupportBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.chat,
      page: () => ChatScreen(),
      binding: ChatBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.notification,
      page: () => NotificationScreen(),
      binding: NotificationBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.rounds,
      page: () => RoundsScreen(),
      binding: RoundsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.score,
      page: () => ScoreViewScreen(),
      binding: ScoreViewBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.americano,
      page: () => AmericanoScreen(),
      binding: AmericanoBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.registration,
      page: () => RegistrationView(),
      binding: RegistrationBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),

    ///Package------------------------------------------------------------------
    GetPage(
      name: RoutesName.packages,
      page: () => PackagesUi(),
      binding: PackagesBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),

    ///Open Matches-------------------------------------------------------------
    GetPage(
      name: RoutesName.openMatch,
      page: () => OpenMatchesScreen(),
      binding: OpenMatchBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.allOpenMatch,
      page: () => AllOpenMatchScreen(),
      binding: AllOpenMatchBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.createQuestions,
      page: () => CreateQuestionsScreen(),
      binding: CreateQuestionsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.createOpenMatch,
      page: () => CreateOpenMatchesScreen(),
      binding: CreateOpenMatchesBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    ///New UI-------------------------------------------------------------------
    GetPage(
      name: RoutesName.openMatchForAllCourts,
      page: () => const OpenMatchForAllCourtScreen(),
      binding: OpenMatchForAllCourtBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.createOpenMatchForAllCourts,
      page: () => CreateOpenMatchForAllCourtsScreen(),
      binding: CreateOpenMatchForAllCourtsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.bookACourt,
      page: () => BookACourtScreen(),
      binding: BookACourtBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.matchBooking,
      page: () => OpenMatchBookingScreen(),
      binding: OpenMatchBookingBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),

    ///LeaderBoard--------------------------------------------------------------
    GetPage(
      name: RoutesName.leaderBoard,
      page: () => LeaderboardScreen(),
      binding: LeaderboardBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),

    ///ScoreBoard---------------------------------------------------------------
    GetPage(
      name: RoutesName.scoreBoard,
      page: () => ScoreBoardScreen(),
      binding: ScoreBoardBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    ///Requests-----------------------------------------------------------------
   GetPage(
      name: RoutesName.requests,
      page: () => RequestsScreen(),
      binding: RequestsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),

    ///Wallet-------------------------------------------------------------------
    GetPage(
      name: RoutesName.wallet,
      page: () => WalletScreen(),
      binding: WalletBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),


    ///XP Points----------------------------------------------------------------
    GetPage(
      name: RoutesName.xpPoints,
      page: () => XpPointsScreen(),
      binding: XpPointsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    ///Tutorial----------------------------------------------------------------
    GetPage(
      name: RoutesName.tutorial,
      page: () => TutorialScreen(),
      binding: TutorialBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),

    ///Tournaments----------------------------------------------------------------
    GetPage(
      name: RoutesName.tournaments,
      page: () => TournamentsScreen(),
      binding: TournamentsBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.fipPromises,
      page: () => FipPromisesScreen(),
      binding: FipPromisesBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.liveTournament,
      page: () => LiveTournamentScreen(),
      binding: LiveTournamentBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.joinTournament,
      page: () => JoinTournamentScreen(),
      binding: JoinTournamentBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),

    ///League-------------------------------------------------------------------
    GetPage(
      name: RoutesName.league,
      page: () => LeagueScreen(),
      binding: LeagueBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.leagueMatchLists,
      page: () => LeagueMatchListScreen(),
      binding: LeagueMatchListBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
    GetPage(
      name: RoutesName.liveAndCompleteLeagueMatch,
      page: () => LiveAndCompleteLeagueMatchScreen(),
      binding: LiveAndCompleteLeagueMatchBinding(),
      transition: Transition.rightToLeft,
      transitionDuration: defaultDuration,
    ),
  ];
}
