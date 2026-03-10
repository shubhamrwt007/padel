import 'package:padel_mobile/presentations/profile/widgets/profile_exports.dart';

class TutorialScreen extends StatefulWidget {
  final String? buttonType;
  const TutorialScreen({super.key,this.buttonType});

  @override
  State<TutorialScreen> createState() =>
      _TutorialScreenState();
}

class _TutorialScreenState extends State<TutorialScreen> {
  final PageController _pageController = PageController();
  int currentIndex = 0;

  final List<String> images = [
    Assets.imagesTutorialScreenPng1,
    Assets.imagesTutorialScreenPng2,
    Assets.imagesTutorialScreenPng3,
    Assets.imagesTutorialScreenPng4,
  ];

  final List<String> buttonText = [
    "Show Me More",
    "What Else?",
    "Tell Me About XPs!",
    "Let's Play!",
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          /// 🔹 Full Image Pages
          Transform.translate(
            offset: Offset(0, -60),
            child: PageView.builder(
              controller: _pageController,
              itemCount: images.length,
              onPageChanged: (index) {
                setState(() => currentIndex = index);
              },
              itemBuilder: (_, index) {
                return Image.asset(
                  images[index],
                  fit: BoxFit.contain,
                  width: double.infinity,
                  height: double.infinity,
                );
              },
            ),
          ),

          /// 🔹 Top Bar (Back + Skip)
          SafeArea(
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 12),
              child: Row(
                children: [
                  if (currentIndex != 0)
                    IconButton(
                      icon: const Icon(Icons.arrow_back),
                      onPressed: () {
                        _pageController.previousPage(
                          duration: const Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),
                  const Spacer(),
                  if (currentIndex != images.length - 1)
                    TextButton(
                      onPressed: () {
                        _pageController.animateToPage(
                          images.length - 1, // last page
                          duration: const Duration(milliseconds: 400),
                          curve: Curves.easeInOut,
                        );
                      },
                      child: const Text("Skip"),
                    ),
                ],
              ),
            ),
          ),

          /// 🔹 Bottom Content
          Positioned(
            bottom: 60,
            left: 24,
            right: 24,
            child: Column(
              children: [
                /// Dots
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(
                    images.length,
                        (index) => AnimatedContainer(
                      duration: const Duration(milliseconds: 250),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      height: 6,
                      width: currentIndex == index ? 22 : 6,
                      decoration: BoxDecoration(
                        color: currentIndex == index
                            ? AppColors.primaryColor
                            : Colors.grey.shade300,
                        borderRadius: BorderRadius.circular(4),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 20),

                /// CTA Button
                // SizedBox(
                //   width: double.infinity,
                //   height: 52,
                //   child: ElevatedButton(
                //     onPressed: () {
                //       if (currentIndex < images.length - 1) {
                //         _pageController.nextPage(
                //           duration: const Duration(milliseconds: 300),
                //           curve: Curves.easeInOut,
                //         );
                //       } else {
                //         // Final navigation
                //       }
                //     },
                //     child: Text(buttonText[currentIndex]),
                //   ),
                // ),
               GestureDetector(
                 onTap: () {
                   if (currentIndex < images.length - 1) {
                     _pageController.nextPage(
                       duration: const Duration(milliseconds: 300),
                       curve: Curves.easeInOut,
                     );
                   } else {
                     // Final navigation
                     if(widget.buttonType == "home"){
                       print("FromHome--------------------------");
                       Get.back();
                     }else{
                       print("FromSignUp--------------------------");
                       Get.offAllNamed(RoutesName.bottomNav);
                     }
                   }
                 },
                 child: Container(
                   height: 50,
                   width:Get.width,
                   alignment: Alignment.center,
                   padding: const EdgeInsets.all(5),
                   decoration: BoxDecoration(
                     color: AppColors.primaryColor,
                     borderRadius: BorderRadius.circular(5),
                   ),
                   child: Text(buttonText[currentIndex],style: Theme.of(context).textTheme.headlineMedium!.copyWith(
                     color: AppColors.whiteColor,
                     fontWeight: FontWeight.w600,
                     fontSize: 18,
                 ),
               )))
              ],
            ),
          ),
        ],
      ),
    );
  }
}
