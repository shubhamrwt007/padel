import 'package:padel_mobile/presentations/booking/widgets/booking_exports.dart';
import 'package:padel_mobile/presentations/splash/widgets/splash_exports.dart';

class SplashScreen extends StatelessWidget {
  const SplashScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return PrimaryContainer(
      child: Scaffold(
        backgroundColor: Colors.transparent,
        body: Center(
            child:
            SvgPicture.asset(Assets.images.padelLogo11.path,height: 60,width: 60,)),
      ),
    );
  }
}
