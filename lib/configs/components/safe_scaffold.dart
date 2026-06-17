import 'package:flutter/material.dart';
import 'safe_bottom_container.dart';

/// [SafeScaffold] ek premium drop-in replacement hai Flutter ke regular [Scaffold] ka.
/// Jab aap isme [bottomNavigationBar] lagayenge, toh ye automatically use humare
/// [SafeBottomContainer] ke andar wrap kar dega, jisse aapko har screen par manual
/// safe area padding ke calculations nahi karne padenge.
/// 
/// ### Example Usage:
/// ```dart
/// return SafeScaffold(
///   appBar: AppBar(title: Text("My Screen")),
///   body: Center(child: Text("Hello")),
///   // Custom bottom bar configuration
///   bottomBarBackgroundColor: Colors.white,
///   bottomBarBorderRadius: BorderRadius.vertical(top: Radius.circular(30)),
///   bottomNavigationBar: Container(
///     height: 60,
///     child: Center(child: Text("Bottom Bar Content")),
///   ),
/// );
/// ```
class SafeScaffold extends StatelessWidget {
  /// Regular Scaffold ka body
  final Widget? body;

  /// Regular Scaffold ka AppBar
  final PreferredSizeWidget? appBar;

  /// Regular Scaffold ka custom bottom navigation bar widget.
  /// Is widget ko automatically [SafeBottomContainer] mein wrap kiya jayega.
  final Widget? bottomNavigationBar;

  /// Floating Action Button widget
  final Widget? floatingActionButton;

  /// Floating Action Button ki placement location
  final FloatingActionButtonLocation? floatingActionButtonLocation;

  /// Sidebar drawer widget
  final Widget? drawer;

  /// Pure scaffold ka background color
  final Color? backgroundColor;

  /// Kya keyboard aane par scaffold automatically resize hona chahiye? Default: true
  final bool resizeToAvoidBottomInset;

  /// Kya scaffold body ko bottom bar ke niche tak extend hona chahiye? Default: false
  final bool extendBody;

  /// Kya scaffold body ko status bar ke niche tak extend hona chahiye? Default: false
  final bool extendBodyBehindAppBar;

  // Safe bottom container ki customization settings:
  
  /// Bottom bar ka background color. Iska use niche ki extra system padding ko background dene ke liye hota hai.
  final Color bottomBarBackgroundColor;

  /// Bottom bar ki corner rounding radius.
  final BorderRadiusGeometry? bottomBarBorderRadius;

  /// Bottom bar ke niche padne wali box shadow list.
  final List<BoxShadow>? bottomBarBoxShadow;

  /// Bottom bar ke upar min bottom space gap.
  final double minBottomPadding;

  /// Agar [true] hoga (default), toh safe padding sirf tabhi apply hogi jab bottom navigation buttons active honge (yaani bottom padding >= [buttonsThreshold]).
  /// iPhones aur generic screen gestures ke liye normal padding rahegi.
  final bool onlyForButtons;

  /// System bottom buttons ki height threshold (typically >= 40.0 pixels Android navigation buttons ke liye)
  final double buttonsThreshold;

  const SafeScaffold({
    super.key,
    this.body,
    this.appBar,
    this.bottomNavigationBar,
    this.floatingActionButton,
    this.floatingActionButtonLocation,
    this.drawer,
    this.backgroundColor,
    this.resizeToAvoidBottomInset = true,
    this.extendBody = false,
    this.extendBodyBehindAppBar = false,
    this.bottomBarBackgroundColor = Colors.white,
    this.bottomBarBorderRadius,
    this.bottomBarBoxShadow,
    this.minBottomPadding = 0.0,
    this.onlyForButtons = true,
    this.buttonsThreshold = 40.0,
  });

  @override
  Widget build(BuildContext context) {
    Widget? wrappedBottomBar;

    if (bottomNavigationBar != null) {
      wrappedBottomBar = SafeBottomContainer(
        backgroundColor: bottomBarBackgroundColor,
        borderRadius: bottomBarBorderRadius,
        boxShadow: bottomBarBoxShadow,
        minBottomPadding: minBottomPadding,
        onlyForButtons: onlyForButtons,
        buttonsThreshold: buttonsThreshold,
        child: bottomNavigationBar!,
      );
    }

    return Scaffold(
      appBar: appBar,
      body: body,
      bottomNavigationBar: wrappedBottomBar,
      floatingActionButton: floatingActionButton,
      floatingActionButtonLocation: floatingActionButtonLocation,
      drawer: drawer,
      backgroundColor: backgroundColor,
      resizeToAvoidBottomInset: resizeToAvoidBottomInset,
      extendBody: extendBody,
      extendBodyBehindAppBar: extendBodyBehindAppBar,
    );
  }
}
